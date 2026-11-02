import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/db/app_database.dart';
import '../../core/networking/ws_service.dart';
import '../../core/protocol/protocol.dart' as pb;
import '../presence/presence.dart';
import 'typing_tracker.dart';

/// Keeps the local database and the server in step. All mutations run through ONE serial queue so a push,
/// a sync page and an outbox flush can never interleave and corrupt the sequence cursor.
///
/// Reliability model (docs/protocol.md): delivery is at-least-once. Duplicates are harmless because every
/// message is stored by its clientMessageId (upsert); gaps are detected from the per-conversation seq
/// and repaired by a forward sync.
class ChatSync {
  ChatSync({
    required this.transport,
    required this.db,
    required this.userId,
    String Function()? newId,
    DateTime Function()? now,
    this.retryDelay = const Duration(seconds: 15),
    this.onTyping,
    this.onPresence,
    this.onPresenceSnapshot,
    TypingThrottle? typingThrottle,
  })  : _newId = newId ?? (() => const Uuid().v4()),
        _now = now ?? DateTime.now,
        _throttle = typingThrottle ?? TypingThrottle();

  final ChatTransport transport;
  final AppDatabase db;
  final String userId;
  final Duration retryDelay;

  /// Ephemeral signals are handed to the UI layer through callbacks; ChatSync itself never stores them.
  final void Function(String conversationId, String userId, bool isTyping)? onTyping;
  final void Function(PresenceInfo info)? onPresence;
  final void Function(List<PresenceInfo> all)? onPresenceSnapshot;
  final TypingThrottle _throttle;
  final String Function() _newId;
  final DateTime Function() _now;

  StreamSubscription<void>? _connSub;
  StreamSubscription<pb.ServerEnvelope>? _pushSub;
  Timer? _retryTimer;
  Future<void> _tail = Future<void>.value();
  bool _disposed = false;

  Future<void> start() async {
    await db.resetSending();
    _connSub = transport.connected.listen((_) => unawaited(_enqueue(_onConnected)));
    _pushSub = transport.pushes.listen((env) => unawaited(_enqueue(() => _onPush(env))));
    if (transport.isConnected) unawaited(_enqueue(_onConnected));
  }

  Future<void> dispose() async {
    _disposed = true;
    _retryTimer?.cancel();
    await _connSub?.cancel();
    await _pushSub?.cancel();
  }

  Future<void> _enqueue(Future<void> Function() job) => _run(job).catchError((Object e) {
        if (e is! ConnectionLost && e is! TimeoutException) debugPrint('sync job failed: $e');
      });

  Future<T> _run<T>(Future<T> Function() job) {
    final c = Completer<T>();
    _tail = _tail.then((_) async {
      if (_disposed) {
        c.completeError(const ConnectionLost());
        return;
      }
      try {
        c.complete(await job());
      } catch (e, s) {
        c.completeError(e, s);
      }
    });
    return c.future;
  }

  // ------------------------------------------------------------------ public actions
  /// Stores the message locally first (it shows up immediately, as "pending"), then tries to send.
  Future<void> sendText(String conversationId, String text) async {
    final body = text.trim();
    if (body.isEmpty) return;
    final nowMs = _now().millisecondsSinceEpoch;
    await db.upsertMessage(MessagesCompanion(
      clientMessageId: Value(_newId()),
      conversationId: Value(conversationId),
      senderId: Value(userId),
      body: Value(body),
      createdAtMs: Value(nowMs),
      status: const Value('pending'),
    ));
    await db.bumpConversation(conversationId, seq: 0, activityMs: nowMs);
    setTyping(conversationId, false); // sending ends "typing"
    unawaited(_enqueue(_flush));
  }

  /// Tells the other members that I am (not) typing. Throttled and best-effort: never queued, never retried.
  void setTyping(String conversationId, bool isTyping) {
    if (!transport.isConnected || !_throttle.shouldSend(conversationId, isTyping)) return;
    transport.notify(pb.ClientEnvelope()
      ..typing = pb.TypingEvent(conversationId: conversationId, isTyping: isTyping));
  }

  Future<void> retry(String clientMessageId) async {
    await db.setStatus(clientMessageId, 'pending');
    unawaited(_enqueue(_flush));
  }

  /// Creates (or finds) the direct conversation with [peerUserId] and returns its id.
  Future<String> createDirect(String peerUserId) => _run(() async {
        final env = await transport.request(
            pb.ClientEnvelope()..createDirect = pb.CreateDirectConversation(peerUserId: peerUserId));
        if (env.whichBody() != pb.ServerEnvelope_Body.conversation) {
          throw const ProtocolFailure(pb.ErrorCode.ERROR_CODE_INTERNAL, 'unexpected response');
        }
        await _applyConversation(env.conversation);
        return env.conversation.conversationId;
      });

  // ------------------------------------------------------------------ groups (Milestone 5)
  // Every call returns after the server confirmed AND the local cache was updated; failures surface as
  // ProtocolFailure (e.g. PERMISSION_DENIED when a non-owner tries to manage members) for the UI to show.
  Future<pb.ConversationInfo> _expectConversation(pb.ClientEnvelope request) async {
    final env = await transport.request(request);
    if (env.whichBody() != pb.ServerEnvelope_Body.conversation) {
      throw const ProtocolFailure(pb.ErrorCode.ERROR_CODE_INTERNAL, 'unexpected response');
    }
    await _applyConversation(env.conversation);
    unawaited(_enqueue(_refreshPresence)); // there may be new people whose presence we have not seen yet
    return env.conversation;
  }

  Future<String> createGroup(String title, List<String> memberUserIds) => _run(() async {
        final info = await _expectConversation(
            pb.ClientEnvelope()..createGroup = pb.CreateGroup(title: title, memberUserIds: memberUserIds));
        return info.conversationId;
      });

  Future<void> addMembers(String conversationId, List<String> userIds) => _run(() async {
        await _expectConversation(
            pb.ClientEnvelope()..addMembers = pb.AddMembers(conversationId: conversationId, userIds: userIds));
      });

  Future<void> removeMember(String conversationId, String userId) => _run(() async {
        await _expectConversation(
            pb.ClientEnvelope()..removeMember = pb.RemoveMember(conversationId: conversationId, userId: userId));
      });

  Future<void> renameGroup(String conversationId, String title) => _run(() async {
        await _expectConversation(
            pb.ClientEnvelope()..renameGroup = pb.RenameGroup(conversationId: conversationId, title: title));
      });

  Future<void> leaveConversation(String conversationId) => _run(() async {
        final env = await transport
            .request(pb.ClientEnvelope()..leaveConversation = pb.LeaveConversation(conversationId: conversationId));
        if (env.whichBody() != pb.ServerEnvelope_Body.conversationRemoved) {
          throw const ProtocolFailure(pb.ErrorCode.ERROR_CODE_INTERNAL, 'unexpected response');
        }
        await db.deleteConversation(conversationId);
      });

  /// Older history for infinite scroll.
  Future<void> loadOlder(String conversationId) => _enqueue(() async {
        final c = await db.conversation(conversationId);
        if (c == null || c.oldestReached || !transport.isConnected) return;
        final minSeq = await db.minSeq(conversationId) ?? 0;
        if (minSeq <= 1) {
          await db.updateConversationSync(conversationId, oldestReached: true);
          return;
        }
        final env = await transport.request(pb.ClientEnvelope()
          ..historyRequest = pb.HistoryRequest(conversationId: conversationId, beforeSeq: Int64(minSeq), limit: 50));
        final batch = _batch(env);
        if (batch == null) return;
        await _store(conversationId, batch.messages);
        await db.updateConversationSync(conversationId, oldestReached: !batch.hasMore);
      });

  /// Marks everything currently known as read (best effort; also cleared locally right away).
  Future<void> markRead(String conversationId) async {
    final seq = await db.maxSeq(conversationId);
    if (seq == 0) return;
    final me = await db.member(conversationId, userId);
    if (me != null && me.readSeq >= seq) return;
    await db.advanceMember(conversationId, userId, delivered: seq, read: seq);
    if (!transport.isConnected) return;
    try {
      await transport.request(pb.ClientEnvelope()
        ..markRead = pb.MarkRead(conversationId: conversationId, readUpToSeq: Int64(seq)));
    } catch (_) {/* the next markRead (or reconnect) will carry it */}
  }

  // ------------------------------------------------------------------ reconnect: list -> sync -> flush
  Future<void> _onConnected() async {
    await _refreshConversations();
    for (final c in await db.allConversations()) {
      await _syncConversation(c.id);
    }
    await _flush();
    await _refreshPresence(); // last: it is cosmetic and must never delay message sync
  }

  /// Presence pushes are best-effort, so after every (re)connect we ask for a fresh snapshot.
  Future<void> _refreshPresence() async {
    try {
      final env = await transport.request(pb.ClientEnvelope()..getPresence = pb.GetPresence());
      if (env.whichBody() == pb.ServerEnvelope_Body.presenceSnapshot) {
        onPresenceSnapshot?.call([for (final u in env.presenceSnapshot.users) PresenceInfo.fromPb(u)]);
      }
    } on ConnectionLost {
      // offline again: nothing to do
    } on TimeoutException {
      // ignore: cosmetic
    } on ProtocolFailure catch (e) {
      debugPrint('presence refresh failed: ${e.code.name}');
    }
  }

  Future<void> _refreshConversations() async {
    final env = await transport.request(pb.ClientEnvelope()..listConversations = pb.ListConversations());
    if (env.whichBody() != pb.ServerEnvelope_Body.conversationList) return;
    final serverIds = <String>{};
    for (final info in env.conversationList.conversations) {
      serverIds.add(info.conversationId);
      await _applyConversation(info);
    }
    // The list is complete, so anything we still hold that is not in it was removed while we were away.
    for (final c in await db.allConversations()) {
      if (!serverIds.contains(c.id)) await db.deleteConversation(c.id);
    }
  }

  Future<void> _applyConversation(pb.ConversationInfo info) async {
    await db.upsertConversation(ConversationsCompanion(
      id: Value(info.conversationId),
      kind: Value(info.kind == pb.ConversationKind.CONVERSATION_KIND_GROUP ? 'group' : 'direct'),
      title: Value(info.title),
      lastSeq: Value(info.lastSeq.toInt()),
      lastActivityMs: Value(info.lastActivityUnixMs.toInt()),
    ));
    await db.replaceMembers(info.conversationId, [
      for (final m in info.members)
        MembersCompanion(
          conversationId: Value(info.conversationId),
          userId: Value(m.userId),
          username: Value(m.username),
          displayName: Value(m.displayName),
          deliveredSeq: Value(m.deliveredUpToSeq.toInt()),
          readSeq: Value(m.readUpToSeq.toInt()),
          role: Value(_roleName(m.role)),
        ),
    ]);
  }

  static String _roleName(pb.MemberRole r) {
    if (r == pb.MemberRole.MEMBER_ROLE_OWNER) return 'owner';
    if (r == pb.MemberRole.MEMBER_ROLE_ADMIN) return 'admin';
    return 'member';
  }

  Future<void> _syncConversation(String id) async {
    final c = await db.conversation(id);
    if (c == null || c.syncCursor >= c.lastSeq) return;
    if (c.syncCursor == 0) {
      // never synced: fetch only the newest page, older pages load on demand
      final env = await transport.request(pb.ClientEnvelope()
        ..historyRequest = pb.HistoryRequest(conversationId: id, beforeSeq: Int64.ZERO, limit: 50));
      final batch = _batch(env);
      if (batch == null) return;
      await _store(id, batch.messages);
      // No visible messages although the conversation has a history (a group we joined later: the server only
      // shows what was said after we joined). Everything up to lastSeq is then "synced", nothing is missing.
      final top = batch.messages.isEmpty ? c.lastSeq : batch.messages.last.seq.toInt();
      await db.updateConversationSync(id, syncCursor: top, oldestReached: !batch.hasMore);
    } else {
      var cursor = c.syncCursor;
      while (true) {
        final env = await transport.request(pb.ClientEnvelope()
          ..syncRequest = pb.SyncRequest(conversationId: id, afterSeq: Int64(cursor), limit: 100));
        final batch = _batch(env);
        if (batch == null || batch.messages.isEmpty) break;
        await _store(id, batch.messages);
        cursor = batch.messages.last.seq.toInt();
        await db.updateConversationSync(id, syncCursor: cursor);
        if (!batch.hasMore) break;
      }
    }
    await _ackDelivered(id);
  }

  pb.MessageBatch? _batch(pb.ServerEnvelope env) =>
      env.whichBody() == pb.ServerEnvelope_Body.batch ? env.batch : null;

  Future<void> _store(String conversationId, List<pb.ChatMessage> msgs) async {
    if (msgs.isEmpty) return;
    var maxSeq = 0, maxMs = 0;
    for (final m in msgs) {
      await db.upsertMessage(MessagesCompanion(
        clientMessageId: Value(m.clientMessageId),
        serverId: Value(m.messageId),
        conversationId: Value(m.conversationId),
        senderId: Value(m.senderId),
        seq: Value(m.seq.toInt()),
        body: Value(m.text),
        createdAtMs: Value(m.createdAtUnixMs.toInt()),
        status: const Value('accepted'),
      ));
      if (m.seq.toInt() > maxSeq) maxSeq = m.seq.toInt();
      if (m.createdAtUnixMs.toInt() > maxMs) maxMs = m.createdAtUnixMs.toInt();
    }
    await db.bumpConversation(conversationId, seq: maxSeq, activityMs: maxMs);
  }

  /// Tell the server (and so the sender) that everything we hold from others is delivered.
  Future<void> _ackDelivered(String conversationId) async {
    final top = await db.maxSeq(conversationId);
    final me = await db.member(conversationId, userId);
    if (top == 0 || (me != null && me.deliveredSeq >= top)) return;
    await db.advanceMember(conversationId, userId, delivered: top);
    try {
      await transport.request(pb.ClientEnvelope()
        ..ackDelivered = pb.DeliveryAck(conversationId: conversationId, deliveredUpToSeq: Int64(top)));
    } catch (_) {/* re-sent after the next sync */}
  }

  // ------------------------------------------------------------------ pushes
  Future<void> _onPush(pb.ServerEnvelope env) async {
    switch (env.whichBody()) {
      case pb.ServerEnvelope_Body.newMessage:
        await _onNewMessage(env.newMessage);
        break;
      case pb.ServerEnvelope_Body.conversation:
        await _applyConversation(env.conversation);
        await _syncConversation(env.conversation.conversationId);
        unawaited(_enqueue(_refreshPresence));
        break;
      case pb.ServerEnvelope_Body.conversationRemoved:
        await db.deleteConversation(env.conversationRemoved.conversationId);
        break;
      case pb.ServerEnvelope_Body.typing:
        final t = env.typing;
        if (t.userId != userId) onTyping?.call(t.conversationId, t.userId, t.isTyping);
        break;
      case pb.ServerEnvelope_Body.presence:
        onPresence?.call(PresenceInfo.fromPb(env.presence));
        break;
      case pb.ServerEnvelope_Body.receipt:
        final r = env.receipt;
        await db.advanceMember(r.conversationId, r.userId,
            delivered: r.deliveredUpToSeq.toInt(), read: r.readUpToSeq.toInt());
        break;
      default:
        break;
    }
  }

  Future<void> _onNewMessage(pb.ChatMessage m) async {
    var c = await db.conversation(m.conversationId);
    if (c == null) {
      await _refreshConversations(); // a conversation we have not seen yet
      c = await db.conversation(m.conversationId);
      if (c == null) return;
    }
    await _store(c.id, [m]);
    onTyping?.call(c.id, m.senderId, false); // a message ends that person's "typing"
    await _noteSeq(c.id, m.seq.toInt());
    if (m.senderId != userId) unawaited(_ackDelivered(c.id));
  }

  /// Advance the contiguous cursor, or repair a gap with a forward sync.
  Future<void> _noteSeq(String conversationId, int seq) async {
    final c = await db.conversation(conversationId);
    if (c == null) return;
    if (seq == c.syncCursor + 1) {
      await db.updateConversationSync(conversationId, syncCursor: seq);
    } else if (seq > c.syncCursor + 1) {
      await _syncConversation(conversationId);
    } // seq <= cursor: a duplicate, already stored by the upsert
  }

  // ------------------------------------------------------------------ outbox
  Future<void> _flush() async {
    if (!transport.isConnected) return;
    for (final m in await db.pendingMessages()) {
      if (!transport.isConnected || !await _sendOne(m)) break;
    }
  }

  /// Returns false when sending should stop for now (offline, rate limited, server trouble).
  Future<bool> _sendOne(MessageRow m) async {
    await db.setStatus(m.clientMessageId, 'sending');
    try {
      final env = await transport.request(pb.ClientEnvelope()
        ..sendMessage = pb.SendMessage(
            conversationId: m.conversationId, clientMessageId: m.clientMessageId, text: m.body));
      if (env.whichBody() != pb.ServerEnvelope_Body.accepted) {
        await db.setStatus(m.clientMessageId, 'pending');
        return false;
      }
      final a = env.accepted;
      await db.markAccepted(m.clientMessageId,
          serverId: a.messageId, seq: a.seq.toInt(), createdAtMs: a.createdAtUnixMs.toInt());
      await db.bumpConversation(m.conversationId, seq: a.seq.toInt(), activityMs: a.createdAtUnixMs.toInt());
      await _noteSeq(m.conversationId, a.seq.toInt());
      return true;
    } on ProtocolFailure catch (e) {
      final transient = e.code == pb.ErrorCode.ERROR_CODE_RATE_LIMITED || e.code == pb.ErrorCode.ERROR_CODE_INTERNAL;
      if (transient) {
        await db.setStatus(m.clientMessageId, 'pending');
        _scheduleRetry();
        return false;
      }
      await db.setStatus(m.clientMessageId, 'failed'); // permanent (not a member, invalid text, ...)
      return true;
    } on ConnectionLost {
      await db.setStatus(m.clientMessageId, 'pending'); // flushed again after the next connect
      return false;
    } on TimeoutException {
      await db.setStatus(m.clientMessageId, 'pending');
      return false;
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(retryDelay, () => unawaited(_enqueue(_flush)));
  }
}

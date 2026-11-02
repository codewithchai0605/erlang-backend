// ChatSync against a fake transport and an in-memory database.
//
// NOTE: the in-memory database needs the native sqlite3 library. If `flutter test` cannot load it on your
// machine, this file fails to start while every other test file still runs; see docs/operations.md.
import 'dart:async';

import 'package:client/core/db/app_database.dart';
import 'package:client/core/networking/ws_service.dart';
import 'package:client/core/protocol/protocol.dart' as pb;
import 'package:client/features/chat/chat_sync.dart';
import 'package:client/features/presence/presence.dart';
import 'package:drift/native.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records what the app sends and answers from a function the test controls.
class FakeTransport implements ChatTransport {
  FakeTransport(this.responder);

  pb.ServerEnvelope Function(pb.ClientEnvelope request) responder;
  bool online = false; // false: start() does not run the reconnect routine unless a test asks for it
  final requests = <pb.ClientEnvelope>[];
  final notifications = <pb.ClientEnvelope>[];
  final _connected = StreamController<void>.broadcast();
  final _pushes = StreamController<pb.ServerEnvelope>.broadcast();

  @override
  bool get isConnected => online;
  @override
  Stream<void> get connected => _connected.stream;
  @override
  Stream<pb.ServerEnvelope> get pushes => _pushes.stream;

  @override
  Future<pb.ServerEnvelope> request(pb.ClientEnvelope envelope) async {
    requests.add(envelope);
    return responder(envelope);
  }

  @override
  void notify(pb.ClientEnvelope envelope) => notifications.add(envelope);

  void push(pb.ServerEnvelope env) => _pushes.add(env);
  void reconnect() {
    online = true;
    _connected.add(null);
  }
}

pb.Member _member(String id, {pb.MemberRole role = pb.MemberRole.MEMBER_ROLE_MEMBER}) =>
    pb.Member(userId: id, username: id, displayName: id.toUpperCase(), role: role);

pb.ConversationInfo _group(String id, {String title = 'Team', int lastSeq = 0, List<pb.Member>? members}) => pb.ConversationInfo(
      conversationId: id,
      kind: pb.ConversationKind.CONVERSATION_KIND_GROUP,
      title: title,
      lastSeq: Int64(lastSeq),
      members: members ?? [_member('me', role: pb.MemberRole.MEMBER_ROLE_OWNER), _member('bob')],
    );

pb.ServerEnvelope _conv(pb.ConversationInfo c) => pb.ServerEnvelope()..conversation = c;

void main() {
  late AppDatabase db;
  late FakeTransport transport;
  late ChatSync sync;
  final typing = <String>[];
  final presence = <PresenceInfo>[];
  final snapshots = <List<PresenceInfo>>[];

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    transport = FakeTransport((req) => pb.ServerEnvelope()..error = pb.ProtocolError(code: pb.ErrorCode.ERROR_CODE_INTERNAL));
    typing.clear();
    presence.clear();
    snapshots.clear();
    sync = ChatSync(
      transport: transport,
      db: db,
      userId: 'me',
      onTyping: (c, u, t) => typing.add('$c/$u/$t'),
      onPresence: presence.add,
      onPresenceSnapshot: snapshots.add,
    );
    await sync.start();
  });

  tearDown(() async {
    await sync.dispose();
    await db.close();
  });

  test('createGroup sends the request, stores the group and its member roles', () async {
    transport.responder = (req) => _conv(_group('g1'));
    final id = await sync.createGroup('Team', ['bob']);

    expect(id, 'g1');
    final sent = transport.requests.single;
    expect(sent.whichBody(), pb.ClientEnvelope_Body.createGroup);
    expect(sent.createGroup.title, 'Team');
    expect(sent.createGroup.memberUserIds, ['bob']);

    final row = await db.conversation('g1');
    expect(row?.kind, 'group');
    expect(row?.title, 'Team');
    final me = await db.member('g1', 'me');
    expect(me?.role, 'owner');
    expect((await db.member('g1', 'bob'))?.role, 'member');
  });

  test('a rejected group action surfaces the server error and changes nothing', () async {
    // the real transport turns an error envelope into a thrown ProtocolFailure; the fake mimics that contract
    transport.responder = (req) => throw const ProtocolFailure(pb.ErrorCode.ERROR_CODE_PERMISSION_DENIED, 'forbidden');
    await expectLater(sync.renameGroup('g1', 'Hijack'), throwsA(isA<ProtocolFailure>()));
    expect(await db.allConversations(), isEmpty);
  });

  test('leaving deletes the conversation, its members and its messages locally', () async {
    transport.responder = (req) => _conv(_group('g1'));
    await sync.createGroup('Team', ['bob']);
    await db.upsertMessage(MessagesCompanion.insert(
        clientMessageId: 'm1', conversationId: 'g1', senderId: 'bob', body: 'hello', createdAtMs: 1, status: 'accepted'));

    transport.responder = (req) => pb.ServerEnvelope()..conversationRemoved = pb.ConversationRemoved(conversationId: 'g1');
    await sync.leaveConversation('g1');

    expect(await db.conversation('g1'), isNull);
    expect(await db.member('g1', 'me'), isNull);
    expect(await db.message('m1'), isNull);
  });

  test('a ConversationRemoved push (removed by the owner) deletes it as well', () async {
    transport.responder = (req) => _conv(_group('g1'));
    await sync.createGroup('Team', ['bob']);

    transport.push(pb.ServerEnvelope()..conversationRemoved = pb.ConversationRemoved(conversationId: 'g1'));
    await pumpEventQueue();

    expect(await db.conversation('g1'), isNull);
  });

  test('typing and presence pushes are forwarded; my own typing echo is ignored', () async {
    transport.push(pb.ServerEnvelope()..typing = pb.TypingUpdate(conversationId: 'c1', userId: 'bob', isTyping: true));
    transport.push(pb.ServerEnvelope()..typing = pb.TypingUpdate(conversationId: 'c1', userId: 'me', isTyping: true));
    transport.push(pb.ServerEnvelope()..presence = pb.PresenceUpdate(userId: 'bob', online: false, lastSeenUnixMs: Int64(42)));
    await pumpEventQueue();

    expect(typing, ['c1/bob/true']);
    expect(presence.single.userId, 'bob');
    expect(presence.single.online, isFalse);
    expect(presence.single.lastSeenMs, 42);
  });

  test('setTyping is throttled and only talks to the server while connected', () async {
    transport.online = false;
    sync.setTyping('c1', true);
    expect(transport.notifications, isEmpty);

    transport.online = true;
    sync.setTyping('c1', true);
    sync.setTyping('c1', true); // inside the throttle window
    sync.setTyping('c1', false);
    expect(transport.notifications.length, 2);
    expect(transport.notifications.first.typing.isTyping, isTrue);
    expect(transport.notifications.last.typing.isTyping, isFalse);
  });

  test('reconnect: the server list is authoritative, conversations we were removed from disappear', () async {
    // the cache holds g1 and g2; while offline we were removed from g2
    transport.responder = (req) => _conv(_group('g2'));
    await sync.createGroup('Old', ['bob']);
    transport.responder = (req) => _conv(_group('g1'));
    await sync.createGroup('Kept', ['bob']);

    transport.responder = (req) {
      if (req.whichBody() == pb.ClientEnvelope_Body.listConversations) {
        return pb.ServerEnvelope()..conversationList = pb.ConversationList(conversations: [_group('g1')]);
      }
      if (req.whichBody() == pb.ClientEnvelope_Body.getPresence) {
        return pb.ServerEnvelope()..presenceSnapshot = pb.PresenceSnapshot(users: [pb.PresenceUpdate(userId: 'bob', online: true)]);
      }
      return pb.ServerEnvelope()..batch = pb.MessageBatch();
    };
    transport.reconnect();
    await pumpEventQueue(times: 50);

    expect((await db.allConversations()).map((c) => c.id), ['g1']);
    expect(snapshots.single.single.online, isTrue); // presence is refreshed after every reconnect
  });

  test('a group joined later: no visible history means "synced up to lastSeq", not "never synced"', () async {
    transport.responder = (req) {
      if (req.whichBody() == pb.ClientEnvelope_Body.listConversations) {
        return pb.ServerEnvelope()..conversationList = pb.ConversationList(conversations: [_group('g9', lastSeq: 10)]);
      }
      if (req.whichBody() == pb.ClientEnvelope_Body.getPresence) return pb.ServerEnvelope()..presenceSnapshot = pb.PresenceSnapshot();
      // history_request: the server hides everything from before we joined
      return pb.ServerEnvelope()..batch = pb.MessageBatch(hasMore: false);
    };
    transport.reconnect();
    await pumpEventQueue(times: 50);

    final c = await db.conversation('g9');
    expect(c?.syncCursor, 10);
    expect(c?.oldestReached, isTrue);
  });
}

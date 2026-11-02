import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// LOCAL CACHE of server state plus the outbox. The server stays authoritative; this lets the UI render
/// instantly and offline, and keeps unsent messages (status pending/failed) across restarts.
@DataClassName('ConversationRow')
class Conversations extends Table {
  TextColumn get id => text()();
  TextColumn get kind => text()(); // direct | group
  TextColumn get title => text().withDefault(const Constant(''))();
  IntColumn get lastSeq => integer().withDefault(const Constant(0))(); // newest seq the server told us about
  IntColumn get syncCursor => integer().withDefault(const Constant(0))(); // newest seq we hold contiguously
  BoolColumn get oldestReached => boolean().withDefault(const Constant(false))();
  IntColumn get lastActivityMs => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MemberRow')
class Members extends Table {
  TextColumn get conversationId => text()();
  TextColumn get userId => text()();
  TextColumn get username => text()();
  TextColumn get displayName => text()();
  IntColumn get deliveredSeq => integer().withDefault(const Constant(0))();
  IntColumn get readSeq => integer().withDefault(const Constant(0))();
  TextColumn get role => text().withDefault(const Constant('member'))(); // owner | admin | member (schema v2)

  @override
  Set<Column> get primaryKey => {conversationId, userId};
}

/// clientMessageId is the primary key for EVERY message (sent or received): the server echoes it, so
/// reconciling an accepted send, receiving a duplicate push and syncing are all the same idempotent upsert.
/// status: pending (outbox) | sending | failed | accepted
@DataClassName('MessageRow')
@TableIndex(name: 'messages_conv_seq', columns: {#conversationId, #seq})
class Messages extends Table {
  TextColumn get clientMessageId => text()();
  TextColumn get serverId => text().nullable()();
  TextColumn get conversationId => text()();
  TextColumn get senderId => text()();
  IntColumn get seq => integer().nullable()();
  TextColumn get body => text()();
  IntColumn get createdAtMs => integer()();
  TextColumn get status => text()();

  @override
  Set<Column> get primaryKey => {clientMessageId};
}

class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.kind,
    required this.groupTitle,
    required this.memberCount,
    required this.peerUserId,
    required this.peerName,
    required this.peerUsername,
    required this.lastBody,
    required this.lastSeq,
    required this.myReadSeq,
    required this.lastActivityMs,
  });

  final String id;
  final String kind;
  final String groupTitle;
  final int memberCount;
  final String? peerUserId; // the other person in a direct chat (drives the presence dot)
  final String? peerName;
  final String? peerUsername;
  final String? lastBody;
  final int lastSeq;
  final int myReadSeq;
  final int lastActivityMs;

  bool get isGroup => kind == 'group';
  String get title => isGroup ? (groupTitle.isEmpty ? 'Group' : groupTitle) : (peerName ?? 'Conversation');
  // My own messages advance my read mark on the server, so this is exactly "messages from others unseen".
  int get unread => lastSeq > myReadSeq ? lastSeq - myReadSeq : 0;
}

@DriftDatabase(tables: [Conversations, Members, Messages])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'chat_cache'));

  @override
  int get schemaVersion => 2;

  /// v1 -> v2: members gained `role`. The cache is disposable (the server is authoritative), but adding a
  /// column is cheap and keeps unsent messages in the outbox intact.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.addColumn(members, members.role);
        },
      );

  // ------------------------------------------------------------------ conversations
  Future<ConversationRow?> conversation(String id) =>
      (select(conversations)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<ConversationRow?> watchConversation(String id) =>
      (select(conversations)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<List<ConversationRow>> allConversations() => select(conversations).get();

  /// The user left, was removed, or the group no longer exists: forget it and everything in it.
  Future<void> deleteConversation(String id) => transaction(() async {
        await (delete(messages)..where((t) => t.conversationId.equals(id))).go();
        await (delete(members)..where((t) => t.conversationId.equals(id))).go();
        await (delete(conversations)..where((t) => t.id.equals(id))).go();
      });

  /// Only the columns present in [c] are written on conflict, so syncCursor etc. survive a list refresh.
  Future<void> upsertConversation(ConversationsCompanion c) => into(conversations).insertOnConflictUpdate(c);

  Future<void> updateConversationSync(String id, {int? syncCursor, bool? oldestReached}) =>
      (update(conversations)..where((t) => t.id.equals(id))).write(ConversationsCompanion(
        syncCursor: syncCursor == null ? const Value.absent() : Value(syncCursor),
        oldestReached: oldestReached == null ? const Value.absent() : Value(oldestReached),
      ));

  Future<void> bumpConversation(String id, {required int seq, required int activityMs}) => customUpdate(
        'UPDATE conversations SET last_seq = MAX(last_seq, ?), last_activity_ms = MAX(last_activity_ms, ?) WHERE id = ?',
        variables: [Variable.withInt(seq), Variable.withInt(activityMs), Variable.withString(id)],
        updates: {conversations},
      );

  Stream<List<ConversationSummary>> watchSummaries(String myUserId) => customSelect(
        'SELECT c.id, c.kind, c.title, c.last_seq, c.last_activity_ms, '
        '(SELECT COUNT(*) FROM members m WHERE m.conversation_id = c.id) AS member_count, '
        '(SELECT m.user_id FROM members m WHERE m.conversation_id = c.id AND m.user_id <> ? LIMIT 1) AS peer_id, '
        '(SELECT m.display_name FROM members m WHERE m.conversation_id = c.id AND m.user_id <> ? LIMIT 1) AS peer_name, '
        '(SELECT m.username FROM members m WHERE m.conversation_id = c.id AND m.user_id <> ? LIMIT 1) AS peer_username, '
        '(SELECT m.read_seq FROM members m WHERE m.conversation_id = c.id AND m.user_id = ?) AS my_read, '
        '(SELECT b.body FROM messages b WHERE b.conversation_id = c.id ORDER BY b.created_at_ms DESC LIMIT 1) AS last_body '
        'FROM conversations c ORDER BY c.last_activity_ms DESC',
        variables: [for (var i = 0; i < 4; i++) Variable.withString(myUserId)],
        readsFrom: {conversations, members, messages},
      ).watch().map((rows) => rows
          .map((r) => ConversationSummary(
                id: r.read<String>('id'),
                kind: r.read<String>('kind'),
                groupTitle: r.read<String>('title'),
                memberCount: r.read<int>('member_count'),
                peerUserId: r.readNullable<String>('peer_id'),
                peerName: r.readNullable<String>('peer_name'),
                peerUsername: r.readNullable<String>('peer_username'),
                lastBody: r.readNullable<String>('last_body'),
                lastSeq: r.read<int>('last_seq'),
                myReadSeq: r.readNullable<int>('my_read') ?? 0,
                lastActivityMs: r.read<int>('last_activity_ms'),
              ))
          .toList());

  // ------------------------------------------------------------------ members / receipts
  Future<void> replaceMembers(String conversationId, List<MembersCompanion> rows) => transaction(() async {
        await (delete(members)..where((t) => t.conversationId.equals(conversationId))).go();
        await batch((b) => b.insertAll(members, rows));
      });

  Future<MemberRow?> member(String conversationId, String userId) =>
      (select(members)..where((t) => t.conversationId.equals(conversationId) & t.userId.equals(userId)))
          .getSingleOrNull();

  Stream<List<MemberRow>> watchMembers(String conversationId) =>
      (select(members)..where((t) => t.conversationId.equals(conversationId))).watch();

  /// Receipts only ever move forward (MAX), so late or duplicate updates are harmless.
  Future<void> advanceMember(String conversationId, String userId, {int delivered = 0, int read = 0}) =>
      customUpdate(
        'UPDATE members SET delivered_seq = MAX(delivered_seq, ?), read_seq = MAX(read_seq, ?) '
        'WHERE conversation_id = ? AND user_id = ?',
        variables: [
          Variable.withInt(delivered),
          Variable.withInt(read),
          Variable.withString(conversationId),
          Variable.withString(userId),
        ],
        updates: {members},
      );

  // ------------------------------------------------------------------ messages / outbox
  Stream<List<MessageRow>> watchMessages(String conversationId) =>
      (select(messages)..where((t) => t.conversationId.equals(conversationId))).watch().map((rows) {
        // accepted messages by seq, then unsent ones by creation time
        final sorted = [...rows]..sort((a, b) {
            final sa = a.seq, sb = b.seq;
            if (sa != null && sb != null) return sa.compareTo(sb);
            if (sa != null) return -1;
            if (sb != null) return 1;
            return a.createdAtMs.compareTo(b.createdAtMs);
          });
        return sorted;
      });

  Future<void> upsertMessage(MessagesCompanion m) => into(messages).insertOnConflictUpdate(m);

  Future<MessageRow?> message(String clientMessageId) =>
      (select(messages)..where((t) => t.clientMessageId.equals(clientMessageId))).getSingleOrNull();

  Future<List<MessageRow>> pendingMessages() => (select(messages)
        ..where((t) => t.status.isIn(['pending', 'sending']))
        ..orderBy([(t) => OrderingTerm.asc(t.createdAtMs)]))
      .get();

  Future<void> setStatus(String clientMessageId, String status) =>
      (update(messages)..where((t) => t.clientMessageId.equals(clientMessageId)))
          .write(MessagesCompanion(status: Value(status)));

  Future<void> markAccepted(String clientMessageId,
          {required String serverId, required int seq, required int createdAtMs}) =>
      (update(messages)..where((t) => t.clientMessageId.equals(clientMessageId))).write(MessagesCompanion(
        serverId: Value(serverId),
        seq: Value(seq),
        createdAtMs: Value(createdAtMs),
        status: const Value('accepted'),
      ));

  /// After a crash/kill, anything stuck in "sending" is simply retried (sends are idempotent).
  Future<void> resetSending() => (update(messages)..where((t) => t.status.equals('sending')))
      .write(const MessagesCompanion(status: Value('pending')));

  Future<int?> minSeq(String conversationId) async {
    final row = await customSelect(
      'SELECT MIN(seq) AS v FROM messages WHERE conversation_id = ? AND seq IS NOT NULL',
      variables: [Variable.withString(conversationId)],
      readsFrom: {messages},
    ).getSingle();
    return row.readNullable<int>('v');
  }

  Future<int> maxSeq(String conversationId) async {
    final row = await customSelect(
      'SELECT MAX(seq) AS v FROM messages WHERE conversation_id = ? AND seq IS NOT NULL',
      variables: [Variable.withString(conversationId)],
      readsFrom: {messages},
    ).getSingle();
    return row.readNullable<int>('v') ?? 0;
  }

  /// Sign-out: the cache belongs to one account.
  Future<void> clearAll() => transaction(() async {
        for (final t in allTables) {
          await delete(t).go();
        }
      });
}

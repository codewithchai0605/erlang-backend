import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/db/app_database.dart';
import 'core/networking/api_client.dart';
import 'core/networking/ws_service.dart';
import 'core/networking/ws_transport.dart';
import 'core/storage/session_storage.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/auth_repository.dart';
import 'features/chat/chat_sync.dart';
import 'features/chat/typing_tracker.dart';
import 'features/presence/presence.dart';

final sessionStorageProvider = Provider<SessionStorage>((ref) => SecureSessionStorage());

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(
      dio: newDio(AppConfig.baseUrl),
      storage: ref.watch(sessionStorageProvider),
    ));

final apiClientProvider = Provider<ApiClient>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  return ApiClient(dio: newDio(AppConfig.baseUrl), tokenProvider: auth.validAccessToken, refresh: auth.refresh);
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final wsServiceProvider = Provider<WsService>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final ws = WsService(
    tokenProvider: auth.validAccessToken,
    transportFactory: IoWsTransport.new,
    onAuthRejected: () async {
      await auth.refresh(); // either gets a fresh token for the next attempt, or signs the user out
    },
  );
  ref.onDispose(ws.dispose);
  return ws;
});

final connectionStatusProvider = StreamProvider<ConnectionStatus>((ref) async* {
  final ws = ref.watch(wsServiceProvider);
  yield ws.status;
  yield* ws.statuses;
});

/// Exists only while signed in: starting it starts the socket + sync engine, and signing out disposes both.
/// It watches ONLY the signed-in user id: profile edits or token refreshes must not reconnect the socket.
final chatSyncProvider = Provider<ChatSync?>((ref) {
  final who = ref.watch(authControllerProvider.select((a) => (a.status, a.session?.userId)));
  final userId = who.$2;
  if (who.$1 != AuthStatus.authenticated || userId == null) return null;
  final ws = ref.read(wsServiceProvider);
  final presence = ref.read(presenceProvider.notifier);
  final typing = ref.read(typingProvider.notifier);
  final sync = ChatSync(
    transport: ws,
    db: ref.read(databaseProvider),
    userId: userId,
    onTyping: typing.apply,
    onPresence: presence.apply,
    onPresenceSnapshot: presence.applyAll,
  );
  sync.start();
  ws.start();
  ref.onDispose(() {
    sync.dispose();
    ws.stop();
  });
  return sync;
});

/// A peer's presence, or null when unknown. Unknown includes "I am offline myself": while disconnected we
/// cannot know anything about anybody, so we show nothing instead of stale information.
final peerPresenceProvider = Provider.autoDispose.family<PresenceInfo?, String>((ref, userId) {
  final status = ref.watch(connectionStatusProvider).value ?? ConnectionStatus.disconnected;
  if (status != ConnectionStatus.connected) return null;
  return ref.watch(presenceProvider.select((m) => m[userId]));
});

/// Ids of the people currently typing in [conversationId] (never includes me).
final typingUsersProvider = Provider.autoDispose.family<Set<String>, String>(
    (ref, conversationId) => ref.watch(typingProvider.select((m) => m[conversationId] ?? const <String>{})));

final conversationProvider = StreamProvider.autoDispose.family<ConversationRow?, String>(
    (ref, conversationId) => ref.watch(databaseProvider).watchConversation(conversationId));

final conversationSummariesProvider = StreamProvider.autoDispose<List<ConversationSummary>>((ref) {
  final me = ref.watch(authControllerProvider).session?.userId;
  if (me == null) return const Stream.empty();
  return ref.watch(databaseProvider).watchSummaries(me);
});

final messagesProvider = StreamProvider.autoDispose.family<List<MessageRow>, String>(
    (ref, conversationId) => ref.watch(databaseProvider).watchMessages(conversationId));

final membersProvider = StreamProvider.autoDispose.family<List<MemberRow>, String>(
    (ref, conversationId) => ref.watch(databaseProvider).watchMembers(conversationId));

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
final chatSyncProvider = Provider<ChatSync?>((ref) {
  final auth = ref.watch(authControllerProvider);
  if (auth.status != AuthStatus.authenticated) return null;
  final ws = ref.read(wsServiceProvider);
  final sync = ChatSync(transport: ws, db: ref.read(databaseProvider), userId: auth.session!.userId);
  sync.start();
  ws.start();
  ref.onDispose(() {
    sync.dispose();
    ws.stop();
  });
  return sync;
});

final conversationSummariesProvider = StreamProvider.autoDispose<List<ConversationSummary>>((ref) {
  final me = ref.watch(authControllerProvider).session?.userId;
  if (me == null) return const Stream.empty();
  return ref.watch(databaseProvider).watchSummaries(me);
});

final messagesProvider = StreamProvider.autoDispose.family<List<MessageRow>, String>(
    (ref, conversationId) => ref.watch(databaseProvider).watchMessages(conversationId));

final membersProvider = StreamProvider.autoDispose.family<List<MemberRow>, String>(
    (ref, conversationId) => ref.watch(databaseProvider).watchMembers(conversationId));

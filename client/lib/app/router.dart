import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/chat/conversation_info_screen.dart';
import '../features/chat/new_group_screen.dart';
import '../features/home/home_shell.dart';
import '../features/settings/settings_screen.dart';

/// Routes: /splash (restoring session), /login, /register, /chats (list; two-pane on wide windows),
/// /chats/c/:id (a conversation; on narrow screens it replaces the list and Back returns to it),
/// /chats/c/:id/info (group or contact details), /chats/new-group and /settings.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final status = ref.read(authControllerProvider).status;
      final loc = state.matchedLocation;
      const authRoutes = {'/login', '/register'};
      switch (status) {
        case AuthStatus.unknown:
          return loc == '/splash' ? null : '/splash';
        case AuthStatus.unauthenticated:
          return authRoutes.contains(loc) ? null : '/login';
        case AuthStatus.authenticated:
          return (loc == '/splash' || authRoutes.contains(loc)) ? '/chats' : null;
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/chats',
        builder: (_, _) => const HomeShell(),
        routes: [
          GoRoute(path: 'new-group', builder: (_, _) => const NewGroupScreen()),
          GoRoute(
            path: 'c/:id',
            builder: (_, state) => HomeShell(selectedId: state.pathParameters['id']),
            routes: [
              GoRoute(
                path: 'info',
                builder: (_, state) => ConversationInfoScreen(conversationId: state.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    ],
  );
});

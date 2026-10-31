import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/session_storage.dart';
import '../../providers.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthState {
  const AuthState(this.status, [this.session]);
  const AuthState.unknown() : this(AuthStatus.unknown);
  const AuthState.unauthenticated() : this(AuthStatus.unauthenticated);
  final AuthStatus status;
  final StoredSession? session;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    final repo = ref.read(authRepositoryProvider);
    repo.onSessionLost = () => _signedOut();
    Future<void>.microtask(_restore);
    return const AuthState.unknown();
  }

  Future<void> _restore() async {
    final s = await ref.read(authRepositoryProvider).restore();
    state = s == null ? const AuthState.unauthenticated() : AuthState(AuthStatus.authenticated, s);
  }

  /// Throws ApiException on failure (shown by the form).
  Future<void> login(String username, String password) async {
    final s = await ref.read(authRepositoryProvider).login(username: username, password: password);
    state = AuthState(AuthStatus.authenticated, s);
  }

  Future<void> register(String username, String password, String displayName) async {
    final s = await ref
        .read(authRepositoryProvider)
        .register(username: username, password: password, displayName: displayName);
    state = AuthState(AuthStatus.authenticated, s);
  }

  Future<void> logout() async {
    await ref.read(apiClientProvider).logout();
    await ref.read(authRepositoryProvider).clearLocal();
    await _signedOut();
  }

  Future<void> _signedOut() async {
    await ref.read(databaseProvider).clearAll(); // the cache belongs to the account that just left
    state = const AuthState.unauthenticated();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);

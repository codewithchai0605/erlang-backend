import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/networking/api_client.dart';
import '../../core/storage/session_storage.dart';

/// Talks to /api/v1/auth/*, persists the session and keeps the access token fresh.
/// Uses a bare Dio (no auth interceptor) to avoid a refresh -> 401 -> refresh loop.
class AuthRepository {
  AuthRepository({required this._dio, required this._storage, DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final Dio _dio;
  final SessionStorage _storage;
  final DateTime Function() _now;

  /// Called when the server rejects our refresh token: the user must sign in again.
  void Function()? onSessionLost;

  StoredSession? _session;
  Future<bool>? _refreshing;

  StoredSession? get session => _session;

  Future<StoredSession?> restore() async {
    final s = await _storage.read();
    if (s == null) return null;
    if (!s.refreshExpiresAt.isAfter(_now())) {
      await _storage.clear();
      return null;
    }
    return _session = s;
  }

  Future<StoredSession> register({required String username, required String password, required String displayName}) =>
      _authenticate('/api/v1/auth/register', {'username': username, 'password': password, 'display_name': displayName});

  Future<StoredSession> login({required String username, required String password}) =>
      _authenticate('/api/v1/auth/login', {'username': username, 'password': password});

  Future<StoredSession> _authenticate(String path, Map<String, Object?> body) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>(path, data: {
        ...body,
        'device': {'platform': defaultTargetPlatform.name},
      });
      final user = r.data!['user'] as Map<String, dynamic>;
      final t = r.data!['tokens'] as Map<String, dynamic>;
      final s = StoredSession(
        userId: user['id'] as String,
        username: user['username'] as String,
        displayName: user['display_name'] as String,
        accessToken: t['access_token'] as String,
        accessExpiresAt: _now().add(Duration(seconds: t['access_expires_in'] as int)),
        refreshToken: t['refresh_token'] as String,
        refreshExpiresAt: _now().add(Duration(seconds: t['refresh_expires_in'] as int)),
      );
      await _storage.write(s);
      return _session = s;
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Returns a token valid for at least another minute, refreshing first when needed.
  Future<String?> validAccessToken() async {
    final s = _session;
    if (s == null) return null;
    if (s.accessExpiresAt.isAfter(_now().add(const Duration(seconds: 60)))) return s.accessToken;
    await refresh();
    return _session?.accessToken;
  }

  /// Single-flight: concurrent callers share one refresh request (refresh tokens rotate, so two parallel
  /// refreshes with the same token would look like token theft to the server).
  Future<bool> refresh() => _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<bool> _doRefresh() async {
    final s = _session;
    if (s == null) return false;
    try {
      final r = await _dio.post<Map<String, dynamic>>('/api/v1/auth/refresh', data: {'refresh_token': s.refreshToken});
      final t = r.data!['tokens'] as Map<String, dynamic>;
      final next = s.withTokens(
        accessToken: t['access_token'] as String,
        accessExpiresAt: _now().add(Duration(seconds: t['access_expires_in'] as int)),
        refreshToken: t['refresh_token'] as String,
        refreshExpiresAt: _now().add(Duration(seconds: t['refresh_expires_in'] as int)),
      );
      await _storage.write(next);
      _session = next;
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await clearLocal();
        onSessionLost?.call();
      }
      return false; // network trouble: keep the session and try again later
    }
  }

  /// Persists a new display name (after the server accepted it) and returns the updated session.
  Future<StoredSession?> saveDisplayName(String name) async {
    final s = _session;
    if (s == null) return null;
    final next = s.withDisplayName(name);
    await _storage.write(next);
    return _session = next;
  }

  Future<void> clearLocal() async {
    _session = null;
    await _storage.clear();
  }
}

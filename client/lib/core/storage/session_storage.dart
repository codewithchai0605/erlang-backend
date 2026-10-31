import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// What we keep on the device after sign-in. Tokens live ONLY in the platform secure store.
class StoredSession {
  const StoredSession({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.accessToken,
    required this.accessExpiresAt,
    required this.refreshToken,
    required this.refreshExpiresAt,
  });

  final String userId;
  final String username;
  final String displayName;
  final String accessToken;
  final DateTime accessExpiresAt;
  final String refreshToken;
  final DateTime refreshExpiresAt;

  StoredSession withTokens({
    required String accessToken,
    required DateTime accessExpiresAt,
    required String refreshToken,
    required DateTime refreshExpiresAt,
  }) =>
      StoredSession(
        userId: userId,
        username: username,
        displayName: displayName,
        accessToken: accessToken,
        accessExpiresAt: accessExpiresAt,
        refreshToken: refreshToken,
        refreshExpiresAt: refreshExpiresAt,
      );

  Map<String, Object?> toJson() => {
        'userId': userId,
        'username': username,
        'displayName': displayName,
        'accessToken': accessToken,
        'accessExpiresAt': accessExpiresAt.millisecondsSinceEpoch,
        'refreshToken': refreshToken,
        'refreshExpiresAt': refreshExpiresAt.millisecondsSinceEpoch,
      };

  factory StoredSession.fromJson(Map<String, Object?> j) => StoredSession(
        userId: j['userId']! as String,
        username: j['username']! as String,
        displayName: j['displayName']! as String,
        accessToken: j['accessToken']! as String,
        accessExpiresAt: DateTime.fromMillisecondsSinceEpoch(j['accessExpiresAt']! as int),
        refreshToken: j['refreshToken']! as String,
        refreshExpiresAt: DateTime.fromMillisecondsSinceEpoch(j['refreshExpiresAt']! as int),
      );
}

abstract interface class SessionStorage {
  Future<StoredSession?> read();
  Future<void> write(StoredSession session);
  Future<void> clear();
}

class SecureSessionStorage implements SessionStorage {
  SecureSessionStorage([FlutterSecureStorage? storage]) : _s = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _s;
  static const _key = 'session.v1';

  @override
  Future<StoredSession?> read() async {
    try {
      final raw = await _s.read(key: _key);
      if (raw == null) return null;
      return StoredSession.fromJson((jsonDecode(raw) as Map).cast<String, Object?>());
    } catch (_) {
      await clear(); // corrupt or unreadable entry: treat as signed out
      return null;
    }
  }

  @override
  Future<void> write(StoredSession session) => _s.write(key: _key, value: jsonEncode(session.toJson()));

  @override
  Future<void> clear() => _s.delete(key: _key);
}

/// In-memory implementation for tests.
class MemorySessionStorage implements SessionStorage {
  StoredSession? value;
  @override
  Future<StoredSession?> read() async => value;
  @override
  Future<void> write(StoredSession session) async => value = session;
  @override
  Future<void> clear() async => value = null;
}

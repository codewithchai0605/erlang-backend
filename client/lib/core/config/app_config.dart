import 'package:flutter/foundation.dart';

/// Build-time configuration: `flutter run --dart-define=CHAT_BASE_URL=http://192.168.1.10:8080`.
/// Defaults: Android emulator reaches the host machine at 10.0.2.2; desktop uses localhost.
class AppConfig {
  const AppConfig._();

  static const _fromEnv = String.fromEnvironment('CHAT_BASE_URL');

  static String get baseUrl {
    if (_fromEnv.isNotEmpty) return _fromEnv;
    return defaultTargetPlatform == TargetPlatform.android ? 'http://10.0.2.2:8080' : 'http://localhost:8080';
  }

  static Uri get wsUri {
    final u = Uri.parse(baseUrl);
    return u.replace(scheme: u.scheme == 'https' ? 'wss' : 'ws', path: '/ws');
  }
}

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../protocol/protocol.dart' as pb;
import 'backoff.dart';
import 'ws_transport.dart';

const protocolVersion = 1;

/// The connection dropped (or was never up) while a request was pending.
class ConnectionLost implements Exception {
  const ConnectionLost();
  @override
  String toString() => 'ConnectionLost';
}

/// The server answered a request with a ProtocolError.
class ProtocolFailure implements Exception {
  const ProtocolFailure(this.code, this.message);
  final pb.ErrorCode code;
  final String message;
  @override
  String toString() => 'ProtocolFailure(${code.name}: $message)';
}

enum ConnectionStatus { disconnected, connecting, connected }

/// What the chat layer needs from the connection; lets tests substitute a fake.
abstract interface class ChatTransport {
  bool get isConnected;

  /// Emits once after every successful (re)connect + Hello handshake.
  Stream<void> get connected;

  /// Server-initiated messages (empty request_id): new messages, receipts, new conversations.
  Stream<pb.ServerEnvelope> get pushes;

  /// Sends [envelope] and completes with the matching response. Throws [ConnectionLost],
  /// [ProtocolFailure] or [TimeoutException].
  Future<pb.ServerEnvelope> request(pb.ClientEnvelope envelope);

  /// Fire-and-forget (typing indicators): no request id, no response, silently dropped when offline.
  void notify(pb.ClientEnvelope envelope);
}

/// Owns ONE WebSocket at a time and keeps reconnecting (exponential backoff + jitter) while started.
class WsService implements ChatTransport {
  WsService({
    required this.tokenProvider,
    required this.transportFactory,
    this.onAuthRejected,
    Uri? uri,
    this.requestTimeout = const Duration(seconds: 15),
    this.helloTimeout = const Duration(seconds: 10),
    this.backoffBase = const Duration(seconds: 1),
    Random? random,
  })  : uri = uri ?? AppConfig.wsUri,
        _random = random ?? Random();

  final Uri uri;
  final Future<String?> Function() tokenProvider;
  final WsTransportFactory transportFactory;
  final Future<void> Function()? onAuthRejected;
  final Duration requestTimeout;
  final Duration helloTimeout;
  final Duration backoffBase;
  final Random _random;

  final _statusCtrl = StreamController<ConnectionStatus>.broadcast();
  final _connectedCtrl = StreamController<void>.broadcast();
  final _pushCtrl = StreamController<pb.ServerEnvelope>.broadcast();
  final _pending = <String, Completer<pb.ServerEnvelope>>{};

  ConnectionStatus _status = ConnectionStatus.disconnected;
  bool _running = false;
  Completer<void> _stopSignal = Completer<void>();
  Future<void>? _loopFuture;
  WsTransport? _transport;
  int _seq = 0;

  ConnectionStatus get status => _status;
  Stream<ConnectionStatus> get statuses => _statusCtrl.stream;

  @override
  bool get isConnected => _status == ConnectionStatus.connected;
  @override
  Stream<void> get connected => _connectedCtrl.stream;
  @override
  Stream<pb.ServerEnvelope> get pushes => _pushCtrl.stream;

  void start() {
    if (_running) return;
    _running = true;
    _stopSignal = Completer<void>();
    _loopFuture = _loop();
  }

  Future<void> stop() async {
    _running = false;
    if (!_stopSignal.isCompleted) _stopSignal.complete();
    await _loopFuture;
    _loopFuture = null;
  }

  Future<void> dispose() async {
    await stop();
    await _statusCtrl.close();
    await _connectedCtrl.close();
    await _pushCtrl.close();
  }

  @override
  Future<pb.ServerEnvelope> request(pb.ClientEnvelope envelope) {
    final t = _transport;
    if (!isConnected || t == null) return Future.error(const ConnectionLost());
    final id = 'r${++_seq}';
    envelope.requestId = id;
    final completer = Completer<pb.ServerEnvelope>();
    _pending[id] = completer;
    try {
      t.sendBinary(envelope.writeToBuffer());
    } catch (_) {
      _pending.remove(id);
      return Future.error(const ConnectionLost());
    }
    return completer.future.timeout(requestTimeout, onTimeout: () {
      _pending.remove(id);
      throw TimeoutException('request $id timed out');
    });
  }

  @override
  void notify(pb.ClientEnvelope envelope) {
    final t = _transport;
    if (!isConnected || t == null) return;
    envelope.requestId = '';
    try {
      t.sendBinary(envelope.writeToBuffer());
    } catch (_) {/* best effort: an indicator that does not arrive is not worth an error */}
  }

  // ------------------------------------------------------------------ connection loop
  Future<void> _loop() async {
    var attempt = 0;
    while (_running) {
      _setStatus(ConnectionStatus.connecting);
      try {
        final token = await tokenProvider();
        if (token == null) break; // signed out: nothing to connect with
        final acked = await _session(token);
        attempt = acked ? 1 : attempt + 1;
      } catch (e) {
        debugPrint('ws connect failed: $e');
        attempt += 1;
      }
      _failPending();
      _setStatus(ConnectionStatus.disconnected);
      if (!_running) break;
      await Future.any([Future<void>.delayed(backoffDelay(attempt, random: _random, base: backoffBase)), _stopSignal.future]);
    }
    _running = false;
    _setStatus(ConnectionStatus.disconnected);
  }

  /// One connection lifetime. Returns true if the Hello handshake succeeded.
  Future<bool> _session(String token) async {
    final t = transportFactory(uri);
    _transport = t;
    try {
      await t.ready.timeout(helloTimeout);
    } catch (_) {
      await _safeClose(t);
      _transport = null;
      return false;
    }
    var acked = false;
    final done = Completer<void>();
    final sub = t.stream.listen(
      (data) {
        final env = _decode(data);
        if (env == null) {
          unawaited(_safeClose(t, 1007));
          return;
        }
        if (!acked && env.whichBody() == pb.ServerEnvelope_Body.helloAck) {
          acked = true;
          _setStatus(ConnectionStatus.connected);
          _connectedCtrl.add(null);
          return;
        }
        _route(env);
      },
      onError: (Object _) {
        if (!done.isCompleted) done.complete();
      },
      onDone: () {
        if (!done.isCompleted) done.complete();
      },
    );
    final helloTimer = Timer(helloTimeout, () {
      if (!acked) unawaited(_safeClose(t, 4000));
    });
    t.sendBinary((pb.ClientEnvelope()
          ..requestId = 'hello'
          ..hello = pb.Hello(protocolVersion: protocolVersion, accessToken: token))
        .writeToBuffer());

    await Future.any([done.future, _stopSignal.future]);

    helloTimer.cancel();
    await sub.cancel();
    await _safeClose(t, 1000);
    _transport = null;
    if (t.closeCode == 1008) {
      try {
        await onAuthRejected?.call(); // token revoked/expired: let the auth layer refresh or sign out
      } catch (_) {}
    }
    return acked;
  }

  pb.ServerEnvelope? _decode(dynamic data) {
    if (data is! List<int>) return null; // the protocol is binary-only
    try {
      return pb.ServerEnvelope.fromBuffer(data);
    } catch (_) {
      return null;
    }
  }

  void _route(pb.ServerEnvelope env) {
    final waiter = env.requestId.isEmpty ? null : _pending.remove(env.requestId);
    if (waiter == null) {
      if (env.whichBody() == pb.ServerEnvelope_Body.error) {
        debugPrint('server error: ${env.error.code.name}');
      } else {
        _pushCtrl.add(env);
      }
      return;
    }
    if (env.whichBody() == pb.ServerEnvelope_Body.error) {
      waiter.completeError(ProtocolFailure(env.error.code, env.error.message));
    } else {
      waiter.complete(env);
    }
  }

  void _failPending() {
    final waiters = _pending.values.toList();
    _pending.clear();
    for (final w in waiters) {
      if (!w.isCompleted) w.completeError(const ConnectionLost());
    }
  }

  Future<void> _safeClose(WsTransport t, [int? code]) async {
    try {
      await t.close(code, null);
    } catch (_) {}
  }

  void _setStatus(ConnectionStatus s) {
    if (_status == s) return;
    _status = s;
    if (!_statusCtrl.isClosed) _statusCtrl.add(s);
  }
}

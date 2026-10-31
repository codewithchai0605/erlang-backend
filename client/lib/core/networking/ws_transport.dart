import 'package:web_socket_channel/io.dart';

/// Minimal socket abstraction so WsService can be tested with a fake (no network).
abstract interface class WsTransport {
  Future<void> get ready;
  Stream<dynamic> get stream;
  void sendBinary(List<int> data);
  int? get closeCode;
  Future<void> close([int? code, String? reason]);
}

typedef WsTransportFactory = WsTransport Function(Uri uri);

class IoWsTransport implements WsTransport {
  IoWsTransport(Uri uri)
      : _ch = IOWebSocketChannel.connect(
          uri,
          // WebSocket-level pings detect half-dead connections (e.g. Wi-Fi dropped silently)
          pingInterval: const Duration(seconds: 20),
          connectTimeout: const Duration(seconds: 10),
        );

  final IOWebSocketChannel _ch;

  @override
  Future<void> get ready => _ch.ready;
  @override
  Stream<dynamic> get stream => _ch.stream;
  @override
  void sendBinary(List<int> data) => _ch.sink.add(data);
  @override
  int? get closeCode => _ch.closeCode;
  @override
  Future<void> close([int? code, String? reason]) => _ch.sink.close(code, reason);
}

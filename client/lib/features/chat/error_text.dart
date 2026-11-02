import 'dart:async';

import '../../core/networking/api_client.dart';
import '../../core/networking/ws_service.dart';
import '../../core/protocol/protocol.dart' as pb;

/// One place that turns exceptions into a sentence a person can act on. Never shows stack traces or codes.
String describeError(Object error) {
  if (error is ProtocolFailure) {
    if (error.code == pb.ErrorCode.ERROR_CODE_PERMISSION_DENIED) return 'You are not allowed to do that.';
    if (error.code == pb.ErrorCode.ERROR_CODE_RATE_LIMITED) return 'Too many requests. Please wait a moment.';
    if (error.code == pb.ErrorCode.ERROR_CODE_NOT_FOUND) return 'That person or conversation was not found.';
    return error.message.isEmpty ? 'The server rejected that request.' : _capitalize(error.message);
  }
  if (error is ApiException) return error.message;
  if (error is ConnectionLost || error is TimeoutException) return 'You are offline. Try again once you are connected.';
  return 'Something went wrong. Please try again.';
}

String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

import 'dart:math';

/// Reconnect delay with "equal jitter": exponential growth (base * 2^(attempt-1)) capped at [cap], then a
/// random value between half and the full amount. Jitter stops thousands of clients that lost the server
/// at the same moment from reconnecting in lock-step.
Duration backoffDelay(
  int attempt, {
  Random? random,
  Duration base = const Duration(seconds: 1),
  Duration cap = const Duration(seconds: 30),
}) {
  final r = random ?? Random();
  final exponent = min(max(attempt - 1, 0), 20);
  final exp = min(cap.inMilliseconds, base.inMilliseconds * (1 << exponent));
  final half = exp ~/ 2;
  return Duration(milliseconds: half + r.nextInt(half + 1));
}

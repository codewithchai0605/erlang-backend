import 'dart:math';

import 'package:client/core/networking/backoff.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('delay grows exponentially with equal jitter and is capped', () {
    final r = Random(1);
    for (var attempt = 1; attempt <= 40; attempt++) {
      final full = min(30000, 1000 * (1 << min(attempt - 1, 20)));
      final d = backoffDelay(attempt, random: r).inMilliseconds;
      expect(d, inInclusiveRange(full ~/ 2, full), reason: 'attempt $attempt');
    }
  });

  test('jitter makes clients desynchronise', () {
    final delays = {for (var i = 0; i < 50; i++) backoffDelay(6, random: Random(i)).inMilliseconds};
    expect(delays.length, greaterThan(10));
  });
}

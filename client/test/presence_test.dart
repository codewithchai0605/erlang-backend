import 'package:client/features/presence/presence.dart';
import 'package:flutter_test/flutter_test.dart';

PresenceInfo _offline(DateTime lastSeen) =>
    PresenceInfo(userId: 'u', online: false, lastSeenMs: lastSeen.millisecondsSinceEpoch);

void main() {
  final now = DateTime(2026, 11, 1, 15, 30);

  test('online wins over any last-seen value', () {
    expect(lastSeenLabel(const PresenceInfo(userId: 'u', online: true, lastSeenMs: 123), now: now), 'online');
  });

  test('never seen reads as offline, not as a made-up time', () {
    expect(lastSeenLabel(const PresenceInfo(userId: 'u', online: false, lastSeenMs: 0), now: now), 'offline');
  });

  test('same day, yesterday and older', () {
    expect(lastSeenLabel(_offline(DateTime(2026, 11, 1, 9, 5)), now: now), 'last seen today at 09:05');
    expect(lastSeenLabel(_offline(DateTime(2026, 10, 31, 23, 59)), now: now), 'last seen yesterday at 23:59');
    expect(lastSeenLabel(_offline(DateTime(2026, 10, 3, 8, 0)), now: now), 'last seen Oct 3');
  });

  test('"yesterday" is about calendar days, not 24 hours', () {
    // 00:10 today vs 23:50 yesterday is only 20 minutes apart but is "yesterday"
    final just = DateTime(2026, 11, 1, 0, 10);
    expect(lastSeenLabel(_offline(DateTime(2026, 10, 31, 23, 50)), now: just), 'last seen yesterday at 23:50');
  });
}

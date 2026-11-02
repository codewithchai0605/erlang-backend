import 'package:client/features/chat/typing_label.dart';
import 'package:client/features/chat/typing_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('typingLabel', () {
    String? names(String id) => {'a': 'Alice', 'b': 'Bob', 'c': 'Cleo', 'd': 'Dan'}[id];

    test('one, two, many', () {
      expect(typingLabel([], names), '');
      expect(typingLabel(['a'], names), 'Alice is typing…');
      expect(typingLabel(['a', 'b'], names), 'Alice and Bob are typing…');
      expect(typingLabel(['a', 'b', 'c'], names), 'Alice, Bob and 1 other are typing…');
      expect(typingLabel(['a', 'b', 'c', 'd'], names), 'Alice, Bob and 2 others are typing…');
    });

    test('an unknown user (just joined) reads as Someone', () {
      expect(typingLabel(['zz'], names), 'Someone is typing…');
    });
  });

  group('TypingTracker (incoming)', () {
    test('indicator appears, refreshes silently, and disappears on "stopped"', () {
      final seen = <Map<String, Set<String>>>[];
      final t = TypingTracker(onChanged: seen.add, expiry: const Duration(seconds: 30));
      t.apply('c1', 'u1', true);
      expect(t.snapshot, {'c1': {'u1'}});
      t.apply('c1', 'u1', true); // refresh: nothing visible changed, so no extra notification
      expect(seen.length, 1);
      t.apply('c1', 'u1', false);
      expect(t.snapshot, isEmpty);
      expect(seen.length, 2);
      t.dispose();
    });

    test('an indicator expires by itself when "stopped typing" never arrives', () async {
      final seen = <Map<String, Set<String>>>[];
      final t = TypingTracker(onChanged: seen.add, expiry: const Duration(milliseconds: 40));
      t.apply('c1', 'u1', true);
      expect(t.snapshot, isNotEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(t.snapshot, isEmpty);
      expect(seen.last, isEmpty);
      t.dispose();
    });

    test('a refresh postpones the expiry', () async {
      final t = TypingTracker(onChanged: (_) {}, expiry: const Duration(milliseconds: 100));
      t.apply('c1', 'u1', true);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      t.apply('c1', 'u1', true);
      await Future<void>.delayed(const Duration(milliseconds: 60)); // 120 ms since the first event
      expect(t.snapshot, isNotEmpty);
      t.dispose();
    });

    test('several people and conversations are independent', () {
      final t = TypingTracker(onChanged: (_) {}, expiry: const Duration(seconds: 30));
      t.apply('c1', 'u1', true);
      t.apply('c1', 'u2', true);
      t.apply('c2', 'u1', true);
      t.apply('c1', 'u1', false);
      expect(t.snapshot, {'c1': {'u2'}, 'c2': {'u1'}});
      t.clearAll();
      expect(t.snapshot, isEmpty);
      t.dispose();
    });
  });

  group('TypingThrottle (outgoing)', () {
    test('sends the first keystroke, then at most once per interval', () {
      var now = DateTime(2026, 1, 1, 12);
      final th = TypingThrottle(minInterval: const Duration(seconds: 3), now: () => now);
      expect(th.shouldSend('c1', true), isTrue);
      now = now.add(const Duration(seconds: 1));
      expect(th.shouldSend('c1', true), isFalse);
      now = now.add(const Duration(seconds: 3));
      expect(th.shouldSend('c1', true), isTrue); // refresh so the peer's indicator does not expire
    });

    test('"stopped typing" is sent once, and only if "typing" was sent', () {
      final th = TypingThrottle();
      expect(th.shouldSend('c1', false), isFalse);
      expect(th.shouldSend('c1', true), isTrue);
      expect(th.shouldSend('c1', false), isTrue);
      expect(th.shouldSend('c1', false), isFalse);
    });

    test('conversations are throttled independently', () {
      final th = TypingThrottle();
      expect(th.shouldSend('c1', true), isTrue);
      expect(th.shouldSend('c2', true), isTrue);
    });
  });
}

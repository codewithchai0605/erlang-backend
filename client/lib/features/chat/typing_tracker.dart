import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';

/// INCOMING typing indicators: who is typing in which conversation.
///
/// The server only relays events; it never remembers them. So each indicator carries its own expiry: if no
/// refresh arrives within [expiry], it disappears. That heals every lost "stopped typing" event (peer
/// disconnected, packet dropped, app killed) without any server-side state.
class TypingTracker {
  TypingTracker({required this.onChanged, this.expiry = const Duration(seconds: 6)});

  final void Function(Map<String, Set<String>> snapshot) onChanged;
  final Duration expiry;
  final Map<String, Map<String, Timer>> _timers = {};

  Map<String, Set<String>> get snapshot => {
        for (final e in _timers.entries)
          if (e.value.isNotEmpty) e.key: e.value.keys.toSet(),
      };

  void apply(String conversationId, String userId, bool isTyping) {
    final users = _timers.putIfAbsent(conversationId, () => {});
    final had = users.containsKey(userId);
    users.remove(userId)?.cancel();
    if (isTyping) {
      users[userId] = Timer(expiry, () => apply(conversationId, userId, false));
    }
    if (users.isEmpty) _timers.remove(conversationId);
    if (had != isTyping) onChanged(snapshot); // a refresh of an existing indicator changes nothing visible
  }

  void clearAll() {
    for (final users in _timers.values) {
      for (final t in users.values) {
        t.cancel();
      }
    }
    _timers.clear();
    onChanged(snapshot);
  }

  void dispose() {
    for (final users in _timers.values) {
      for (final t in users.values) {
        t.cancel();
      }
    }
    _timers.clear();
  }
}

/// OUTGOING side: decides whether a local keystroke is worth a network message. While the user keeps typing
/// we refresh at most every [minInterval]; "stopped typing" is sent once, and only if we had said "typing".
class TypingThrottle {
  TypingThrottle({this.minInterval = const Duration(seconds: 3), DateTime Function()? now}) : _now = now ?? DateTime.now;

  final Duration minInterval;
  final DateTime Function() _now;
  final Map<String, DateTime> _lastTypingSent = {};

  bool shouldSend(String conversationId, bool isTyping) {
    final last = _lastTypingSent[conversationId];
    if (!isTyping) return _lastTypingSent.remove(conversationId) != null;
    final now = _now();
    if (last != null && now.difference(last) < minInterval) return false;
    _lastTypingSent[conversationId] = now;
    return true;
  }
}

/// conversationId -> user ids currently typing (never includes me: the server does not echo my own events).
class TypingNotifier extends Notifier<Map<String, Set<String>>> {
  late TypingTracker _tracker; // not final: build() runs again if the provider is invalidated

  @override
  Map<String, Set<String>> build() {
    ref.watch(authControllerProvider.select((a) => a.session?.userId)); // new account => start empty
    _tracker = TypingTracker(onChanged: (s) => state = s);
    ref.onDispose(_tracker.dispose);
    return const {};
  }

  void apply(String conversationId, String userId, bool isTyping) => _tracker.apply(conversationId, userId, isTyping);

  void clear() => _tracker.clearAll();
}

final typingProvider = NotifierProvider<TypingNotifier, Map<String, Set<String>>>(TypingNotifier.new);

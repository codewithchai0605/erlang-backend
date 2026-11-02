/// "Alice is typing...", "Alice and Bob are typing...", "Alice, Bob and 2 others are typing...".
/// [nameOf] resolves a user id to a display name; unknown ids (someone who just joined) read as "Someone".
/// Pure function: the UI strings are unit-tested without any widget.
String typingLabel(Iterable<String> typingUserIds, String? Function(String userId) nameOf) {
  final names = [for (final id in typingUserIds) nameOf(id) ?? 'Someone'];
  switch (names.length) {
    case 0:
      return '';
    case 1:
      return '${names[0]} is typing…';
    case 2:
      return '${names[0]} and ${names[1]} are typing…';
    default:
      return '${names[0]}, ${names[1]} and ${names.length - 2} other${names.length - 2 == 1 ? '' : 's'} are typing…';
  }
}

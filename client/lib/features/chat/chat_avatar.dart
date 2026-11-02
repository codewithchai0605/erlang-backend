import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Circle avatar with the first letter of the name (or a group icon) and an optional presence dot.
/// [online] == null means "unknown": no dot is drawn at all (we never claim someone is offline without knowing).
class ChatAvatar extends StatelessWidget {
  const ChatAvatar({super.key, required this.name, this.isGroup = false, this.online, this.radius = 20});

  final String name;
  final bool isGroup;
  final bool? online;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();
    final avatar = CircleAvatar(
      radius: radius,
      child: isGroup ? Icon(Icons.groups, size: radius * 1.1) : Text(initial),
    );
    if (online != true) return ExcludeSemantics(child: avatar);
    final scheme = Theme.of(context).colorScheme;
    final dot = radius * 0.55;
    return ExcludeSemantics(
      // The dot is decorative here; the same fact is spoken in the tile/header text ("online").
      child: Stack(clipBehavior: Clip.none, children: [
        avatar,
        Positioned(
          right: -1,
          bottom: -1,
          child: Container(
            width: dot,
            height: dot,
            decoration: BoxDecoration(
              color: ChatColors.of(context).online,
              shape: BoxShape.circle,
              border: Border.all(color: scheme.surface, width: 2),
            ),
          ),
        ),
      ]),
    );
  }
}

import 'package:flutter/material.dart';

/// Colours come from one seed so light/dark stay consistent; spacing uses a 4-pt scale.
class AppTheme {
  const AppTheme._();
  static const _seed = Color(0xFF3F51B5);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: b);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      extensions: [
        ChatColors(
          // Green with enough contrast against the surface in both modes (never rely on colour alone:
          // the presence dot always has a text/semantic equivalent).
          online: b == Brightness.light ? const Color(0xFF2E7D32) : const Color(0xFF66BB6A),
          typing: scheme.primary,
        ),
      ],
    );
  }
}

/// App-specific semantic colours that Material's ColorScheme has no slot for.
@immutable
class ChatColors extends ThemeExtension<ChatColors> {
  const ChatColors({required this.online, required this.typing});

  final Color online;
  final Color typing;

  static ChatColors of(BuildContext context) =>
      Theme.of(context).extension<ChatColors>() ?? const ChatColors(online: Color(0xFF2E7D32), typing: Color(0xFF3F51B5));

  @override
  ChatColors copyWith({Color? online, Color? typing}) => ChatColors(online: online ?? this.online, typing: typing ?? this.typing);

  @override
  ChatColors lerp(ThemeExtension<ChatColors>? other, double t) {
    if (other is! ChatColors) return this;
    return ChatColors(online: Color.lerp(online, other.online, t)!, typing: Color.lerp(typing, other.typing, t)!);
  }
}

class Gap {
  const Gap._();
  static const double xs = 4, s = 8, m = 16, l = 24, xl = 32;
}

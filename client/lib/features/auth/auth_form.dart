import 'dart:convert';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/responsive/breakpoints.dart';

String? validateUsername(String? v) {
  final s = (v ?? '').trim();
  if (!RegExp(r'^[A-Za-z0-9_]{3,32}$').hasMatch(s)) return '3-32 letters, digits or underscores';
  return null;
}

String? validatePassword(String? v) {
  final p = v ?? '';
  if (utf8.encode(p).length < 8) return 'At least 8 characters';
  if (utf8.encode(p).length > 72) return 'At most 72 bytes';
  return null;
}

String? validateDisplayName(String? v) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return 'Required';
  if (s.runes.length > 50) return 'At most 50 characters';
  return null;
}

/// Shared frame for the sign-in / register screens: centred card, bounded width, scrolls with the keyboard.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Gap.l),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: Breakpoints.maxFormWidth),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                    const SizedBox(height: Gap.l),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class ErrorText extends StatelessWidget {
  const ErrorText(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Padding(
          padding: const EdgeInsets.only(bottom: Gap.m),
          child: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
      );
}

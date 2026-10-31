import 'package:flutter/material.dart';

/// Colours come from one seed so light/dark stay consistent; spacing uses a 4-pt scale.
class AppTheme {
  const AppTheme._();
  static const _seed = Color(0xFF3F51B5);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: b),
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      );
}

class Gap {
  const Gap._();
  static const double xs = 4, s = 8, m = 16, l = 24, xl = 32;
}

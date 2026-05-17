import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData dark() {
    const ink = Color(0xFF080B12);
    const panel = Color(0xFF121826);
    const line = Color(0xFF263247);
    const ember = Color(0xFFFFB454);
    const aether = Color(0xFF67E8F9);
    const text = Color(0xFFE7EDF8);

    final scheme = ColorScheme.fromSeed(
      seedColor: aether,
      brightness: Brightness.dark,
      surface: ink,
      primary: aether,
      secondary: ember,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: ink,
      cardColor: panel,
      dividerColor: line,
      textTheme: const TextTheme(
        displaySmall: TextStyle(fontWeight: FontWeight.w800, color: text),
        headlineSmall: TextStyle(fontWeight: FontWeight.w700, color: text),
        titleMedium: TextStyle(fontWeight: FontWeight.w700, color: text),
        bodyMedium: TextStyle(color: Color(0xFFC6D0E1)),
        labelLarge: TextStyle(fontWeight: FontWeight.w700),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(120, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(120, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: const BorderSide(color: line),
        ),
      ),
    );
  }
}

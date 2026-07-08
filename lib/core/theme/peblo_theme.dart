import 'package:flutter/material.dart';

/// Peblo brand palette — vibrant, warm and high-contrast, tuned for young
/// children. Deliberately **story-agnostic**: this is the app's brand look, used
/// for every story. Per-story theming (e.g. a story that ships its own accent
/// colours) can be layered on top via [BrandBackground]'s `palette` parameter.
abstract final class PebloColors {
  static const Color primary = Color(0xFF6C4CE0); // playful violet
  static const Color primaryDark = Color(0xFF4B2FBF);
  static const Color accent = Color(0xFFFFC94D); // sunny yellow
  static const Color coral = Color(0xFFFF6B6B); // wrong / warm
  static const Color mint = Color(0xFF3ED9A4); // correct / success
  static const Color sky = Color(0xFF57C7FF);
  static const Color bubble = Color(0xFFB388FF); // soft accent for scenery
  static const Color cream = Color(0xFFFFF7EC); // background
  static const Color ink = Color(0xFF2B2140); // text
  static const Color cloud = Color(0xFFFFFFFF);
}

abstract final class PebloTheme {
  static const String fontFamily = 'Fredoka';

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: PebloColors.primary,
        primary: PebloColors.primary,
        secondary: PebloColors.accent,
        surface: PebloColors.cream,
      ),
      scaffoldBackgroundColor: PebloColors.cream,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: fontFamily,
        bodyColor: PebloColors.ink,
        displayColor: PebloColors.ink,
      ),
    );
  }
}

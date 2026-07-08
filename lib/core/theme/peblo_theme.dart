import 'package:flutter/material.dart';

/// Peblo brand-inspired palette. Vibrant, high-contrast and warm — tuned for
/// young children (big rounded shapes, generous tap targets, soft background).
abstract final class PebloColors {
  static const Color primary = Color(0xFF6C4CE0); // playful violet
  static const Color primaryDark = Color(0xFF4B2FBF);
  static const Color accent = Color(0xFFFFC94D); // sunny yellow
  static const Color coral = Color(0xFFFF6B6B); // wrong / warm
  static const Color mint = Color(0xFF3ED9A4); // correct / success
  static const Color sky = Color(0xFF57C7FF);
  static const Color cream = Color(0xFFFFF7EC); // background
  static const Color ink = Color(0xFF2B2140); // text
  static const Color cloud = Color(0xFFFFFFFF);
}

abstract final class PebloTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
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
        bodyColor: PebloColors.ink,
        displayColor: PebloColors.ink,
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Paleta portada do design system original (fullmatch-core.jsx / daleh-web):
/// tema escuro "campo de futebol à noite".
class DalehColors {
  static const bg = Color(0xFF0A1512);
  static const surface = Color(0xFF101C18);
  static const surface2 = Color(0xFF17261F);
  static const line = Color(0xFF223229);
  static const turf = Color(0xFFC6FF4D);
  static const turfDim = Color(0xFF8FCC2E);
  static const amber = Color(0xFFFFB238);
  static const text = Color(0xFFF2F7F4);
  static const muted = Color(0xFF85998E);
  static const danger = Color(0xFFFF6E6E);
}

ThemeData buildDalehTheme() {
  final base = ThemeData.dark(useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: DalehColors.bg,
    colorScheme: base.colorScheme.copyWith(
      surface: DalehColors.bg,
      primary: DalehColors.turf,
      onPrimary: DalehColors.bg,
      error: DalehColors.danger,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: DalehColors.text,
      displayColor: DalehColors.text,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: DalehColors.bg,
      foregroundColor: DalehColors.text,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: DalehColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: DalehColors.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DalehColors.surface2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DalehColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DalehColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DalehColors.turf, width: 2),
      ),
      labelStyle: const TextStyle(color: DalehColors.muted),
      hintStyle: const TextStyle(color: DalehColors.muted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DalehColors.turf,
        foregroundColor: DalehColors.bg,
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: DalehColors.text,
        backgroundColor: DalehColors.surface2,
        side: const BorderSide(color: DalehColors.line),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

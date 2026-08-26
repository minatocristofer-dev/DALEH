import 'package:flutter/material.dart';

/// Design system DALEH: "premium football app" — preto/grafite dominante,
/// lima como acento pontual (não como cor de fundo), cards em camadas com
/// bordas finas translúcidas em vez de sombras pesadas. Todo o app lê essas
/// constantes (nunca cor solta em widget) — trocar a paleta aqui basta pra
/// atualizar o app inteiro.
class DalehColors {
  // Fundo — profundidade por variação sutil de grafite, nunca preto chapado.
  static const bg = Color(0xFF050708);
  static const bgSecondary = Color(0xFF080B0D);
  static const surface = Color(0xFF0C1013); // cards, appbar, bottom sheets
  static const surface2 = Color(0xFF101417); // inputs, avatares placeholder
  static const surfaceHigh = Color(0xFF14191D); // estado selecionado/hover

  // Acento — lima. Reservado pra CTA primário, score, tab ativa, seleção.
  // Não deve dominar visualmente o app (ver regra "não usar verde demais").
  static const turf = Color(0xFFB8FF00);
  static const turfHover = Color(0xFFC4FF32);
  static const turfDim = Color(0xFF7EB500);

  // Texto
  static const text = Color(0xFFF6F7F7);
  static const textSecondary = Color(0xFFB6BDC1);
  static const muted = Color(0xFF7E878C);

  // Bordas — translúcidas em branco, funcionam sobre qualquer superfície escura.
  static const line = Color(0x12FFFFFF); // rgba(255,255,255,.07)
  static const lineStrong = Color(0x1CFFFFFF); // rgba(255,255,255,.11)

  // Status
  static const amber = Color(0xFFFFC857);
  static const danger = Color(0xFFFF5555);
  static const info = Color(0xFF49B8FF);
}

/// Espaçamento em múltiplos de 4 — usar nas telas retocadas nesta fase em vez
/// de números soltos.
class DalehSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
}

class DalehRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const pill = 999.0;
}

ThemeData buildDalehTheme() {
  final base = ThemeData.dark(useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: DalehColors.bg,
    colorScheme: base.colorScheme.copyWith(
      surface: DalehColors.surface,
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
      titleTextStyle: TextStyle(color: DalehColors.text, fontWeight: FontWeight.w800, fontSize: 18),
    ),
    cardTheme: CardThemeData(
      color: DalehColors.surface,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DalehRadius.lg),
        side: const BorderSide(color: DalehColors.line),
      ),
    ),
    dividerTheme: const DividerThemeData(color: DalehColors.line, thickness: 1, space: 1),
    tabBarTheme: const TabBarThemeData(
      labelColor: DalehColors.text,
      unselectedLabelColor: DalehColors.muted,
      indicatorColor: DalehColors.turf,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: DalehColors.line,
      labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.4),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, letterSpacing: 0.4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DalehColors.surface2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DalehRadius.md),
        borderSide: const BorderSide(color: DalehColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DalehRadius.md),
        borderSide: const BorderSide(color: DalehColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DalehRadius.md),
        borderSide: const BorderSide(color: DalehColors.turf, width: 2),
      ),
      labelStyle: const TextStyle(color: DalehColors.muted),
      hintStyle: const TextStyle(color: DalehColors.muted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DalehColors.turf,
        foregroundColor: DalehColors.bg,
        disabledBackgroundColor: DalehColors.turf.withValues(alpha: 0.35),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DalehRadius.md)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: DalehColors.text,
        backgroundColor: DalehColors.surface2,
        side: BorderSide(color: DalehColors.turf.withValues(alpha: 0.3)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DalehRadius.md)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: DalehColors.text),
    ),
  );
}

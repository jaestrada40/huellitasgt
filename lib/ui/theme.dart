import 'package:flutter/material.dart';

/// Colores del diseño (convertidos desde los oklch del prototipo).
class AppColors {
  static const canvas = Color(0xFFFAF6F1);
  static const card = Color(0xFFFFFFFF);
  static const primary = Color(0xFF2FA284);
  static const onPrimary = Color(0xFFFCFCFC);
  static const mint = Color(0xFFD8F2E9);
  static const mintInk = Color(0xFF00503D);
  static const peach = Color(0xFFFFE8D6);
  static const orange = Color(0xFFFB9D59);
  static const orangeText = Color(0xFF9B4805);
  static const coral = Color(0xFFE85854);
  static const greenBg = Color(0xFFDCF7E1);
  static const greenInk = Color(0xFF3EAB5E);
  static const ink = Color(0xFF261D16);
  static const inkSoft = Color(0xFF787069);
  static const inkFaint = Color(0xFFB3ACA5);
  static const muted = Color(0xFFF1EEE9);
  static const divider = Color(0xFFE8E4DD);
  static const shadow = Color(0xFF584332);
}

class AppRadius {
  static const card = 20.0;
  static const pill = 26.0;
  static const field = 16.0;
}

/// Estilos de texto del diseño. La fuente es la del sistema (SF en iPhone).
class AppText {
  static const h1 = TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.85, height: 1.25, color: AppColors.ink);
  static const title = TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.7, height: 1.2, color: AppColors.ink);
  static const h2 = TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.4, color: AppColors.ink);
  static const cardTitle = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink);
  static const body = TextStyle(fontSize: 14, color: AppColors.inkSoft);
  static const bodyStrong = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.inkSoft);
  static const caps = TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppColors.inkSoft);
  static const label = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.inkSoft);
}

List<BoxShadow> cardShadow() => [
      BoxShadow(
        color: AppColors.shadow.withValues(alpha: 0.18),
        blurRadius: 20,
        offset: const Offset(0, 6),
        spreadRadius: -8,
      ),
    ];

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    surface: AppColors.canvas,
    error: AppColors.coral,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.canvas,
  );
  OutlineInputBorder none() => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: BorderSide.none,
      );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.canvas,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        side: const BorderSide(color: AppColors.divider),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(textStyle: const TextStyle(fontWeight: FontWeight.w700)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.muted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: none(),
      enabledBorder: none(),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: const BorderSide(color: AppColors.coral),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: const BorderSide(color: AppColors.coral, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      hintStyle: const TextStyle(color: AppColors.inkSoft),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: const StadiumBorder(),
      side: BorderSide.none,
      backgroundColor: AppColors.card,
      selectedColor: AppColors.primary,
      labelStyle: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
      secondaryLabelStyle: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onPrimary),
      checkmarkColor: AppColors.onPrimary,
      showCheckmark: false,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.divider, space: 1, thickness: 1),
  );
}

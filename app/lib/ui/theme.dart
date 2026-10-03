import 'package:flutter/material.dart';

/// SPEC-010 R1: tokens del diseño "kcalcula ia UI". Ninguna pantalla repite
/// valores hexadecimales: todo sale de aquí.
abstract final class KColors {
  static const text = Color(0xFF1B2430);
  static const textSecondary = Color(0xFF5F6B7A);
  static const accent = Color(0xFF3F6483);
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFEEF3FA);
  static const surfaceSoft = Color(0xFFF3F7FC);
  static const navSelected = Color(0xFFE4EDF7);
  static const border = Color(0xFFE3E9F1);
  static const track = Color(0xFFE8EDF4);

  /// Identidad de cada macro (no son señales de alarma).
  static const protein = Color(0xFFC2776B);
  static const carbs = Color(0xFFC9A15A);
  static const fat = Color(0xFF5FA8A0);

  /// Confirmación (p. ej. "Base verificada").
  static const confirmBackground = Color(0xFFE8F3EC);
  static const confirmText = Color(0xFF2F6B4A);

  /// Errores de la app (no de la meta: la meta nunca usa rojo).
  static const error = Color(0xFFB3261E);
}

/// SPEC-010 R6: estado del día frente a la meta, sin rojo ni verde de
/// alarma. El significado nunca depende solo del color: quien lo usa añade
/// texto o icono.
enum DayGoalStatus {
  // 3,3:1 contra el blanco (≥ 3:1 para elementos gráficos, WCAG 1.4.11).
  belowGoal(Color(0xFF7690AC), 'Por debajo'),
  onGoal(KColors.accent, 'En tu meta'),
  aboveGoal(KColors.text, 'Por encima');

  const DayGoalStatus(this.color, this.label);

  final Color color;
  final String label;
}

abstract final class KRadii {
  static const card = 24.0;
  static const button = 28.0;
}

/// Sombra suave de las tarjetas del diseño.
const kCardShadow = [
  BoxShadow(color: Color(0x0F1E3C6E), spreadRadius: 1),
  BoxShadow(color: Color(0x0D142850), blurRadius: 3, offset: Offset(0, 1)),
  BoxShadow(color: Color(0x0D142850), blurRadius: 16, offset: Offset(0, 4)),
];

const kFontFamily = 'Outfit';

/// SPEC-010 R1/R2: tema global. Outfit va embebida en la app (assets), nunca
/// se descarga.
ThemeData buildAppTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: KColors.accent,
    onPrimary: Colors.white,
    primaryContainer: KColors.navSelected,
    onPrimaryContainer: KColors.accent,
    secondary: KColors.accent,
    onSecondary: Colors.white,
    surface: KColors.background,
    onSurface: KColors.text,
    onSurfaceVariant: KColors.textSecondary,
    surfaceContainerHighest: KColors.surface,
    outline: KColors.border,
    outlineVariant: KColors.track,
    error: KColors.error,
    onError: Colors.white,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: kFontFamily,
    scaffoldBackgroundColor: KColors.background,
  );
  final text = base.textTheme.apply(
    bodyColor: KColors.text,
    displayColor: KColors.text,
  );
  const buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(KRadii.button)),
  );
  const buttonSize = Size(64, 56);
  const buttonText = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );
  return base.copyWith(
    textTheme: text.copyWith(
      headlineLarge: text.headlineLarge?.copyWith(
        fontWeight: FontWeight.w300,
        color: KColors.accent,
      ),
      headlineMedium: text.headlineMedium?.copyWith(
        fontWeight: FontWeight.w300,
        color: KColors.accent,
      ),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w400),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w500),
      bodyLarge: text.bodyLarge?.copyWith(fontWeight: FontWeight.w300),
      bodyMedium: text.bodyMedium?.copyWith(fontWeight: FontWeight.w300),
      bodySmall: text.bodySmall?.copyWith(color: KColors.textSecondary),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: KColors.background,
      foregroundColor: KColors.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: kFontFamily,
        fontSize: 26,
        fontWeight: FontWeight.w300,
        color: KColors.accent,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: buttonSize,
        shape: buttonShape,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: buttonSize,
        shape: buttonShape,
        foregroundColor: KColors.text,
        side: const BorderSide(color: KColors.border),
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        foregroundColor: KColors.accent,
        textStyle: buttonText.copyWith(fontSize: 15),
      ),
    ),
    cardTheme: const CardThemeData(
      color: KColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(KRadii.card)),
        side: BorderSide(color: KColors.track),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: KColors.surfaceSoft,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        borderSide: BorderSide(color: KColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        borderSide: BorderSide(color: KColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        borderSide: BorderSide(color: KColors.accent, width: 1.5),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: KColors.background,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(KRadii.card)),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: KColors.accent,
      linearTrackColor: KColors.track,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: KColors.accent,
        selectedForegroundColor: Colors.white,
        side: const BorderSide(color: KColors.border),
      ),
    ),
    dividerTheme: const DividerThemeData(color: KColors.track),
  );
}

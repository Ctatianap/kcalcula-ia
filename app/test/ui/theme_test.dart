import 'dart:math' as math;

import 'package:calorias_ia/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contraste WCAG 2.x entre dos colores opacos.
double _contrast(Color a, Color b) {
  double channel(double c) =>
      c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  double luminance(Color c) =>
      0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
  final la = luminance(a), lb = luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  test('AC1: el tema usa el acento, Outfit y fondo blanco', () {
    final theme = buildAppTheme();
    expect(theme.colorScheme.primary, KColors.accent);
    expect(theme.scaffoldBackgroundColor, KColors.background);
    expect(theme.textTheme.bodyMedium?.fontFamily, kFontFamily);
  });

  group('AC5: contraste ≥ 4,5:1', () {
    for (final (name, fg, bg) in [
      ('texto principal', KColors.text, KColors.background),
      ('texto secundario', KColors.textSecondary, KColors.background),
      (
        'texto secundario sobre superficie',
        KColors.textSecondary,
        KColors.surface,
      ),
      ('blanco sobre el acento', Colors.white, KColors.accent),
      ('acento sobre blanco', KColors.accent, KColors.background),
      ('acento sobre la pestaña activa', KColors.accent, KColors.navSelected),
      ('sello de confirmación', KColors.confirmText, KColors.confirmBackground),
    ]) {
      test(name, () => expect(_contrast(fg, bg), greaterThanOrEqualTo(4.5)));
    }
  });

  test(
    'R6/R7: cada estado del día contrasta ≥ 3:1 con el blanco (WCAG 1.4.11)',
    () {
      for (final status in DayGoalStatus.values) {
        expect(
          _contrast(status.color, KColors.background),
          greaterThanOrEqualTo(3),
          reason: status.label,
        );
      }
    },
  );

  test('R6: los estados del día no usan rojo ni verde de alarma', () {
    for (final status in DayGoalStatus.values) {
      final c = status.color;
      final isRed = c.r > 0.6 && c.g < 0.4 && c.b < 0.4;
      final isGreen = c.g > 0.5 && c.r < 0.4 && c.b < 0.4;
      expect(isRed || isGreen, isFalse, reason: status.label);
      expect(status.label, isNotEmpty);
    }
  });
}

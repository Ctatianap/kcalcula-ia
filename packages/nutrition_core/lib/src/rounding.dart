/// Kcal enteras, redondeo half-up. `double.round()` de Dart ya redondea
/// los .5 positivos hacia arriba, que es lo que pide `docs/architecture.md`.
int presentKcal(double kcal) => kcal.round();

/// Macros con 1 decimal, mismo redondeo half-up.
double presentMacro(double grams) => (grams * 10).round() / 10;

/// Entero con separador de miles de es-CO ("1.250"), para presentar kcal.
String formatThousandsEs(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Macro presentado (1 decimal, half-up) con coma decimal de es-CO ("45,3").
String formatMacroEs(double grams) =>
    presentMacro(grams).toStringAsFixed(1).replaceAll('.', ',');

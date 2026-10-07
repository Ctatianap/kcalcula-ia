/// Entrada de números en es-CO compartida por varias pantallas (las
/// features no se importan entre sí).
library;

/// SPEC-008 R1 / SPEC-015 R2: mismo rango que `nutrition_core`
/// (`estimationWeightMinKg`–`estimationWeightMaxKg`).
const weightRangeMessage = 'Escribe tu peso en kg, entre 30 y 300.';

/// Número con máximo un decimal, con coma o punto ("63,5"); `null` si no.
double? parseDecimal(String text) => parseDecimalUpTo(text, maxDecimals: 1);

/// SPEC-030 R1: número sin signo con coma o punto decimal y hasta
/// [maxDecimals] decimales ("1,4", "0.25"); `null` si no. Sin separador de
/// miles: "1.200" con `maxDecimals: 2` no es válido, para no leerlo como
/// 1,2 sin avisar.
double? parseDecimalUpTo(String text, {required int maxDecimals}) {
  final normalized = text.trim().replaceAll(',', '.');
  final pattern = RegExp('^\\d+(\\.\\d{1,$maxDecimals})?\$');
  if (!pattern.hasMatch(normalized)) return null;
  return double.parse(normalized);
}

/// SPEC-030 R2: número para mostrar en es-CO, con coma, hasta
/// [maxDecimals] decimales y sin ceros de más ("15", "2,9", "1,78").
/// Solo presentación: no cambia el valor guardado (invariante 3).
String formatDecimalEs(double value, {int maxDecimals = 2}) {
  var text = value.toStringAsFixed(maxDecimals);
  if (text.contains('.')) {
    text = text.replaceFirst(RegExp(r'\.?0+$'), '');
  }
  return text.replaceAll('.', ',');
}

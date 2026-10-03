/// Entrada de números en es-CO compartida por varias pantallas (las
/// features no se importan entre sí).
library;

/// SPEC-008 R1 / SPEC-015 R2: mismo rango que `nutrition_core`
/// (`estimationWeightMinKg`–`estimationWeightMaxKg`).
const weightRangeMessage = 'Escribe tu peso en kg, entre 30 y 300.';

/// Número con máximo un decimal, con coma o punto ("63,5"); `null` si no.
double? parseDecimal(String text) {
  final normalized = text.trim().replaceAll(',', '.');
  if (!RegExp(r'^\d+(\.\d)?$').hasMatch(normalized)) return null;
  return double.parse(normalized);
}

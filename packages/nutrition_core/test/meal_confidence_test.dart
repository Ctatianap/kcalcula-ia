import 'package:nutrition_core/nutrition_core.dart';
import 'package:test/test.dart';

void main() {
  group('AC6: confianza por comida', () {
    test(
      'un ítem Estimación que aporta < 15% no baja el nivel de la comida',
      () {
        final level = mealConfidence([
          (energyKcal: 500, confidence: ConfidenceLevel.buenaEstimacion), // 50%
          (energyKcal: 490, confidence: ConfidenceLevel.altaPrecision), // 49%
          (
            energyKcal: 10,
            confidence: ConfidenceLevel.estimacion,
          ), // 1%, no cuenta
        ]);
        expect(level, ConfidenceLevel.buenaEstimacion);
      },
    );

    test(
      'un ítem Estimación que aporta >= 15% sí baja el nivel de la comida',
      () {
        final level = mealConfidence([
          (energyKcal: 500, confidence: ConfidenceLevel.altaPrecision),
          (energyKcal: 500, confidence: ConfidenceLevel.estimacion), // 50%
        ]);
        expect(level, ConfidenceLevel.estimacion);
      },
    );

    test('si ningún ítem llega al 15%, se usa el más bajo de todos', () {
      // Caso de borde: muchos ítems pequeños, ninguno individualmente >= 15%.
      final level = mealConfidence([
        (energyKcal: 20, confidence: ConfidenceLevel.altaPrecision),
        (energyKcal: 20, confidence: ConfidenceLevel.altaPrecision),
        (energyKcal: 20, confidence: ConfidenceLevel.estimacion),
        (energyKcal: 20, confidence: ConfidenceLevel.altaPrecision),
        (energyKcal: 20, confidence: ConfidenceLevel.altaPrecision),
        (energyKcal: 20, confidence: ConfidenceLevel.altaPrecision),
        (energyKcal: 20, confidence: ConfidenceLevel.altaPrecision),
      ]);
      expect(level, ConfidenceLevel.estimacion);
    });
  });
}

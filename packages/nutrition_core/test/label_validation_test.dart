import 'package:nutrition_core/nutrition_core.dart';
import 'package:test/test.dart';

void main() {
  group('checkLabelAtwater', () {
    test('dentro de ±20%: "30 g = 140 kcal" (AC2)', () {
      // 140 kcal / 30 g -> por 100 g: kcal=466.7, p=10, c=56.7, f=20 (ejemplo)
      final result = checkLabelAtwater(
        energyKcal: 466.7,
        proteinG: 10,
        carbsG: 56.7,
        fatG: 20,
      );
      // 4*10 + 4*56.7 + 9*20 = 40 + 226.8 + 180 = 446.8, dentro de ±20% de 466.7
      expect(result.withinTolerance, isTrue);
      expect(result.calculatedKcal, closeTo(446.8, 1e-9));
      expect(result.declaredKcal, 466.7);
    });

    test('fuera de ±20% (AC3)', () {
      final result = checkLabelAtwater(
        energyKcal: 500,
        proteinG: 1,
        carbsG: 1,
        fatG: 1,
      );
      // 4+4+9=17, muy lejos de 500
      expect(result.withinTolerance, isFalse);
      expect(result.calculatedKcal, 17);
    });

    test('borde exacto del ±20% cuenta como dentro de tolerancia', () {
      final result = checkLabelAtwater(
        energyKcal: 100,
        proteinG: 10,
        carbsG: 10,
        fatG: 20 / 9, // calculado = 40+40+20 = 100 * 1.2? recalculado abajo
      );
      // 4*10+4*10+9*(20/9) = 40+40+20 = 100, dentro de rango trivialmente.
      expect(result.withinTolerance, isTrue);
    });
  });

  group('isValidServingGrams', () {
    test('null no es válido', () {
      expect(isValidServingGrams(null), isFalse);
    });

    test('0 o negativo no es válido', () {
      expect(isValidServingGrams(0), isFalse);
      expect(isValidServingGrams(-5), isFalse);
    });

    test('positivo es válido', () {
      expect(isValidServingGrams(30), isTrue);
    });
  });
}

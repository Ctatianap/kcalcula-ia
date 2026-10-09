import 'package:nutrition_core/nutrition_core.dart';
import 'package:test/test.dart';

void main() {
  group('SPEC-042 AC1: portionsForAmount', () {
    test('45 g con porción de 30 g = 1,5', () {
      expect(portionsForAmount(45, 30), 1.5);
    });
    test('30 g con porción de 30 g = 1', () {
      expect(portionsForAmount(30, 30), 1);
    });
    test('porción 0 o negativa → null', () {
      expect(portionsForAmount(10, 0), isNull);
      expect(portionsForAmount(10, -5), isNull);
    });
  });

  group('SPEC-042 AC1: amountForPortions', () {
    test('3 porciones de 27 g = 81 g', () {
      expect(amountForPortions(3, 27), 81);
    });
    test('media porción de 200 ml = 100 ml', () {
      expect(amountForPortions(0.5, 200), 100);
    });
    test('porción 0 o negativa → null', () {
      expect(amountForPortions(2, 0), isNull);
      expect(amountForPortions(2, -1), isNull);
    });
  });

  group('SPEC-042 AC1: per100FromAmount', () {
    test('150 kcal en 30 g = 500 por 100 g', () {
      expect(per100FromAmount(150, 30), 500);
    });
    test('1,5 g en 30 g = 5 por 100 g', () {
      expect(per100FromAmount(1.5, 30), 5);
    });
    test('cantidad 0 o negativa → null', () {
      expect(per100FromAmount(5, 0), isNull);
      expect(per100FromAmount(5, -30), isNull);
    });
  });

  group('SPEC-042 AC1: amountFromPer100', () {
    test('500 por 100 g en 30 g = 150', () {
      expect(amountFromPer100(500, 30), 150);
    });
    test('48 por 100 g en 27 g = 12,96', () {
      expect(amountFromPer100(48, 27), closeTo(12.96, 1e-9));
    });
    test('cantidad 0 o negativa → null', () {
      expect(amountFromPer100(10, 0), isNull);
      expect(amountFromPer100(10, -1), isNull);
    });
  });

  test('SPEC-042 AC1: ida y vuelta por 100 g conserva el valor', () {
    for (final (value, amount) in [
      (150.0, 30.0),
      (1.5, 27.0),
      (90.0, 200.0),
      (0.0, 45.0),
      (7.3, 33.3),
    ]) {
      final per100 = per100FromAmount(value, amount)!;
      expect(amountFromPer100(per100, amount), closeTo(value, 1e-9));
    }
  });

  test('SPEC-042 AC1: ida y vuelta de porciones conserva los gramos', () {
    for (final (grams, portion) in [(45.0, 30.0), (81.0, 27.0), (13.0, 7.0)]) {
      final portions = portionsForAmount(grams, portion)!;
      expect(amountForPortions(portions, portion), closeTo(grams, 1e-9));
    }
  });
}

import 'package:nutrition_core/nutrition_core.dart';
import 'package:test/test.dart';

void main() {
  group('GoalProgress (SPEC-008 R6, AC6)', () {
    test(
      'por debajo de la meta: resta sin redondear y redondea al presentar',
      () {
        const p = GoalProgress(consumed: 1249.6, goal: 2000);
        expect(p.remaining, closeTo(750.4, 1e-9));
        expect(p.excess, 0);
        expect(p.isOverGoal, isFalse);
        expect(presentKcal(p.consumed), 1250);
        expect(presentKcal(p.remaining), 750);
        expect(p.fraction, closeTo(0.6248, 1e-9));
      },
    );

    test('por encima de la meta: exceso y barra llena', () {
      const p = GoalProgress(consumed: 2150.2, goal: 2000);
      expect(p.isOverGoal, isTrue);
      expect(p.remaining, 0);
      expect(presentKcal(p.excess), 150);
      expect(p.fraction, 1);
    });

    test('igual a la meta: quedan 0, no "por encima"', () {
      const p = GoalProgress(consumed: 2000, goal: 2000);
      expect(p.isOverGoal, isFalse);
      expect(p.remaining, 0);
      expect(p.fraction, 1);
    });

    test('día sin comidas', () {
      const p = GoalProgress(consumed: 0, goal: 2000);
      expect(p.remaining, 2000);
      expect(p.fraction, 0);
    });

    test('macros en gramos con un decimal', () {
      const p = GoalProgress(consumed: 45.26, goal: 100);
      expect(presentMacro(p.remaining), 54.7);
    });
  });

  group('formatThousandsEs', () {
    test('separador de miles con punto', () {
      expect(formatThousandsEs(0), '0');
      expect(formatThousandsEs(750), '750');
      expect(formatThousandsEs(1250), '1.250');
      expect(formatThousandsEs(2000), '2.000');
      expect(formatThousandsEs(1234567), '1.234.567');
    });
  });

  group('formatMacroEs', () {
    test('un decimal con coma, half-up', () {
      expect(formatMacroEs(45.26), '45,3');
      expect(formatMacroEs(100), '100,0');
      expect(formatMacroEs(0.04), '0,0');
    });
  });

  group('ratio y presentPercent (SPEC-013 R3)', () {
    test('1.538 de 1.640 kcal → 94 %', () {
      const p = GoalProgress(consumed: 1538, goal: 1640);
      expect(p.ratio, closeTo(0.937805, 1e-6));
      expect(presentPercent(p.ratio), 94);
    });

    test('sin tope por encima de la meta: 1.900 de 1.640 → 116 %', () {
      const p = GoalProgress(consumed: 1900, goal: 1640);
      expect(presentPercent(p.ratio), 116);
      expect(p.fraction, 1);
    });

    test('half-up en el .5 y meta no positiva → 0', () {
      expect(presentPercent(0.945), 95);
      expect(presentPercent(0.9449), 94);
      expect(const GoalProgress(consumed: 500, goal: 0).ratio, 0);
    });
  });
}

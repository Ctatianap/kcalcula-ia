import 'package:nutrition_core/nutrition_core.dart';
import 'package:test/test.dart';

WeightEntry _w(int day, double kg, {int month = 10}) =>
    (date: DateTime(2026, month, day), kg: kg);

void main() {
  group('SPEC-015 AC1: cambio de la semana', () {
    test('62,0 hoy y 62,4 hace 7 días → −0,4', () {
      final change = weeklyWeightChange([_w(3, 62.0), _w(26, 62.4, month: 9)]);
      expect(change, closeTo(-0.4, 1e-9));
      expect(presentMacro(change!), -0.4);
    });

    test('un solo registro → sin cambio', () {
      expect(weeklyWeightChange([_w(3, 62.0)]), isNull);
    });

    test('sin registros → sin último peso ni cambio', () {
      expect(latestWeight(const []), isNull);
      expect(weeklyWeightChange(const []), isNull);
    });

    test('usa el registro más cercano a 7 días antes del último', () {
      // Últ.: 3 oct. Candidatos: 30 sep (3 d), 27 sep (6 d), 24 sep (9 d).
      final entries = [
        _w(3, 61.0),
        _w(30, 61.5, month: 9),
        _w(27, 62.0, month: 9),
        _w(24, 63.0, month: 9),
      ];
      expect(weeklyWeightChange(entries), closeTo(-1.0, 1e-9));
    });

    test('en empate (6 y 8 días) gana el más antiguo', () {
      final entries = [_w(9, 60.0), _w(3, 61.0), _w(1, 62.0)];
      expect(weeklyWeightChange(entries), closeTo(-2.0, 1e-9));
    });

    test('más de 14 días atrás no cuenta como referencia', () {
      expect(weeklyWeightChange([_w(3, 61.0), _w(18, 62.0, month: 9)]), isNull);
      expect(
        weeklyWeightChange([_w(3, 61.0), _w(19, 62.0, month: 9)]),
        closeTo(-1.0, 1e-9),
      );
    });

    test('mismo peso → 0 (la app muestra "sin cambios")', () {
      expect(weeklyWeightChange([_w(3, 62.0), _w(26, 62.0, month: 9)]), 0);
    });

    test('el orden de la lista no importa', () {
      expect(
        weeklyWeightChange([_w(26, 62.4, month: 9), _w(3, 62.0)]),
        closeTo(-0.4, 1e-9),
      );
    });
  });
}

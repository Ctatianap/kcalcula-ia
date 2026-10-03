import 'package:nutrition_core/nutrition_core.dart';
import 'package:test/test.dart';

double _kcalOf(MacroSuggestion m) =>
    m.proteinG * kcalPerGramProtein +
    m.carbsG * kcalPerGramCarbs +
    m.fatG * kcalPerGramFat;

void main() {
  group('AC5b: suggestMacros (Res. 3803 + FAO 2003)', () {
    test('2.000 kcal y 63 kg: proteína ajustada al 14 % (69,93 g < 70 g)', () {
      final m = suggestMacros(energyKcal: 2000, weightKg: 63);
      expect(m.proteinG, closeTo(70.0, 1e-9));
      expect(m.fatG, closeTo(550 / 9, 1e-9)); // 61,11 g = 27,5 %
      expect(m.carbsG, closeTo(292.5, 1e-9));
      expect(_kcalOf(m), closeTo(2000, 0.01));
    });

    test('2.000 kcal y 120 kg: proteína topada al 20 % (100 g)', () {
      final m = suggestMacros(energyKcal: 2000, weightKg: 120);
      expect(m.proteinG, closeTo(100, 1e-9));
      expect(m.carbsG, closeTo((2000 - 400 - 550) / 4, 1e-9));
      expect(_kcalOf(m), closeTo(2000, 0.01));
    });

    test('2.500 kcal y 80 kg: sin ajuste, 1,11 g/kg (88,8 g = 14,2 %)', () {
      final m = suggestMacros(energyKcal: 2500, weightKg: 80);
      expect(m.proteinG, closeTo(88.8, 1e-9));
      expect(_kcalOf(m), closeTo(2500, 0.01));
    });

    test('cada macro dentro de su rango de la Res. 3803', () {
      for (final (kcal, kg) in [
        (1500.0, 45.0),
        (2275.0, 63.0),
        (3500.0, 150.0),
      ]) {
        final m = suggestMacros(energyKcal: kcal, weightKg: kg);
        final protein = m.proteinG * 4 / kcal;
        final fat = m.fatG * 9 / kcal;
        final carbs = m.carbsG * 4 / kcal;
        expect(protein, inInclusiveRange(0.14, 0.20));
        expect(fat, inInclusiveRange(0.20, 0.35));
        expect(carbs, inInclusiveRange(0.50, 0.65));
        expect(_kcalOf(m), closeTo(kcal, 0.01));
      }
    });
  });
}

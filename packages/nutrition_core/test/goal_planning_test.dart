import 'package:nutrition_core/nutrition_core.dart';
import 'package:test/test.dart';

double _kcalOf(MacroGrams m) =>
    m.proteinG * kcalPerGramProtein +
    m.carbsG * kcalPerGramCarbs +
    m.fatG * kcalPerGramFat;

void main() {
  test('AC4: kcal por objetivo con mantenimiento 2.000', () {
    expect(objectiveKcal(2000, GoalObjective.loseFatGentle), 1750);
    expect(objectiveKcal(2000, GoalObjective.loseFat), 1500);
    expect(objectiveKcal(2000, GoalObjective.maintain), 2000);
    expect(objectiveKcal(2000, GoalObjective.gainMuscleGentle), 2200);
    expect(objectiveKcal(2000, GoalObjective.gainMuscle), 2400);
  });

  test('AC5: 2.000 kcal con "Mantener" → 100 g / 55,6 g / 275 g', () {
    final m = macroGramsFor(2000, GoalObjective.maintain);
    expect(m.proteinG, closeTo(100, 1e-9));
    expect(m.fatG, closeTo(500 / 9, 1e-9));
    expect(m.carbsG, closeTo(275, 1e-9));
  });

  test('AC5: los gramos suman las kcal en todos los objetivos', () {
    for (final objective in GoalObjective.values) {
      for (final kcal in [1500.0, 2276.0, 3100.0]) {
        expect(_kcalOf(macroGramsFor(kcal, objective)), closeTo(kcal, 0.01));
      }
    }
  });

  test('AC5: cada reparto está dentro de los AMDR y con grasa ≥ 20 %', () {
    for (final objective in GoalObjective.values) {
      final s = macroSharesFor(objective);
      expect(s.protein + s.fat + s.carbs, closeTo(1, 1e-9));
      expect(s.protein, inInclusiveRange(0.10, 0.35));
      expect(s.fat, inInclusiveRange(0.20, 0.35));
      expect(s.carbs, inInclusiveRange(0.45, 0.65));
    }
  });
}

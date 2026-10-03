import 'package:nutrition_core/nutrition_core.dart';
import 'package:test/test.dart';

void main() {
  group('AC1: estado del día con meta 2.000', () {
    for (final (kcal, expected) in [
      (0.0, DayStatus.belowGoal),
      (1799.0, DayStatus.belowGoal),
      (1800.0, DayStatus.onGoal),
      (2000.0, DayStatus.onGoal),
      (2200.0, DayStatus.onGoal),
      (2201.0, DayStatus.aboveGoal),
    ]) {
      test('$kcal → ${expected.name}', () {
        expect(dayStatus(consumedKcal: kcal, goalKcal: 2000), expected);
      });
    }
  });

  test('AC1: sin meta (o meta no positiva) no hay estado', () {
    expect(dayStatus(consumedKcal: 1500), isNull);
    expect(dayStatus(consumedKcal: 1500, goalKcal: 0), isNull);
  });

  test('los límites se comparan sin redondear', () {
    expect(
      dayStatus(consumedKcal: 1799.99, goalKcal: 2000),
      DayStatus.belowGoal,
    );
    expect(
      dayStatus(consumedKcal: 2200.01, goalKcal: 2000),
      DayStatus.aboveGoal,
    );
  });
}

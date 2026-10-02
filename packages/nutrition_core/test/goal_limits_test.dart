import 'package:nutrition_core/nutrition_core.dart';
import 'package:test/test.dart';

void main() {
  group('SPEC-008 OQ4: rangos de la meta', () {
    test('kcal entre 800 y 6.000, inclusive', () {
      expect(isValidGoalKcal(799), isFalse);
      expect(isValidGoalKcal(800), isTrue);
      expect(isValidGoalKcal(6000), isTrue);
      expect(isValidGoalKcal(6001), isFalse);
    });

    test('macros entre 0 y 1.000 g, inclusive', () {
      expect(isValidGoalMacro(-0.1), isFalse);
      expect(isValidGoalMacro(0), isTrue);
      expect(isValidGoalMacro(1000), isTrue);
      expect(isValidGoalMacro(1000.1), isFalse);
    });
  });

  group('SPEC-008 R13/AC14: advertencia de meta baja', () {
    test('1.199 advierte; 1.200 no', () {
      expect(isLowGoalKcal(1199), isTrue);
      expect(isLowGoalKcal(1200), isFalse);
    });
  });
}

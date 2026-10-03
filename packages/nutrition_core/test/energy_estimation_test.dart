import 'package:nutrition_core/nutrition_core.dart';
import 'package:test/test.dart';

void main() {
  group('AC1: metabolismo basal (Harris y Benedict)', () {
    // Casos resueltos por la fuente: Harris JA, Benedict FG (1919),
    // *A Biometric Study of Basal Metabolism in Man*, Carnegie Institution,
    // p. 230 (https://archive.org/details/biometricstudyof00harruoft).
    // La fuente suma términos ya redondeados: tolerancia ±1 kcal.
    for (final (sex, age, height, weight, expected) in [
      (BiologicalSex.male, 27, 172.0, 77.2, 1806),
      (BiologicalSex.female, 22, 166.0, 77.2, 1597),
      (BiologicalSex.female, 66, 162.0, 62.3, 1242),
    ]) {
      test('${sex.name}, $age años, $height cm, $weight kg → $expected', () {
        final kcal = estimateBasalKcal(
          weightKg: weight,
          heightCm: height,
          ageYears: age,
          sex: sex,
        );
        expect(kcal, closeTo(expected, 1));
      });
    }
  });

  group('AC2: mantenimiento = basal × PAL de EFSA 2013', () {
    final basal = estimateBasalKcal(
      weightKg: 77.2,
      heightCm: 172,
      ageYears: 27,
      sex: BiologicalSex.male,
    );
    for (final (level, pal) in [
      (ActivityLevel.sedentary, 1.4),
      (ActivityLevel.lightlyActive, 1.6),
      (ActivityLevel.active, 1.8),
      (ActivityLevel.veryActive, 2.0),
    ]) {
      test('${level.name} → × $pal', () {
        expect(level.pal, pal);
        final kcal = estimateMaintenanceKcal(
          weightKg: 77.2,
          heightCm: 172,
          ageYears: 27,
          sex: BiologicalSex.male,
          activityLevel: level,
        );
        expect(kcal, closeTo(basal * pal, 1e-9));
      });
    }
  });

  group('AC3: entradas fuera de rango → error tipado', () {
    double basal({
      double weightKg = 63,
      double heightCm = 165,
      int ageYears = 30,
    }) => estimateBasalKcal(
      weightKg: weightKg,
      heightCm: heightCm,
      ageYears: ageYears,
      sex: BiologicalSex.female,
    );

    Matcher throwsField(EstimationField field) => throwsA(
      isA<InvalidEstimationInput>().having((e) => e.field, 'field', field),
    );

    test('peso, incluido NaN', () {
      expect(() => basal(weightKg: 29.9), throwsField(EstimationField.weight));
      expect(() => basal(weightKg: 300.1), throwsField(EstimationField.weight));
      expect(
        () => basal(weightKg: double.nan),
        throwsField(EstimationField.weight),
      );
      expect(basal(weightKg: 30), isA<double>());
    });

    test('estatura, incluido infinito', () {
      expect(() => basal(heightCm: 119), throwsField(EstimationField.height));
      expect(
        () => basal(heightCm: double.infinity),
        throwsField(EstimationField.height),
      );
    });

    test('edad: 18 a 100', () {
      expect(() => basal(ageYears: 17), throwsField(EstimationField.age));
      expect(() => basal(ageYears: 101), throwsField(EstimationField.age));
      expect(basal(ageYears: 18), isA<double>());
      expect(basal(ageYears: 100), isA<double>());
    });
  });

  group('ageInYears', () {
    test('antes y después del cumpleaños', () {
      final birth = DateTime(1996, 10, 15);
      expect(ageInYears(birth, DateTime(2026, 10, 14)), 29);
      expect(ageInYears(birth, DateTime(2026, 10, 15)), 30);
      expect(ageInYears(birth, DateTime(2026, 12, 1)), 30);
    });
  });
}

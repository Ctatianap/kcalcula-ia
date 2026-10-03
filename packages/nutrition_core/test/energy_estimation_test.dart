import 'package:nutrition_core/nutrition_core.dart';
import 'package:test/test.dart';

/// Casos de referencia calculados por la fuente (no de memoria):
/// NASEM (2023), *Dietary Reference Intakes for Energy*, cap. 7, ejemplos
/// resueltos y Tablas 7-9 (hombres) y 7-10 (mujeres), "Estimated Energy
/// Requirements (EER) for Overall Population"; edades usadas según la nota
/// al pie de esas tablas. Transcripción en
/// `docs/research/2026-10-02-formula-gasto-energetico.md` (OQ9 de SPEC-008).
const _levels = [
  ActivityLevel.inactive,
  ActivityLevel.lowActive,
  ActivityLevel.active,
  ActivityLevel.veryActive,
];

const _table79Men = [
  (25, 176.1, 81.4, [2775, 2988, 3177, 3516]),
  (40, 176.3, 89.9, [2733, 2955, 3151, 3519]),
  (60, 174.9, 88.7, [2491, 2709, 2907, 3258]),
  (80, 172.2, 83.3, [2181, 2389, 2586, 2896]),
  (50, 175.4, 87.2, [2581, 2799, 2994, 3345]),
];

const _table710Women = [
  (25, 162.7, 69.3, [2152, 2316, 2454, 2683]),
  (40, 162.5, 75.0, [2112, 2278, 2418, 2647]),
  (60, 160.8, 74.8, [1960, 2125, 2264, 2489]),
  (80, 156.8, 69.7, [1737, 1896, 2035, 2249]),
  (50, 161.2, 73.2, [2014, 2178, 2317, 2543]),
];

void main() {
  group('AC3: estimateMaintenanceKcal contra la DRI 2023', () {
    test(
      'ejemplo resuelto: mujer, 22 años, 165 cm, 63 kg, low active → 2.275',
      () {
        final kcal = estimateMaintenanceKcal(
          weightKg: 63,
          heightCm: 165,
          ageYears: 22,
          sex: BiologicalSex.female,
          activityLevel: ActivityLevel.lowActive,
        );
        expect(kcal, closeTo(2275, 1));
      },
    );

    test(
      'ejemplo resuelto: mujer, 70 años, 157 cm, 70 kg, inactive → 1.812',
      () {
        final kcal = estimateMaintenanceKcal(
          weightKg: 70,
          heightCm: 157,
          ageYears: 70,
          sex: BiologicalSex.female,
          activityLevel: ActivityLevel.inactive,
        );
        expect(kcal, closeTo(1812, 1));
      },
    );

    for (final (sex, rows) in [
      (BiologicalSex.male, _table79Men),
      (BiologicalSex.female, _table710Women),
    ]) {
      for (final (age, height, weight, expected) in rows) {
        for (var i = 0; i < _levels.length; i++) {
          test('${sex.name}, $age años, $height cm, $weight kg, '
              '${_levels[i].name} → ${expected[i]}', () {
            final kcal = estimateMaintenanceKcal(
              weightKg: weight,
              heightCm: height,
              ageYears: age,
              sex: sex,
              activityLevel: _levels[i],
            );
            expect(kcal, closeTo(expected[i], 1));
          });
        }
      }
    }
  });

  group('AC4: entradas fuera de rango → error tipado', () {
    double estimate({
      double weightKg = 63,
      double heightCm = 165,
      int ageYears = 30,
    }) => estimateMaintenanceKcal(
      weightKg: weightKg,
      heightCm: heightCm,
      ageYears: ageYears,
      sex: BiologicalSex.female,
      activityLevel: ActivityLevel.active,
    );

    Matcher throwsField(EstimationField field) => throwsA(
      isA<InvalidEstimationInput>().having((e) => e.field, 'field', field),
    );

    test('peso', () {
      expect(
        () => estimate(weightKg: 29.9),
        throwsField(EstimationField.weight),
      );
      expect(
        () => estimate(weightKg: 300.1),
        throwsField(EstimationField.weight),
      );
      expect(estimate(weightKg: 30), isA<double>());
      expect(estimate(weightKg: 300), isA<double>());
    });

    test('NaN e infinito', () {
      expect(
        () => estimate(weightKg: double.nan),
        throwsField(EstimationField.weight),
      );
      expect(
        () => estimate(heightCm: double.infinity),
        throwsField(EstimationField.height),
      );
    });

    test('estatura', () {
      expect(
        () => estimate(heightCm: 119),
        throwsField(EstimationField.height),
      );
      expect(
        () => estimate(heightCm: 231),
        throwsField(EstimationField.height),
      );
    });

    test('edad: desde 19 (la fuente es para adultos de 19 años o más)', () {
      expect(() => estimate(ageYears: 18), throwsField(EstimationField.age));
      expect(() => estimate(ageYears: 101), throwsField(EstimationField.age));
      expect(estimate(ageYears: 19), isA<double>());
      expect(estimate(ageYears: 100), isA<double>());
    });
  });
}

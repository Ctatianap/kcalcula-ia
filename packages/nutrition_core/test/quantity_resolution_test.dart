import 'package:nutrition_core/nutrition_core.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group('explicit_weight', () {
    test('gramos directo', () {
      final food = buildFood();
      final result = resolveGrams(
        input: const QuantityInput(
          quantity: 150,
          unit: QuantityUnit.gramos,
          isVague: false,
        ),
        food: food,
      );
      expect(result.resolvable, isTrue);
      expect(result.basis, QuantityBasis.explicitWeight);
      expect(result.grams, 150);
      expect(result.usedDensityFallback, isFalse);
    });

    test('mililitros con densidad conocida', () {
      final food = buildFood(densityGPerMl: 0.92);
      final result = resolveGrams(
        input: const QuantityInput(
          quantity: 10,
          unit: QuantityUnit.mililitros,
          isVague: false,
        ),
        food: food,
      );
      expect(result.basis, QuantityBasis.explicitWeight);
      expect(result.grams, closeTo(9.2, 1e-9));
      expect(result.usedDensityFallback, isFalse);
    });

    test('mililitros sin densidad usa 1 g/ml y marca el fallback', () {
      final food = buildFood();
      final result = resolveGrams(
        input: const QuantityInput(
          quantity: 10,
          unit: QuantityUnit.mililitros,
          isVague: false,
        ),
        food: food,
      );
      expect(result.grams, 10);
      expect(result.usedDensityFallback, isTrue);
    });
  });

  group('unit_portion', () {
    test('"2 huevos" usa la porción "unidad"', () {
      final food = buildFood(
        portions: [buildPortion(descriptor: 'unidad', grams: 50)],
      );
      final result = resolveGrams(
        input: const QuantityInput(
          quantity: 2,
          unit: QuantityUnit.unidad,
          isVague: false,
        ),
        food: food,
      );
      expect(result.basis, QuantityBasis.unitPortion);
      expect(result.grams, 100);
      expect(result.usedCuratedEstimatePortion, isFalse);
    });

    test('sin fila de porción "unidad" queda no resoluble', () {
      final food = buildFood();
      final result = resolveGrams(
        input: const QuantityInput(
          quantity: 2,
          unit: QuantityUnit.unidad,
          isVague: false,
        ),
        food: food,
      );
      expect(result.resolvable, isFalse);
      expect(result.grams, isNull);
      expect(result.basis, QuantityBasis.unitPortion);
    });
  });

  test('size_descriptor: "arepa pequeña" usa la porción "pequeno"', () {
    final food = buildFood(
      portions: [buildPortion(descriptor: 'pequeno', grams: 60)],
    );
    final result = resolveGrams(
      input: const QuantityInput(size: SizeDescriptor.pequeno, isVague: false),
      food: food,
    );
    expect(result.basis, QuantityBasis.sizeDescriptor);
    expect(result.grams, 60);
  });

  group('household_measure', () {
    test('"1 cucharada de aceite" con densidad', () {
      final food = buildFood(densityGPerMl: 0.92);
      final result = resolveGrams(
        input: const QuantityInput(
          quantity: 1,
          unit: QuantityUnit.cucharada,
          isVague: false,
        ),
        food: food,
        householdUnitMlByUnit: const {QuantityUnit.cucharada: 15},
      );
      expect(result.basis, QuantityBasis.householdMeasure);
      expect(result.grams, closeTo(13.8, 1e-9));
      expect(result.usedDensityFallback, isFalse);
    });

    test('sin unidad doméstica configurada queda no resoluble', () {
      final food = buildFood();
      final result = resolveGrams(
        input: const QuantityInput(
          quantity: 1,
          unit: QuantityUnit.cucharada,
          isVague: false,
        ),
        food: food,
      );
      expect(result.resolvable, isFalse);
    });
  });

  group('default_portion', () {
    test('"un poquito de queso": sin cantidad, unidad ni tamaño', () {
      final food = buildFood(
        portions: [
          buildPortion(
            descriptor: 'porcion',
            grams: 30,
            isCuratedEstimate: true,
          ),
        ],
      );
      final result = resolveGrams(
        input: const QuantityInput(isVague: true),
        food: food,
      );
      expect(result.basis, QuantityBasis.defaultPortion);
      expect(result.grams, 30);
      expect(result.usedCuratedEstimatePortion, isTrue);
    });

    test('unidad "porcion" explícita multiplica por la cantidad', () {
      final food = buildFood(
        portions: [buildPortion(descriptor: 'porcion', grams: 200)],
      );
      final result = resolveGrams(
        input: const QuantityInput(
          quantity: 2,
          unit: QuantityUnit.porcion,
          isVague: false,
        ),
        food: food,
      );
      expect(result.basis, QuantityBasis.defaultPortion);
      expect(result.grams, 400);
    });
  });
}

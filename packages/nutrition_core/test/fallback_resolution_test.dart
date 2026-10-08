import 'package:nutrition_core/nutrition_core.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// SPEC-043: cantidad sin equivalencia en el catálogo. Casos de referencia
/// con alimentos de prueba (no son datos reales del catálogo).
void main() {
  group('AC1: "2 unidad" de un alimento sin porción "unidad"', () {
    final food = buildFood(
      portions: [buildPortion(descriptor: 'porcion', grams: 120)],
    );
    final input = const QuantityInput(
      quantity: 2,
      unit: QuantityUnit.unidad,
      isVague: false,
    );

    test('no se puede convertir', () {
      expect(resolveGrams(input: input, food: food).resolvable, isFalse);
    });

    test('el respaldo es la porción típica, con base default_portion', () {
      final fallback = fallbackResolution(food);
      expect(fallback.resolvable, isTrue);
      expect(fallback.grams, 120);
      expect(fallback.basis, QuantityBasis.defaultPortion);
      expect(fallback.usedDensityFallback, isFalse);
      expect(fallback.usedCuratedEstimatePortion, isFalse);
    });

    test('su confianza es Estimación', () {
      final fallback = fallbackResolution(food);
      expect(
        itemConfidence(
          basis: fallback.basis,
          isVague: false,
          usedCuratedEstimatePortion: fallback.usedCuratedEstimatePortion,
          usedDensityFallback: fallback.usedDensityFallback,
          withoutEquivalence: true,
        ),
        ConfidenceLevel.estimacion,
      );
    });
  });

  group('AC2: qué porción usa el respaldo', () {
    test('sin porciones → 100 g', () {
      final fallback = fallbackResolution(buildFood());
      expect(fallback.grams, fallbackReferenceGrams);
      expect(fallbackReferenceGrams, 100);
    });

    test('con "porcion" → esa, aunque no sea la primera', () {
      final fallback = fallbackResolution(
        buildFood(
          portions: [
            buildPortion(descriptor: 'unidad', grams: 50),
            buildPortion(descriptor: 'porcion', grams: 30),
          ],
        ),
      );
      expect(fallback.grams, 30);
    });

    test('sin "porcion" pero con otras → la primera', () {
      final fallback = fallbackResolution(
        buildFood(
          portions: [
            buildPortion(
              descriptor: 'pequeno',
              grams: 70,
              isCuratedEstimate: true,
            ),
            buildPortion(descriptor: 'grande', grams: 140),
          ],
        ),
      );
      expect(fallback.grams, 70);
      // La marca de porción curada se conserva.
      expect(fallback.usedCuratedEstimatePortion, isTrue);
    });
  });

  test('R2: sin la marca, itemConfidence no cambia (regresión de las otras reglas)', () {
    expect(
      itemConfidence(
        basis: QuantityBasis.unitPortion,
        isVague: false,
        usedCuratedEstimatePortion: false,
        usedDensityFallback: false,
      ),
      ConfidenceLevel.buenaEstimacion,
    );
    // Con la marca, cualquier base queda en Estimación.
    for (final basis in QuantityBasis.values) {
      expect(
        itemConfidence(
          basis: basis,
          isVague: false,
          usedCuratedEstimatePortion: false,
          usedDensityFallback: false,
          hasLabelGramsOrMl: true,
          withoutEquivalence: true,
        ),
        ConfidenceLevel.estimacion,
      );
    }
  });
}

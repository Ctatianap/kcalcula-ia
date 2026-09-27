import 'package:nutrition_core/nutrition_core.dart';
import 'package:test/test.dart';

void main() {
  group('AC5: confianza por ítem', () {
    test('"150 g de pechuga" -> Buena estimación', () {
      final level = itemConfidence(
        basis: QuantityBasis.explicitWeight,
        isVague: false,
        usedCuratedEstimatePortion: false,
        usedDensityFallback: false,
      );
      expect(level, ConfidenceLevel.buenaEstimacion);
    });

    test(
      '"2 huevos" (unit_portion con fuente, no curada) -> Buena estimación',
      () {
        final level = itemConfidence(
          basis: QuantityBasis.unitPortion,
          isVague: false,
          usedCuratedEstimatePortion: false,
          usedDensityFallback: false,
        );
        expect(level, ConfidenceLevel.buenaEstimacion);
      },
    );

    test('"arepa pequeña" -> Estimación', () {
      final level = itemConfidence(
        basis: QuantityBasis.sizeDescriptor,
        isVague: false,
        usedCuratedEstimatePortion: false,
        usedDensityFallback: false,
      );
      expect(level, ConfidenceLevel.estimacion);
    });

    test('"un poquito de queso" (porción por defecto) -> Estimación', () {
      final level = itemConfidence(
        basis: QuantityBasis.defaultPortion,
        isVague: true,
        usedCuratedEstimatePortion: true,
        usedDensityFallback: false,
      );
      expect(level, ConfidenceLevel.estimacion);
    });

    test('unit_portion sobre una porción curada baja a Estimación', () {
      final level = itemConfidence(
        basis: QuantityBasis.unitPortion,
        isVague: false,
        usedCuratedEstimatePortion: true,
        usedDensityFallback: false,
      );
      expect(level, ConfidenceLevel.estimacion);
    });

    test('explicit_weight en ml sin densidad baja a Estimación', () {
      final level = itemConfidence(
        basis: QuantityBasis.explicitWeight,
        isVague: false,
        usedCuratedEstimatePortion: false,
        usedDensityFallback: true,
      );
      expect(level, ConfidenceLevel.estimacion);
    });

    test('label con gramos/ml -> Alta precisión', () {
      final level = itemConfidence(
        basis: QuantityBasis.label,
        isVague: false,
        usedCuratedEstimatePortion: false,
        usedDensityFallback: false,
        hasLabelGramsOrMl: true,
      );
      expect(level, ConfidenceLevel.altaPrecision);
    });
  });
}

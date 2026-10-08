import 'models/confidence_level.dart';
import 'models/quantity_basis.dart';

/// Confianza por ítem, según la tabla de `docs/architecture.md`:
/// - Alta precisión: `label` con cantidad en g/ml.
/// - Buena estimación: `explicit_weight`, o `unit_portion` sin ser una
///   porción curada.
/// - Estimación: todo lo demás, `is_vague`, porciones curadas, ml sin
///   densidad conocida, o una cantidad sin equivalencia en el catálogo
///   (SPEC-043: se usó `fallbackResolution`).
ConfidenceLevel itemConfidence({
  required QuantityBasis basis,
  required bool isVague,
  required bool usedCuratedEstimatePortion,
  required bool usedDensityFallback,
  bool hasLabelGramsOrMl = false,

  /// SPEC-043 R2: la cantidad no se pudo convertir y se usó una porción
  /// típica de respaldo.
  bool withoutEquivalence = false,
}) {
  if (isVague ||
      usedDensityFallback ||
      usedCuratedEstimatePortion ||
      withoutEquivalence) {
    return ConfidenceLevel.estimacion;
  }
  switch (basis) {
    case QuantityBasis.label:
      return hasLabelGramsOrMl
          ? ConfidenceLevel.altaPrecision
          : ConfidenceLevel.estimacion;
    case QuantityBasis.explicitWeight:
    case QuantityBasis.unitPortion:
      return ConfidenceLevel.buenaEstimacion;
    case QuantityBasis.sizeDescriptor:
    case QuantityBasis.householdMeasure:
    case QuantityBasis.defaultPortion:
      return ConfidenceLevel.estimacion;
  }
}

/// Confianza por comida: el nivel más bajo entre los ítems que aportan
/// ≥ 15 % de las kcal de la comida. Si ninguno llega al 15 %, se usa el
/// nivel más bajo de todos.
ConfidenceLevel mealConfidence(
  List<({double energyKcal, ConfidenceLevel confidence})> items,
) {
  if (items.isEmpty) {
    throw ArgumentError.value(items, 'items', 'no puede estar vacío');
  }
  final totalKcal = items.fold<double>(0, (sum, item) => sum + item.energyKcal);
  final contributing = totalKcal > 0
      ? items.where((item) => item.energyKcal / totalKcal >= 0.15).toList()
      : <({double energyKcal, ConfidenceLevel confidence})>[];
  final pool = contributing.isNotEmpty ? contributing : items;
  return pool
      .map((item) => item.confidence)
      .reduce((a, b) => a.index < b.index ? a : b);
}

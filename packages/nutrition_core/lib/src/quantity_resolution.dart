import 'models/food_catalog_entry.dart';
import 'models/portion_option.dart';
import 'models/quantity_basis.dart';
import 'models/quantity_unit.dart';

/// Señal de cantidad de un ítem, tal como llega (ya tipada) desde
/// `parsed_meal.v1`: `quantity`/`unit`/`size` son mutuamente opcionales.
class QuantityInput {
  final double? quantity;
  final QuantityUnit? unit;
  final SizeDescriptor? size;
  final bool isVague;

  const QuantityInput({
    this.quantity,
    this.unit,
    this.size,
    required this.isVague,
  });
}

/// Resultado de resolver una [QuantityInput] contra un [FoodCatalogEntry].
///
/// `resolvable: false` significa que la base de cálculo detectada (por
/// ejemplo `unitPortion`) no tiene una fila de porción para ese alimento;
/// el ítem debe mostrarse como pendiente de edición manual, no lanzar una
/// excepción.
typedef QuantityResolution = ({
  double? grams,
  QuantityBasis basis,
  bool resolvable,
  bool usedDensityFallback,
  bool usedCuratedEstimatePortion,
});

QuantityResolution resolveGrams({
  required QuantityInput input,
  required FoodCatalogEntry food,
  Map<QuantityUnit, double> householdUnitMlByUnit = const {},
}) {
  final quantity = input.quantity;
  final unit = input.unit;

  if (quantity != null && unit == QuantityUnit.gramos) {
    return _resolved(grams: quantity, basis: QuantityBasis.explicitWeight);
  }

  if (quantity != null && unit == QuantityUnit.mililitros) {
    final density = food.densityGPerMl;
    return _resolved(
      grams: quantity * (density ?? 1.0),
      basis: QuantityBasis.explicitWeight,
      usedDensityFallback: density == null,
    );
  }

  if (quantity != null && unit == QuantityUnit.unidad) {
    final portion = food.portionFor('unidad');
    if (portion == null) {
      return _unresolvable(QuantityBasis.unitPortion);
    }
    return _fromPortion(
      multiplier: quantity,
      portion: portion,
      basis: QuantityBasis.unitPortion,
    );
  }

  if (input.size != null) {
    final portion = food.portionFor(input.size!.name);
    if (portion == null) {
      return _unresolvable(QuantityBasis.sizeDescriptor);
    }
    return _fromPortion(
      multiplier: quantity ?? 1,
      portion: portion,
      basis: QuantityBasis.sizeDescriptor,
    );
  }

  if (quantity != null && isHouseholdUnit(unit)) {
    final ml = householdUnitMlByUnit[unit];
    if (ml == null) {
      return _unresolvable(QuantityBasis.householdMeasure);
    }
    final density = food.densityGPerMl;
    return _resolved(
      grams: quantity * ml * (density ?? 1.0),
      basis: QuantityBasis.householdMeasure,
      usedDensityFallback: density == null,
    );
  }

  // Sin base explícita (o unidad "porcion" explícita): porción por defecto.
  final defaultPortion = food.portionFor('porcion');
  if (defaultPortion == null) {
    return _unresolvable(QuantityBasis.defaultPortion);
  }
  return _fromPortion(
    multiplier: quantity ?? 1,
    portion: defaultPortion,
    basis: QuantityBasis.defaultPortion,
  );
}

QuantityResolution _resolved({
  required double grams,
  required QuantityBasis basis,
  bool usedDensityFallback = false,
  bool usedCuratedEstimatePortion = false,
}) => (
  grams: grams,
  basis: basis,
  resolvable: true,
  usedDensityFallback: usedDensityFallback,
  usedCuratedEstimatePortion: usedCuratedEstimatePortion,
);

QuantityResolution _fromPortion({
  required double multiplier,
  required PortionOption portion,
  required QuantityBasis basis,
}) => _resolved(
  grams: multiplier * portion.grams,
  basis: basis,
  usedCuratedEstimatePortion: portion.isCuratedEstimate,
);

QuantityResolution _unresolvable(QuantityBasis basis) => (
  grams: null,
  basis: basis,
  resolvable: false,
  usedDensityFallback: false,
  usedCuratedEstimatePortion: false,
);

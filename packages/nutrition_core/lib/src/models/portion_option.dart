import 'quantity_unit.dart';

/// Fila de la tabla `portions` de `catalog.db` para un alimento: cuántos
/// gramos representa un descriptor de porción ("unidad", "pequeno", ...).
class PortionOption {
  final String descriptor;
  final double grams;
  final String sourceId;
  final String sourceRef;
  final bool isCuratedEstimate;

  const PortionOption({
    required this.descriptor,
    required this.grams,
    required this.sourceId,
    required this.sourceRef,
    required this.isCuratedEstimate,
  });
}

/// Fila de `household_units`: mililitros de una unidad doméstica de volumen.
class HouseholdUnitEntry {
  final QuantityUnit unit;
  final double ml;
  final String sourceRef;

  const HouseholdUnitEntry({
    required this.unit,
    required this.ml,
    required this.sourceRef,
  });
}

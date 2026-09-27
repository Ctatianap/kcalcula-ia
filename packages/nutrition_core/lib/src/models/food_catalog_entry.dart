import 'portion_option.dart';

/// Alimento del catálogo, con valores por 100 g de porción comestible.
/// `nutrition_core` no lee `catalog.db`: recibe esta entrada ya resuelta
/// desde `app/infra/catalog`.
class FoodCatalogEntry {
  final String id;
  final String nameEs;
  final String sourceId;
  final String sourceRef;
  final double energyKcal100g;
  final double proteinG100g;
  final double carbsG100g;
  final double fatG100g;

  /// Densidad para convertir mililitros a gramos. `null` si no se conoce
  /// (fuerza confianza Estimación cuando la cantidad viene en ml).
  final double? densityGPerMl;

  final List<PortionOption> portions;

  const FoodCatalogEntry({
    required this.id,
    required this.nameEs,
    required this.sourceId,
    required this.sourceRef,
    required this.energyKcal100g,
    required this.proteinG100g,
    required this.carbsG100g,
    required this.fatG100g,
    required this.portions,
    this.densityGPerMl,
  });

  PortionOption? portionFor(String descriptor) {
    for (final portion in portions) {
      if (portion.descriptor == descriptor) return portion;
    }
    return null;
  }
}

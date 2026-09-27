/// Fila cargada de `data/curated/sources.csv`.
class SourceRow {
  final String id;
  final String name;
  final String license;
  final String url;
  final String version;

  const SourceRow({
    required this.id,
    required this.name,
    required this.license,
    required this.url,
    required this.version,
  });
}

/// Fila cargada de `data/curated/foods.csv`. Valores por 100 g de porción
/// comestible.
class FoodRow {
  final String id;
  final String nameEs;
  final String category;
  final String sourceId;
  final String sourceRef;
  final double energyKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? fiberG;
  final double? sugarG;
  final double? sodiumMg;
  final double? densityGPerMl;
  final String licenseStatus;
  final bool atwaterReview;

  const FoodRow({
    required this.id,
    required this.nameEs,
    required this.category,
    required this.sourceId,
    required this.sourceRef,
    required this.energyKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.licenseStatus,
    required this.atwaterReview,
    this.fiberG,
    this.sugarG,
    this.sodiumMg,
    this.densityGPerMl,
  });
}

/// Fila cargada de `data/curated/food_synonyms.csv`.
class SynonymRow {
  final String foodId;
  final String term;

  const SynonymRow({required this.foodId, required this.term});
}

/// Fila cargada de `data/curated/portions.csv`.
class PortionRow {
  final String foodId;
  final String descriptor;
  final double grams;
  final String sourceId;
  final String sourceRef;
  final bool isCuratedEstimate;

  const PortionRow({
    required this.foodId,
    required this.descriptor,
    required this.grams,
    required this.sourceId,
    required this.sourceRef,
    required this.isCuratedEstimate,
  });
}

/// Fila cargada de `data/curated/household_units.csv`.
class HouseholdUnitRow {
  final String unit;
  final double ml;
  final String sourceRef;

  const HouseholdUnitRow({
    required this.unit,
    required this.ml,
    required this.sourceRef,
  });
}

/// Todo lo que el build necesita, ya cargado desde `data/curated/*.csv`.
class CuratedData {
  final List<SourceRow> sources;
  final List<FoodRow> foods;
  final List<SynonymRow> synonyms;
  final List<PortionRow> portions;
  final List<HouseholdUnitRow> householdUnits;

  const CuratedData({
    required this.sources,
    required this.foods,
    required this.synonyms,
    required this.portions,
    required this.householdUnits,
  });
}

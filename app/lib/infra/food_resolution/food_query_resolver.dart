import 'package:nutrition_core/nutrition_core.dart';

import '../catalog/catalog_repository.dart';
import '../catalog/food_match_result.dart';
import '../storage/app_database.dart' show PersonalProduct;

/// SPEC-004 R7 (decisión del usuario: búsqueda integrada, no una lista
/// separada): `source_id` que marca un [FoodCatalogEntry] construido a
/// partir de un producto personal, nunca de `catalog.db`.
const personalProductSourceId = 'user_confirmed_label';

/// Prefijo del `id` de un producto personal dentro de un [FoodCatalogEntry],
/// para no colisionar con los ids del catálogo (que son slugs sin ":").
const personalProductIdPrefix = 'personal:';

bool isPersonalProductFood(FoodCatalogEntry food) =>
    food.sourceId == personalProductSourceId;

/// `null` si `id` no tiene el prefijo de producto personal.
int? personalProductIdFrom(String id) {
  if (!id.startsWith(personalProductIdPrefix)) return null;
  return int.tryParse(id.substring(personalProductIdPrefix.length));
}

FoodCatalogEntry personalProductToFoodCatalogEntry(PersonalProduct product) =>
    FoodCatalogEntry(
      id: '$personalProductIdPrefix${product.id}',
      nameEs: product.nameEs,
      sourceId: personalProductSourceId,
      sourceRef: product.sourceRef,
      energyKcal100g: product.energyKcal100,
      proteinG100g: product.proteinG100,
      carbsG100g: product.carbsG100,
      fatG100g: product.fatG100,
      densityGPerMl: product.densityGPerMl,
      portions: [
        PortionOption(
          descriptor: 'porcion',
          grams: product.servingGrams,
          sourceId: personalProductSourceId,
          sourceRef: product.sourceRef,
          isCuratedEstimate: false,
        ),
      ],
    );

String _normalize(String text) {
  const withAccents = 'áéíóúÁÉÍÓÚñÑ';
  const withoutAccents = 'aeiouAEIOUnN';
  var result = text.trim().toLowerCase();
  for (var i = 0; i < withAccents.length; i++) {
    result = result.replaceAll(withAccents[i], withoutAccents[i].toLowerCase());
  }
  return result;
}

/// Combina `catalog.db` (vía [CatalogRepository]) con los productos
/// personales del usuario bajo las mismas reglas `matched`/`ambiguous`/
/// `not_found` que ya existían solo para el catálogo (R8 de
/// `docs/architecture.md`). Los productos personales llegan ya resueltos en
/// memoria ([personalProducts], una lista pequeña) para que todo este
/// resolver sea síncrono, igual que [CatalogRepository.resolve] — quien lo
/// construye es responsable de recargar la lista si cambió (por ejemplo,
/// tras guardar un producto nuevo).
class FoodQueryResolver {
  final CatalogRepository _catalog;
  final List<PersonalProduct> _personalProducts;

  const FoodQueryResolver({
    required CatalogRepository catalog,
    required List<PersonalProduct> personalProducts,
  })
    // ignore: prefer_initializing_formals
    : _catalog = catalog,
       // ignore: prefer_initializing_formals
       _personalProducts = personalProducts;

  String get catalogVersion => _catalog.catalogVersion;

  Map<QuantityUnit, double> householdUnitMlByUnit() =>
      _catalog.householdUnitMlByUnit();

  List<FoodCatalogEntry> _matchingPersonalProducts(String foodQuery) {
    final normalized = _normalize(foodQuery);
    if (normalized.isEmpty) return const [];
    return _personalProducts
        .where((p) => _normalize(p.nameEs).contains(normalized))
        .map(personalProductToFoodCatalogEntry)
        .toList();
  }

  FoodMatchResult resolve(String foodQuery) {
    final catalogResult = _catalog.resolve(foodQuery);
    final personalMatches = _matchingPersonalProducts(foodQuery);

    if (catalogResult is FoodMatched) {
      if (personalMatches.isEmpty) return catalogResult;
      // Coincide exacto en el catálogo Y por nombre con algún producto
      // personal: no se elige por el usuario en silencio, se desambigua.
      return FoodAmbiguous(
        [
          FoodCandidate(
            id: catalogResult.food.id,
            nameEs: catalogResult.food.nameEs,
          ),
          ...personalMatches.map(
            (f) => FoodCandidate(id: f.id, nameEs: f.nameEs),
          ),
        ].take(3).toList(),
      );
    }

    final catalogCandidates = catalogResult is FoodAmbiguous
        ? catalogResult.candidates
        : const <FoodCandidate>[];
    final personalCandidates = personalMatches
        .map((f) => FoodCandidate(id: f.id, nameEs: f.nameEs))
        .toList();
    final combined = [...catalogCandidates, ...personalCandidates];

    if (combined.isEmpty) return FoodNotFound();
    if (combined.length == 1) {
      final food = getFoodById(combined.first.id);
      return food != null ? FoodMatched(food) : FoodNotFound();
    }
    return FoodAmbiguous(combined.take(3).toList());
  }

  FoodCatalogEntry? getFoodById(String id) {
    final personalId = personalProductIdFrom(id);
    if (personalId == null) return _catalog.getFoodById(id);
    final product = _personalProducts.where((p) => p.id == personalId).toList();
    if (product.isEmpty) return null;
    return personalProductToFoodCatalogEntry(product.first);
  }
}

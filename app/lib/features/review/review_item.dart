import 'package:nutrition_core/nutrition_core.dart';

import '../../infra/catalog/food_match_result.dart';
import '../../infra/storage/storage_repository.dart' show MealItem;

enum ReviewItemStatus { matched, ambiguous, notFound }

/// Una fila de la pantalla de revisión: el ítem de `parsed_meal.v1` más el
/// resultado de resolverlo contra el catálogo y `nutrition_core`.
class ReviewItem {
  final String mention;
  final String foodQuery;
  final bool isVague;
  final int? parentIndex;
  final double? quantityRaw;
  final String? unitRaw;
  final String? sizeRaw;

  final ReviewItemStatus status;
  final List<FoodCandidate> candidates;
  final FoodCatalogEntry? food;
  final double grams;
  final QuantityBasis? basis;
  final ConfidenceLevel? confidence;
  final NutrientTotals? nutrients;

  /// R10: porción por defecto destacada para edición (p. ej. "un poquito
  /// de queso"), o una cantidad que no se pudo resolver del todo.
  final bool highlightForEdit;

  /// SPEC-033 R5: un producto personal se muestra en porciones salvo que la
  /// persona pida verlo en g/ml.
  final bool showInGrams;

  /// SPEC-026 R2/AC4: el ítem tal como se guardó, mientras la persona no lo
  /// cambie: al guardar se conserva su instantánea (nombre y valores),
  /// aunque el catálogo o el producto hayan cambiado. `null` si es nuevo o
  /// se editó.
  final MealItem? savedSnapshot;

  const ReviewItem({
    required this.mention,
    required this.foodQuery,
    required this.isVague,
    required this.status,
    required this.grams,
    this.parentIndex,
    this.quantityRaw,
    this.unitRaw,
    this.sizeRaw,
    this.candidates = const [],
    this.food,
    this.basis,
    this.confidence,
    this.nutrients,
    this.highlightForEdit = false,
    this.showInGrams = false,
    this.savedSnapshot,
  });

  ReviewItem copyWith({
    ReviewItemStatus? status,
    List<FoodCandidate>? candidates,
    FoodCatalogEntry? food,
    double? grams,
    QuantityBasis? basis,
    ConfidenceLevel? confidence,
    NutrientTotals? nutrients,
    bool? highlightForEdit,
    bool? showInGrams,

    /// SPEC-026: editar la cantidad descarta la instantánea guardada.
    bool keepSnapshot = true,

    /// SPEC-023: la persona escribió la cantidad exacta; deja de ser vaga y
    /// se guarda tal como la escribió.
    ({double quantity, String unit})? writtenQuantity,
  }) => ReviewItem(
    mention: mention,
    foodQuery: foodQuery,
    isVague: writtenQuantity == null && isVague,
    parentIndex: parentIndex,
    quantityRaw: writtenQuantity?.quantity ?? quantityRaw,
    unitRaw: writtenQuantity?.unit ?? unitRaw,
    sizeRaw: writtenQuantity == null ? sizeRaw : null,
    status: status ?? this.status,
    candidates: candidates ?? this.candidates,
    food: food ?? this.food,
    grams: grams ?? this.grams,
    basis: basis ?? this.basis,
    confidence: confidence ?? this.confidence,
    nutrients: nutrients ?? this.nutrients,
    highlightForEdit: highlightForEdit ?? this.highlightForEdit,
    showInGrams: showInGrams ?? this.showInGrams,
    savedSnapshot: keepSnapshot ? savedSnapshot : null,
  );
}

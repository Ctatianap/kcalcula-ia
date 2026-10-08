import 'package:nutrition_core/nutrition_core.dart';

import '../../infra/catalog/food_match_result.dart';

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
  }) => ReviewItem(
    mention: mention,
    foodQuery: foodQuery,
    isVague: isVague,
    parentIndex: parentIndex,
    quantityRaw: quantityRaw,
    unitRaw: unitRaw,
    sizeRaw: sizeRaw,
    status: status ?? this.status,
    candidates: candidates ?? this.candidates,
    food: food ?? this.food,
    grams: grams ?? this.grams,
    basis: basis ?? this.basis,
    confidence: confidence ?? this.confidence,
    nutrients: nutrients ?? this.nutrients,
    highlightForEdit: highlightForEdit ?? this.highlightForEdit,
    showInGrams: showInGrams ?? this.showInGrams,
  );
}

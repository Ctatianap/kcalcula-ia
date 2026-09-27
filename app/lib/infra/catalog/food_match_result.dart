import 'package:nutrition_core/nutrition_core.dart';

/// Resultado de resolver el `food_query` de un ítem contra el catálogo
/// (R8): `matched` (coincidencia clara), `ambiguous` (hasta 3 candidatos) o
/// `not_found`. Nunca se inventan valores.
sealed class FoodMatchResult {}

class FoodMatched extends FoodMatchResult {
  final FoodCatalogEntry food;

  FoodMatched(this.food);
}

class FoodAmbiguous extends FoodMatchResult {
  final List<FoodCandidate> candidates;

  FoodAmbiguous(this.candidates);
}

class FoodNotFound extends FoodMatchResult {}

class FoodCandidate {
  final String id;
  final String nameEs;

  const FoodCandidate({required this.id, required this.nameEs});
}

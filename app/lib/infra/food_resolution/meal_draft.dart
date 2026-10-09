import 'package:nutrition_core/nutrition_core.dart';

/// SPEC-017/SPEC-018: una comida con sus alimentos ya resueltos (sin IA),
/// lista para abrir el "Detalle de comida". Vive en `infra/` porque la
/// arman "¿Qué comiste?" (Recientes) y la búsqueda manual, y la abre el
/// detalle: las features no se importan entre sí.
class MealDraft {
  final List<MealDraftItem> items;

  const MealDraft(this.items);
}

class MealDraftItem {
  /// Id del catálogo o de producto personal (`personal:<id>`).
  final String foodId;
  final String mention;
  final double grams;

  /// Cómo se obtuvo la cantidad y la confianza que le dieron las reglas al
  /// registrarla (SPEC-017: repetir una comida no la vuelve más precisa).
  final QuantityBasis basis;
  final ConfidenceLevel confidence;

  /// Cantidad tal como se expresó ("2" "unidad"), para guardarla igual que
  /// la original; sin ella se guardan los gramos.
  final double? quantityInput;
  final String? unitInput;
  final String? sizeInput;

  const MealDraftItem({
    required this.foodId,
    required this.mention,
    required this.grams,
    required this.basis,
    required this.confidence,
    this.quantityInput,
    this.unitInput,
    this.sizeInput,
  });
}

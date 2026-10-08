/// SPEC-033 R2/R7: lo que devuelve la ruta [AppRoutes.ingredientLabel] al
/// Detalle de comida cuando la persona confirma la etiqueta de un
/// ingrediente. Vive en `infra/` porque lo comparten `capture` (lo crea) y
/// `review` (lo usa), y las features no se importan entre sí.
typedef IngredientLabelResult = ({
  /// Id del producto personal recién guardado en `user.db`.
  int productId,

  /// Cantidad elegida en "Confirmar etiqueta" (SPEC-032), en [unit].
  double quantity,

  /// "g" o "ml".
  String unit,
});

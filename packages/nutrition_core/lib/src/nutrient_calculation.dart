import 'models/food_catalog_entry.dart';

/// Totales de nutrientes sin redondear. Solo se redondea al presentar
/// (`presentKcal`/`presentMacro`).
typedef NutrientTotals = ({
  double energyKcal,
  double proteinG,
  double carbsG,
  double fatG,
});

const zeroNutrientTotals = (
  energyKcal: 0.0,
  proteinG: 0.0,
  carbsG: 0.0,
  fatG: 0.0,
);

NutrientTotals calculateItemNutrients(FoodCatalogEntry food, double grams) {
  final factor = grams / 100;
  return (
    energyKcal: food.energyKcal100g * factor,
    proteinG: food.proteinG100g * factor,
    carbsG: food.carbsG100g * factor,
    fatG: food.fatG100g * factor,
  );
}

/// Suma los totales de varios ítems sin redondear ninguno antes de sumar.
NutrientTotals sumNutrients(Iterable<NutrientTotals> items) {
  var kcal = 0.0, protein = 0.0, carbs = 0.0, fat = 0.0;
  for (final item in items) {
    kcal += item.energyKcal;
    protein += item.proteinG;
    carbs += item.carbsG;
    fat += item.fatG;
  }
  return (energyKcal: kcal, proteinG: protein, carbsG: carbs, fatG: fat);
}

import 'package:nutrition_core/nutrition_core.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  test('AC4: 165 kcal/100g y 150 g -> 247.5 kcal internas, se muestra 248', () {
    final food = buildFood(
      energyKcal100g: 165,
      proteinG100g: 31,
      carbsG100g: 0,
      fatG100g: 3.6,
    );
    final totals = calculateItemNutrients(food, 150);
    expect(totals.energyKcal, closeTo(247.5, 1e-9));
    expect(presentKcal(totals.energyKcal), 248);
  });

  test('la suma de la comida se hace sobre valores sin redondear', () {
    // Dos ítems cuyas kcal individuales redondean a .5 hacia arriba, pero
    // cuya suma real (247.5 + 100.5 = 348.0) no debe calcularse a partir de
    // los enteros ya redondeados (248 + 101 = 349).
    final chicken = buildFood(energyKcal100g: 165);
    final rice = buildFood(energyKcal100g: 67);

    final chickenTotals = calculateItemNutrients(chicken, 150); // 247.5
    final riceTotals = calculateItemNutrients(rice, 150); // 100.5

    final mealTotals = sumNutrients([chickenTotals, riceTotals]);
    expect(mealTotals.energyKcal, closeTo(348.0, 1e-9));
    expect(presentKcal(mealTotals.energyKcal), 348);
  });

  test('presentMacro redondea a 1 decimal, half-up', () {
    expect(presentMacro(1.25), 1.3);
    expect(presentMacro(1.24), 1.2);
  });

  test('AC5 SPEC-004: producto de etiqueta "30 g = 140 kcal", comí 45 g -> 210 kcal, Alta precisión', () {
    // La etiqueta declara 140 kcal por una porción de 30 g; nutrition_core
    // guarda el producto personal en su forma normalizada por 100 g.
    final product = buildFood(
      energyKcal100g: 140 / 30 * 100, // 466.666...
      proteinG100g: 0,
      carbsG100g: 0,
      fatG100g: 140 / 9 / 30 * 100, // solo grasa, para que Atwater calce
      portions: [buildPortion(descriptor: 'porcion', grams: 30)],
    );

    final resolution = resolveGrams(
      input: const QuantityInput(
        quantity: 45,
        unit: QuantityUnit.gramos,
        isVague: false,
      ),
      food: product,
      isLabelProduct: true,
    );
    expect(resolution.basis, QuantityBasis.label);
    expect(resolution.grams, 45);

    final totals = calculateItemNutrients(product, resolution.grams!);
    expect(totals.energyKcal, closeTo(210, 1e-9));
    expect(presentKcal(totals.energyKcal), 210);

    final confidence = itemConfidence(
      basis: resolution.basis,
      isVague: false,
      usedCuratedEstimatePortion: resolution.usedCuratedEstimatePortion,
      usedDensityFallback: resolution.usedDensityFallback,
      hasLabelGramsOrMl: true,
    );
    expect(confidence, ConfidenceLevel.altaPrecision);
  });
}

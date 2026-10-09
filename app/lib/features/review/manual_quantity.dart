import 'package:nutrition_core/nutrition_core.dart';

import '../../infra/food_resolution/food_query_resolver.dart';
import '../../infra/food_resolution/meal_draft.dart';
import 'quantity_mapping.dart' show confidenceOfResolution;

/// SPEC-018 R2: una forma de elegir la cantidad de un alimento buscado a
/// mano. Todas pasan por `resolveGrams` de `nutrition_core` (las mismas
/// reglas que el texto) y la confianza sale de `itemConfidence`.
class QuantityOption {
  final String key;
  final String label;

  /// Gramos de 1 unidad de esta opción, para mostrarlos; `null` en gramos.
  final double? gramsPerUnit;
  final double defaultAmount;
  final QuantityInput Function(double amount) input;

  /// Cómo se guarda la cantidad dicha (mismo vocabulario que
  /// `parsed_meal.v1`: "g", "unidad", "cucharada"… o un tamaño).
  final String? unitInput;
  final String? sizeInput;

  const QuantityOption({
    required this.key,
    required this.label,
    required this.gramsPerUnit,
    required this.defaultAmount,
    required this.input,
    this.unitInput,
    this.sizeInput,
  });
}

const _sizeLabels = {
  SizeDescriptor.pequeno: 'Tamaño pequeño',
  SizeDescriptor.mediano: 'Tamaño mediano',
  SizeDescriptor.grande: 'Tamaño grande',
};

const _householdLabels = {
  QuantityUnit.cucharadita: 'Cucharadita',
  QuantityUnit.cucharada: 'Cucharada',
  QuantityUnit.taza: 'Taza',
  QuantityUnit.vaso: 'Vaso',
};

QuantityResolution _resolve(
  FoodCatalogEntry food,
  QuantityInput input,
  Map<QuantityUnit, double> householdUnitMlByUnit,
) => resolveGrams(
  input: input,
  food: food,
  householdUnitMlByUnit: householdUnitMlByUnit,
  isLabelProduct: isPersonalProductFood(food),
);

/// Gramos y su porción del catálogo; las medidas caseras solo si el
/// alimento tiene densidad o una porción con ese nombre (no ofrecer "taza"
/// para un huevo). Porciones como "tajada" o "lata" no tienen regla de
/// cantidad en `nutrition_core`: para esas, gramos.
List<QuantityOption> quantityOptionsFor(
  FoodCatalogEntry food,
  Map<QuantityUnit, double> householdUnitMlByUnit,
) {
  double? gramsOf(QuantityInput input) {
    final r = _resolve(food, input, householdUnitMlByUnit);
    return r.resolvable ? r.grams : null;
  }

  final options = <QuantityOption>[];
  void add(
    String key,
    String label,
    QuantityInput Function(double) input, {
    String? unitInput,
    String? sizeInput,
  }) {
    final perUnit = gramsOf(input(1));
    if (perUnit == null) return;
    options.add(
      QuantityOption(
        key: key,
        label: label,
        gramsPerUnit: perUnit,
        defaultAmount: 1,
        input: input,
        unitInput: unitInput,
        sizeInput: sizeInput,
      ),
    );
  }

  if (food.portionFor('unidad') != null) {
    add(
      'unidad',
      'Unidad',
      (n) =>
          QuantityInput(quantity: n, unit: QuantityUnit.unidad, isVague: false),
      unitInput: 'unidad',
    );
  }
  for (final size in SizeDescriptor.values) {
    if (food.portionFor(size.name) != null) {
      add(
        size.name,
        _sizeLabels[size]!,
        (n) => QuantityInput(quantity: n, size: size, isVague: false),
        sizeInput: size.name,
      );
    }
  }
  if (food.portionFor('porcion') != null) {
    add(
      'porcion',
      'Porción',
      (n) => QuantityInput(
        quantity: n,
        unit: QuantityUnit.porcion,
        isVague: false,
      ),
      unitInput: 'porcion',
    );
  }
  for (final MapEntry(key: unit, value: label) in _householdLabels.entries) {
    if (!householdUnitMlByUnit.containsKey(unit)) continue;
    if (food.densityGPerMl == null && food.portionFor(unit.name) == null) {
      continue;
    }
    add(
      unit.name,
      label,
      (n) => QuantityInput(quantity: n, unit: unit, isVague: false),
      unitInput: unit.name,
    );
  }
  options.add(
    QuantityOption(
      key: 'gramos',
      label: 'Gramos',
      gramsPerUnit: null,
      defaultAmount: 100,
      input: (n) =>
          QuantityInput(quantity: n, unit: QuantityUnit.gramos, isVague: false),
      unitInput: 'g',
    ),
  );
  return options;
}

/// R2: el ítem listo para el detalle, o `null` si la cantidad no sirve.
MealDraftItem? manualDraftItem(
  FoodCatalogEntry food,
  QuantityOption option,
  double amount,
  Map<QuantityUnit, double> householdUnitMlByUnit,
) {
  if (amount <= 0) return null;
  final resolution = _resolve(
    food,
    option.input(amount),
    householdUnitMlByUnit,
  );
  final grams = resolution.grams;
  if (!resolution.resolvable || grams == null || grams <= 0) return null;
  return MealDraftItem(
    foodId: food.id,
    mention: food.nameEs,
    grams: grams,
    basis: resolution.basis,
    confidence: confidenceOfResolution(resolution, isVague: false),
    quantityInput: amount,
    unitInput: option.unitInput,
    sizeInput: option.sizeInput,
  );
}

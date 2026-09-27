/// Unidad explícita con la que el usuario expresó una cantidad, tal como
/// llega en `parsed_meal.v1.items[].unit`.
enum QuantityUnit {
  gramos,
  mililitros,
  unidad,
  cucharada,
  cucharadita,
  taza,
  vaso,
  porcion,
}

/// Descriptor de tamaño, tal como llega en `parsed_meal.v1.items[].size`.
enum SizeDescriptor { pequeno, mediano, grande }

const _householdUnits = {
  QuantityUnit.cucharada,
  QuantityUnit.cucharadita,
  QuantityUnit.taza,
  QuantityUnit.vaso,
};

bool isHouseholdUnit(QuantityUnit? unit) =>
    unit != null && _householdUnits.contains(unit);

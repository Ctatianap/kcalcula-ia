/// Cómo se obtuvieron los gramos de un ítem, en el orden de preferencia de
/// `docs/architecture.md`.
enum QuantityBasis {
  explicitWeight,
  label,
  unitPortion,
  sizeDescriptor,
  householdMeasure,
  defaultPortion,
}

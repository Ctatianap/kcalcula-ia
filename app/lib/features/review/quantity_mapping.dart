import 'package:nutrition_core/nutrition_core.dart';

/// Traduce los strings de `parsed_meal.v1` a los enums tipados de
/// `nutrition_core`. Vive en `features/review` porque es el único lugar
/// donde se cruzan ambos vocabularios.
QuantityUnit? mapUnit(String? raw) => switch (raw) {
  'g' => QuantityUnit.gramos,
  'ml' => QuantityUnit.mililitros,
  'unidad' => QuantityUnit.unidad,
  'cucharada' => QuantityUnit.cucharada,
  'cucharadita' => QuantityUnit.cucharadita,
  'taza' => QuantityUnit.taza,
  'vaso' => QuantityUnit.vaso,
  'porcion' => QuantityUnit.porcion,
  _ => null,
};

SizeDescriptor? mapSize(String? raw) => switch (raw) {
  'pequeno' => SizeDescriptor.pequeno,
  'mediano' => SizeDescriptor.mediano,
  'grande' => SizeDescriptor.grande,
  _ => null,
};

/// T-042: la confianza de una cantidad resuelta, con la regla de
/// `nutrition_core` (invariante 4). Un producto personal en g/ml es
/// "etiqueta con cantidad en g/ml".
ConfidenceLevel confidenceOfResolution(
  QuantityResolution resolution, {
  required bool isVague,
}) => itemConfidence(
  basis: resolution.basis,
  isVague: isVague,
  usedCuratedEstimatePortion: resolution.usedCuratedEstimatePortion,
  usedDensityFallback: resolution.usedDensityFallback,
  hasLabelGramsOrMl: resolution.basis == QuantityBasis.label,
);

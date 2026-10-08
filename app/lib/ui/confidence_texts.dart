/// SPEC-023 R3: por qué un ingrediente tiene su nivel de confianza y qué
/// puede hacer la persona para mejorarlo. Describe la regla de
/// `nutrition_core` (`itemConfidence`, `docs/architecture.md`, sección
/// Confianza); no calcula nada ni inventa cifras.
library;

import 'package:nutrition_core/nutrition_core.dart';

/// La razón que explica el nivel de un ingrediente.
enum ConfidenceReason {
  label,
  explicitWeight,
  unitPortion,
  sizeDescriptor,
  householdMeasure,
  defaultPortion,
  vague,
  curatedPortion,
  densityFallback,

  /// SPEC-043: la cantidad no tiene equivalencia en el catálogo.
  withoutEquivalence,
}

/// Lo que la persona puede hacer para mejorar la cifra.
enum ConfidenceAction { writeGrams, useLabel }

const writeGramsAction = 'Escribe los gramos';
const useLabelHelpAction = 'Usa la etiqueta';

typedef ConfidenceExplanation = ({
  String title,
  String body,
  List<ConfidenceAction> actions,
});

/// La razón a partir de cómo se obtuvo la cantidad ([basis]), si era vaga
/// y el nivel que le dio la regla. Un nivel "Estimación" con una base que
/// por sí sola daría más significa, según la regla, porción curada
/// (`unit_portion`) o ml sin densidad (peso o etiqueta).
ConfidenceReason confidenceReasonFor({
  required QuantityBasis? basis,
  required bool isVague,
  required ConfidenceLevel level,

  /// SPEC-043: se usó el respaldo de `fallbackResolution`.
  bool withoutEquivalence = false,
}) {
  if (withoutEquivalence) return ConfidenceReason.withoutEquivalence;
  if (isVague) return ConfidenceReason.vague;
  final estimated = level == ConfidenceLevel.estimacion;
  return switch (basis) {
    QuantityBasis.label when estimated => ConfidenceReason.densityFallback,
    QuantityBasis.label => ConfidenceReason.label,
    QuantityBasis.explicitWeight when estimated =>
      ConfidenceReason.densityFallback,
    QuantityBasis.explicitWeight => ConfidenceReason.explicitWeight,
    QuantityBasis.unitPortion when estimated => ConfidenceReason.curatedPortion,
    QuantityBasis.unitPortion => ConfidenceReason.unitPortion,
    QuantityBasis.sizeDescriptor => ConfidenceReason.sizeDescriptor,
    QuantityBasis.householdMeasure => ConfidenceReason.householdMeasure,
    QuantityBasis.defaultPortion || null => ConfidenceReason.defaultPortion,
  };
}

/// SPEC-043 R4: la palabra de cantidad que dijo la persona ("unidad",
/// "pequeño", "taza"…), para la explicación.
String saidQuantityWord({String? unit, String? size}) => switch (size ?? unit) {
  'pequeno' => 'pequeño',
  'mediano' => 'mediano',
  'grande' => 'grande',
  'cucharadita' => 'cucharadita',
  'cucharada' => 'cucharada',
  'taza' => 'taza',
  'vaso' => 'vaso',
  'unidad' => 'unidad',
  _ => 'esa cantidad',
};

/// SPEC-023 R3/AC4: explicación en español de cada razón. [said] es la
/// palabra de cantidad (SPEC-043), solo para [ConfidenceReason.withoutEquivalence].
ConfidenceExplanation confidenceExplanation(
  ConfidenceReason reason, {
  String said = 'esa cantidad',
}) => switch (reason) {
  ConfidenceReason.withoutEquivalence => (
    title: 'Sin equivalencia',
    body:
        'No tenemos cuánto pesa «$said» de este alimento, así que usamos '
        'una porción típica.',
    actions: const [ConfidenceAction.writeGrams, ConfidenceAction.useLabel],
  ),
  ConfidenceReason.label => (
    title: 'De tu etiqueta',
    body:
        'Los valores salen de la etiqueta que confirmaste y la cantidad '
        'está en gramos o mililitros.',
    actions: const <ConfidenceAction>[],
  ),
  ConfidenceReason.explicitWeight => (
    title: 'Peso dicho por ti',
    body:
        'Usamos los gramos que dijiste y los valores de la base de '
        'alimentos. Si es un producto empacado, su etiqueta es más '
        'precisa.',
    actions: const [ConfidenceAction.useLabel],
  ),
  ConfidenceReason.unitPortion => (
    title: 'Unidad típica',
    body:
        'Cada unidad se convierte a gramos con el peso típico que trae la '
        'base para este alimento.',
    actions: const [ConfidenceAction.writeGrams, ConfidenceAction.useLabel],
  ),
  ConfidenceReason.sizeDescriptor => (
    title: 'Tamaño estimado',
    body:
        'La porción viene de una medida típica (pequeño, mediano o '
        'grande), no de un peso.',
    actions: const [ConfidenceAction.writeGrams, ConfidenceAction.useLabel],
  ),
  ConfidenceReason.householdMeasure => (
    title: 'Medida casera',
    body:
        'La taza, el vaso o la cucharada se convierten a gramos con una '
        'medida típica (y, si no tenemos la densidad del alimento, como si '
        '1 ml pesara 1 g).',
    actions: const [ConfidenceAction.writeGrams, ConfidenceAction.useLabel],
  ),
  ConfidenceReason.defaultPortion => (
    title: 'Porción típica',
    body:
        'No dijiste cuánto, así que usamos una porción típica de este '
        'alimento.',
    actions: const [ConfidenceAction.writeGrams, ConfidenceAction.useLabel],
  ),
  ConfidenceReason.vague => (
    title: 'Cantidad aproximada',
    body:
        'La cantidad era aproximada (por ejemplo, «un poco»), así que '
        'usamos una porción típica.',
    actions: const [ConfidenceAction.writeGrams, ConfidenceAction.useLabel],
  ),
  ConfidenceReason.curatedPortion => (
    title: 'Porción aproximada',
    body:
        'El peso de esta unidad es una aproximación, no un dato de una '
        'tabla oficial.',
    actions: const [ConfidenceAction.writeGrams, ConfidenceAction.useLabel],
  ),
  ConfidenceReason.densityFallback => (
    title: 'Mililitros sin densidad',
    body:
        'Pasamos de mililitros a gramos como si 1 ml pesara 1 g, porque no '
        'tenemos la densidad de este alimento.',
    actions: const [ConfidenceAction.writeGrams, ConfidenceAction.useLabel],
  ),
};

/// SPEC-023 R3: la regla de la comida (invariante 4: la aplica
/// `mealConfidence`; aquí solo se explica).
const mealConfidenceRuleText =
    'El nivel de la comida es el más bajo entre los ingredientes que aportan '
    'al menos el 15 % de sus calorías. Toca el indicador de un ingrediente '
    'para ver cómo mejorarlo.';

/// SPEC-004: validación de los valores transcritos de una etiqueta antes de
/// que el usuario los confirme. Invariante 2 de `CLAUDE.md`: la IA solo
/// transcribe, `nutrition_core` valida (Atwater ±20 %, porción obligatoria).
///
/// Misma fórmula que `data/build_catalog/lib/validators.dart` — duplicada a
/// propósito (ver SPEC-004, Technical Constraints): `nutrition_core` no
/// depende de otros paquetes del repo.
typedef LabelAtwaterCheck = ({
  bool withinTolerance,
  double calculatedKcal,
  double declaredKcal,
});

LabelAtwaterCheck checkLabelAtwater({
  required double energyKcal,
  required double proteinG,
  required double carbsG,
  required double fatG,
}) {
  final calculatedKcal = 4 * proteinG + 4 * carbsG + 9 * fatG;
  final tolerance = energyKcal.abs() * 0.20;
  final withinTolerance = (calculatedKcal - energyKcal).abs() <= tolerance;
  return (
    withinTolerance: withinTolerance,
    calculatedKcal: calculatedKcal,
    declaredKcal: energyKcal,
  );
}

/// R3: porción obligatoria y positiva.
bool isValidServingGrams(double? servingGrams) =>
    servingGrams != null && servingGrams > 0;

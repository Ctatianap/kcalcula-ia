/// SPEC-008 (v2) R10: rangos de entrada plausibles para la meta diaria. Son una
/// validación de entrada, no una recomendación nutricional.
const goalKcalMin = 800.0;
const goalKcalMax = 6000.0;
const goalMacroMaxG = 1000.0;

/// SPEC-008 (v2) R10: por debajo de este valor la app advierte (no bloquea).
/// Decisión de producto: no hay un piso institucional (ver
/// `docs/research/2026-10-02-formula-gasto-energetico.md`, PV-13). El
/// mínimo de 800 coincide con la frontera de las dietas muy bajas en
/// calorías que requieren supervisión médica (NIH 1993, misma nota).
const lowGoalWarningKcal = 1200.0;

bool isValidGoalKcal(double kcal) => kcal >= goalKcalMin && kcal <= goalKcalMax;

bool isValidGoalMacro(double grams) => grams >= 0 && grams <= goalMacroMaxG;

bool isLowGoalKcal(double kcal) => kcal < lowGoalWarningKcal;

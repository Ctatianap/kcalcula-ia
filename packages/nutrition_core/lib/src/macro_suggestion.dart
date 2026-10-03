/// SPEC-008 R3: reparto de las kcal sugeridas en proteína, grasa y
/// carbohidratos (gramos, sin redondear).
///
/// Fuentes (ver `docs/research/2026-10-02-formula-gasto-energetico.md`):
/// - Resolución 3803 de 2016 (MinSalud, RIEN), Tabla 12: RDA de proteína
///   para adultos 1,11 g/kg/día; Tabla 1: proteína 14–20 %, grasa 20–35 %,
///   carbohidratos 50–65 % de la energía.
///   https://normograma.invima.gov.co/compilacion/docs/resolucion_minsaludps_3803_2016.htm
///   (consultado 2026-10-02).
/// - FAO Food and Nutrition Paper 77 (2003): 4 kcal/g de proteína y de
///   carbohidratos, 9 kcal/g de grasa.
///
/// Las fuentes solo dan rangos: el punto elegido (proteína por g/kg ajustada
/// al rango, grasa en la mitad de su rango, carbohidratos el resto) es una
/// **decisión de producto** de SPEC-008, no una recomendación.
library;

import 'dart:math' as math;

const proteinRdaGPerKg = 1.11;
const proteinMinEnergyShare = 0.14;
const proteinMaxEnergyShare = 0.20;
const fatEnergyShare = 0.275;
const kcalPerGramProtein = 4.0;
const kcalPerGramCarbs = 4.0;
const kcalPerGramFat = 9.0;

typedef MacroSuggestion = ({double proteinG, double carbsG, double fatG});

MacroSuggestion suggestMacros({
  required double energyKcal,
  required double weightKg,
}) {
  final proteinKcalByWeight = proteinRdaGPerKg * weightKg * kcalPerGramProtein;
  final proteinKcal = math.min(
    math.max(proteinKcalByWeight, proteinMinEnergyShare * energyKcal),
    proteinMaxEnergyShare * energyKcal,
  );
  final fatKcal = fatEnergyShare * energyKcal;
  final carbsKcal = energyKcal - proteinKcal - fatKcal;
  return (
    proteinG: proteinKcal / kcalPerGramProtein,
    carbsG: carbsKcal / kcalPerGramCarbs,
    fatG: fatKcal / kcalPerGramFat,
  );
}

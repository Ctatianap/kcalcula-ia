/// SPEC-008 (v2) R6/R7: objetivo y reparto de macros en % de las kcal.
///
/// Fuentes (ver `docs/research/2026-10-02-harris-benedict-actividad-objetivo.md`, PV-14):
/// - Déficit: 250–500 kcal/día para personas que entrenan (posición conjunta
///   Dietitians of Canada, Academy of Nutrition and Dietetics y ACSM, 2016,
///   https://www.dietitians.ca/DietitiansOfCanada/media/Documents/Resources/noap-position-paper.pdf);
///   500 kcal/día también en AHA/ACC/TOS 2013 (Jensen et al., Circulation
///   2014;129:S102-38).
/// - Superávit: 10–20 % sobre el mantenimiento (Iraki et al. 2019, Sports,
///   https://pmc.ncbi.nlm.nih.gov/articles/PMC6680710/).
/// - % de energía: dentro de los AMDR (proteína 10–35 %, grasa 20–35 %,
///   carbohidratos 45–65 %; NASEM 2024,
///   https://www.nationalacademies.org/read/27957/chapter/5) y con grasa
///   ≥ 20 % (posición conjunta 2016). **El punto dentro de esos rangos es una
///   decisión de producto** de SPEC-008, aprobada por la usuaria.
/// - Conversión: 4 kcal/g de proteína y de carbohidratos, 9 de grasa (FAO
///   Food and Nutrition Paper 77, 2003).
/// Consultados 2026-10-02.
library;

enum GoalObjective {
  loseFatGentle,
  loseFat,
  maintain,
  gainMuscleGentle,
  gainMuscle,
}

const kcalPerGramProtein = 4.0;
const kcalPerGramCarbs = 4.0;
const kcalPerGramFat = 9.0;

typedef MacroShares = ({double protein, double fat, double carbs});
typedef MacroGrams = ({double proteinG, double carbsG, double fatG});

/// R7: reparto por objetivo (fracciones de las kcal).
MacroShares macroSharesFor(GoalObjective objective) => switch (objective) {
  GoalObjective.loseFatGentle ||
  GoalObjective.loseFat => (protein: 0.30, fat: 0.25, carbs: 0.45),
  GoalObjective.maintain ||
  GoalObjective.gainMuscleGentle ||
  GoalObjective.gainMuscle => (protein: 0.20, fat: 0.25, carbs: 0.55),
};

/// R6: kcal del objetivo a partir del mantenimiento, sin redondear.
double objectiveKcal(double maintenanceKcal, GoalObjective objective) =>
    switch (objective) {
      GoalObjective.loseFatGentle => maintenanceKcal - 250,
      GoalObjective.loseFat => maintenanceKcal - 500,
      GoalObjective.maintain => maintenanceKcal,
      GoalObjective.gainMuscleGentle => maintenanceKcal * 1.10,
      GoalObjective.gainMuscle => maintenanceKcal * 1.20,
    };

/// R7/R10: gramos de cada macro para unas kcal y un objetivo.
MacroGrams macroGramsFor(double kcal, GoalObjective objective) {
  final shares = macroSharesFor(objective);
  return (
    proteinG: kcal * shares.protein / kcalPerGramProtein,
    carbsG: kcal * shares.carbs / kcalPerGramCarbs,
    fatG: kcal * shares.fat / kcalPerGramFat,
  );
}

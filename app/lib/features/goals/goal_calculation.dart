import 'package:nutrition_core/nutrition_core.dart';

// SPEC-015: el recálculo vive en infra para que Progreso (anotar peso) y
// Mi perfil lo compartan sin importarse entre features.
export '../../infra/storage/goal_sync.dart';

const disclaimerText =
    'Son estimaciones generales, no una recomendación médica. Si tienes una '
    'condición de salud, consulta a un profesional.';

/// SPEC-008 R2: textos de los niveles de actividad (incluye el NEAT).
const activityLevelTexts = {
  ActivityLevel.sedentary: (
    'Sin ejercicio',
    'Poco o nada de ejercicio, trabajo sentado.',
  ),
  ActivityLevel.lightlyActive: (
    'Actividad ligera',
    'Ejercicio 1–3 días por semana.',
  ),
  ActivityLevel.active: (
    'Actividad moderada',
    'Ejercicio 3–5 días por semana.',
  ),
  ActivityLevel.veryActive: (
    'Actividad intensa',
    'Ejercicio 6–7 días por semana.',
  ),
  ActivityLevel.extraActive: (
    'Actividad muy intensa',
    'Dos entrenamientos al día, o trabajo físico.',
  ),
};

/// SPEC-008 R6: textos de los objetivos.
const objectiveTexts = {
  GoalObjective.loseFatGentle: (
    'Bajar grasa (suave)',
    'Mantenimiento − 250 kcal',
  ),
  GoalObjective.loseFat: ('Bajar grasa', 'Mantenimiento − 500 kcal'),
  GoalObjective.maintain: ('Mantener', 'Tu mantenimiento'),
  GoalObjective.gainMuscleGentle: (
    'Subir masa muscular (suave)',
    'Mantenimiento + 10 %',
  ),
  GoalObjective.gainMuscle: ('Subir masa muscular', 'Mantenimiento + 20 %'),
};

/// "~2.276 kcal".
String approxKcal(double kcal) =>
    '~${formatThousandsEs(presentKcal(kcal))} kcal';

/// Gramos enteros para un resumen: "Proteína 114 g · Grasa 63 g · ...".
String macroSummary(MacroGrams m) =>
    'Proteína ${m.proteinG.round()} g · '
    'Grasa ${m.fatG.round()} g · '
    'Carbohidratos ${m.carbsG.round()} g';

/// Entero, con o sin separador de miles de es-CO ("1890" o "1.890").
double? parseKcal(String text) {
  final trimmed = text.trim();
  if (!RegExp(r'^(\d+|\d{1,3}(\.\d{3})+)$').hasMatch(trimmed)) return null;
  return int.parse(trimmed.replaceAll('.', '')).toDouble();
}

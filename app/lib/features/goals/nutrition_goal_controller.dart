import 'package:flutter/foundation.dart';
import 'package:nutrition_core/nutrition_core.dart';

import '../../infra/storage/storage_repository.dart';

const kcalRangeMessage = 'Escribe un número entero entre 800 y 6.000.';
const macroRangeMessage =
    'Escribe un número entre 0 y 1.000, con máximo un decimal.';
const lowGoalWarningMessage =
    'Esta meta es más baja de lo que se suele recomendar sin acompañamiento '
    'profesional.';

enum MacroField { protein, carbs, fat }

const estimationDisclaimer =
    'Es una estimación general, no una recomendación médica. Si tienes una '
    'condición de salud, consulta a un profesional.';
const ageUnavailableMessage =
    'La sugerencia está disponible desde los 19 años.';
const weightRangeMessage = 'Escribe tu peso en kg, entre 30 y 300.';
const heightRangeMessage = 'Escribe tu estatura en cm, entre 120 y 230.';
const ageRangeMessage = 'Escribe tu edad en años, hasta 100.';

/// SPEC-008 R14: niveles de actividad de la DRI 2023 (Tabla 7-1), en es-CO.
const activityLevelTexts = {
  ActivityLevel.inactive: (
    'Poco movimiento',
    'Solo las actividades del día a día.',
  ),
  ActivityLevel.lowActive: (
    'Algo activo',
    'El día a día y además unos 60–80 min de caminata (5–6 km/h).',
  ),
  ActivityLevel.active: (
    'Activo',
    'El día a día, 30–50 min de caminata y 45 min de bicicleta moderada, o '
        'equivalente.',
  ),
  ActivityLevel.veryActive: (
    'Muy activo',
    'El día a día, 45 min de bicicleta moderada y unos 25 min de trote, o '
        'equivalente.',
  ),
};
const activityLevelNote = 'Elige el que más se parezca a un día normal tuyo.';

/// SPEC-008 R1/R9/R13: edición de la meta diaria. Los rangos y el umbral de
/// advertencia viven en `nutrition_core`; aquí solo se interpreta el texto
/// que escribe el usuario.
class NutritionGoalController extends ChangeNotifier {
  final StorageRepository _storage;

  String kcalText = '';
  final Map<MacroField, String> macroText = {
    for (final f in MacroField.values) f: '',
  };
  bool hasEstimationInputs = false;

  // SPEC-008 R2: datos de la sugerencia (opcionales).
  String weightText = '';
  String heightText = '';
  String ageText = '';
  BiologicalSex? sex;
  ActivityLevel? activityLevel;

  /// Campos que hoy muestran el valor sugerido sin editar (llevan "~").
  final Set<Object> suggestedFields = {};

  /// Hay una sugerencia aplicada: al guardar se guardan también sus datos.
  bool suggestionApplied = false;
  bool loaded = false;
  bool busy = false;

  NutritionGoalController({required StorageRepository storage})
    // ignore: prefer_initializing_formals
    : _storage = storage;

  Future<void> load() async {
    final goal = await _storage.getNutritionGoal();
    if (goal != null) {
      kcalText = presentKcal(goal.energyKcal).toString();
      macroText[MacroField.protein] = _macroToText(goal.proteinG);
      macroText[MacroField.carbs] = _macroToText(goal.carbsG);
      macroText[MacroField.fat] = _macroToText(goal.fatG);
    }
    final inputs = await _storage.getGoalEstimationInputs();
    hasEstimationInputs = inputs != null;
    if (inputs != null) {
      weightText = _numberToText(inputs.weightKg);
      heightText = _numberToText(inputs.heightCm);
      ageText = inputs.ageYears.toString();
      sex = BiologicalSex.values.asNameMap()[inputs.sex];
      activityLevel = ActivityLevel.values.asNameMap()[inputs.activityLevel];
    }
    loaded = true;
    notifyListeners();
  }

  void setKcal(String text) {
    kcalText = text;
    suggestedFields.remove('kcal');
    notifyListeners();
  }

  void setMacro(MacroField field, String text) {
    macroText[field] = text;
    suggestedFields.remove(field);
    notifyListeners();
  }

  void setWeight(String text) {
    weightText = text;
    notifyListeners();
  }

  void setHeight(String text) {
    heightText = text;
    notifyListeners();
  }

  void setAge(String text) {
    ageText = text;
    notifyListeners();
  }

  void setSex(BiologicalSex value) {
    sex = value;
    notifyListeners();
  }

  void setActivityLevel(ActivityLevel value) {
    activityLevel = value;
    notifyListeners();
  }

  double? get _weight => parseGoalMacro(weightText);
  double? get _height => parseGoalMacro(heightText);
  int? get _age => int.tryParse(ageText.trim());

  String? get weightError {
    if (weightText.trim().isEmpty) return null;
    final w = _weight;
    return w == null || w < estimationWeightMinKg || w > estimationWeightMaxKg
        ? weightRangeMessage
        : null;
  }

  String? get heightError {
    if (heightText.trim().isEmpty) return null;
    final h = _height;
    return h == null || h < estimationHeightMinCm || h > estimationHeightMaxCm
        ? heightRangeMessage
        : null;
  }

  String? get ageError {
    if (ageText.trim().isEmpty) return null;
    final a = _age;
    if (a == null || a > estimationAgeMax) return ageRangeMessage;
    if (a < estimationAgeMin) return ageUnavailableMessage;
    return null;
  }

  /// Edge case de la SPEC: datos incompletos → "Calcular" deshabilitado.
  bool get canEstimate =>
      _weight != null &&
      _height != null &&
      _age != null &&
      sex != null &&
      activityLevel != null &&
      weightError == null &&
      heightError == null &&
      ageError == null;

  /// R2/R3/AC5: rellena los cuatro campos con la sugerencia; no guarda.
  void applySuggestion() {
    if (!canEstimate) return;
    final double kcal;
    try {
      kcal = estimateMaintenanceKcal(
        weightKg: _weight!,
        heightCm: _height!,
        ageYears: _age!,
        sex: sex!,
        activityLevel: activityLevel!,
      );
    } on InvalidEstimationInput {
      return;
    }
    final macros = suggestMacros(energyKcal: kcal, weightKg: _weight!);
    kcalText = presentKcal(kcal).toString();
    macroText[MacroField.protein] = _macroToText(macros.proteinG);
    macroText[MacroField.carbs] = _macroToText(macros.carbsG);
    macroText[MacroField.fat] = _macroToText(macros.fatG);
    suggestedFields
      ..clear()
      ..addAll(['kcal', ...MacroField.values]);
    suggestionApplied = true;
    notifyListeners();
  }

  double? get _kcal => parseGoalKcal(kcalText);

  /// R1/AC1: "Guardar" deshabilitado con kcal vacía.
  bool get canSave => kcalText.trim().isNotEmpty && !busy;

  String? get kcalError {
    if (kcalText.trim().isEmpty) return null;
    final kcal = _kcal;
    return kcal == null || !isValidGoalKcal(kcal) ? kcalRangeMessage : null;
  }

  /// R13/AC14: advierte pero no bloquea.
  String? get kcalWarning {
    final kcal = _kcal;
    if (kcal == null || !isValidGoalKcal(kcal)) return null;
    return isLowGoalKcal(kcal) ? lowGoalWarningMessage : null;
  }

  String? macroError(MacroField field) {
    final text = macroText[field]!.trim();
    if (text.isEmpty) return null;
    final grams = parseGoalMacro(text);
    return grams == null || !isValidGoalMacro(grams) ? macroRangeMessage : null;
  }

  bool get _hasErrors =>
      kcalError != null || MacroField.values.any((f) => macroError(f) != null);

  /// Devuelve `true` si guardó. Con errores no guarda (AC1).
  Future<bool> save() async {
    if (!canSave || _hasErrors) {
      notifyListeners();
      return false;
    }
    busy = true;
    notifyListeners();
    try {
      await _storage.saveNutritionGoal(
        energyKcal: _kcal!,
        proteinG: _macroValue(MacroField.protein),
        carbsG: _macroValue(MacroField.carbs),
        fatG: _macroValue(MacroField.fat),
      );
      // R8/R9: los datos de la sugerencia solo se guardan si se usó.
      if (suggestionApplied && canEstimate) {
        await _storage.saveGoalEstimationInputs(
          weightKg: _weight!,
          heightCm: _height!,
          ageYears: _age!,
          sex: sex!.name,
          activityLevel: activityLevel!.name,
        );
        hasEstimationInputs = true;
      }
      return true;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// R9/AC8: borra los datos de la sugerencia sin tocar la meta.
  Future<void> deleteEstimationInputs() async {
    await _storage.deleteGoalEstimationInputs();
    hasEstimationInputs = false;
    notifyListeners();
  }

  double? _macroValue(MacroField field) {
    final text = macroText[field]!.trim();
    return text.isEmpty ? null : parseGoalMacro(text);
  }

  String _macroToText(double? grams) =>
      grams == null ? '' : _numberToText(presentMacro(grams));

  /// "61,1" o "70" (sin ",0").
  String _numberToText(double value) {
    final text = formatMacroEs(value);
    return text.endsWith(',0') ? text.substring(0, text.length - 2) : text;
  }
}

/// Entero sin separadores ("2000"); `null` si no lo es.
double? parseGoalKcal(String text) {
  final value = int.tryParse(text.trim());
  return value?.toDouble();
}

/// Número con máximo un decimal, con coma o punto ("45,5"); `null` si no.
double? parseGoalMacro(String text) {
  final normalized = text.trim().replaceAll(',', '.');
  if (!RegExp(r'^\d+(\.\d)?$').hasMatch(normalized)) return null;
  return double.parse(normalized);
}

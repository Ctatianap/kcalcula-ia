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
    hasEstimationInputs = await _storage.getGoalEstimationInputs() != null;
    loaded = true;
    notifyListeners();
  }

  void setKcal(String text) {
    kcalText = text;
    notifyListeners();
  }

  void setMacro(MacroField field, String text) {
    macroText[field] = text;
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
      grams == null ? '' : formatMacroEs(grams).replaceAll(',0', '');
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

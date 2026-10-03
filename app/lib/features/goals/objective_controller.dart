import 'package:flutter/foundation.dart';
import 'package:nutrition_core/nutrition_core.dart';

import '../../infra/storage/storage_repository.dart';
import 'goal_calculation.dart';

const kcalRangeMessage = 'Escribe un número entero entre 800 y 6.000.';
const lowGoalWarningMessage =
    'Esta meta es más baja de lo que se suele recomendar sin acompañamiento '
    'profesional.';
const objectiveOutOfRangeMessage =
    'Con tu perfil, este objetivo queda fuera del rango que maneja la app '
    '(800 a 6.000 kcal). Puedes escribir tu meta a mano.';
const goalSaveErrorMessage = 'No pude guardar tu meta. Intenta de nuevo.';

/// SPEC-008 R6–R10: elegir objetivo (que se vuelve la meta diaria) o
/// escribir la meta a mano.
class ObjectiveController extends ChangeNotifier {
  final StorageRepository _storage;
  final DateTime Function() _now;

  bool loaded = false;
  bool busy = false;
  bool hasProfile = false;
  double? maintenance;
  NutritionGoal? currentGoal;
  GoalObjective selected = GoalObjective.maintain;
  String manualKcalText = '';

  /// Mensaje en español si guardar falló (sin el texto de la excepción, R12).
  String? errorMessage;

  ObjectiveController({
    required StorageRepository storage,
    DateTime Function()? now,
  })
    // ignore: prefer_initializing_formals
    : _storage = storage,
       _now = now ?? DateTime.now;

  Future<void> load() async {
    final profile = await _storage.getUserProfile();
    hasProfile = profile != null;
    maintenance = profile == null
        ? null
        : maintenanceForProfile(profile, _now());
    currentGoal = await _storage.getNutritionGoal();
    final saved = GoalObjective.values.asNameMap()[currentGoal?.objective];
    if (saved != null) selected = saved;
    loaded = true;
    notifyListeners();
  }

  void select(GoalObjective objective) {
    selected = objective;
    errorMessage = null;
    notifyListeners();
  }

  void setManualKcal(String text) {
    manualKcalText = text;
    errorMessage = null;
    notifyListeners();
  }

  /// R6: kcal que daría cada objetivo hoy, sin redondear.
  double? kcalFor(GoalObjective objective) {
    final m = maintenance;
    return m == null ? null : objectiveKcal(m, objective);
  }

  bool isInRange(GoalObjective objective) {
    final kcal = kcalFor(objective);
    return kcal != null && isValidGoalKcal(kcal);
  }

  /// R9: objetivo de la meta guardada si es manual, o `null`.
  GoalObjective? get manualGoalObjective {
    final goal = currentGoal;
    if (goal == null || !goal.isManual) return null;
    return GoalObjective.values.asNameMap()[goal.objective];
  }

  /// R9: lo que daría hoy el objetivo de la meta manual.
  double? get suggestedForManualGoal {
    final objective = manualGoalObjective;
    return objective == null ? null : kcalFor(objective);
  }

  /// R9: "Usar este valor": la meta vuelve a seguir al perfil.
  Future<bool> useSuggestedForManualGoal() async {
    final objective = manualGoalObjective;
    if (objective == null) return false;
    selected = objective;
    return useSelectedObjective();
  }

  double? get _manualKcal => parseGoalKcal(manualKcalText);

  String? get manualKcalError {
    if (manualKcalText.trim().isEmpty) return null;
    final kcal = _manualKcal;
    return kcal == null || !isValidGoalKcal(kcal) ? kcalRangeMessage : null;
  }

  /// R10/AC10: advierte pero no bloquea.
  String? get manualKcalWarning {
    final kcal = _manualKcal;
    if (kcal == null || !isValidGoalKcal(kcal)) return null;
    return isLowGoalKcal(kcal) ? lowGoalWarningMessage : null;
  }

  bool get canSaveManual =>
      manualKcalText.trim().isNotEmpty && manualKcalError == null && !busy;

  /// R8: el objetivo seleccionado se vuelve la meta diaria.
  Future<bool> useSelectedObjective() async {
    final kcal = kcalFor(selected);
    if (kcal == null || !isValidGoalKcal(kcal)) {
      errorMessage = objectiveOutOfRangeMessage;
      notifyListeners();
      return false;
    }
    return _save(
      goalValuesFor(kcal: kcal, objective: selected, isManual: false),
    );
  }

  /// R10: meta escrita a mano, con el reparto del objetivo seleccionado.
  Future<bool> saveManual() async {
    if (!canSaveManual) return false;
    return _save(
      goalValuesFor(kcal: _manualKcal!, objective: selected, isManual: true),
    );
  }

  Future<bool> _save(NutritionGoalValues goal) async {
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _storage.saveNutritionGoal(goal);
      currentGoal = await _storage.getNutritionGoal();
      return true;
    } catch (_) {
      errorMessage = goalSaveErrorMessage;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}

/// Entero, con o sin separador de miles de es-CO ("2000" o "2.000");
/// `null` si no lo es.
double? parseGoalKcal(String text) {
  final trimmed = text.trim();
  if (!RegExp(r'^(\d+|\d{1,3}(\.\d{3})+)$').hasMatch(trimmed)) return null;
  return int.parse(trimmed.replaceAll('.', '')).toDouble();
}

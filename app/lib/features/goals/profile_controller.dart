import 'package:flutter/foundation.dart';
import 'package:nutrition_core/nutrition_core.dart';

import '../../infra/storage/storage_repository.dart';
import 'goal_calculation.dart';

const birthDateFormatMessage = 'Escribe la fecha como dd/mm/aaaa.';
const ageRangeMessage = 'La app es para personas de 18 a 100 años.';
const weightRangeMessage = 'Escribe tu peso en kg, entre 30 y 300.';
const heightRangeMessage = 'Escribe tu estatura en cm, entre 120 y 230.';
const profileSaveErrorMessage = 'No pude guardar tu perfil. Intenta de nuevo.';
const profileLoadErrorMessage = 'No pude leer tu perfil. Intenta de nuevo.';
const goalNotRecalculatedMessage =
    'Guardé tu perfil, pero con estos datos tu objetivo quedaría fuera del '
    'rango que maneja la app (800 a 6.000 kcal), así que tu meta no cambió. '
    'Revisa "Mi objetivo".';

/// SPEC-008 R1–R5/R9: perfil editable y punto de partida en vivo.
class ProfileController extends ChangeNotifier {
  final StorageRepository _storage;
  final DateTime Function() _now;

  BiologicalSex? sex;
  String birthDateText = '';
  String heightText = '';
  String weightText = '';
  ActivityLevel? activityLevel;

  bool loaded = false;
  bool busy = false;
  bool hasSavedProfile = false;

  /// La lectura falló: no se deja guardar un formulario vacío encima de un
  /// perfil que existe pero no se pudo leer.
  bool loadFailed = false;

  /// Mensaje en español si guardar falló. Nunca el texto de la excepción:
  /// el de SQLite incluye los parámetros (datos de salud) y no debe llegar a
  /// Crashlytics (R12).
  String? errorMessage;

  /// R9/Edge Cases: se guardó el perfil pero la meta no se pudo recalcular.
  String? infoMessage;

  ProfileController({
    required StorageRepository storage,
    DateTime Function()? now,
  })
    // ignore: prefer_initializing_formals
    : _storage = storage,
       _now = now ?? DateTime.now;

  Future<void> load() async {
    final UserProfileData? profile;
    loadFailed = false;
    errorMessage = null;
    try {
      profile = await _storage.getUserProfile();
    } catch (_) {
      errorMessage = profileLoadErrorMessage;
      loadFailed = true;
      loaded = true;
      notifyListeners();
      return;
    }
    if (profile != null) {
      sex = BiologicalSex.values.asNameMap()[profile.sex];
      birthDateText = formatBirthDate(profile.birthDate);
      heightText = _numberToText(profile.heightCm);
      weightText = _numberToText(profile.weightKg);
      activityLevel = ActivityLevel.values.asNameMap()[profile.activityLevel];
      hasSavedProfile = true;
    }
    loaded = true;
    notifyListeners();
  }

  void _changed() {
    errorMessage = null;
    infoMessage = null;
    notifyListeners();
  }

  void setSex(BiologicalSex value) {
    sex = value;
    _changed();
  }

  void setBirthDate(String text) {
    birthDateText = text;
    _changed();
  }

  void setHeight(String text) {
    heightText = text;
    _changed();
  }

  void setWeight(String text) {
    weightText = text;
    _changed();
  }

  void setActivityLevel(ActivityLevel value) {
    activityLevel = value;
    _changed();
  }

  DateTime? get _birthDate => parseBirthDate(birthDateText);
  double? get _height => parseDecimal(heightText);
  double? get _weight => parseDecimal(weightText);
  int? get _age {
    final birth = _birthDate;
    return birth == null ? null : ageInYears(birth, _now());
  }

  /// R1: edad calculada a partir de la fecha de nacimiento.
  int? get age => birthDateError == null ? _age : null;

  String? get birthDateError {
    if (birthDateText.trim().isEmpty) return null;
    final age = _age;
    if (age == null) return birthDateFormatMessage;
    if (age < estimationAgeMin || age > estimationAgeMax) {
      return ageRangeMessage;
    }
    return null;
  }

  String? get heightError {
    if (heightText.trim().isEmpty) return null;
    final h = _height;
    return h == null || h < estimationHeightMinCm || h > estimationHeightMaxCm
        ? heightRangeMessage
        : null;
  }

  String? get weightError {
    if (weightText.trim().isEmpty) return null;
    final w = _weight;
    return w == null || w < estimationWeightMinKg || w > estimationWeightMaxKg
        ? weightRangeMessage
        : null;
  }

  bool get isComplete =>
      sex != null &&
      activityLevel != null &&
      _birthDate != null &&
      _height != null &&
      _weight != null &&
      birthDateError == null &&
      heightError == null &&
      weightError == null;

  /// R3: metabolismo basal con los datos del formulario, o `null`.
  double? get basalKcal {
    if (!isComplete) return null;
    try {
      return estimateBasalKcal(
        weightKg: _weight!,
        heightCm: _height!,
        ageYears: _age!,
        sex: sex!,
      );
    } on InvalidEstimationInput {
      return null;
    }
  }

  /// R4/R5: mantenimiento en vivo (calculado en `nutrition_core`); cambia
  /// al editar peso o actividad.
  double? get maintenanceKcal {
    if (!isComplete) return null;
    try {
      return estimateMaintenanceKcal(
        weightKg: _weight!,
        heightCm: _height!,
        ageYears: _age!,
        sex: sex!,
        activityLevel: activityLevel!,
      );
    } on InvalidEstimationInput {
      return null;
    }
  }

  bool get canSave => isComplete && !busy && !loadFailed;

  /// R1/R9: guarda el perfil y, si la meta viene de un objetivo, la
  /// recalcula en la misma transacción. Devuelve `true` si guardó.
  Future<bool> save() async {
    if (!canSave) return false;
    busy = true;
    errorMessage = null;
    infoMessage = null;
    notifyListeners();
    try {
      final goal = await _storage.getNutritionGoal();
      final recalculated = recalculatedGoal(goal, maintenanceKcal);
      await _storage.saveUserProfile(
        sex: sex!.name,
        birthDate: _birthDate!,
        heightCm: _height!,
        weightKg: _weight!,
        activityLevel: activityLevel!.name,
        recalculatedGoal: recalculated,
      );
      hasSavedProfile = true;
      if (goal != null && !goal.isManual && recalculated == null) {
        infoMessage = goalNotRecalculatedMessage;
      }
      return true;
    } catch (_) {
      errorMessage = profileSaveErrorMessage;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  String _numberToText(double value) {
    final text = formatMacroEs(value);
    return text.endsWith(',0') ? text.substring(0, text.length - 2) : text;
  }
}

/// "15/10/1996" → fecha, o `null` si el formato o la fecha no son válidos.
DateTime? parseBirthDate(String text) {
  final match = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$')
      .firstMatch(text.trim());
  if (match == null) return null;
  final day = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final year = int.parse(match.group(3)!);
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) return null;
  return date;
}

String formatBirthDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Número con máximo un decimal, con coma o punto ("63,5"); `null` si no.
double? parseDecimal(String text) {
  final normalized = text.trim().replaceAll(',', '.');
  if (!RegExp(r'^\d+(\.\d)?$').hasMatch(normalized)) return null;
  return double.parse(normalized);
}

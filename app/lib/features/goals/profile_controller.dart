import 'package:flutter/foundation.dart';
import 'package:nutrition_core/nutrition_core.dart';

import '../../infra/storage/storage_repository.dart';
import '../../ui/number_input_es.dart';
import 'goal_calculation.dart';

// SPEC-015: compartidos con la tarjeta de Peso de Progreso.
export '../../ui/number_input_es.dart';

/// SPEC-041 R5.
const birthDateMissingMessage = 'Elige día, mes y año de nacimiento.';
const ageRangeMessage = 'La app es para personas de 18 a 100 años.';
const heightRangeMessage = 'Escribe tu estatura en cm, entre 120 y 230.';
const measuredRangeMessage =
    'Escribe un número entero entre 800 y 6.000, o déjalo vacío.';
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

  /// SPEC-041 R1: la fecha de nacimiento, elegida en tres selectores.
  int? birthDay;
  int? birthMonth;
  int? birthYear;

  String heightText = '';
  String weightText = '';
  ActivityLevel? activityLevel;

  /// R4: mantenimiento medido (opcional), p. ej. promedio de un reloj.
  String measuredText = '';

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

  /// SPEC-015 R2: peso guardado, para saber si cambió al guardar.
  double? _savedWeightKg;

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
      birthDay = profile.birthDate.day;
      birthMonth = profile.birthDate.month;
      birthYear = profile.birthDate.year;
      heightText = _numberToText(profile.heightCm);
      weightText = _numberToText(profile.weightKg);
      _savedWeightKg = profile.weightKg;
      activityLevel = ActivityLevel.values.asNameMap()[profile.activityLevel];
      final measured = profile.measuredMaintenanceKcal;
      measuredText = measured == null
          ? ''
          : formatThousandsEs(presentKcal(measured));
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

  void setBirthDay(int value) {
    birthDay = value;
    _changed();
  }

  void setBirthMonth(int value) {
    birthMonth = value;
    _dropMissingDay();
    _changed();
  }

  void setBirthYear(int value) {
    birthYear = value;
    _dropMissingDay();
    _changed();
  }

  /// SPEC-041 R3: un día que ya no existe en ese mes queda sin elegir; no
  /// se cambia por otro en silencio.
  void _dropMissingDay() {
    final day = birthDay;
    if (day != null && day > birthDays.length) birthDay = null;
  }

  /// SPEC-041 R3: días que existen en el mes y año elegidos.
  List<int> get birthDays => [
    for (var d = 1; d <= daysInMonth(birthYear, birthMonth); d++) d,
  ];

  /// SPEC-041 R2: del año actual − 18 al año actual − 100; también el
  /// guardado si quedó fuera (Edge Cases).
  List<int> get birthYears {
    final now = _now().year;
    final years = [
      for (var y = now - estimationAgeMin; y >= now - estimationAgeMax; y--) y,
    ];
    final saved = birthYear;
    if (saved != null && !years.contains(saved)) {
      years
        ..add(saved)
        ..sort((a, b) => b.compareTo(a));
    }
    return years;
  }

  void setHeight(String text) {
    heightText = text;
    _changed();
  }

  void setWeight(String text) {
    weightText = text;
    _changed();
  }

  void setMeasured(String text) {
    measuredText = text;
    _changed();
  }

  void setActivityLevel(ActivityLevel value) {
    activityLevel = value;
    _changed();
  }

  DateTime? get _birthDate {
    final (d, m, y) = (birthDay, birthMonth, birthYear);
    return d == null || m == null || y == null ? null : DateTime(y, m, d);
  }

  double? get _height => parseDecimal(heightText);
  double? get _weight => parseDecimal(weightText);
  int? get _age {
    final birth = _birthDate;
    return birth == null ? null : ageInYears(birth, _now());
  }

  /// R1: edad calculada a partir de la fecha de nacimiento.
  int? get age => birthDateError == null ? _age : null;

  String? get birthDateError {
    if (birthDay == null && birthMonth == null && birthYear == null) {
      return null;
    }
    final age = _age;
    if (age == null) return birthDateMissingMessage;
    if (age < estimationAgeMin || age > estimationAgeMax) {
      return ageRangeMessage;
    }
    return null;
  }

  double? get _measured => parseKcal(measuredText);

  String? get measuredError {
    if (measuredText.trim().isEmpty) return null;
    final m = _measured;
    return m == null || !isValidGoalKcal(m) ? measuredRangeMessage : null;
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
      weightError == null &&
      measuredError == null;

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

  /// R4: hay un mantenimiento medido válido, que manda sobre la fórmula.
  bool get usesMeasured =>
      measuredText.trim().isNotEmpty && measuredError == null;

  /// R4/R5: mantenimiento que se usa: el medido si existe; si no, el de la
  /// fórmula.
  double? get maintenanceKcal {
    if (!isComplete) return null;
    return usesMeasured ? _measured : formulaMaintenanceKcal;
  }

  /// R5: mantenimiento según la fórmula (calculado en `nutrition_core`);
  /// cambia al editar peso o actividad.
  double? get formulaMaintenanceKcal {
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
        measuredMaintenanceKcal: usesMeasured ? _measured : null,
        recalculatedGoal: recalculated,
        // SPEC-015 R2: un peso distinto (o el primero) crea el registro de
        // hoy en el historial de peso.
        weightLogDay: _weight != _savedWeightKg ? _now() : null,
      );
      hasSavedProfile = true;
      _savedWeightKg = _weight;
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

/// SPEC-041 R3: días del mes (29 en febrero si aún no hay año).
int daysInMonth(int? year, int? month) {
  if (month == null) return 31;
  if (year == null) return month == 2 ? 29 : DateTime(2000, month + 1, 0).day;
  return DateTime(year, month + 1, 0).day;
}

/// SPEC-041 R1: nombres de los meses (1 = enero).
const monthNamesEs = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

import 'package:flutter/foundation.dart';
import 'package:nutrition_core/nutrition_core.dart';

import '../../infra/ai_client/label_extraction_dto.dart';
import '../../infra/storage/storage_repository.dart';

/// Campos transcritos que el usuario puede editar (SPEC-004 R4). Siempre
/// "por porción": si la etiqueta solo dio valores por 100 g/ml, se derivan
/// una vez al construir el controller (matemática simple, no una segunda
/// transcripción) para tener un único formulario, no dos.
class LabelConfirmationController extends ChangeNotifier {
  final StorageRepository _storage;

  String productName;
  double? servingQuantity;
  String servingUnit; // "g" | "ml"
  double? energyKcal;
  double? proteinG;
  double? carbsG;
  double? fatG;
  double? fiberG;
  double? sugarG;
  double? sodiumMg;
  late double consumedQuantity;

  final Set<String> unreadableFields;
  bool _atwaterConfirmedDespiteWarning = false;

  LabelConfirmationController({
    required LabelExtractionDto extraction,
    required StorageRepository storage,
  })
    // ignore: prefer_initializing_formals
    : _storage = storage,
       productName = extraction.productName ?? '',
       servingQuantity = extraction.servingSize?.quantity,
       servingUnit = extraction.servingSize?.unit ?? 'g',
       unreadableFields = extraction.unreadableFields.toSet() {
    final nutrients = extraction.perServing ?? _derivePerServing(extraction);
    energyKcal = nutrients?.energyKcal;
    proteinG = nutrients?.proteinG;
    carbsG = nutrients?.carbsG;
    fatG = nutrients?.fatG;
    fiberG = nutrients?.fiberG;
    sugarG = nutrients?.sugarG;
    sodiumMg = nutrients?.sodiumMg;
    consumedQuantity = servingQuantity ?? 0;
  }

  /// R2 edge case: la etiqueta solo dio valores por 100 g/ml — se derivan
  /// una vez a "por porción" (× cantidad/100) para el único formulario de
  /// edición. No es una segunda transcripción de la IA, es aritmética sobre
  /// lo ya transcrito.
  LabelNutrientSetDto? _derivePerServing(LabelExtractionDto extraction) {
    final per100 = extraction.per100;
    final servingQty = extraction.servingSize?.quantity;
    if (per100 == null || servingQty == null) return null;
    final factor = servingQty / 100;
    double? scale(double? value) => value == null ? null : value * factor;
    return LabelNutrientSetDto(
      energyKcal: scale(per100.energyKcal),
      proteinG: scale(per100.proteinG),
      carbsG: scale(per100.carbsG),
      fatG: scale(per100.fatG),
      fiberG: scale(per100.fiberG),
      sugarG: scale(per100.sugarG),
      sodiumMg: scale(per100.sodiumMg),
    );
  }

  /// R3: Atwater ±20 % sobre los valores por porción — la razón no cambia
  /// al escalar a por-100 g (es lineal), así que se puede validar aquí
  /// directamente sin convertir primero.
  LabelAtwaterCheck? get atwaterCheck {
    if (energyKcal == null ||
        proteinG == null ||
        carbsG == null ||
        fatG == null) {
      return null;
    }
    return checkLabelAtwater(
      energyKcal: energyKcal!,
      proteinG: proteinG!,
      carbsG: carbsG!,
      fatG: fatG!,
    );
  }

  bool get needsAtwaterConfirmation =>
      atwaterCheck != null && !atwaterCheck!.withinTolerance;

  bool get atwaterConfirmedDespiteWarning => _atwaterConfirmedDespiteWarning;

  void setAtwaterConfirmedDespiteWarning(bool value) {
    _atwaterConfirmedDespiteWarning = value;
    notifyListeners();
  }

  /// R3: porción obligatoria y positiva, los 4 macros presentes (el usuario
  /// completó cualquier campo no legible), cantidad consumida > 0, y si
  /// Atwater falla, confirmación explícita.
  bool get canSave => missingForSave.isEmpty;

  /// SPEC-030 R4: lo que falta para poder guardar, en el orden de la
  /// pantalla; vacío si `canSave`.
  List<String> get missingForSave => [
    if (productName.trim().isEmpty) 'nombre del producto',
    if (!isValidServingGrams(servingQuantity)) 'porción',
    if (energyKcal == null) 'calorías',
    if (proteinG == null) 'proteína',
    if (carbsG == null) 'carbohidratos',
    if (fatG == null) 'grasa',
    if (consumedQuantity <= 0) 'cuánto comiste',
    if (needsAtwaterConfirmation && !_atwaterConfirmedDespiteWarning)
      'confirmar que los valores son correctos',
  ];

  void setProductName(String value) {
    productName = value;
    notifyListeners();
  }

  /// R5: mientras el usuario no haya tocado "cuánto comiste" directamente,
  /// sigue reflejando la porción — incluye el caso en que la porción llegó
  /// vacía (etiqueta ilegible) y el usuario la completa después.
  bool _consumedQuantityTouchedByUser = false;

  void setServingQuantity(double? value) {
    servingQuantity = value;
    if (!_consumedQuantityTouchedByUser) {
      consumedQuantity = value ?? 0;
    }
    notifyListeners();
  }

  void setServingUnit(String value) {
    servingUnit = value;
    notifyListeners();
  }

  void setConsumedQuantity(double value) {
    consumedQuantity = value;
    _consumedQuantityTouchedByUser = true;
    notifyListeners();
  }

  void setEnergyKcal(double? v) {
    energyKcal = v;
    notifyListeners();
  }

  void setProteinG(double? v) {
    proteinG = v;
    notifyListeners();
  }

  void setCarbsG(double? v) {
    carbsG = v;
    notifyListeners();
  }

  void setFatG(double? v) {
    fatG = v;
    notifyListeners();
  }

  void setFiberG(double? v) {
    fiberG = v;
    notifyListeners();
  }

  void setSugarG(double? v) {
    sugarG = v;
    notifyListeners();
  }

  void setSodiumMg(double? v) {
    sodiumMg = v;
    notifyListeners();
  }

  /// R7: guarda el producto personal (valores normalizados a por-100 g/ml,
  /// misma convención que `catalog.db`) y devuelve su `nombre` — quien
  /// llama construye el `ParsedMealDto` de un solo ítem con
  /// `food_query = nombre` y `quantity/unit = consumedQuantity/servingUnit`
  /// para reutilizar el mismo `ReviewController` que texto/voz (R8).
  Future<String> save() async {
    if (!canSave) {
      throw StateError(
        'canSave es false: hay campos obligatorios sin completar.',
      );
    }
    final factor = 100 / servingQuantity!;
    await _storage.savePersonalProduct(
      nameEs: productName.trim(),
      energyKcal100: energyKcal! * factor,
      proteinG100: proteinG! * factor,
      carbsG100: carbsG! * factor,
      fatG100: fatG! * factor,
      fiberG100: fiberG == null ? null : fiberG! * factor,
      sugarG100: sugarG == null ? null : sugarG! * factor,
      sodiumMg100: sodiumMg == null ? null : sodiumMg! * factor,
      servingGrams: servingQuantity!,
      sourceRef:
          'Etiqueta transcrita por IA y confirmada por el usuario el '
          '${DateTime.now().toIso8601String().substring(0, 10)}'
          '${productName.trim().isEmpty ? '' : ' — producto: ${productName.trim()}'}.',
    );
    return productName.trim();
  }
}

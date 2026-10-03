import 'package:flutter/foundation.dart';

import '../../infra/ai_client/ai_client.dart';
import '../../infra/ai_client/ai_client_errors.dart';
import '../../infra/ai_client/parsed_meal_dto.dart';
import '../../infra/catalog/catalog_repository.dart';
import '../../infra/food_resolution/food_query_resolver.dart';
import '../../infra/storage/storage_repository.dart';
import 'review_controller.dart';

/// SPEC-012 R2: los cuatro pasos de "Analizando", en orden.
const analysisSteps = [
  'Enviando a la IA',
  'Identificando alimentos y cantidades',
  'Buscando en la base verificada',
  'Calculando en tu teléfono',
];

const noFoodsMessage = 'No encontré alimentos en lo que escribiste';
const genericAiErrorMessage = 'Ocurrió un error. Intenta de nuevo.';
const readErrorMessage = 'No pude leer tus datos. Intenta de nuevo.';

sealed class MealAnalysisState {
  const MealAnalysisState();
}

/// `completedSteps`: cuántos de [analysisSteps] ya terminaron de verdad.
class AnalysisInProgress extends MealAnalysisState {
  final int completedSteps;

  const AnalysisInProgress(this.completedSteps);
}

/// R6/R7: `isAiError` distingue el fallo de la IA (con consejos) del fallo
/// al leer `user.db` (SPEC-009).
class AnalysisFailed extends MealAnalysisState {
  final String message;
  final bool isAiError;

  const AnalysisFailed(this.message, {required this.isAiError});
}

class AnalysisReady extends MealAnalysisState {
  final ReviewController review;

  const AnalysisReady(this.review);
}

/// SPEC-012 R2/R3: texto → `parseMeal` (pasos 1 y 2) → resolución local
/// (paso 3) → cálculo en `nutrition_core` (paso 4) → detalle. Cada paso se
/// marca cuando de verdad termina. Tras [cancel] o [dispose], una respuesta
/// tardía se ignora: no navega ni guarda.
class MealAnalysisController extends ChangeNotifier {
  final String text;
  final AiClient _aiClient;
  final StorageRepository _storage;
  final CatalogRepository _catalog;
  final DateTime Function() _clock;

  /// Pausa breve con los cuatro pasos marcados antes de abrir el detalle,
  /// para que se alcance a ver que terminaron.
  final Duration stepHold;

  MealAnalysisState _state = const AnalysisInProgress(0);
  int _runId = 0;
  bool _cancelled = false;
  bool _disposed = false;

  MealAnalysisController({
    required this.text,
    required this._aiClient,
    required this._storage,
    required this._catalog,
    this._clock = DateTime.now,
    this.stepHold = const Duration(milliseconds: 300),
  });

  MealAnalysisState get state => _state;

  bool get isCancelled => _cancelled;

  bool _isCurrent(int run) => !_disposed && !_cancelled && run == _runId;

  void _set(MealAnalysisState next) {
    _state = next;
    notifyListeners();
  }

  /// También es "Reintentar" (R6): vuelve a enviar el mismo texto.
  Future<void> run() async {
    final run = ++_runId;
    _cancelled = false;
    _set(const AnalysisInProgress(0));

    final ParsedMealDto parsed;
    try {
      parsed = await _aiClient.parseMeal(text: text);
    } on AiClientException catch (error) {
      if (_isCurrent(run)) {
        _set(AnalysisFailed(error.userMessage, isAiError: true));
      }
      return;
    } catch (_) {
      if (_isCurrent(run)) {
        _set(const AnalysisFailed(genericAiErrorMessage, isAiError: true));
      }
      return;
    }
    if (!_isCurrent(run)) return;
    if (parsed.items.isEmpty) {
      _set(const AnalysisFailed(noFoodsMessage, isAiError: true));
      return;
    }
    _set(const AnalysisInProgress(2));

    final List<PersonalProduct> personalProducts;
    try {
      personalProducts = await _storage.getAllPersonalProducts();
    } catch (_) {
      // SPEC-009: sin el texto de SQLite (trae datos del usuario).
      if (_isCurrent(run)) {
        _set(const AnalysisFailed(readErrorMessage, isAiError: false));
      }
      return;
    }
    if (!_isCurrent(run)) return;
    final resolver = FoodQueryResolver(
      catalog: _catalog,
      personalProducts: personalProducts,
    );
    final matches = ReviewController.resolveAll(parsed, resolver);
    _set(const AnalysisInProgress(3));

    final review = ReviewController(
      parsedMeal: parsed,
      resolver: resolver,
      storage: _storage,
      now: _clock(),
      matches: matches,
    );
    _set(const AnalysisInProgress(4));

    await Future<void>.delayed(stepHold);
    if (!_isCurrent(run)) {
      review.dispose();
      return;
    }
    _set(AnalysisReady(review));
  }

  /// R3: no se guarda nada y la respuesta pendiente se ignora.
  void cancel() => _cancelled = true;

  @override
  void dispose() {
    _disposed = true;
    final current = _state;
    if (current is AnalysisReady) current.review.dispose();
    super.dispose();
  }
}

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

import 'ai_client_errors.dart';
import 'label_extraction_dto.dart';
import 'meal_correction_dto.dart';
import 'parsed_meal_dto.dart';

/// Firma inyectable de la llamada real a `parseMeal`, para poder probar
/// [AiClient] sin `FirebaseFunctions`/App Check reales (R2).
typedef ParseMealCaller = Future<Map<String, dynamic>> Function(
  Map<String, dynamic> data,
);

/// SPEC-004: igual que [ParseMealCaller], para `extractLabel`.
typedef ExtractLabelCaller = Future<Map<String, dynamic>> Function(
  Map<String, dynamic> data,
);

/// SPEC-024: igual que [ParseMealCaller], para `correctMeal`.
typedef CorrectMealCaller = Future<Map<String, dynamic>> Function(
  Map<String, dynamic> data,
);

/// SPEC-024: mensaje si la IA no dio una corrección aplicable.
const correctionInvalidMessage =
    'No pude aplicar esa corrección. Prueba a decirla de otra forma.';

class AiClient {
  final ParseMealCaller _callParseMeal;
  final ExtractLabelCaller? _callExtractLabel;
  final CorrectMealCaller? _callCorrectMeal;

  /// `callExtractLabel` es opcional (segundo parámetro posicional) para no
  /// romper los sitios existentes que construyen `AiClient(caller)` solo
  /// para `parseMeal` (tests de SPEC-001/SPEC-002).
  const AiClient(
    this._callParseMeal, [
    this._callExtractLabel,
    this._callCorrectMeal,
  ]);

  factory AiClient.firebase(FirebaseFunctions functions) {
    return AiClient(
      (data) async {
        final callable = functions.httpsCallable(
          'parseMeal',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 10)),
        );
        final result = await callable.call<Map<String, dynamic>>(data);
        return result.data;
      },
      (data) async {
        final callable = functions.httpsCallable(
          'extractLabel',
          // SPEC-029: igual que `timeoutSeconds` de `extractLabel` (Vertex
          // tarda p95 21 s con una etiqueta).
          options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
        );
        final result = await callable.call<Map<String, dynamic>>(data);
        return result.data;
      },
      (data) async {
        final callable = functions.httpsCallable(
          'correctMeal',
          // SPEC-024 R7: igual que `timeoutSeconds` de `correctMeal`.
          options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
        );
        final result = await callable.call<Map<String, dynamic>>(data);
        return result.data;
      },
    );
  }

  /// SPEC-024 R2: envía la corrección y los ítems (sin nutrientes) a
  /// `correctMeal`. Mismo manejo de errores que [parseMeal]; si la IA no dio
  /// una corrección aplicable, el mensaje es [correctionInvalidMessage].
  Future<MealCorrectionDto> correctMeal({
    required String correction,
    required List<CorrectionDraftItem> items,
    String locale = 'es-CO',
  }) async {
    final caller = _callCorrectMeal;
    if (caller == null) {
      throw StateError(
        'AiClient no fue construido con un caller de correctMeal.',
      );
    }
    Map<String, dynamic> data;
    try {
      data = await caller({
        'correction': correction,
        'locale': locale,
        'items': [for (final i in items) i.toJson()],
      });
    } on FirebaseFunctionsException catch (error) {
      throw _correctionError(
        mapAiClientError(code: error.code, details: error.details),
      );
    } on FirebaseException catch (error) {
      throw mapAiClientError(code: error.code);
    } catch (_) {
      throw networkAiClientException;
    }
    return MealCorrectionDto.fromJson(data);
  }

  static AiClientException _correctionError(AiClientException error) =>
      error.type == AiClientErrorType.invalidOutput
      ? AiClientException(
          AiClientErrorType.invalidOutput,
          correctionInvalidMessage,
          code: error.code,
        )
      : error;

  /// R2: llama a `parseMeal` con `{ text, locale }`. Nunca lanza la
  /// excepción cruda de Firebase: siempre un [AiClientException] con
  /// mensaje en español.
  Future<ParsedMealDto> parseMeal({
    required String text,
    String locale = 'es-CO',
  }) async {
    Map<String, dynamic> data;
    try {
      data = await _callParseMeal({'text': text, 'locale': locale});
    } on FirebaseFunctionsException catch (error) {
      throw mapAiClientError(code: error.code, details: error.details);
    } on FirebaseException catch (error) {
      throw mapAiClientError(code: error.code);
    } catch (_) {
      throw networkAiClientException;
    }
    return ParsedMealDto.fromJson(data);
  }

  /// SPEC-004 R2: llama a `extractLabel` con la imagen ya redimensionada
  /// (R10, responsabilidad de quien llama, no de este cliente). Mismo
  /// manejo de errores que `parseMeal`.
  Future<LabelExtractionDto> extractLabel({
    required String imageBase64,
    required String mimeType,
  }) async {
    final caller = _callExtractLabel;
    if (caller == null) {
      throw StateError(
        'AiClient no fue construido con un caller de extractLabel.',
      );
    }
    Map<String, dynamic> data;
    try {
      data = await caller({'image_base64': imageBase64, 'mime_type': mimeType});
    } on FirebaseFunctionsException catch (error) {
      throw mapAiClientError(code: error.code, details: error.details);
    } on FirebaseException catch (error) {
      throw mapAiClientError(code: error.code);
    } catch (_) {
      throw networkAiClientException;
    }
    return LabelExtractionDto.fromJson(data);
  }
}

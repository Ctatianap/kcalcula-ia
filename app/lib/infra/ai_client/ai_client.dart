import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

import 'ai_client_errors.dart';
import 'label_extraction_dto.dart';
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

class AiClient {
  final ParseMealCaller _callParseMeal;
  final ExtractLabelCaller? _callExtractLabel;

  /// `callExtractLabel` es opcional (segundo parámetro posicional) para no
  /// romper los sitios existentes que construyen `AiClient(caller)` solo
  /// para `parseMeal` (tests de SPEC-001/SPEC-002).
  const AiClient(this._callParseMeal, [this._callExtractLabel]);

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
          options: HttpsCallableOptions(timeout: const Duration(seconds: 10)),
        );
        final result = await callable.call<Map<String, dynamic>>(data);
        return result.data;
      },
    );
  }

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

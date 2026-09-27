import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

import 'ai_client_errors.dart';
import 'parsed_meal_dto.dart';

/// Firma inyectable de la llamada real a `parseMeal`, para poder probar
/// [AiClient] sin `FirebaseFunctions`/App Check reales (R2).
typedef ParseMealCaller = Future<Map<String, dynamic>> Function(
  Map<String, dynamic> data,
);

class AiClient {
  final ParseMealCaller _callParseMeal;

  const AiClient(this._callParseMeal);

  factory AiClient.firebase(FirebaseFunctions functions) {
    return AiClient((data) async {
      final callable = functions.httpsCallable(
        'parseMeal',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 10)),
      );
      final result = await callable.call<Map<String, dynamic>>(data);
      return result.data;
    });
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
}

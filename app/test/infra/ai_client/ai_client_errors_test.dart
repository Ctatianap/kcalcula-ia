import 'package:calorias_ia/infra/ai_client/ai_client_errors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mapAiClientError', () {
    test('ai-invalid-output (en details) -> mensaje de reformular', () {
      final error = mapAiClientError(
        code: 'invalid-argument',
        details: {'errorCode': 'ai-invalid-output'},
      );
      expect(error.type, AiClientErrorType.invalidOutput);
      expect(error.userMessage, contains('reformularla'));
    });

    test('deadline-exceeded -> mensaje de red', () {
      final error = mapAiClientError(code: 'deadline-exceeded');
      expect(error.type, AiClientErrorType.network);
    });

    test('unauthenticated (App Check inválido) -> mensaje genérico, código guardado', () {
      final error = mapAiClientError(code: 'unauthenticated');
      expect(error.type, AiClientErrorType.appCheck);
      expect(error.code, 'unauthenticated');
      // Mensaje genérico: no expone detalles técnicos al usuario.
      expect(error.userMessage.toLowerCase(), isNot(contains('app check')));
    });

    test('código desconocido -> mensaje genérico, no lanza', () {
      final error = mapAiClientError(code: 'algo-inesperado');
      expect(error.type, AiClientErrorType.unknown);
    });
  });
}

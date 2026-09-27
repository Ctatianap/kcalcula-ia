/// Categoría de error del cliente de IA, para que la UI decida qué hacer
/// (mostrar el mensaje, ofrecer reintentar, conservar el texto escrito).
enum AiClientErrorType { network, invalidOutput, appCheck, unknown }

/// Error visible al usuario: en español, accionable, sin trazas técnicas
/// (convención de CLAUDE.md). `code` es solo para logs de diagnóstico.
class AiClientException implements Exception {
  final AiClientErrorType type;
  final String userMessage;
  final String? code;

  const AiClientException(this.type, this.userMessage, {this.code});

  @override
  String toString() => 'AiClientException($type, code: $code)';
}

const _networkErrorMessage =
    'Sin conexión. Revisa tu internet e intenta de nuevo.';
const _genericErrorMessage = 'Ocurrió un error. Intenta de nuevo.';
const _invalidOutputMessage =
    'No pude entender la comida, ¿puedes reformularla?';

/// Mapea un código de error de Cloud Functions (y sus `details`, si los
/// hay) a un [AiClientException] con mensaje en español. Función pura para
/// poder probarla sin depender de `FirebaseFunctionsException` (su
/// constructor es `@protected`, no se puede instanciar fuera del paquete).
AiClientException mapAiClientError({required String code, dynamic details}) {
  if (details is Map && details['errorCode'] == 'ai-invalid-output') {
    return const AiClientException(
      AiClientErrorType.invalidOutput,
      _invalidOutputMessage,
      code: 'ai-invalid-output',
    );
  }

  switch (code) {
    case 'deadline-exceeded':
    case 'unavailable':
      return AiClientException(
        AiClientErrorType.network,
        _networkErrorMessage,
        code: code,
      );
    case 'unauthenticated':
    case 'permission-denied':
      return AiClientException(
        AiClientErrorType.appCheck,
        _genericErrorMessage,
        code: code,
      );
    case 'invalid-argument':
      // Sin `details.errorCode`: es la validación de longitud (R1), no
      // ai-invalid-output. Mismo mensaje genérico; el AC10 correspondiente
      // vive en functions/, no aquí.
      return AiClientException(
        AiClientErrorType.unknown,
        _genericErrorMessage,
        code: code,
      );
    default:
      return AiClientException(
        AiClientErrorType.unknown,
        _genericErrorMessage,
        code: code,
      );
  }
}

/// Para errores que no llegan como excepción de Firebase (por ejemplo, sin
/// red antes de que el plugin pueda hacer la llamada).
const networkAiClientException = AiClientException(
  AiClientErrorType.network,
  _networkErrorMessage,
);

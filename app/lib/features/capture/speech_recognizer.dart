import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Envuelve el reconocimiento de voz del sistema operativo (D3 de ADR-001)
/// detrás de una interfaz propia, para poder inyectar un fake en tests sin
/// tocar canales de plataforma (R3).
abstract class SpeechRecognizer {
  bool get isAvailable;

  /// `onError` reporta errores del plugin en cualquier momento (durante
  /// `initialize` o mientras escucha), no solo al inicializar.
  Future<bool> initialize({required void Function(String message) onError});

  Future<void> listen({
    required void Function(String text, bool isFinal) onResult,
    Duration pauseFor = const Duration(seconds: 2),
    String localeId = 'es_CO',
  });

  Future<void> stop();
}

class PluginSpeechRecognizer implements SpeechRecognizer {
  final stt.SpeechToText _speech = stt.SpeechToText();

  @override
  bool get isAvailable => _speech.isAvailable;

  @override
  Future<bool> initialize({required void Function(String message) onError}) {
    return _speech.initialize(
      onError: (error) => onError(error.errorMsg),
      onStatus: (_) {},
    );
  }

  @override
  Future<void> listen({
    required void Function(String text, bool isFinal) onResult,
    Duration pauseFor = const Duration(seconds: 2),
    String localeId = 'es_CO',
  }) {
    return _speech.listen(
      onResult: (result) =>
          onResult(result.recognizedWords, result.finalResult),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        pauseFor: pauseFor,
        localeId: localeId,
      ),
    );
  }

  @override
  Future<void> stop() => _speech.stop();
}

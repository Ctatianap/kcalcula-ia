import 'package:calorias_ia/features/capture/microphone_permission.dart';
import 'package:calorias_ia/features/capture/speech_recognizer.dart';

class FakeMicrophonePermission implements MicrophonePermission {
  final bool granted;

  FakeMicrophonePermission({this.granted = true});

  @override
  Future<bool> ensureGranted() async => granted;
}

class FakeSpeechRecognizer implements SpeechRecognizer {
  final bool availableOnInit;

  FakeSpeechRecognizer({this.availableOnInit = true});

  bool _available = false;
  void Function(String message)? _onError;
  void Function()? _onDone;
  void Function(String text, bool isFinal)? _onResult;

  /// Último `pauseFor` recibido en `listen` (AC11).
  Duration? lastPauseFor;

  @override
  bool get isAvailable => _available;

  @override
  Future<bool> initialize({
    required void Function(String message) onError,
    required void Function() onDone,
  }) async {
    _onError = onError;
    _onDone = onDone;
    _available = availableOnInit;
    return availableOnInit;
  }

  @override
  Future<void> listen({
    required void Function(String text, bool isFinal) onResult,
    Duration? pauseFor,
    String localeId = 'es_CO',
  }) async {
    _onResult = onResult;
    lastPauseFor = pauseFor;
  }

  @override
  Future<void> stop() async {}

  /// Helper de test: simula que el plugin reportó una palabra reconocida
  /// (parcial o final).
  void emitResult(String text, {bool isFinal = false}) {
    _onResult?.call(text, isFinal);
  }

  /// Helper de test: simula que el reconocedor cerró la escucha por su
  /// cuenta (status `done`), sin que el usuario tocara "Detener".
  void emitDone() {
    _onDone?.call();
  }

  /// Helper de test: simula un error del plugin durante la escucha.
  void emitError(String message) {
    _onError?.call(message);
  }
}

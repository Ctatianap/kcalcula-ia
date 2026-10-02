import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'microphone_permission.dart';
import 'speech_recognizer.dart';

const _noMicrophonePermissionMessage =
    'Necesito permiso del micrófono para esto. Puedes escribir en su lugar.';
const _notAvailableMessage =
    'El reconocimiento de voz no está disponible en este dispositivo. Puedes escribir en su lugar.';
const _genericErrorMessage =
    'No pude escuchar bien. Intenta de nuevo o escribe directamente.';

sealed class VoiceInputState {
  const VoiceInputState();
}

/// `text` no nulo: la escucha terminó sola (R5) y esa es la transcripción
/// que debe quedar en el campo. Nulo: no hay nada nuevo que escribir.
class VoiceInputIdle extends VoiceInputState {
  final String? text;

  const VoiceInputIdle({this.text});
}

/// R4: `text` es la transcripción parcial en vivo mientras escucha.
class VoiceInputListening extends VoiceInputState {
  final String text;

  const VoiceInputListening(this.text);
}

class VoiceInputError extends VoiceInputState {
  final String message;

  const VoiceInputError(this.message);
}

/// Se sobrescribe en tests con un fake; en la app real usa las
/// implementaciones reales de los plugins.
final speechRecognizerProvider = Provider<SpeechRecognizer>(
  (ref) => PluginSpeechRecognizer(),
);

final microphonePermissionProvider = Provider<MicrophonePermission>(
  (ref) => SystemMicrophonePermission(),
);

/// R2, R3, R4, R5, R7, R9: pide permiso, escucha con el reconocimiento de
/// voz del sistema operativo y expone la transcripción en vivo. `CaptureScreen`
/// vuelca `text` en el mismo `TextField` que usa para texto escrito — no
/// hay un flujo paralelo, solo otra forma de rellenar el mismo campo.
class VoiceInputController extends Notifier<VoiceInputState> {
  /// R9: texto que ya estaba en el campo al empezar a escuchar.
  String _prefix = '';
  String _transcript = '';
  bool _sessionActive = false;

  @override
  VoiceInputState build() => const VoiceInputIdle();

  Future<void> startListening({String existingText = ''}) async {
    final hasPermission = await ref
        .read(microphonePermissionProvider)
        .ensureGranted();
    if (!hasPermission) {
      state = const VoiceInputError(_noMicrophonePermissionMessage);
      return;
    }

    final recognizer = ref.read(speechRecognizerProvider);
    final available = await recognizer.initialize(
      onError: (_) {
        _sessionActive = false;
        state = const VoiceInputError(_genericErrorMessage);
      },
      onDone: _onDone,
    );
    if (!available) {
      state = const VoiceInputError(_notAvailableMessage);
      return;
    }

    _prefix = existingText.trim();
    _transcript = _prefix;
    _sessionActive = true;
    state = VoiceInputListening(_transcript);
    await recognizer.listen(
      onResult: _onResult,
      pauseFor: const Duration(seconds: 2),
      localeId: 'es_CO',
    );
  }

  void _onResult(String text, bool isFinal) {
    final words = text.trim();
    _transcript = words.isEmpty || _prefix.isEmpty
        ? '$_prefix$words'
        : '$_prefix $words';
    if (_sessionActive) {
      state = VoiceInputListening(_transcript);
    } else if (isFinal) {
      // Android puede mandar el resultado final después de `done`.
      state = VoiceInputIdle(text: _transcript);
    }
  }

  /// R5: el reconocedor cerró la escucha por su cuenta (silencio o decisión
  /// del sistema operativo). El texto se conserva en el campo.
  void _onDone() {
    if (!_sessionActive) return;
    _sessionActive = false;
    state = VoiceInputIdle(text: _transcript);
  }

  /// R5: detener manualmente. En ambos casos el texto queda en el campo para
  /// editar.
  Future<void> stopListening() async {
    _sessionActive = false;
    await ref.read(speechRecognizerProvider).stop();
    state = const VoiceInputIdle();
  }
}

final voiceInputControllerProvider =
    NotifierProvider<VoiceInputController, VoiceInputState>(
      VoiceInputController.new,
    );

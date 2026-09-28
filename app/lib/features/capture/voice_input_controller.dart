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

class VoiceInputIdle extends VoiceInputState {
  const VoiceInputIdle();
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

/// R2, R3, R4, R5, R7: pide permiso, escucha con el reconocimiento de voz
/// del sistema operativo y expone la transcripción en vivo. `CaptureScreen`
/// vuelca `text` en el mismo `TextField` que usa para texto escrito — no
/// hay un flujo paralelo, solo otra forma de rellenar el mismo campo.
class VoiceInputController extends Notifier<VoiceInputState> {
  @override
  VoiceInputState build() => const VoiceInputIdle();

  Future<void> startListening() async {
    final hasPermission = await ref
        .read(microphonePermissionProvider)
        .ensureGranted();
    if (!hasPermission) {
      state = const VoiceInputError(_noMicrophonePermissionMessage);
      return;
    }

    final recognizer = ref.read(speechRecognizerProvider);
    final available = await recognizer.initialize(
      onError: (_) => state = const VoiceInputError(_genericErrorMessage),
    );
    if (!available) {
      state = const VoiceInputError(_notAvailableMessage);
      return;
    }

    state = const VoiceInputListening('');
    await recognizer.listen(
      onResult: (text, isFinal) => state = VoiceInputListening(text),
      pauseFor: const Duration(seconds: 2),
      localeId: 'es_CO',
    );
  }

  /// R5: detener manualmente. El timeout de silencio automático lo maneja
  /// el propio plugin (`pauseFor`) llamando a `onResult` con el resultado
  /// final; en ambos casos el texto queda en el campo para editar.
  Future<void> stopListening() async {
    await ref.read(speechRecognizerProvider).stop();
    state = const VoiceInputIdle();
  }

  void reset() => state = const VoiceInputIdle();
}

final voiceInputControllerProvider =
    NotifierProvider<VoiceInputController, VoiceInputState>(
      VoiceInputController.new,
    );

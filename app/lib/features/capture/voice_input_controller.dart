import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'microphone_permission.dart';
import 'speech_recognizer.dart';

const _noMicrophonePermissionMessage =
    'Necesito permiso del micrófono para esto. Puedes escribir en su lugar.';
const _notAvailableMessage =
    'El reconocimiento de voz no está disponible en este dispositivo. Puedes escribir en su lugar.';

/// R5: en Android no se fija tiempo de silencio — con 2 s el reconocedor
/// cortaba a mitad de frase (medición de AC8,
/// `docs/research/2026-10-01-voz-es-co-dispositivos.md`). En iOS el
/// reconocedor no cierra solo, así que se mantiene el corte de ~2 s.
Duration? silencePauseFor(TargetPlatform platform) =>
    platform == TargetPlatform.android ? null : const Duration(seconds: 2);

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
  bool _starting = false;

  /// Identifica la sesión de escucha vigente; los resultados de una sesión
  /// descartada (ver [discardPendingResult]) se ignoran.
  int _session = 0;

  @override
  VoiceInputState build() => const VoiceInputIdle();

  Future<void> startListening({String existingText = ''}) async {
    // Doble toque mientras se piden permisos o se inicializa: se ignora.
    if (_starting || _sessionActive) return;
    _starting = true;
    try {
      await _start(existingText);
    } finally {
      _starting = false;
    }
  }

  Future<void> _start(String existingText) async {
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
        // Un error de una escucha que ya terminó no tiene nada que reintentar.
        if (!_sessionActive) return;
        _sessionActive = false;
        state = const VoiceInputError(_genericErrorMessage);
      },
      onDone: _onDone,
    );
    if (!available) {
      state = const VoiceInputError(_notAvailableMessage);
      return;
    }

    final session = ++_session;
    _prefix = existingText.trim();
    _transcript = _prefix;
    _sessionActive = true;
    state = VoiceInputListening(_transcript);
    try {
      await recognizer.listen(
        onResult: (text, isFinal) => _onResult(session, text, isFinal),
        pauseFor: silencePauseFor(defaultTargetPlatform),
        localeId: 'es_CO',
      );
    } catch (_) {
      // R5/R7: si no logra empezar, nunca se queda en "escuchando".
      if (session == _session) {
        _sessionActive = false;
        state = const VoiceInputError(_genericErrorMessage);
      }
    }
  }

  void _onResult(int session, String text, bool isFinal) {
    if (session != _session) return;
    final words = text.trim();
    _transcript = words.isEmpty || _prefix.isEmpty
        ? '$_prefix$words'
        : '$_prefix $words';
    if (_sessionActive) {
      state = VoiceInputListening(_transcript);
    } else if (isFinal && state is! VoiceInputError) {
      // Android puede mandar el resultado final después de `done` o de
      // detener a mano. Tras un error se conserva el mensaje: el campo ya
      // tiene los parciales.
      state = VoiceInputIdle(text: _transcript);
    }
  }

  /// R10: el usuario borró el campo; un resultado tardío de la escucha
  /// anterior no debe volver a llenarlo.
  void discardPendingResult() {
    if (_sessionActive) return;
    _session++;
    state = const VoiceInputIdle();
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

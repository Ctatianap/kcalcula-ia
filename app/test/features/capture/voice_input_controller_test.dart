import 'package:calorias_ia/features/capture/microphone_permission.dart';
import 'package:calorias_ia/features/capture/speech_recognizer.dart';
import 'package:calorias_ia/features/capture/voice_input_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_voice_input.dart';

ProviderContainer _buildContainer({
  required MicrophonePermission permission,
  required SpeechRecognizer recognizer,
}) {
  return ProviderContainer(
    overrides: [
      microphonePermissionProvider.overrideWithValue(permission),
      speechRecognizerProvider.overrideWithValue(recognizer),
    ],
  );
}

void main() {
  test(
    'AC4: sin permiso de micrófono -> VoiceInputError, no llama al reconocedor',
    () async {
      final container = _buildContainer(
        permission: FakeMicrophonePermission(granted: false),
        recognizer: FakeSpeechRecognizer(),
      );
      addTearDown(container.dispose);

      await container
          .read(voiceInputControllerProvider.notifier)
          .startListening();

      final state = container.read(voiceInputControllerProvider);
      expect(state, isA<VoiceInputError>());
      expect(
        (state as VoiceInputError).message,
        contains('permiso del micrófono'),
      );
    },
  );

  test(
    'AC5: reconocimiento no disponible en el dispositivo -> VoiceInputError',
    () async {
      final container = _buildContainer(
        permission: FakeMicrophonePermission(granted: true),
        recognizer: FakeSpeechRecognizer(availableOnInit: false),
      );
      addTearDown(container.dispose);

      await container
          .read(voiceInputControllerProvider.notifier)
          .startListening();

      final state = container.read(voiceInputControllerProvider);
      expect(state, isA<VoiceInputError>());
      expect(
        (state as VoiceInputError).message,
        contains('no está disponible'),
      );
    },
  );

  test('AC2: la transcripción parcial va apareciendo en el estado mientras escucha', () async {
    final recognizer = FakeSpeechRecognizer();
    final container = _buildContainer(
      permission: FakeMicrophonePermission(granted: true),
      recognizer: recognizer,
    );
    addTearDown(container.dispose);

    await container
        .read(voiceInputControllerProvider.notifier)
        .startListening();
    expect(
      container.read(voiceInputControllerProvider),
      isA<VoiceInputListening>(),
    );

    recognizer.emitResult('dos');
    expect(
      (container.read(
        voiceInputControllerProvider,
      ) as VoiceInputListening).text,
      'dos',
    );

    recognizer.emitResult('dos huevos', isFinal: true);
    expect(
      (container.read(
        voiceInputControllerProvider,
      ) as VoiceInputListening).text,
      'dos huevos',
    );
  });

  test(
    'AC6: un error del plugin durante la escucha -> VoiceInputError',
    () async {
      final recognizer = FakeSpeechRecognizer();
      final container = _buildContainer(
        permission: FakeMicrophonePermission(granted: true),
        recognizer: recognizer,
      );
      addTearDown(container.dispose);

      await container
          .read(voiceInputControllerProvider.notifier)
          .startListening();
      recognizer.emitError('no-match');

      final state = container.read(voiceInputControllerProvider);
      expect(state, isA<VoiceInputError>());
      expect((state as VoiceInputError).message, isNot(contains('no-match')));
    },
  );

  test('stopListening vuelve a VoiceInputIdle', () async {
    final container = _buildContainer(
      permission: FakeMicrophonePermission(granted: true),
      recognizer: FakeSpeechRecognizer(),
    );
    addTearDown(container.dispose);

    await container
        .read(voiceInputControllerProvider.notifier)
        .startListening();
    await container.read(voiceInputControllerProvider.notifier).stopListening();

    expect(container.read(voiceInputControllerProvider), isA<VoiceInputIdle>());
  });
}

import 'package:calorias_ia/features/capture/microphone_permission.dart';
import 'package:calorias_ia/features/capture/speech_recognizer.dart';
import 'package:calorias_ia/features/capture/voice_input_controller.dart';
import 'package:flutter/foundation.dart';
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

  test(
    'AC9: el reconocedor termina solo -> VoiceInputIdle con la transcripción',
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
      recognizer.emitResult('almorcé 180 gramos de arroz');
      recognizer.emitDone();

      final state = container.read(voiceInputControllerProvider);
      expect(state, isA<VoiceInputIdle>());
      expect((state as VoiceInputIdle).text, 'almorcé 180 gramos de arroz');

      // Un segundo `done` no cambia nada.
      recognizer.emitDone();
      expect(
        (container.read(voiceInputControllerProvider) as VoiceInputIdle).text,
        'almorcé 180 gramos de arroz',
      );
    },
  );

  test(
    'AC9: un resultado final que llega después de done queda en el estado',
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
      recognizer.emitResult('una manzana');
      recognizer.emitDone();
      recognizer.emitResult('una manzana verde', isFinal: true);

      final state = container.read(voiceInputControllerProvider);
      expect(state, isA<VoiceInputIdle>());
      expect((state as VoiceInputIdle).text, 'una manzana verde');
    },
  );

  test('AC10: la transcripción nueva se agrega al texto existente', () async {
    final recognizer = FakeSpeechRecognizer();
    final container = _buildContainer(
      permission: FakeMicrophonePermission(granted: true),
      recognizer: recognizer,
    );
    addTearDown(container.dispose);

    await container
        .read(voiceInputControllerProvider.notifier)
        .startListening(existingText: 'dos huevos ');
    expect(
      (container.read(
        voiceInputControllerProvider,
      ) as VoiceInputListening).text,
      'dos huevos',
    );

    recognizer.emitResult('');
    expect(
      (container.read(
        voiceInputControllerProvider,
      ) as VoiceInputListening).text,
      'dos huevos',
    );

    recognizer.emitResult('y una arepa');
    expect(
      (container.read(
        voiceInputControllerProvider,
      ) as VoiceInputListening).text,
      'dos huevos y una arepa',
    );
  });

  group('AC11: tiempo de silencio por plataforma', () {
    test('Android no fija tiempo de silencio; iOS usa 2 s', () {
      expect(silencePauseFor(TargetPlatform.android), isNull);
      expect(silencePauseFor(TargetPlatform.iOS), const Duration(seconds: 2));
    });

    for (final (platform, expected) in [
      (TargetPlatform.android, null),
      (TargetPlatform.iOS, const Duration(seconds: 2)),
    ]) {
      test('startListening en $platform pasa pauseFor=$expected', () async {
        debugDefaultTargetPlatformOverride = platform;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        final recognizer = FakeSpeechRecognizer();
        final container = _buildContainer(
          permission: FakeMicrophonePermission(granted: true),
          recognizer: recognizer,
        );
        addTearDown(container.dispose);

        await container
            .read(voiceInputControllerProvider.notifier)
            .startListening();

        expect(recognizer.lastPauseFor, expected);
      });
    }
  });

  group('robustez de la sesión (revisión 2026-10-02)', () {
    test(
      'R5/R7: si listen falla al empezar -> VoiceInputError, no escuchando',
      () async {
        final container = _buildContainer(
          permission: FakeMicrophonePermission(granted: true),
          recognizer: FakeSpeechRecognizer(listenThrows: Exception('busy')),
        );
        addTearDown(container.dispose);

        await container
            .read(voiceInputControllerProvider.notifier)
            .startListening();

        final state = container.read(voiceInputControllerProvider);
        expect(state, isA<VoiceInputError>());
        expect((state as VoiceInputError).message, isNot(contains('busy')));
      },
    );

    test('un resultado final después de un error conserva el error', () async {
      final recognizer = FakeSpeechRecognizer();
      final container = _buildContainer(
        permission: FakeMicrophonePermission(granted: true),
        recognizer: recognizer,
      );
      addTearDown(container.dispose);

      await container
          .read(voiceInputControllerProvider.notifier)
          .startListening();
      recognizer.emitResult('una');
      recognizer.emitError('network');
      recognizer.emitResult('una manzana', isFinal: true);

      expect(
        container.read(voiceInputControllerProvider),
        isA<VoiceInputError>(),
      );
    });

    test(
      'detener a mano y luego resultado final -> VoiceInputIdle con texto',
      () async {
        final recognizer = FakeSpeechRecognizer();
        final container = _buildContainer(
          permission: FakeMicrophonePermission(granted: true),
          recognizer: recognizer,
        );
        addTearDown(container.dispose);
        final controller = container.read(
          voiceInputControllerProvider.notifier,
        );

        await controller.startListening();
        recognizer.emitResult('un café');
        await controller.stopListening();
        recognizer.emitResult('un café con leche', isFinal: true);

        final state = container.read(voiceInputControllerProvider);
        expect(state, isA<VoiceInputIdle>());
        expect((state as VoiceInputIdle).text, 'un café con leche');
      },
    );

    test('R10: tras descartar, un resultado tardío se ignora', () async {
      final recognizer = FakeSpeechRecognizer();
      final container = _buildContainer(
        permission: FakeMicrophonePermission(granted: true),
        recognizer: recognizer,
      );
      addTearDown(container.dispose);
      final controller = container.read(voiceInputControllerProvider.notifier);

      await controller.startListening();
      recognizer.emitResult('un café');
      await controller.stopListening();
      controller.discardPendingResult();
      recognizer.emitResult('un café con leche', isFinal: true);

      final state = container.read(voiceInputControllerProvider);
      expect(state, isA<VoiceInputIdle>());
      expect((state as VoiceInputIdle).text, isNull);
    });

    test('doble toque mientras inicia -> una sola llamada a listen', () async {
      final recognizer = FakeSpeechRecognizer();
      final container = _buildContainer(
        permission: FakeMicrophonePermission(granted: true),
        recognizer: recognizer,
      );
      addTearDown(container.dispose);
      final controller = container.read(voiceInputControllerProvider.notifier);

      await Future.wait([
        controller.startListening(),
        controller.startListening(),
      ]);

      expect(recognizer.listenCalls, 1);
    });
  });
}

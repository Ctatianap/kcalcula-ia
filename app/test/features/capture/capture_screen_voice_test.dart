import 'package:calorias_ia/features/capture/capture_screen.dart';
import 'package:calorias_ia/features/capture/voice_input_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_voice_input.dart';

Future<void> _pump(
  WidgetTester tester, {
  required FakeMicrophonePermission permission,
  required FakeSpeechRecognizer recognizer,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        microphonePermissionProvider.overrideWithValue(permission),
        speechRecognizerProvider.overrideWithValue(recognizer),
      ],
      child: const MaterialApp(home: CaptureScreen()),
    ),
  );
  // SPEC-012 R1: el micrófono vive en la pestaña Voz.
  await tester.tap(find.text('Voz'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('AC1: tocar el micrófono muestra el indicador de escuchando', (
    tester,
  ) async {
    await _pump(
      tester,
      permission: FakeMicrophonePermission(granted: true),
      recognizer: FakeSpeechRecognizer(),
    );

    expect(find.text('Escuchando…'), findsNothing);
    await tester.tap(find.byIcon(Icons.mic));
    await tester.pumpAndSettle();

    expect(find.text('Escuchando…'), findsOneWidget);
    expect(find.byIcon(Icons.stop), findsOneWidget);
  });

  testWidgets(
    'AC3: la transcripción final queda editable y habilita Analizar',
    (tester) async {
      final recognizer = FakeSpeechRecognizer();
      await _pump(
        tester,
        permission: FakeMicrophonePermission(granted: true),
        recognizer: recognizer,
      );

      await tester.tap(find.byIcon(Icons.mic));
      await tester.pumpAndSettle();

      recognizer.emitResult('dos huevos y una arepa', isFinal: true);
      await tester.pumpAndSettle();

      expect(find.text('dos huevos y una arepa'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();

      final registrarFinder = find.widgetWithText(FilledButton, 'Analizar');
      expect(tester.widget<FilledButton>(registrarFinder).onPressed, isNotNull);

      // Sigue siendo editable: agregar texto a mano no lo bloquea.
      await tester.enterText(
        find.byType(TextField),
        'dos huevos y una arepa grande',
      );
      await tester.pump();
      expect(find.text('dos huevos y una arepa grande'), findsOneWidget);
    },
  );

  testWidgets(
    'AC4: sin permiso -> mensaje de error y el campo de texto sigue disponible',
    (tester) async {
      await _pump(
        tester,
        permission: FakeMicrophonePermission(granted: false),
        recognizer: FakeSpeechRecognizer(),
      );

      await tester.tap(find.byIcon(Icons.mic));
      await tester.pumpAndSettle();

      expect(find.textContaining('permiso del micrófono'), findsOneWidget);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isTrue);

      await tester.enterText(find.byType(TextField), 'una manzana');
      await tester.pump();
      expect(find.text('una manzana'), findsOneWidget);
    },
  );

  testWidgets(
    'AC5: reconocimiento no disponible -> mensaje de error, fallback a texto',
    (tester) async {
      await _pump(
        tester,
        permission: FakeMicrophonePermission(granted: true),
        recognizer: FakeSpeechRecognizer(availableOnInit: false),
      );

      await tester.tap(find.byIcon(Icons.mic));
      await tester.pumpAndSettle();

      expect(find.textContaining('no está disponible'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
    },
  );

  testWidgets(
    'AC9: si el reconocedor termina solo, vuelve el micrófono y el texto queda',
    (tester) async {
      final recognizer = FakeSpeechRecognizer();
      await _pump(
        tester,
        permission: FakeMicrophonePermission(granted: true),
        recognizer: recognizer,
      );

      await tester.tap(find.byIcon(Icons.mic));
      await tester.pumpAndSettle();
      recognizer.emitResult('medio aguacate');
      recognizer.emitDone();
      await tester.pumpAndSettle();

      expect(find.text('Escuchando…'), findsNothing);
      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.text('medio aguacate'), findsOneWidget);
      final analizar = find.widgetWithText(FilledButton, 'Analizar');
      expect(tester.widget<FilledButton>(analizar).onPressed, isNotNull);
    },
  );

  testWidgets('AC10: dictar de nuevo agrega al final del texto del campo', (
    tester,
  ) async {
    final recognizer = FakeSpeechRecognizer();
    await _pump(
      tester,
      permission: FakeMicrophonePermission(granted: true),
      recognizer: recognizer,
    );

    await tester.enterText(find.byType(TextField), 'dos huevos');
    await tester.tap(find.byIcon(Icons.mic));
    await tester.pumpAndSettle();
    recognizer.emitResult('y una arepa');
    recognizer.emitDone();
    await tester.pumpAndSettle();

    expect(find.text('dos huevos y una arepa'), findsOneWidget);
  });

  group('AC12: botón para borrar el texto', () {
    testWidgets('con texto, ✕ vacía el campo y deshabilita Analizar', (
      tester,
    ) async {
      await _pump(
        tester,
        permission: FakeMicrophonePermission(granted: true),
        recognizer: FakeSpeechRecognizer(),
      );

      expect(find.byIcon(Icons.clear), findsNothing);
      await tester.enterText(find.byType(TextField), 'una manzana');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(find.byIcon(Icons.clear), findsNothing);
      final analizar = find.widgetWithText(FilledButton, 'Analizar');
      expect(tester.widget<FilledButton>(analizar).onPressed, isNull);
    });

    testWidgets('mientras escucha, ✕ no aparece', (tester) async {
      final recognizer = FakeSpeechRecognizer();
      await _pump(
        tester,
        permission: FakeMicrophonePermission(granted: true),
        recognizer: recognizer,
      );

      await tester.tap(find.byIcon(Icons.mic));
      await tester.pumpAndSettle();
      recognizer.emitResult('dos huevos');
      await tester.pumpAndSettle();

      expect(find.text('dos huevos'), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('después de limpiar, dictar empieza desde cero', (
      tester,
    ) async {
      final recognizer = FakeSpeechRecognizer();
      await _pump(
        tester,
        permission: FakeMicrophonePermission(granted: true),
        recognizer: recognizer,
      );

      await tester.enterText(find.byType(TextField), 'dos huevos');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.mic));
      await tester.pumpAndSettle();
      recognizer.emitResult('una arepa');
      recognizer.emitDone();
      await tester.pumpAndSettle();

      expect(find.text('una arepa'), findsOneWidget);
    });
  });
}

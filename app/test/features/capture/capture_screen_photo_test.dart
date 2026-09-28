import 'package:calorias_ia/features/capture/capture_screen.dart';
import 'package:calorias_ia/features/capture/label_capture_controller.dart';
import 'package:calorias_ia/infra/ai_client/ai_client.dart';
import 'package:calorias_ia/infra/ai_client/ai_client_providers.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_image_picker.dart';

const _validLabelResponse = {
  'schema_version': 'label_extraction.v1',
  'product_name': 'Producto de prueba',
  'serving_size': {'quantity': 30, 'unit': 'g'},
  'per_serving': {
    'energy_kcal': 140,
    'protein_g': 2,
    'carbs_g': 20,
    'fat_g': 6,
    'fiber_g': null,
    'sugar_g': null,
    'sodium_mg': null,
  },
  'per_100': null,
  'unreadable_fields': <String>[],
};

Future<void> _pump(
  WidgetTester tester, {
  required FakeCameraPermission permission,
  required FakeImagePickerService picker,
  AiClient? aiClient,
}) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        cameraPermissionProvider.overrideWithValue(permission),
        imagePickerServiceProvider.overrideWithValue(picker),
        appDatabaseProvider.overrideWithValue(db),
        if (aiClient != null) aiClientProvider.overrideWithValue(aiClient),
      ],
      child: const MaterialApp(home: CaptureScreen()),
    ),
  );
}

Future<void> _openCameraOption(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.camera_alt));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Tomar foto'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'AC1: tomar foto con éxito navega a la pantalla de confirmación',
    (tester) async {
      await _pump(
        tester,
        permission: FakeCameraPermission(granted: true),
        picker: FakeImagePickerService(cameraResult: fakeImageBytes),
        aiClient: AiClient((data) async => {}, (data) async {
          expect(data['mime_type'], 'image/jpeg');
          return _validLabelResponse;
        }),
      );

      await _openCameraOption(tester);

      expect(find.text('Confirmar etiqueta'), findsOneWidget);
    },
  );

  testWidgets(
    'AC7: sin permiso de cámara -> mensaje de error y el campo de texto sigue disponible',
    (tester) async {
      await _pump(
        tester,
        permission: FakeCameraPermission(granted: false),
        picker: FakeImagePickerService(),
      );

      await _openCameraOption(tester);

      expect(find.textContaining('permiso de la cámara'), findsOneWidget);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isTrue);
    },
  );

  testWidgets('cancelar el selector (sin foto) no navega ni muestra error', (
    tester,
  ) async {
    await _pump(
      tester,
      permission: FakeCameraPermission(granted: true),
      picker: FakeImagePickerService(cameraResult: null),
    );

    await _openCameraOption(tester);

    expect(find.text('Confirmar etiqueta'), findsNothing);
    expect(find.textContaining('permiso de la cámara'), findsNothing);
  });

  testWidgets(
    'AC8: error del proveedor de IA -> mensaje en español, sin traza técnica',
    (tester) async {
      await _pump(
        tester,
        permission: FakeCameraPermission(granted: true),
        picker: FakeImagePickerService(cameraResult: fakeImageBytes),
        aiClient: AiClient((data) async => {}, (data) async {
          throw Exception('boom');
        }),
      );

      await _openCameraOption(tester);

      expect(find.text('Confirmar etiqueta'), findsNothing);
      expect(find.textContaining('Sin conexión'), findsOneWidget);
    },
  );
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infra/ai_client/ai_client_errors.dart';
import '../../infra/ai_client/ai_client_providers.dart';
import '../../infra/ai_client/label_extraction_dto.dart';
import 'camera_permission.dart';
import 'image_picker_service.dart';

const _noCameraPermissionMessage =
    'Necesito permiso de la cámara para esto. Puedes escribirlo en su lugar.';

sealed class LabelCaptureState {
  const LabelCaptureState();
}

class LabelCaptureIdle extends LabelCaptureState {
  const LabelCaptureIdle();
}

class LabelCaptureLoading extends LabelCaptureState {
  const LabelCaptureLoading();
}

class LabelCaptureSuccess extends LabelCaptureState {
  final LabelExtractionDto extraction;

  const LabelCaptureSuccess(this.extraction);
}

class LabelCaptureError extends LabelCaptureState {
  final String message;

  const LabelCaptureError(this.message);
}

final imagePickerServiceProvider = Provider<ImagePickerService>(
  (ref) => PluginImagePickerService(),
);

final cameraPermissionProvider = Provider<CameraPermission>(
  (ref) => SystemCameraPermission(),
);

/// SPEC-004 R1, R2, R7, R9: pide permiso, toma/elige la foto (ya
/// redimensionada por [ImagePickerService], R10) y llama a `extractLabel`.
/// `mime_type` siempre `image/jpeg`: `image_picker` re-codifica a JPEG en
/// cuanto se pide `imageQuality` (que siempre se pide, ver R10).
class LabelCaptureController extends Notifier<LabelCaptureState> {
  @override
  LabelCaptureState build() => const LabelCaptureIdle();

  Future<void> captureFromCamera() => _capture(
    (picker) => picker.pickFromCamera(),
    requiresCameraPermission: true,
  );

  Future<void> captureFromGallery() => _capture(
    (picker) => picker.pickFromGallery(),
    requiresCameraPermission: false,
  );

  Future<void> _capture(
    Future<Uint8List?> Function(ImagePickerService picker) pick, {
    required bool requiresCameraPermission,
  }) async {
    if (requiresCameraPermission) {
      final hasPermission = await ref
          .read(cameraPermissionProvider)
          .ensureGranted();
      // SPEC-033: con un provider autoDispose, la persona puede salir de la
      // pantalla mientras esperamos; escribir el estado lanzaría un error.
      if (!ref.mounted) return;
      if (!hasPermission) {
        state = const LabelCaptureError(_noCameraPermissionMessage);
        return;
      }
    }

    final bytes = await pick(ref.read(imagePickerServiceProvider));
    if (!ref.mounted) return;
    if (bytes == null) {
      // El usuario canceló el selector: sin error, vuelve al estado inicial.
      state = const LabelCaptureIdle();
      return;
    }

    state = const LabelCaptureLoading();
    try {
      final extraction = await ref
          .read(aiClientProvider)
          .extractLabel(
            imageBase64: base64Encode(bytes),
            mimeType: 'image/jpeg',
          );
      if (!ref.mounted) return;
      state = LabelCaptureSuccess(extraction);
    } on AiClientException catch (error) {
      if (!ref.mounted) return;
      state = LabelCaptureError(error.userMessage);
    }
  }

  void reset() => state = const LabelCaptureIdle();
}

final labelCaptureControllerProvider =
    NotifierProvider<LabelCaptureController, LabelCaptureState>(
      LabelCaptureController.new,
    );

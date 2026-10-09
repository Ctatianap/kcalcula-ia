import 'dart:typed_data';

import 'package:calorias_ia/features/capture/camera_permission.dart';
import 'package:calorias_ia/features/capture/image_picker_service.dart';

class FakeCameraPermission implements CameraPermission {
  final bool granted;

  FakeCameraPermission({this.granted = true});

  @override
  Future<bool> ensureGranted() async => granted;
}

/// Bytes de prueba deterministas — no importa el contenido real de la
/// imagen, solo que `LabelCaptureController` los pase tal cual a
/// `AiClient.extractLabel` (base64Encode de lo que sea).
final fakeImageBytes = Uint8List.fromList([1, 2, 3, 4]);

class FakeImagePickerService implements ImagePickerService {
  final Uint8List? cameraResult;
  final Uint8List? galleryResult;

  FakeImagePickerService({this.cameraResult, this.galleryResult});

  @override
  Future<Uint8List?> pickFromCamera() async => cameraResult;

  @override
  Future<Uint8List?> pickFromGallery() async => galleryResult;
}

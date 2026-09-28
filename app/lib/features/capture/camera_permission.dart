import 'package:permission_handler/permission_handler.dart';

/// Detrás de una interfaz propia por la misma razón que
/// [MicrophonePermission] (SPEC-002).
abstract class CameraPermission {
  Future<bool> ensureGranted();
}

class SystemCameraPermission implements CameraPermission {
  @override
  Future<bool> ensureGranted() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;
    final result = await Permission.camera.request();
    return result.isGranted;
  }
}

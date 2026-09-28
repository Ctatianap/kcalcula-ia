import 'package:permission_handler/permission_handler.dart';

/// Detrás de una interfaz propia por la misma razón que [SpeechRecognizer]:
/// `permission_handler` también usa canales de plataforma, no se puede
/// simular directamente en un test de widget.
abstract class MicrophonePermission {
  Future<bool> ensureGranted();
}

class SystemMicrophonePermission implements MicrophonePermission {
  @override
  Future<bool> ensureGranted() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    final result = await Permission.microphone.request();
    return result.isGranted;
  }
}

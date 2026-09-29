import 'package:share_plus/share_plus.dart';

/// SPEC-006 R7: detrás de una interfaz propia por la misma razón que
/// [ImagePickerService] (SPEC-004): `share_plus` usa canales de plataforma
/// (el share sheet nativo del SO), no se puede simular directamente en un
/// test de widget.
abstract class SharingService {
  /// Entrega el archivo en `path` al mecanismo de compartir del sistema
  /// operativo. El destino final (guardar, enviar por correo, etc.) lo
  /// elige el usuario en ese momento — la app nunca decide ni transmite el
  /// archivo por su cuenta (R7).
  Future<void> shareFile(String path, {String? subject});
}

class PluginSharingService implements SharingService {
  @override
  Future<void> shareFile(String path, {String? subject}) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path)], subject: subject),
    );
  }
}

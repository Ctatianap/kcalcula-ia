import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// SPEC-004 R10: se redimensiona/comprime en el dispositivo antes de
/// enviar — `image_picker` lo hace nativamente vía `maxWidth`/`maxHeight`/
/// `imageQuality` (re-codifica a JPEG en ese proceso, tanto en Android como
/// en iOS), sin necesitar un paquete de procesamiento de imágenes aparte.
const labelImageMaxDimension = 1600.0;
const labelImageQuality = 85;

/// Detrás de una interfaz propia por la misma razón que `SpeechRecognizer`
/// (SPEC-002): `image_picker` usa canales de plataforma, no se puede
/// simular directamente en un test de widget.
abstract class ImagePickerService {
  Future<Uint8List?> pickFromCamera();
  Future<Uint8List?> pickFromGallery();
}

class PluginImagePickerService implements ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<Uint8List?> pickFromCamera() => _pick(ImageSource.camera);

  @override
  Future<Uint8List?> pickFromGallery() => _pick(ImageSource.gallery);

  Future<Uint8List?> _pick(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: labelImageMaxDimension,
      maxHeight: labelImageMaxDimension,
      imageQuality: labelImageQuality,
    );
    if (file == null) return null;
    return file.readAsBytes();
  }
}

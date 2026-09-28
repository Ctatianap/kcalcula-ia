import 'dart:typed_data';

import 'package:calorias_ia/features/capture/image_picker_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

/// AC10: verifica que `PluginImagePickerService` de verdad le pide al
/// plugin que redimensione/comprima (R10) — no se puede verificar el
/// tamaño real de la imagen resultante sin decodificarla (fuera de alcance
/// de un test unitario), pero sí que los parámetros correctos llegan a la
/// interfaz de plataforma, que es lo que dispara el redimensionado nativo.
class _RecordingImagePickerPlatform extends ImagePickerPlatform {
  ImagePickerOptions? lastOptions;
  ImageSource? lastSource;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    lastSource = source;
    lastOptions = options;
    return XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'test.jpg');
  }
}

void main() {
  test(
    'labelImageMaxDimension/labelImageQuality no cambian sin darse cuenta',
    () {
      expect(labelImageMaxDimension, 1600.0);
      expect(labelImageQuality, 85);
    },
  );

  test(
    'pickFromCamera pide maxWidth/maxHeight/imageQuality al plugin',
    () async {
      final platform = _RecordingImagePickerPlatform();
      ImagePickerPlatform.instance = platform;

      await PluginImagePickerService().pickFromCamera();

      expect(platform.lastSource, ImageSource.camera);
      expect(platform.lastOptions?.maxWidth, labelImageMaxDimension);
      expect(platform.lastOptions?.maxHeight, labelImageMaxDimension);
      expect(platform.lastOptions?.imageQuality, labelImageQuality);
    },
  );

  test(
    'pickFromGallery pide los mismos parámetros de redimensionado',
    () async {
      final platform = _RecordingImagePickerPlatform();
      ImagePickerPlatform.instance = platform;

      await PluginImagePickerService().pickFromGallery();

      expect(platform.lastSource, ImageSource.gallery);
      expect(platform.lastOptions?.maxWidth, labelImageMaxDimension);
    },
  );
}

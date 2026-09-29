import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../infra/sharing/sharing_service.dart';
import '../../infra/storage/storage_repository.dart';

/// R5, R7, R8: las tres acciones de Ajustes que tocan datos del usuario. La
/// confirmación ("¿seguro?") es responsabilidad de la pantalla (diálogo),
/// no de este controller — aquí solo vive lo que pasa una vez confirmado.
class SettingsController extends ChangeNotifier {
  final StorageRepository _storage;
  final SharingService _sharing;
  final String _exportDirectoryPath;

  bool busy = false;

  SettingsController({
    required StorageRepository storage,
    required SharingService sharing,
    required String exportDirectoryPath,
  })
    // ignore: prefer_initializing_formals
    : _storage = storage,
       // ignore: prefer_initializing_formals
       _sharing = sharing,
       // ignore: prefer_initializing_formals
       _exportDirectoryPath = exportDirectoryPath;

  Future<void> deleteAllData() => _run(_storage.deleteAllUserData);

  Future<void> revokeConsent() => _run(_storage.revokeConsent);

  /// R7/AC7-AC9: arma el JSON, lo escribe a un archivo local (no
  /// permanente, vive en el directorio de exportación) y lo entrega al
  /// servicio de compartir — el destino final lo elige el usuario ahí.
  Future<void> exportData() => _run(() async {
    final json = await _storage.exportUserData();
    final jsonText = const JsonEncoder.withIndent('  ').convert(json);
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File(
      '$_exportDirectoryPath/calorias_ia_export_$timestamp.json',
    );
    await file.writeAsString(jsonText);
    await _sharing.shareFile(file.path, subject: 'Mis datos de Calorías IA');
  });

  Future<void> _run(Future<void> Function() action) async {
    busy = true;
    notifyListeners();
    try {
      await action();
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}

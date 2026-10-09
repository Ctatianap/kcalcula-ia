import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;

/// `catalog.db` viaja empaquetado como asset (solo lectura); `sqlite3`
/// necesita una ruta de archivo real, así que se copia una vez a un
/// directorio con permisos de escritura y se reutiliza en los arranques
/// siguientes.
Future<String> ensureCatalogDbFile(String writableDirPath) async {
  final file = File('$writableDirPath/catalog.db');
  final bytes = await rootBundle.load('assets/catalog/catalog.db');
  if (!file.existsSync() || file.lengthSync() != bytes.lengthInBytes) {
    await file.writeAsBytes(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      flush: true,
    );
  }
  return file.path;
}

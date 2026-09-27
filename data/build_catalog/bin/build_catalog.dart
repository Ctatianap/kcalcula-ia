import 'dart:io';

import 'package:build_catalog/build.dart';

void main(List<String> args) {
  const curatedDir = 'data/curated';
  const outputDbPath = 'app/assets/catalog/catalog.db';

  // El script se ejecuta desde data/build_catalog/ (dart run) o desde la
  // raíz del repo; resuelve la ruta relativa a la raíz en ambos casos.
  final root = Directory.current.path.endsWith('data/build_catalog')
      ? Directory.current.parent.parent.path
      : Directory.current.path;

  try {
    final report = buildCatalog(
      curatedDir: '$root/$curatedDir',
      outputDbPath: '$root/$outputDbPath',
    );
    stdout.write(report);
  } on CatalogValidationError catch (e) {
    stderr.writeln(e);
    exitCode = 1;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'infra/catalog/catalog_asset_loader.dart';
import 'infra/catalog/catalog_providers.dart';
import 'infra/catalog/catalog_repository.dart';
import 'infra/sharing/sharing_providers.dart';
import 'infra/storage/app_database.dart';
import 'infra/storage/storage_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final docsDir = await getApplicationDocumentsDirectory();
  final db = AppDatabase(AppDatabase.openFile('${docsDir.path}/user.db'));

  final catalogDbPath = await ensureCatalogDbFile(docsDir.path);
  final catalog = CatalogRepository.openFile(catalogDbPath);

  // SPEC-006 R7: directorio de escritura para el JSON de "Exportar mis
  // datos" antes de pasarlo al share sheet — temporal, no `user.db`.
  final tempDir = await getTemporaryDirectory();

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        catalogRepositoryProvider.overrideWithValue(catalog),
        exportDirectoryPathProvider.overrideWithValue(tempDir.path),
      ],
      child: const MyApp(),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'infra/catalog/catalog_asset_loader.dart';
import 'infra/catalog/catalog_providers.dart';
import 'infra/catalog/catalog_repository.dart';
import 'infra/storage/app_database.dart';
import 'infra/storage/storage_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final docsDir = await getApplicationDocumentsDirectory();
  final db = AppDatabase(AppDatabase.openFile('${docsDir.path}/user.db'));

  final catalogDbPath = await ensureCatalogDbFile(docsDir.path);
  final catalog = CatalogRepository.openFile(catalogDbPath);

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        catalogRepositoryProvider.overrideWithValue(catalog),
      ],
      child: const MyApp(),
    ),
  );
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'storage_repository.dart';

/// Se sobrescribe en `main()` con la base de datos real de `user.db`
/// (requiere resolver el directorio de documentos, que es async — por eso
/// no se abre aquí directamente). Los tests de widgets la sobrescriben con
/// una base de datos temporal.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
    'appDatabaseProvider debe sobrescribirse en ProviderScope (main() o tests).',
  );
});

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository(ref.watch(appDatabaseProvider));
});

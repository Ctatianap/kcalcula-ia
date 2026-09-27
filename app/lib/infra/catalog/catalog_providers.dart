import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'catalog_repository.dart';

/// Se sobrescribe en `main()` con `catalog.db` real (empaquetado en
/// `app/assets/catalog/`, generado por `data/build_catalog`). Los tests la
/// sobrescriben con un catálogo de fixtures.
final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  throw UnimplementedError(
    'catalogRepositoryProvider debe sobrescribirse en ProviderScope (main() o tests).',
  );
});

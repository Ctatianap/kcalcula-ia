import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sharing_service.dart';

final sharingServiceProvider = Provider<SharingService>((ref) {
  return PluginSharingService();
});

/// Directorio donde `SettingsController.exportData()` escribe el JSON antes
/// de pasarlo al share sheet. Se sobrescribe en `main()` con
/// `getTemporaryDirectory()` (async, por eso no se resuelve aquí
/// directamente — mismo patrón que `appDatabaseProvider`). Los tests lo
/// sobrescriben con un directorio temporal propio.
final exportDirectoryPathProvider = Provider<String>((ref) {
  throw UnimplementedError(
    'exportDirectoryPathProvider debe sobrescribirse en ProviderScope (main() o tests).',
  );
});

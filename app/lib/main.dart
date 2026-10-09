import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'ui/licenses.dart';
import 'infra/ai_client/ai_client.dart';
import 'infra/ai_client/ai_client_providers.dart';
import 'infra/catalog/catalog_asset_loader.dart';
import 'infra/catalog/catalog_providers.dart';
import 'infra/catalog/catalog_repository.dart';
import 'infra/crash_reporting/crash_reporter.dart';
import 'infra/crash_reporting/crash_reporting_providers.dart';
import 'infra/sharing/sharing_providers.dart';
import 'infra/storage/app_database.dart';
import 'infra/storage/storage_providers.dart';

/// Misma región que `functions/src/index.ts` (SPEC-007 R2).
const _functionsRegion = 'us-east1';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SPEC-007 R1: primera conexión real a Firebase (`kcalcula-ia-dev`),
  // generado por `flutterfire configure` — ver Checklist de beta de
  // SPEC-007.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // SPEC-007 R3/AC14/PV-08: proveedor de depuración en debug, real en
  // release — decidido en tiempo de compilación (`kDebugMode`), nunca por
  // una variable de entorno que pudiera quedar mal puesta (Firebase
  // advierte que el proveedor de depuración en una build de release
  // expone el backend a dispositivos no verificados).
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? const AppleDebugProvider()
        : const AppleAppAttestWithDeviceCheckFallbackProvider(),
  );

  // SPEC-007 R4: la recolección arranca desactivada — solo `_RootGate` la
  // activa, y solo tras confirmar consentimiento vigente (ver app.dart).
  // SPEC-009 R1: los errores de `user.db` se reportan sin su mensaje.
  final CrashReporter crashReporter = SanitizingCrashReporter(
    FirebaseCrashReporter(),
  );
  try {
    await crashReporter.setCollectionEnabled(false);
  } catch (_) {
    // AC12: un fallo aquí no debe impedir que la app arranque.
  }
  FlutterError.onError = crashReporter.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    crashReporter.recordError(error, stack);
    return true;
  };

  final docsDir = await getApplicationDocumentsDirectory();
  final db = AppDatabase(AppDatabase.openFile('${docsDir.path}/user.db'));

  final catalogDbPath = await ensureCatalogDbFile(docsDir.path);
  final catalog = CatalogRepository.openFile(catalogDbPath);

  // SPEC-006 R7: directorio de escritura para el JSON de "Exportar mis
  // datos" antes de pasarlo al share sheet — temporal, no `user.db`.
  final tempDir = await getTemporaryDirectory();

  // SPEC-010 R2: licencia de la fuente embebida (OFL 1.1).
  registerFontLicenses();

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        catalogRepositoryProvider.overrideWithValue(catalog),
        exportDirectoryPathProvider.overrideWithValue(tempDir.path),
        crashReporterProvider.overrideWithValue(crashReporter),
        aiClientProvider.overrideWithValue(
          AiClient.firebase(
            FirebaseFunctions.instanceFor(region: _functionsRegion),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

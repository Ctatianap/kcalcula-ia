import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'crash_reporter.dart';

/// Se sobrescribe en `main()` con `FirebaseCrashReporter()` una vez
/// inicializado Firebase (SPEC-007 R1, pendiente de `flutterfire
/// configure` — ver Checklist de beta de la SPEC). Los tests la
/// sobrescriben con un fake.
final crashReporterProvider = Provider<CrashReporter>((ref) {
  throw UnimplementedError(
    'crashReporterProvider debe sobrescribirse en ProviderScope (main() o tests).',
  );
});

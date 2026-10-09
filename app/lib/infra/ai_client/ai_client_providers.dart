import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_client.dart';

/// Se sobrescribe en `main()` con `AiClient.firebase(...)` una vez
/// inicializado Firebase (requiere `firebase_options.dart` de
/// `flutterfire configure`, pendiente en el checklist de cuentas). Los
/// tests la sobrescriben con un caller fake.
final aiClientProvider = Provider<AiClient>((ref) {
  throw UnimplementedError(
    'aiClientProvider debe sobrescribirse en ProviderScope (main() o tests).',
  );
});

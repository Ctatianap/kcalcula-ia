import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_routes.dart';
import 'features/capture/capture_screen.dart';
import 'features/diary/diary_screen.dart';
import 'features/legal/privacy_policy_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/review/review_screen.dart';
import 'features/settings/settings_screen.dart';
import 'infra/ai_client/parsed_meal_dto.dart';
import 'infra/crash_reporting/crash_reporting_providers.dart';
import 'infra/legal/privacy_policy.dart';
import 'infra/storage/storage_providers.dart';

/// Raíz de composición: es el único lugar que conoce las features y las
/// conecta por nombre de ruta (`app_routes.dart`). Las features nunca se
/// importan entre sí.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KCalcula IA',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: AppRoutes.diary,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.capture:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const CaptureScreen(),
            );
          case AppRoutes.review:
            final parsedMeal = settings.arguments as ParsedMealDto;
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => ReviewScreen(parsedMeal: parsedMeal),
            );
          case AppRoutes.onboarding:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const OnboardingScreen(),
            );
          case AppRoutes.settings:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const SettingsScreen(),
            );
          case AppRoutes.privacyPolicy:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const PrivacyPolicyScreen(),
            );
          default:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const _RootGate(),
            );
        }
      },
    );
  }
}

/// SPEC-006 R1/AC1/AC4, extendido por SPEC-007 R5: decide entre
/// `OnboardingScreen` y `DiaryScreen` según si existe un `ConsentRecord`
/// vigente en `user.db` — "vigente" ahora exige que `policyVersion`
/// coincida con la versión actual del código, no solo que exista la fila.
/// Un usuario que aceptó una versión anterior de la política (p. ej. antes
/// de sumar Crashlytics) vuelve a ver el onboarding, con el texto
/// actualizado, antes de seguir usando la app — no es un estado distinto
/// de "primer lanzamiento" (mismo criterio que revocar consentimiento,
/// SPEC-006 R8). La consulta es async (Drift), así que se resuelve una vez
/// en `initState` — mismo patrón que `ReviewScreen` cargando productos
/// personales antes de construir su controller.
class _RootGate extends ConsumerStatefulWidget {
  const _RootGate();

  @override
  ConsumerState<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends ConsumerState<_RootGate> {
  bool? _hasConsent;

  @override
  void initState() {
    super.initState();
    _checkConsent();
  }

  Future<void> _checkConsent() async {
    final storage = ref.read(storageRepositoryProvider);
    final state = await storage.getConsentState();
    final hasCurrentConsent =
        state != null && state.policyVersion == privacyPolicyVersion;
    // SPEC-007 R4/R5/AC12: el reporte de fallos nunca empieza antes de que
    // el usuario haya aceptado la versión vigente de la política. Un fallo
    // al activarlo (p. ej. sin red) no debe dejar la app entera colgada en
    // el spinner — se ignora y se sigue sin reporte de fallos esta sesión.
    if (hasCurrentConsent) {
      try {
        await ref.read(crashReporterProvider).setCollectionEnabled(true);
      } catch (_) {
        // Ver comentario arriba: no bloquea el resto de la app.
      }
    }
    if (!mounted) return;
    setState(() => _hasConsent = hasCurrentConsent);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasConsent == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _hasConsent! ? const DiaryScreen() : const OnboardingScreen();
  }
}

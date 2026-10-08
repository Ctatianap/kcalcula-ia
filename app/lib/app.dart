import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_routes.dart';
import 'features/goals/objective_screen.dart';
import 'features/history/history_screen.dart';
import 'features/progress/progress_screen.dart';
import 'features/goals/profile_screen.dart';
import 'features/capture/capture_screen.dart';
import 'features/capture/ingredient_label_screen.dart';
import 'features/diary/diary_screen.dart';
import 'features/legal/privacy_policy_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/review/meal_analysis_screen.dart';
import 'features/review/review_screen.dart';
import 'features/settings/export_screen.dart';
import 'features/settings/settings_screen.dart';
import 'infra/food_resolution/ingredient_label_result.dart';
import 'infra/ai_client/parsed_meal_dto.dart';
import 'infra/food_resolution/meal_draft.dart';
import 'infra/crash_reporting/crash_reporting_providers.dart';
import 'infra/legal/privacy_policy.dart';
import 'infra/storage/storage_providers.dart';
import 'infra/storage/storage_repository.dart';
import 'ui/theme.dart';

/// Raíz de composición: es el único lugar que conoce las features y las
/// conecta por nombre de ruta (`app_routes.dart`). Las features nunca se
/// importan entre sí.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KCalcula IA',
      // SPEC-010 R1: tema global del diseño "kcalcula ia UI".
      theme: buildAppTheme(),
      // SPEC-016: textos de Material (p. ej. el selector de fechas) en
      // español de Colombia.
      locale: const Locale('es', 'CO'),
      supportedLocales: const [Locale('es', 'CO'), Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      initialRoute: AppRoutes.diary,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.capture:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const CaptureScreen(),
            );
          case AppRoutes.review:
            // SPEC-004: etiqueta confirmada; SPEC-017: comida reciente.
            final arguments = settings.arguments;
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => arguments is MealDraft
                  ? ReviewScreen(draft: arguments)
                  : ReviewScreen(parsedMeal: arguments as ParsedMealDto),
            );
          case AppRoutes.ingredientLabel:
            // SPEC-033: etiqueta de un ingrediente; devuelve el resultado al
            // Detalle.
            return MaterialPageRoute<IngredientLabelResult>(
              settings: settings,
              builder: (_) => IngredientLabelScreen(
                ingredientName: settings.arguments as String,
              ),
            );
          case AppRoutes.analysis:
            final text = settings.arguments as String;
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => MealAnalysisScreen(text: text),
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
          case AppRoutes.profile:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const ProfileScreen(),
            );
          case AppRoutes.export:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const ExportScreen(),
            );
          case AppRoutes.objective:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const ObjectiveScreen(),
            );
          // SPEC-010 R4: las pestañas principales cambian sin animación.
          // Solo se llega aquí después de pasar el control de consentimiento
          // de `/` (_RootGate). No exponer `/today` a deep links sin repetir
          // ese control.
          case AppRoutes.today:
            return _tabRoute(settings, const DiaryScreen());
          case AppRoutes.history:
            // SPEC-013 R3: puede llegar con el día elegido en la semana de Hoy.
            return _tabRoute(
              settings,
              HistoryScreen(initialDay: settings.arguments as DateTime?),
            );
          case AppRoutes.progress:
            return _tabRoute(settings, const ProgressScreen());
          case AppRoutes.privacyPolicy:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const PrivacyPolicyScreen(),
            );
          default:
            return _tabRoute(settings, const _RootGate());
        }
      },
    );
  }
}

Route<void> _tabRoute(RouteSettings settings, Widget screen) =>
    PageRouteBuilder(
      settings: settings,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => screen,
    );

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

  /// SPEC-009 R4: la lectura del consentimiento falló.
  bool _readFailed = false;

  Future<void> _checkConsent() async {
    final storage = ref.read(storageRepositoryProvider);
    final ConsentRecordData? state;
    try {
      state = await storage.getConsentState();
    } catch (_) {
      if (mounted) setState(() => _readFailed = true);
      return;
    }
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
    if (_readFailed) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No pude leer tus datos. Intenta de nuevo.'),
              TextButton(
                onPressed: () {
                  setState(() => _readFailed = false);
                  _checkConsent();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_hasConsent == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _hasConsent! ? const DiaryScreen() : const OnboardingScreen();
  }
}

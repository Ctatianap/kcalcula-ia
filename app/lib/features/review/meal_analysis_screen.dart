import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_routes.dart';
import '../../infra/ai_client/ai_client_errors.dart';
import '../../infra/ai_client/ai_client_providers.dart';
import '../../infra/food_resolution/meal_draft.dart';
import '../../infra/catalog/catalog_providers.dart';
import '../../infra/clock.dart';
import '../../infra/storage/storage_providers.dart';
import '../../ui/components/k_card.dart';
import '../../ui/components/privacy_note.dart';
import '../../ui/theme.dart';
import 'meal_analysis_controller.dart';
import 'food_search_screen.dart';
import 'meal_detail_view.dart';

/// SPEC-012: "Analizando" → "Detalle de comida" o "Algo salió mal", para un
/// texto escrito o dictado. Se abre encima de "¿Qué comiste?", que conserva
/// el texto: Cancelar, Volver y Corregir solo cierran esta pantalla.
class MealAnalysisScreen extends ConsumerStatefulWidget {
  final String text;

  /// Solo para tests: duración de la pausa con los cuatro pasos marcados.
  final Duration? stepHold;

  const MealAnalysisScreen({super.key, required this.text, this.stepHold});

  @override
  ConsumerState<MealAnalysisScreen> createState() => _MealAnalysisScreenState();
}

class _MealAnalysisScreenState extends ConsumerState<MealAnalysisScreen> {
  late final MealAnalysisController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MealAnalysisController(
      text: widget.text,
      aiClient: ref.read(aiClientProvider),
      storage: ref.read(storageRepositoryProvider),
      catalog: ref.read(catalogRepositoryProvider),
      clock: ref.read(clockProvider),
      stepHold: widget.stepHold ?? const Duration(milliseconds: 300),
    );
    _controller.run();
  }

  @override
  void dispose() {
    _controller.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// SPEC-018 R4: desde el error, buscar a mano y abrir el detalle con ese
  /// alimento (en lugar de esta pantalla; Corregir sigue volviendo al texto).
  Future<void> _searchManually() async {
    final item = await pickFoodManually(context);
    if (item == null || !mounted) return;
    _controller.cancel();
    Navigator.of(context)
        .pushReplacementNamed(AppRoutes.review, arguments: MealDraft([item]));
  }

  void _back() {
    _controller.cancel();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => switch (_controller.state) {
        AnalysisInProgress(:final completedSteps) => AnalyzingView(
          text: widget.text,
          completedSteps: completedSteps,
          onCancel: _back,
        ),
        AnalysisFailed(:final message, :final isAiError, :final aiErrorType) =>
          AnalysisErrorView(
            message: message,
            isAiError: isAiError,
            aiErrorType: aiErrorType,
            onRetry: _controller.run,
            onBack: _back,
            onSearchManually: isAiError ? _searchManually : null,
          ),
        AnalysisReady(:final review) => MealDetailView(
          controller: review,
          onCorrect: _back,
        ),
      },
    );
  }
}

/// R2: lo que se envió y los cuatro pasos.
class AnalyzingView extends StatelessWidget {
  final String text;
  final int completedSteps;
  final VoidCallback onCancel;

  const AnalyzingView({
    super.key,
    required this.text,
    required this.completedSteps,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // El gesto de volver del sistema cierra la pantalla igual que Cancelar:
    // al desmontarse, el controller ignora la respuesta pendiente.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analizando'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            const LinearProgressIndicator(),
            const SizedBox(height: 20),
            KCard(
              color: KColors.surfaceSoft,
              child: Text(
                '“$text”',
                key: const Key('analysis-text'),
                style: textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 20),
            for (final (i, label) in analysisSteps.indexed)
              _StepRow(
                index: i,
                label: label,
                done: i < completedSteps,
                active: i == completedSteps,
              ),
            const SizedBox(height: 20),
            const PrivacyNote(),
            const SizedBox(height: 20),
            OutlinedButton(onPressed: onCancel, child: const Text('Cancelar')),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int index;
  final String label;
  final bool done;
  final bool active;

  const _StepRow({
    required this.index,
    required this.label,
    required this.done,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final Widget leading;
    if (done) {
      leading = Icon(
        Icons.check_circle,
        key: Key('analysis-step-done-$index'),
        color: KColors.accent,
      );
    } else if (active) {
      leading = const SizedBox(
        width: 24,
        height: 24,
        child: Padding(
          padding: EdgeInsets.all(3),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else {
      leading = const Icon(Icons.radio_button_unchecked, color: KColors.border);
    }
    return Semantics(
      label: done ? '$label: listo' : label,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: done || active ? KColors.text : KColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// R6 de "Algo salió mal": tres consejos.
const analysisErrorTips = [
  'Revisa tu conexión a internet.',
  'Describe cada alimento con su cantidad, por ejemplo "2 huevos y 1 arepa".',
  'Si es una foto, acércate a la tabla y busca buena luz.',
];

/// R6: título según la causa; solo una respuesta que no se entendió dice
/// "No pude entender tu comida".
String analysisErrorTitle(AiClientErrorType type) => switch (type) {
  AiClientErrorType.invalidOutput => 'No pude entender tu comida',
  AiClientErrorType.network => 'No pude conectarme',
  AiClientErrorType.appCheck ||
  AiClientErrorType.unknown => 'No pude analizar tu comida',
};

/// R6/R7: fallo de la IA o del parseo, con el mensaje específico.
class AnalysisErrorView extends StatelessWidget {
  final String message;
  final bool isAiError;
  final AiClientErrorType aiErrorType;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  /// SPEC-018 R4: "Buscar en la base manualmente" (solo si falló la IA).
  final VoidCallback? onSearchManually;

  const AnalysisErrorView({
    super.key,
    required this.message,
    required this.isAiError,
    this.aiErrorType = AiClientErrorType.unknown,
    required this.onRetry,
    required this.onBack,
    this.onSearchManually,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Algo salió mal'),
        leading: BackButton(onPressed: onBack),
      ),
      body: SafeArea(
        // No perezosa: todos los botones existen aunque no quepan.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: KColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.help_outline,
                    size: 48,
                    color: KColors.accent,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isAiError
                    ? analysisErrorTitle(aiErrorType)
                    : 'No pude leer tus datos',
                textAlign: TextAlign.center,
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                // Sin repetir el título en el error de lectura.
                isAiError ? message : 'Intenta de nuevo.',
                key: const Key('analysis-error-message'),
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: KColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'No se guardó nada en tu diario.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: KColors.textSecondary,
                ),
              ),
              if (isAiError) ...[
                const SizedBox(height: 20),
                KCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final tip in analysisErrorTips)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.lightbulb_outline,
                                size: 18,
                                color: KColors.accent,
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(tip)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
              if (onSearchManually != null) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onSearchManually,
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar en la base manualmente'),
                ),
              ],
              const SizedBox(height: 10),
              OutlinedButton(onPressed: onBack, child: const Text('Volver')),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infra/ai_client/label_extraction_dto.dart';
import '../../infra/food_resolution/ingredient_label_result.dart';
import '../../ui/theme.dart';
import 'capture_screen.dart';
import 'label_capture_controller.dart';
import 'label_confirmation_screen.dart';

/// SPEC-033: su propio controlador (no el de la pestaña Foto), porque
/// "¿Qué comiste?" puede seguir montada debajo y también escucha el
/// resultado de su lectura.
final ingredientLabelCaptureControllerProvider =
    NotifierProvider.autoDispose<LabelCaptureController, LabelCaptureState>(
      LabelCaptureController.new,
    );

/// SPEC-033 R2: foto de la etiqueta de un ingrediente del Detalle →
/// `extractLabel` → "Confirmar etiqueta" (invariante 2) → devuelve un
/// [IngredientLabelResult], o `null` si la persona sale sin guardar.
const writeValuesButtonLabel = 'Escribir los valores';

class IngredientLabelScreen extends ConsumerWidget {
  final String ingredientName;

  const IngredientLabelScreen({super.key, required this.ingredientName});

  /// SPEC-033 R8: "Confirmar etiqueta" vacía; vuelve al Detalle si se
  /// guarda.
  Future<void> _writeValues(BuildContext context) async {
    final navigator = Navigator.of(context);
    final result = await navigator.push<IngredientLabelResult>(
      MaterialPageRoute(
        builder: (_) => LabelConfirmationScreen(
          extraction: const LabelExtractionDto(unreadableFields: []),
          ingredientName: ingredientName,
          manualEntry: true,
        ),
      ),
    );
    if (result != null) navigator.pop(result);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ingredientLabelCaptureControllerProvider);
    final controller = ref.read(
      ingredientLabelCaptureControllerProvider.notifier,
    );

    ref.listen<LabelCaptureState>(ingredientLabelCaptureControllerProvider, (
      previous,
      next,
    ) async {
      if (next is! LabelCaptureSuccess) return;
      final navigator = Navigator.of(context);
      final result = await navigator.push<IngredientLabelResult>(
        MaterialPageRoute(
          builder: (_) => LabelConfirmationScreen(
            extraction: next.extraction,
            ingredientName: ingredientName,
          ),
        ),
      );
      if (result != null) {
        navigator.pop(result);
      } else {
        controller.reset();
      }
    });

    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Etiqueta del ingrediente')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            ingredientName,
            key: const Key('ingredient-label-name'),
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Toma la foto de la tabla nutricional de este producto. Lo '
            'guardamos en tus productos para que la próxima vez no necesites '
            'foto.',
            style: textTheme.bodyMedium?.copyWith(color: KColors.textSecondary),
          ),
          const SizedBox(height: 16),
          LabelPhotoPanel(
            labelState: state,
            onCamera: controller.captureFromCamera,
            onGallery: controller.captureFromGallery,
          ),
          const SizedBox(height: 16),
          // SPEC-033 R8: sin foto y sin IA.
          OutlinedButton.icon(
            key: const Key('ingredient-label-manual'),
            onPressed: state is LabelCaptureLoading
                ? null
                : () => _writeValues(context),
            icon: const Icon(Icons.edit_note),
            label: const Text(writeValuesButtonLabel),
          ),
          const SizedBox(height: 6),
          Text(
            'Si tienes la etiqueta a la vista, escribe los valores y no gastas '
            'una lectura de la IA.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: KColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

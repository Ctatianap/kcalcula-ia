import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_routes.dart';
import 'capture_controller.dart';
import 'label_capture_controller.dart';
import 'label_confirmation_screen.dart';
import 'voice_input_controller.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _analyze() {
    final text = _textController.text.trim();
    if (text.isEmpty || text.length > 500) return;
    ref.read(captureControllerProvider.notifier).analyze(text);
  }

  void _toggleListening(VoiceInputState voiceState) {
    final controller = ref.read(voiceInputControllerProvider.notifier);
    if (voiceState is VoiceInputListening) {
      controller.stopListening();
    } else {
      controller.startListening(existingText: _textController.text);
    }
  }

  /// R1: abre cámara o selector de galería.
  Future<void> _openPhotoSource() async {
    final source = await showModalBottomSheet<_PhotoSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, _PhotoSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(context, _PhotoSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final notifier = ref.read(labelCaptureControllerProvider.notifier);
    if (source == _PhotoSource.camera) {
      await notifier.captureFromCamera();
    } else {
      await notifier.captureFromGallery();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(captureControllerProvider);
    final voiceState = ref.watch(voiceInputControllerProvider);
    final labelState = ref.watch(labelCaptureControllerProvider);

    ref.listen<CaptureState>(captureControllerProvider, (previous, next) {
      if (next is CaptureSuccess) {
        Navigator.of(context)
            .pushNamed(AppRoutes.review, arguments: next.parsedMeal)
            .then((_) => ref.read(captureControllerProvider.notifier).reset());
      }
    });

    // R1/R2/R7: foto de etiqueta -> extractLabel -> pantalla de
    // confirmación (nunca directo a Revisar: primero el usuario confirma
    // los valores, invariante 2).
    ref.listen<LabelCaptureState>(labelCaptureControllerProvider, (
      previous,
      next,
    ) {
      if (next is LabelCaptureSuccess) {
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (_) =>
                    LabelConfirmationScreen(extraction: next.extraction),
              ),
            )
            .then(
              (_) => ref.read(labelCaptureControllerProvider.notifier).reset(),
            );
      }
    });

    // R4/R5/R9: la transcripción (parcial o final) rellena el mismo campo de
    // texto que se usa para escribir; sigue siendo editable en todo momento.
    ref.listen<VoiceInputState>(voiceInputControllerProvider, (previous, next) {
      final text = switch (next) {
        VoiceInputListening(:final text) => text,
        VoiceInputIdle(:final text?) => text,
        _ => null,
      };
      if (text != null) {
        _textController.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
        setState(() {});
      }
    });

    final isAnalyzingLabel = labelState is LabelCaptureLoading;
    final isLoading = state is CaptureLoading || isAnalyzingLabel;
    final isListening = voiceState is VoiceInputListening;
    final text = _textController.text.trim();
    final canAnalyze =
        !isLoading && !isListening && text.isNotEmpty && text.length <= 500;

    return Scaffold(
      appBar: AppBar(title: const Text('¿Qué comiste?')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _textController,
              maxLength: 500,
              minLines: 2,
              maxLines: 5,
              enabled: !isLoading,
              decoration: InputDecoration(
                hintText:
                    'Ej: dos huevos revueltos y una arepa pequeña con queso',
                border: const OutlineInputBorder(),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // R10: vaciar el campo para empezar de cero.
                    if (_textController.text.isNotEmpty && !isListening)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Borrar texto',
                        onPressed: isLoading
                            ? null
                            : () {
                                ref
                                    .read(voiceInputControllerProvider.notifier)
                                    .discardPendingResult();
                                setState(_textController.clear);
                              },
                      ),
                    IconButton(
                      icon: const Icon(Icons.camera_alt),
                      tooltip: 'Foto de etiqueta',
                      onPressed: isLoading ? null : _openPhotoSource,
                    ),
                    IconButton(
                      icon: Icon(isListening ? Icons.stop : Icons.mic),
                      tooltip: isListening ? 'Detener' : 'Hablar',
                      onPressed: isLoading
                          ? null
                          : () => _toggleListening(voiceState),
                    ),
                  ],
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (isListening)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Escuchando…'),
              ),
            if (isAnalyzingLabel)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Analizando foto…'),
              ),
            const SizedBox(height: 12),
            if (state is CaptureFailure)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  state.message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (voiceState is VoiceInputError)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  voiceState.message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (labelState is LabelCaptureError)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  labelState.message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            FilledButton(
              onPressed: canAnalyze ? _analyze : null,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Analizar'),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PhotoSource { camera, gallery }

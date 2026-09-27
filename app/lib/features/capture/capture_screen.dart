import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_routes.dart';
import 'capture_controller.dart';

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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(captureControllerProvider);

    ref.listen<CaptureState>(captureControllerProvider, (previous, next) {
      if (next is CaptureSuccess) {
        Navigator.of(context)
            .pushNamed(AppRoutes.review, arguments: next.parsedMeal)
            .then((_) => ref.read(captureControllerProvider.notifier).reset());
      }
    });

    final isLoading = state is CaptureLoading;
    final text = _textController.text.trim();
    final canAnalyze = !isLoading && text.isNotEmpty && text.length <= 500;

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
              decoration: const InputDecoration(
                hintText:
                    'Ej: dos huevos revueltos y una arepa pequeña con queso',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
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

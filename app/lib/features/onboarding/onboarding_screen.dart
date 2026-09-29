import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_routes.dart';
import '../../infra/storage/storage_providers.dart';
import 'onboarding_controller.dart';

/// R1/R2: se muestra antes que cualquier otra pantalla mientras no exista
/// un `ConsentRecord` en `user.db` (ver `_RootGate` en `app.dart`). AC12: el
/// texto de la casilla (b) nombra explícitamente el dato de salud, qué se
/// envía, a quién y para qué — exigencia de PV-07 (Ley 1581 Art. 6-7).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final OnboardingController _controller;
  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    _controller = OnboardingController(
      storage: ref.read(storageRepositoryProvider),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    setState(() => _accepting = true);
    try {
      await _controller.accept();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.diary);
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  void _openFullPolicy() {
    Navigator.of(context).pushNamed(AppRoutes.privacyPolicy);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Antes de empezar')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Cuéntame qué comiste. Yo me encargo del resto.',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Cuando escribes o fotografías algo, ese texto o esa foto '
                  'se envía a Vertex AI (un servicio de Google que procesa '
                  'fuera de Colombia) únicamente para convertirlo en datos '
                  'estructurados. La IA nunca calcula tus calorías ni '
                  'decide valores nutricionales — eso lo hace tu teléfono, '
                  'con una base de datos verificada. Tus comidas registradas '
                  'nunca salen de tu dispositivo.',
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _openFullPolicy,
                    child: const Text('Ver política de privacidad completa'),
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: _controller.ageConfirmed,
                  onChanged: (value) =>
                      _controller.setAgeConfirmed(value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Confirmo que soy mayor de 18 años'),
                ),
                CheckboxListTile(
                  value: _controller.consentGiven,
                  onChanged: (value) =>
                      _controller.setConsentGiven(value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'Autorizo el tratamiento de lo que escriba o fotografíe '
                    '(dato sensible de salud/nutrición) para que Vertex AI '
                    '(Google, fuera de Colombia) lo estructure — nunca para '
                    'calcular valores nutricionales.',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: (_controller.canContinue && !_accepting)
                      ? _accept
                      : null,
                  child: _accepting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continuar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

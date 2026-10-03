import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrition_core/nutrition_core.dart';

import '../../app_routes.dart';
import '../../infra/storage/storage_providers.dart';
import 'goal_calculation.dart';
import 'profile_controller.dart';

/// SPEC-008 R1–R5: "Mi perfil", con el punto de partida en vivo.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final ProfileController _controller;
  final _birthDate = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = ProfileController(
      storage: ref.read(storageRepositoryProvider),
    );
    _controller.load().then((_) {
      _birthDate.text = _controller.birthDateText;
      _height.text = _controller.heightText;
      _weight.text = _controller.weightText;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _birthDate.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final saved = await _controller.save();
    if (saved && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Perfil guardado.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const decimal = TextInputType.numberWithOptions(decimal: true);
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final c = _controller;
          if (!c.loaded) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Sexo (lo usa la fórmula)'),
              const SizedBox(height: 4),
              SegmentedButton<BiologicalSex>(
                segments: const [
                  ButtonSegment(
                    value: BiologicalSex.female,
                    label: Text('Femenino'),
                  ),
                  ButtonSegment(
                    value: BiologicalSex.male,
                    label: Text('Masculino'),
                  ),
                ],
                emptySelectionAllowed: true,
                selected: {?c.sex},
                onSelectionChanged: (s) {
                  if (s.isNotEmpty) c.setSex(s.first);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('profile-birth-date'),
                controller: _birthDate,
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(
                  labelText: 'Fecha de nacimiento (dd/mm/aaaa)',
                  helperText: c.age == null ? null : '${c.age} años',
                  errorText: c.birthDateError,
                ),
                onChanged: c.setBirthDate,
              ),
              TextField(
                key: const Key('profile-height'),
                controller: _height,
                keyboardType: decimal,
                decoration: InputDecoration(
                  labelText: 'Estatura (cm)',
                  errorText: c.heightError,
                ),
                onChanged: c.setHeight,
              ),
              TextField(
                key: const Key('profile-weight'),
                controller: _weight,
                keyboardType: decimal,
                decoration: InputDecoration(
                  labelText: 'Peso (kg)',
                  errorText: c.weightError,
                ),
                onChanged: c.setWeight,
              ),
              const SizedBox(height: 12),
              const Text('Nivel de actividad (cámbialo según la temporada)'),
              RadioGroup<ActivityLevel>(
                groupValue: c.activityLevel,
                onChanged: (v) {
                  if (v != null) c.setActivityLevel(v);
                },
                child: Column(
                  children: [
                    for (final level in ActivityLevel.values)
                      RadioListTile<ActivityLevel>(
                        contentPadding: EdgeInsets.zero,
                        value: level,
                        title: Text(activityLevelTexts[level]!.$1),
                        subtitle: Text(activityLevelTexts[level]!.$2),
                      ),
                  ],
                ),
              ),
              if (c.basalKcal != null) _StartingPoint(controller: c),
              if (c.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    c.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: c.canSave ? _save : null,
                child: const Text('Guardar perfil'),
              ),
              if (c.hasSavedProfile)
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.objective),
                  child: const Text('Elegir mi objetivo'),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// SPEC-008 R5/R14: metabolismo basal y mantenimiento.
class _StartingPoint extends StatelessWidget {
  final ProfileController controller;

  const _StartingPoint({required this.controller});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mi punto de partida', style: text.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Metabolismo basal: ${approxKcal(controller.basalKcal!)}',
              key: const Key('basal-kcal'),
            ),
            Text('Lo que tu cuerpo gasta en reposo.', style: text.bodySmall),
            const SizedBox(height: 8),
            Text(
              'Mantenimiento: ${approxKcal(controller.maintenanceKcal!)}',
              key: const Key('maintenance-kcal'),
            ),
            Text(
              'Lo que gastas en un día con tu nivel de actividad.',
              style: text.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(disclaimerText, style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}

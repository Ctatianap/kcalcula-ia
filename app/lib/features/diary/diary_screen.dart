import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrition_core/nutrition_core.dart';

import '../../app_routes.dart';
import '../../infra/storage/storage_providers.dart';
import 'diary_controller.dart';

const _mealTypeLabels = {
  'desayuno': 'Desayuno',
  'almuerzo': 'Almuerzo',
  'cena': 'Cena',
  'snack': 'Snack',
};

class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key});

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  late Future<DiarySummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _summaryFuture = loadDiarySummary(
      ref.read(storageRepositoryProvider),
      DateTime.now(),
    );
  }

  Future<void> _openCapture() async {
    await Navigator.of(context).pushNamed(AppRoutes.capture);
    setState(_reload);
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).pushNamed(AppRoutes.settings);
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hoy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Ajustes',
            onPressed: _openSettings,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCapture,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<DiarySummary>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final summary = snapshot.data!;
          if (summary.meals.isEmpty) {
            return const Center(child: Text('Todavía no registras nada hoy.'));
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Total del día: ${presentKcal(summary.dayTotals.energyKcal)} kcal',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: ListView(
                  children: summary.meals
                      .map((m) => _MealTile(summary: m))
                      .toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MealTile extends StatelessWidget {
  final DiaryMealSummary summary;

  const _MealTile({required this.summary});

  @override
  Widget build(BuildContext context) {
    final label = _mealTypeLabels[summary.meal.meal.mealType] ?? 'Snack';
    return ListTile(
      title: Text(label),
      subtitle: Text(summary.meal.items.map((i) => i.nameSnapshot).join(', ')),
      trailing: Text('${presentKcal(summary.totals.energyKcal)} kcal'),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrition_core/nutrition_core.dart';

import '../../app_routes.dart';
import '../../infra/ai_client/parsed_meal_dto.dart';
import '../../infra/catalog/catalog_providers.dart';
import '../../infra/storage/storage_providers.dart';
import 'review_controller.dart';
import 'review_item.dart';

const _gramsStep = 5.0;

const _confidenceLabels = {
  ConfidenceLevel.altaPrecision: 'Alta precisión',
  ConfidenceLevel.buenaEstimacion: 'Buena estimación',
  ConfidenceLevel.estimacion: 'Estimación',
};

const _mealTypeLabels = {
  'desayuno': 'Desayuno',
  'almuerzo': 'Almuerzo',
  'cena': 'Cena',
  'snack': 'Snack',
};

class ReviewScreen extends ConsumerStatefulWidget {
  final ParsedMealDto parsedMeal;

  const ReviewScreen({super.key, required this.parsedMeal});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  late ReviewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ReviewController(
      parsedMeal: widget.parsedMeal,
      catalog: ref.read(catalogRepositoryProvider),
      storage: ref.read(storageRepositoryProvider),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    await _controller.register();
    // Vuelve al diario (no solo a capturar): captura y revisión son un
    // flujo de una sola pasada, no una pila que el usuario recorra hacia
    // atrás ítem por ítem.
    if (mounted) {
      Navigator.of(context)
          .popUntil((route) => route.settings.name == AppRoutes.diary);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Revisar')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final items = _controller.items;
          if (items.isEmpty) {
            return const Center(
              child: Text('No encontré alimentos en lo que escribiste'),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) => _ReviewItemTile(
                    item: items[index],
                    onSelectCandidate: (foodId) =>
                        _controller.selectCandidate(index, foodId),
                    onRemove: () => _controller.removeItem(index),
                    onAdjustGrams: (delta) =>
                        _controller.setGrams(index, items[index].grams + delta),
                  ),
                ),
              ),
              _ReviewSummary(
                controller: _controller,
                onRegister: _controller.canRegister ? _register : null,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReviewItemTile extends StatelessWidget {
  final ReviewItem item;
  final void Function(String foodId) onSelectCandidate;
  final VoidCallback onRemove;
  final void Function(double delta) onAdjustGrams;

  const _ReviewItemTile({
    required this.item,
    required this.onSelectCandidate,
    required this.onRemove,
    required this.onAdjustGrams,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.mention, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            switch (item.status) {
              ReviewItemStatus.matched => _MatchedRow(
                item: item,
                onAdjustGrams: onAdjustGrams,
              ),
              ReviewItemStatus.ambiguous => _AmbiguousRow(
                item: item,
                onSelectCandidate: onSelectCandidate,
              ),
              ReviewItemStatus.notFound => _NotFoundRow(onRemove: onRemove),
            },
          ],
        ),
      ),
    );
  }
}

class _MatchedRow extends StatelessWidget {
  final ReviewItem item;
  final void Function(double delta) onAdjustGrams;

  const _MatchedRow({required this.item, required this.onAdjustGrams});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.highlightForEdit)
          Text(
            'Revisa la cantidad',
            style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
          ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => onAdjustGrams(-_gramsStep),
            ),
            Text('${item.grams.toStringAsFixed(0)} g'),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => onAdjustGrams(_gramsStep),
            ),
            const Spacer(),
            Text('${presentKcal(item.nutrients!.energyKcal)} kcal'),
          ],
        ),
        Chip(label: Text(_confidenceLabels[item.confidence]!)),
      ],
    );
  }
}

class _AmbiguousRow extends StatelessWidget {
  final ReviewItem item;
  final void Function(String foodId) onSelectCandidate;

  const _AmbiguousRow({required this.item, required this.onSelectCandidate});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: item.candidates
          .map(
            (candidate) => ActionChip(
              label: Text(candidate.nameEs),
              onPressed: () => onSelectCandidate(candidate.id),
            ),
          )
          .toList(),
    );
  }
}

class _NotFoundRow extends StatelessWidget {
  final VoidCallback onRemove;

  const _NotFoundRow({required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'No encontrado',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        const Spacer(),
        TextButton(onPressed: onRemove, child: const Text('Quitar')),
      ],
    );
  }
}

class _ReviewSummary extends StatelessWidget {
  final ReviewController controller;
  final VoidCallback? onRegister;

  const _ReviewSummary({required this.controller, required this.onRegister});

  @override
  Widget build(BuildContext context) {
    final totals = controller.mealTotals;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButton<String>(
            value: controller.mealType,
            items: _mealTypeLabels.entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) controller.setMealType(value);
            },
          ),
          Text(
            'Total: ${presentKcal(totals.energyKcal)} kcal',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          FilledButton(onPressed: onRegister, child: const Text('Registrar')),
        ],
      ),
    );
  }
}

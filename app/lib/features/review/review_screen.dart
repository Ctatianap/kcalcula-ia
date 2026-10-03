import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrition_core/nutrition_core.dart';

import '../../app_routes.dart';
import '../../infra/ai_client/parsed_meal_dto.dart';
import '../../infra/catalog/catalog_providers.dart';
import '../../infra/food_resolution/food_query_resolver.dart';
import '../../infra/storage/storage_providers.dart';
import '../../infra/storage/storage_repository.dart';
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

const registerErrorMessage = 'No pude guardar la comida. Intenta de nuevo.';
const readErrorMessage = 'No pude leer tus datos. Intenta de nuevo.';

class ReviewScreen extends ConsumerStatefulWidget {
  final ParsedMealDto parsedMeal;

  const ReviewScreen({super.key, required this.parsedMeal});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  // SPEC-009 R2/R4: errores de `user.db` con mensaje en español, sin
  // relanzar (el texto de SQLite trae los datos de la comida).
  bool _loadFailed = false;
  bool _registering = false;
  String? _registerError;

  ReviewController? _controller;

  @override
  void initState() {
    super.initState();
    _loadController();
  }

  /// SPEC-004 R7 (búsqueda integrada): los productos personales viven en
  /// `user.db` (Drift, async) — se cargan una vez aquí como una lista en
  /// memoria para que el resto de `ReviewController`/`FoodQueryResolver`
  /// siga siendo síncrono, igual que antes de esta SPEC.
  Future<void> _loadController() async {
    final storage = ref.read(storageRepositoryProvider);
    final List<PersonalProduct> personalProducts;
    try {
      personalProducts = await storage.getAllPersonalProducts();
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
      return;
    }
    if (!mounted) return;
    _loadFailed = false;
    setState(() {
      _controller = ReviewController(
        parsedMeal: widget.parsedMeal,
        resolver: FoodQueryResolver(
          catalog: ref.read(catalogRepositoryProvider),
          personalProducts: personalProducts,
        ),
        storage: storage,
      );
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      _registering = true;
      _registerError = null;
    });
    try {
      await _controller!.register();
    } catch (_) {
      if (mounted) {
        setState(() {
          _registering = false;
          _registerError = registerErrorMessage;
        });
      }
      return;
    }
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
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(title: const Text('Revisar')),
      body: _loadFailed
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(readErrorMessage),
                  TextButton(
                    onPressed: () {
                      setState(() => _loadFailed = false);
                      _loadController();
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : controller == null
          ? const Center(child: CircularProgressIndicator())
          : ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final items = controller.items;
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
                              controller.selectCandidate(index, foodId),
                          onRemove: () => controller.removeItem(index),
                          onAdjustGrams: (delta) => controller.setGrams(
                            index,
                            items[index].grams + delta,
                          ),
                        ),
                      ),
                    ),
                    if (_registerError != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _registerError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    _ReviewSummary(
                      controller: controller,
                      onRegister: controller.canRegister && !_registering
                          ? _register
                          : null,
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

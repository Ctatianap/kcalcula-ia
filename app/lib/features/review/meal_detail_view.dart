import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrition_core/nutrition_core.dart';

import '../../app_routes.dart';
import '../../infra/clock.dart';
import '../../ui/components/k_card.dart';
import '../../format/date_format_es.dart';
import '../../ui/theme.dart';
import 'review_controller.dart';
import 'review_item.dart';

const _gramsStep = 5.0;

const registerErrorMessage = 'No pude guardar la comida. Intenta de nuevo.';

const confidenceLabels = {
  ConfidenceLevel.altaPrecision: 'Alta precisión',
  ConfidenceLevel.buenaEstimacion: 'Buena estimación',
  ConfidenceLevel.estimacion: 'Estimación',
};

/// R4: cómo se obtuvo la cantidad de cada ingrediente.
String quantitySourceLabel(QuantityBasis? basis) => switch (basis) {
  QuantityBasis.explicitWeight ||
  QuantityBasis.unitPortion => 'Cantidad dicha por ti',
  QuantityBasis.label => 'De tu etiqueta',
  QuantityBasis.sizeDescriptor => 'Tamaño estimado · ajústalo',
  QuantityBasis.householdMeasure => 'Medida casera estimada · ajústala',
  QuantityBasis.defaultPortion || null => 'Porción estimada · ajústala',
};

/// "Huevo", "Huevo y arepa", "Huevo, arepa y queso".
String joinNamesEs(List<String> names) {
  if (names.length <= 1) return names.join();
  return '${names.sublist(0, names.length - 1).join(', ')} y ${names.last}';
}

String _itemName(ReviewItem item) => item.food?.nameEs ?? item.mention;

/// SPEC-012 R4/R5: "Detalle de comida". Lo usan tanto el análisis de texto
/// como la etiqueta confirmada (y más adelante Recientes y la búsqueda).
class MealDetailView extends ConsumerStatefulWidget {
  final ReviewController controller;

  /// "Corregir": vuelve a "¿Qué comiste?" con el texto.
  final VoidCallback onCorrect;

  const MealDetailView({
    super.key,
    required this.controller,
    required this.onCorrect,
  });

  @override
  ConsumerState<MealDetailView> createState() => _MealDetailViewState();
}

class _MealDetailViewState extends ConsumerState<MealDetailView> {
  late final DateTime _shownAt = ref.read(clockProvider)();
  bool _registering = false;
  String? _registerError;

  Future<void> _register() async {
    // Edge case: un doble toque no guarda dos veces.
    if (_registering) return;
    setState(() {
      _registering = true;
      _registerError = null;
    });
    try {
      await widget.controller.register(eatenAt: ref.read(clockProvider)());
    } catch (_) {
      // SPEC-009 R2: sin relanzar (el texto de SQLite trae la comida).
      if (mounted) {
        setState(() {
          _registering = false;
          _registerError = registerErrorMessage;
        });
      }
      return;
    }
    if (mounted) {
      // SPEC-010: siempre un Hoy recién cargado, aunque se haya registrado
      // desde Historial o Progreso.
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.today, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de comida')),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final items = controller.items;
          final text = Theme.of(context).textTheme;
          return Column(
            children: [
              Expanded(
                // Pocos ítems: se construyen todos (sin lista perezosa).
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        joinNamesEs(items.map(_itemName).toList()),
                        key: const Key('meal-detail-title'),
                        style: text.headlineMedium?.copyWith(fontSize: 26),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${timeEs(_shownAt)} · ${longDateEs(_shownAt)}',
                        style: text.bodyMedium?.copyWith(
                          color: KColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _TotalsCard(controller: controller),
                      if (controller.isFullyVerified) ...[
                        const SizedBox(height: 12),
                        const _VerifiedSeal(),
                      ],
                      const SizedBox(height: 20),
                      Text('Tipo de comida', style: text.titleMedium),
                      const SizedBox(height: 8),
                      _MealTypeSelector(
                        value: controller.mealType,
                        onChanged: controller.setMealType,
                      ),
                      const SizedBox(height: 20),
                      Text('Ingredientes', style: text.titleMedium),
                      const SizedBox(height: 8),
                      if (items.isEmpty)
                        const Text(
                          'Quitaste todos los alimentos. Toca "Corregir" para '
                          'escribir de nuevo.',
                          key: Key('meal-detail-empty'),
                          style: TextStyle(color: KColors.textSecondary),
                        ),
                      for (final (index, item) in items.indexed) ...[
                        _IngredientCard(
                          item: item,
                          onSelectCandidate: (foodId) =>
                              controller.selectCandidate(index, foodId),
                          onRemove: () => controller.removeItem(index),
                          onAdjustGrams: (delta) =>
                              controller.setGrams(index, item.grams + delta),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_registerError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            _registerError!,
                            style: const TextStyle(color: KColors.error),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _registering ? null : widget.onCorrect,
                              child: const Text('Corregir'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: controller.canRegister && !_registering
                                  ? _register
                                  : null,
                              child: const Text('Guardar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final ReviewController controller;

  const _TotalsCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final totals = controller.mealTotals;
    final confidence = controller.mealConfidenceLevel;
    // Como en Hoy: "~" salvo con Alta precisión.
    final approx =
        confidence == null || confidence == ConfidenceLevel.altaPrecision
        ? ''
        : '~';
    const secondary = TextStyle(fontSize: 14, color: KColors.textSecondary);
    return KCard(
      radius: 28,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$approx${formatThousandsEs(presentKcal(totals.energyKcal))} kcal',
            key: const Key('meal-detail-kcal'),
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w300,
              height: 1.1,
            ),
          ),
          if (confidence != null) ...[
            const SizedBox(height: 4),
            Text(confidenceLabels[confidence]!, style: secondary),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              Text(
                'P $approx${formatMacroEs(totals.proteinG)} g',
                style: secondary,
              ),
              Text(
                'C $approx${formatMacroEs(totals.carbsG)} g',
                style: secondary,
              ),
              Text(
                'G $approx${formatMacroEs(totals.fatG)} g',
                style: secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// R5: todos los ítems tienen fuente (catálogo o etiqueta confirmada).
class _VerifiedSeal extends StatelessWidget {
  const _VerifiedSeal();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        key: const Key('verified-seal'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: KColors.confirmBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_outlined, size: 18, color: KColors.confirmText),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                'Base verificada',
                style: TextStyle(
                  color: KColors.confirmText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// R4: botones en lugar del desplegable.
class _MealTypeSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _MealTypeSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final MapEntry(:key, value: label) in mealTypeLabels.entries)
          ChoiceChip(
            key: Key('meal-type-$key'),
            label: Text(label),
            selected: value == key,
            showCheckmark: false,
            selectedColor: KColors.accent,
            labelStyle: TextStyle(
              color: value == key ? KColors.background : KColors.text,
            ),
            onSelected: (_) => onChanged(key),
          ),
      ],
    );
  }
}

class _IngredientCard extends StatelessWidget {
  final ReviewItem item;
  final void Function(String foodId) onSelectCandidate;
  final VoidCallback onRemove;
  final void Function(double delta) onAdjustGrams;

  const _IngredientCard({
    required this.item,
    required this.onSelectCandidate,
    required this.onRemove,
    required this.onAdjustGrams,
  });

  @override
  Widget build(BuildContext context) {
    const secondary = TextStyle(fontSize: 13, color: KColors.textSecondary);
    return KCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _itemName(item),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text('“${item.mention}”', style: secondary),
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
    );
  }
}

class _MatchedRow extends StatelessWidget {
  final ReviewItem item;
  final void Function(double delta) onAdjustGrams;

  const _MatchedRow({required this.item, required this.onAdjustGrams});

  @override
  Widget build(BuildContext context) {
    final highlight = item.highlightForEdit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          quantitySourceLabel(item.basis),
          style: TextStyle(
            fontSize: 13,
            color: highlight ? KColors.accent : KColors.textSecondary,
            fontWeight: highlight ? FontWeight.w500 : FontWeight.w300,
          ),
        ),
        // Con texto grande, las kcal bajan a otra línea en vez de salirse.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: 'Menos',
                  onPressed: () => onAdjustGrams(-_gramsStep),
                ),
                Text('${item.grams.toStringAsFixed(0)} g'),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Más',
                  onPressed: () => onAdjustGrams(_gramsStep),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '${presentKcal(item.nutrients!.energyKcal)} kcal',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¿Cuál de estos?',
          style: TextStyle(fontSize: 13, color: KColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: item.candidates
              .map(
                (candidate) => ActionChip(
                  label: Text(candidate.nameEs),
                  onPressed: () => onSelectCandidate(candidate.id),
                ),
              )
              .toList(),
        ),
      ],
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
        const Expanded(
          child: Text(
            'No encontrado en la base',
            style: TextStyle(fontSize: 13, color: KColors.textSecondary),
          ),
        ),
        TextButton(onPressed: onRemove, child: const Text('Quitar')),
      ],
    );
  }
}

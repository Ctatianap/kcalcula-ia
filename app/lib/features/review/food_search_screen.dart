import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrition_core/nutrition_core.dart';

import '../../infra/catalog/catalog_providers.dart';
import '../../infra/catalog/catalog_repository.dart' show isSearchableQuery;
import '../../infra/catalog/food_match_result.dart';
import '../../infra/food_resolution/food_query_resolver.dart';
import '../../infra/food_resolution/meal_draft.dart';
import '../../infra/storage/storage_providers.dart';
import '../../ui/components/k_card.dart';
import '../../ui/number_input_es.dart';
import '../../ui/theme.dart';
import 'manual_quantity.dart';

const noSearchResultsMessage =
    'No encontré ese alimento. Prueba con otro nombre.';
const invalidAmountMessage = 'Escribe una cantidad mayor que 0.';

String _k(double v) => formatThousandsEs(presentKcal(v));

/// Abre "Buscar alimento" y devuelve el ítem elegido (o `null`).
Future<MealDraftItem?> pickFoodManually(BuildContext context) =>
    Navigator.of(context).push<MealDraftItem>(
      MaterialPageRoute(builder: (_) => const FoodSearchScreen()),
    );

/// SPEC-018 R1: búsqueda en el catálogo y en los productos personales, sin
/// IA. Todo es local.
class FoodSearchScreen extends ConsumerStatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  final _query = TextEditingController();
  FoodQueryResolver? _resolver;
  bool _loadFailed = false;

  /// Resultados calculados al escribir, no en cada `build`.
  List<FoodSearchHit> _hits = const [];

  void _search() {
    final resolver = _resolver;
    setState(
      () => _hits = resolver == null
          ? const []
          : resolver.search(_query.text.trim()),
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final products = await ref
          .read(storageRepositoryProvider)
          .getAllPersonalProducts();
      if (!mounted) return;
      setState(() {
        _loadFailed = false;
        _resolver = FoodQueryResolver(
          catalog: ref.read(catalogRepositoryProvider),
          personalProducts: products,
        );
      });
      _search();
    } catch (_) {
      // SPEC-009: sin el texto de SQLite.
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _choose(FoodSearchHit hit) async {
    final resolver = _resolver!;
    final food = resolver.getFoodById(hit.id);
    if (food == null) return;
    final item = await Navigator.of(context).push<MealDraftItem>(
      MaterialPageRoute(
        builder: (_) => QuantityPickerScreen(
          food: food,
          householdUnitMlByUnit: resolver.householdUnitMlByUnit(),
        ),
      ),
    );
    if (item != null && mounted) Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.text.trim();
    final hits = _hits;
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar alimento')),
      body: _loadFailed
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No pude leer tus datos. Intenta de nuevo.'),
                  TextButton(onPressed: _load, child: const Text('Reintentar')),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: TextField(
                    key: const Key('food-search-input'),
                    controller: _query,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      labelText: 'Alimento',
                      hintText: 'Ej: arepa, tinto, pollo',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => _search(),
                  ),
                ),
                Expanded(
                  child: !isSearchableQuery(query)
                      ? Padding(
                          padding: const EdgeInsets.all(20),
                          // El lector de pantalla anuncia los cambios.
                          child: Semantics(
                            liveRegion: true,
                            child: const Text(
                              'Escribe al menos 2 letras.',
                              style: TextStyle(color: KColors.textSecondary),
                            ),
                          ),
                        )
                      : hits.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: Semantics(
                            liveRegion: true,
                            child: const Text(noSearchResultsMessage),
                          ),
                        )
                      : ListView.builder(
                          itemCount: hits.length,
                          itemBuilder: (context, i) {
                            final hit = hits[i];
                            return ListTile(
                              key: Key('food-hit-${hit.id}'),
                              title: Text(hit.nameEs),
                              subtitle: Text(
                                '${_k(hit.energyKcal100g)} kcal por 100 g',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _choose(hit),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

/// SPEC-018 R2: cantidad con las porciones del catálogo o en gramos, con
/// la vista previa calculada en `nutrition_core`.
class QuantityPickerScreen extends StatefulWidget {
  final FoodCatalogEntry food;
  final Map<QuantityUnit, double> householdUnitMlByUnit;

  const QuantityPickerScreen({
    super.key,
    required this.food,
    required this.householdUnitMlByUnit,
  });

  @override
  State<QuantityPickerScreen> createState() => _QuantityPickerScreenState();
}

class _QuantityPickerScreenState extends State<QuantityPickerScreen> {
  late final List<QuantityOption> _options = quantityOptionsFor(
    widget.food,
    widget.householdUnitMlByUnit,
  );
  late QuantityOption _option = _options.first;
  late final _amount = TextEditingController(
    text: _amountText(_option.defaultAmount),
  );

  String _amountText(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : formatMacroEs(v);

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  MealDraftItem? get _item {
    final amount = parseDecimal(_amount.text);
    if (amount == null) return null;
    return manualDraftItem(
      widget.food,
      _option,
      amount,
      widget.householdUnitMlByUnit,
    );
  }

  String _optionLabel(QuantityOption o) {
    final grams = o.gramsPerUnit;
    return grams == null ? o.label : '${o.label} · ${formatMacroEs(grams)} g';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final item = _item;
    final nutrients = item == null
        ? null
        : calculateItemNutrients(widget.food, item.grams);
    final approx = item?.confidence == ConfidenceLevel.altaPrecision ? '' : '~';
    const secondary = TextStyle(fontSize: 14, color: KColors.textSecondary);
    return Scaffold(
      appBar: AppBar(title: const Text('Elegir cantidad')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.food.nameEs, style: text.headlineMedium),
              const SizedBox(height: 16),
              Text('Medida', style: text.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final o in _options)
                    ChoiceChip(
                      key: Key('quantity-option-${o.key}'),
                      label: Text(_optionLabel(o)),
                      selected: o == _option,
                      onSelected: (_) => setState(() {
                        _option = o;
                        _amount.text = _amountText(o.defaultAmount);
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('quantity-amount'),
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: _option.gramsPerUnit == null
                      ? 'Gramos'
                      : 'Cantidad',
                  errorText: item == null ? invalidAmountMessage : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              if (item != null && nutrients != null)
                KCard(
                  key: const Key('quantity-preview'),
                  color: KColors.surfaceSoft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${formatMacroEs(item.grams)} g · '
                        '$approx${_k(nutrients.energyKcal)} kcal',
                        key: const Key('quantity-preview-kcal'),
                        style: text.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'P $approx${formatMacroEs(nutrients.proteinG)} g · '
                        'C $approx${formatMacroEs(nutrients.carbsG)} g · '
                        'G $approx${formatMacroEs(nutrients.fatG)} g',
                        key: const Key('quantity-preview-macros'),
                        style: secondary,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: item == null
                    ? null
                    : () => Navigator.of(context).pop(item),
                child: const Text('Añadir'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

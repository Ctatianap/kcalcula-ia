import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrition_core/nutrition_core.dart';

import '../../format/text_es.dart';
import '../../infra/food_resolution/food_query_resolver.dart';
import '../../infra/storage/app_database.dart' show PersonalProduct;
import '../../infra/storage/storage_providers.dart';
import '../../ui/personal_products_texts.dart';
import '../../ui/theme.dart';

/// Lo que devuelve "Mis productos": el producto como alimento y su unidad
/// (SPEC-034 R5).
typedef PickedPersonalProduct = ({FoodCatalogEntry food, String servingUnit});

/// Abre "Mis productos" y devuelve el producto elegido (o `null`).
Future<PickedPersonalProduct?> pickPersonalProduct(BuildContext context) =>
    Navigator.of(context).push<PickedPersonalProduct>(
      MaterialPageRoute(builder: (_) => const PersonalProductPickerScreen()),
    );

/// SPEC-033 R4: solo los productos personales (SPEC-004), todos ordenados
/// por nombre y filtrados al escribir. Todo es local: sin IA (R6).
class PersonalProductPickerScreen extends ConsumerStatefulWidget {
  const PersonalProductPickerScreen({super.key});

  @override
  ConsumerState<PersonalProductPickerScreen> createState() =>
      _PersonalProductPickerScreenState();
}

class _PersonalProductPickerScreenState
    extends ConsumerState<PersonalProductPickerScreen> {
  final _query = TextEditingController();
  List<PersonalProduct>? _products;

  /// SPEC-035 R3: nombres alternativos por id de producto.
  Map<int, List<String>> _aliases = const {};
  bool _loadFailed = false;

  List<String> _aliasesOf(PersonalProduct p) => _aliases[p.id] ?? const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final storage = ref.read(storageRepositoryProvider);
      final products = await storage.getAllPersonalProducts();
      final aliases = await storage.getPersonalProductAliases();
      products.sort(
        (a, b) =>
            normalizeFoodText(a.nameEs).compareTo(normalizeFoodText(b.nameEs)),
      );
      if (mounted) {
        setState(() {
          _products = products;
          _aliases = aliases;
          _loadFailed = false;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    final products = _products;
    final query = normalizeFoodText(_query.text);
    final shown = products == null
        ? const <PersonalProduct>[]
        : [
            for (final p in products)
              if (query.isEmpty ||
                  normalizeFoodText(p.nameEs).contains(query) ||
                  _aliasesOf(p)
                      .any((a) => normalizeFoodText(a).contains(query)))
                p,
          ];
    return Scaffold(
      appBar: AppBar(title: const Text('Mis productos')),
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
          : products == null
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                noPersonalProductsMessage,
                key: Key('personal-products-empty'),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: TextField(
                    key: const Key('personal-product-search'),
                    controller: _query,
                    decoration: const InputDecoration(
                      labelText: 'Buscar en mis productos',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: shown.length,
                    itemBuilder: (context, i) {
                      final product = shown[i];
                      final food = personalProductToFoodCatalogEntry(product);
                      // Invariante 3: las kcal de una porción las calcula
                      // nutrition_core.
                      final kcal = calculateItemNutrients(
                        food,
                        product.servingGrams,
                      ).energyKcal;
                      final aliases = _aliasesOf(product);
                      return ListTile(
                        key: Key('personal-product-${product.id}'),
                        title: Text(product.nameEs),
                        subtitle: Text(
                          '1 porción = ${formatMacroEs(product.servingGrams)} ${product.servingUnit} · '
                          '${formatThousandsEs(presentKcal(kcal))} kcal'
                          '${aliases.isEmpty ? '' : '\nTambién: ${aliases.join(', ')}'}',
                          style: const TextStyle(color: KColors.textSecondary),
                        ),
                        isThreeLine: aliases.isNotEmpty,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(
                          context,
                        ).pop((food: food, servingUnit: product.servingUnit)),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

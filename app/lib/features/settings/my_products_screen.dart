import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrition_core/nutrition_core.dart';

import '../../format/text_es.dart';
import '../../infra/catalog/catalog_providers.dart';
import '../../infra/catalog/food_match_result.dart';
import '../../infra/food_resolution/food_query_resolver.dart';
import '../../infra/storage/app_database.dart' show PersonalProduct;
import '../../infra/storage/storage_providers.dart';
import '../../ui/personal_products_texts.dart';
import '../../ui/theme.dart';

/// SPEC-034 R1: el mismo texto que "Elegir de mis productos".
const noProductsMessage = noPersonalProductsMessage;
const productNameRequiredMessage = 'Escribe el nombre del producto.';
const aliasRequiredMessage = 'Escribe cómo lo llamas.';
const aliasRepeatedMessage = 'Ya tienes ese nombre.';
const tooManyAliasesMessage = 'Puedes guardar hasta 10 nombres.';
const productSaveErrorMessage =
    'No pude guardar los cambios. Intenta de nuevo.';
const productLoadErrorMessage = 'No pude leer tus productos. Intenta de nuevo.';
const productDeleteErrorMessage =
    'No pude borrar el producto. Intenta de nuevo.';

/// SPEC-034 R2: máximo de nombres alternativos por producto.
const maxAliases = 10;

/// SPEC-034 R2/AC9: nombre obligatorio.
String? validateProductName(String name) =>
    name.trim().isEmpty ? productNameRequiredMessage : null;

/// SPEC-034 R2/AC9: un alias nuevo no puede ser vacío, repetido (entre los
/// alias o igual al nombre, comparados normalizados) ni el número 11.
String? validateNewAlias(
  String term, {
  required List<String> current,
  required String productName,
}) {
  final normalized = normalizeFoodText(term);
  if (normalized.isEmpty) return aliasRequiredMessage;
  final taken = {
    normalizeFoodText(productName),
    for (final a in current) normalizeFoodText(a),
  };
  if (taken.contains(normalized)) return aliasRepeatedMessage;
  if (current.length >= maxAliases) return tooManyAliasesMessage;
  return null;
}

/// SPEC-034 R1: "Mis productos" desde Ajustes. Todo es local (R7).
class MyProductsScreen extends ConsumerStatefulWidget {
  const MyProductsScreen({super.key});

  @override
  ConsumerState<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends ConsumerState<MyProductsScreen> {
  final _query = TextEditingController();
  List<PersonalProduct>? _products;
  Map<int, List<String>> _aliases = const {};
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
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
      if (!mounted) return;
      setState(() {
        _products = products;
        _aliases = aliases;
        _loadFailed = false;
      });
    } catch (_) {
      // SPEC-009: sin el texto de SQLite.
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  Future<void> _edit(PersonalProduct product) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => EditProductScreen(
          product: product,
          aliases: _aliases[product.id] ?? const [],
        ),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final products = _products;
    final query = normalizeFoodText(_query.text);
    bool matches(PersonalProduct p) =>
        query.isEmpty ||
        normalizeFoodText(p.nameEs).contains(query) ||
        (_aliases[p.id] ?? const []).any(
          (a) => normalizeFoodText(a).contains(query),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Mis productos')),
      body: _loadFailed
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(productLoadErrorMessage),
                  TextButton(onPressed: _load, child: const Text('Reintentar')),
                ],
              ),
            )
          : products == null
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: Text(noProductsMessage, key: Key('my-products-empty')),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: TextField(
                    key: const Key('my-products-search'),
                    controller: _query,
                    decoration: const InputDecoration(
                      labelText: 'Buscar en mis productos',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      for (final product in products.where(matches))
                        _ProductTile(
                          product: product,
                          aliases: _aliases[product.id] ?? const [],
                          onTap: () => _edit(product),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final PersonalProduct product;
  final List<String> aliases;
  final VoidCallback onTap;

  const _ProductTile({
    required this.product,
    required this.aliases,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Invariante 3: las kcal de una porción las calcula nutrition_core.
    final kcal = calculateItemNutrients(
      personalProductToFoodCatalogEntry(product),
      product.servingGrams,
    ).energyKcal;
    final portion =
        '1 porción = ${formatMacroEs(product.servingGrams)} '
        '${product.servingUnit} · ${formatThousandsEs(presentKcal(kcal))} kcal';
    return ListTile(
      key: Key('my-product-${product.id}'),
      title: Text(product.nameEs),
      subtitle: Text(
        aliases.isEmpty ? portion : '$portion\nTambién: ${aliases.join(', ')}',
        style: const TextStyle(color: KColors.textSecondary),
      ),
      isThreeLine: aliases.isNotEmpty,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

/// SPEC-034 R2/R3: nombre, unidad, nombres alternativos y borrar.
class EditProductScreen extends ConsumerStatefulWidget {
  final PersonalProduct product;
  final List<String> aliases;

  const EditProductScreen({
    super.key,
    required this.product,
    required this.aliases,
  });

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  late final _name = TextEditingController(text: widget.product.nameEs);

  /// SPEC-025 R1.
  late final _brand = TextEditingController(text: widget.product.brand ?? '');
  final _newAlias = TextEditingController();
  late String _unit = widget.product.servingUnit;
  late final List<String> _aliases = [...widget.aliases];
  String? _nameError;
  String? _aliasError;
  String? _saveError;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _newAlias.dispose();
    super.dispose();
  }

  /// SPEC-034 edge case: un alias igual a un alimento del catálogo gana
  /// (R4); se avisa.
  /// Gana tanto si el catálogo tenía uno como varios alimentos para ese
  /// término.
  bool _shadowsCatalog(String term) =>
      ref.read(catalogRepositoryProvider).resolve(term) is! FoodNotFound;

  void _addAlias() {
    final term = _newAlias.text.trim();
    final error = validateNewAlias(
      term,
      current: _aliases,
      productName: _name.text,
    );
    setState(() {
      _aliasError = error;
      if (error == null) {
        _aliases.add(term);
        _newAlias.clear();
      }
    });
  }

  Future<void> _save() async {
    final nameError = validateProductName(_name.text);
    setState(() {
      _nameError = nameError;
      _saveError = null;
    });
    if (nameError != null) return;
    // Un nombre escrito sin tocar "+" no se pierde: se agrega (o se avisa).
    if (_newAlias.text.trim().isNotEmpty) {
      _addAlias();
      if (_aliasError != null) return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(storageRepositoryProvider)
          .updatePersonalProduct(
            id: widget.product.id,
            nameEs: _name.text.trim(),
            servingUnit: _unit,
            aliases: _aliases,
            brand: _brand.text,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      // SPEC-009: sin el texto de SQLite.
      if (mounted) setState(() => _saveError = productSaveErrorMessage);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final name = widget.product.nameEs;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Borrar «$name»?'),
        content: const Text('Las comidas que ya registraste no cambian.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(storageRepositoryProvider)
          .deletePersonalProduct(widget.product.id);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _saveError = productDeleteErrorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final shadowing = _aliases.where(_shadowsCatalog).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Editar producto')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            key: const Key('edit-product-name'),
            controller: _name,
            decoration: InputDecoration(
              labelText: 'Nombre',
              errorText: _nameError,
            ),
          ),
          const SizedBox(height: 12),
          // SPEC-025 R1.
          TextField(
            key: const Key('edit-product-brand'),
            controller: _brand,
            maxLength: 40,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Marca (opcional)',
              hintText: 'Ej: Alpina',
              helperText: 'Si dices la marca, usamos este producto.',
            ),
          ),
          const SizedBox(height: 4),
          Text('La porción se mide en', style: text.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'g', label: Text('g')),
              ButtonSegment(value: 'ml', label: Text('ml')),
            ],
            selected: {_unit},
            showSelectedIcon: false,
            onSelectionChanged: (value) => setState(() => _unit = value.single),
          ),
          const SizedBox(height: 20),
          Text('Así lo llamas', style: text.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Si escribes o dices uno de estos nombres, usamos este producto '
            'sin preguntarte.',
            style: text.bodySmall?.copyWith(color: KColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final alias in _aliases)
                InputChip(
                  key: Key('alias-$alias'),
                  label: Text(alias),
                  onDeleted: () => setState(() => _aliases.remove(alias)),
                  deleteButtonTooltipMessage: 'Quitar «$alias»',
                ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  key: const Key('edit-product-new-alias'),
                  controller: _newAlias,
                  decoration: InputDecoration(
                    labelText: 'Otro nombre (ej: mi pan)',
                    errorText: _aliasError,
                  ),
                  onSubmitted: (_) => _addAlias(),
                ),
              ),
              IconButton(
                key: const Key('edit-product-add-alias'),
                tooltip: 'Agregar nombre',
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _addAlias,
              ),
            ],
          ),
          for (final term in shadowing)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Cuando digas «$term» usaremos este producto.',
                style: text.bodySmall?.copyWith(color: KColors.accent),
              ),
            ),
          const SizedBox(height: 24),
          if (_saveError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _saveError!,
                style: const TextStyle(color: KColors.error),
              ),
            ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: const Text('Guardar cambios'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            key: const Key('edit-product-delete'),
            onPressed: _saving ? null : _delete,
            icon: const Icon(Icons.delete_outline, color: KColors.error),
            label: const Text(
              'Borrar producto',
              style: TextStyle(color: KColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

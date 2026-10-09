import 'package:nutrition_core/nutrition_core.dart';

import '../../format/text_es.dart';
import '../catalog/catalog_repository.dart';
import '../catalog/food_match_result.dart';
import '../storage/app_database.dart' show PersonalProduct;

/// SPEC-004 R7 (decisión del usuario: búsqueda integrada, no una lista
/// separada): `source_id` que marca un [FoodCatalogEntry] construido a
/// partir de un producto personal, nunca de `catalog.db`.
const personalProductSourceId = 'user_confirmed_label';

/// Prefijo del `id` de un producto personal dentro de un [FoodCatalogEntry],
/// para no colisionar con los ids del catálogo (que son slugs sin ":").
const personalProductIdPrefix = 'personal:';

bool isPersonalProductFood(FoodCatalogEntry food) =>
    food.sourceId == personalProductSourceId;

/// `null` si `id` no tiene el prefijo de producto personal.
int? personalProductIdFrom(String id) {
  if (!id.startsWith(personalProductIdPrefix)) return null;
  return int.tryParse(id.substring(personalProductIdPrefix.length));
}

FoodCatalogEntry personalProductToFoodCatalogEntry(PersonalProduct product) =>
    FoodCatalogEntry(
      id: '$personalProductIdPrefix${product.id}',
      nameEs: product.nameEs,
      sourceId: personalProductSourceId,
      sourceRef: product.sourceRef,
      energyKcal100g: product.energyKcal100,
      proteinG100g: product.proteinG100,
      carbsG100g: product.carbsG100,
      fatG100g: product.fatG100,
      densityGPerMl: product.densityGPerMl,
      portions: [
        PortionOption(
          descriptor: 'porcion',
          grams: product.servingGrams,
          sourceId: personalProductSourceId,
          sourceRef: product.sourceRef,
          isCuratedEstimate: false,
        ),
      ],
    );

/// Combina `catalog.db` (vía [CatalogRepository]) con los productos
/// personales del usuario bajo las mismas reglas `matched`/`ambiguous`/
/// `not_found` que ya existían solo para el catálogo (R8 de
/// `docs/architecture.md`). Los productos personales llegan ya resueltos en
/// memoria ([personalProducts], una lista pequeña) para que todo este
/// resolver sea síncrono, igual que [CatalogRepository.resolve] — quien lo
/// construye es responsable de recargar la lista si cambió (por ejemplo,
/// tras guardar un producto nuevo).
class FoodQueryResolver {
  final CatalogRepository _catalog;
  final List<PersonalProduct> _personalProducts;

  /// SPEC-034 R4: nombres alternativos por id de producto personal.
  final Map<int, List<String>> _aliases;

  const FoodQueryResolver({
    required CatalogRepository catalog,
    required List<PersonalProduct> personalProducts,
    Map<int, List<String>> aliases = const {},
  })
    // ignore: prefer_initializing_formals
    : _catalog = catalog,
       // ignore: prefer_initializing_formals
       _personalProducts = personalProducts,
       // ignore: prefer_initializing_formals
       _aliases = aliases;

  String get catalogVersion => _catalog.catalogVersion;

  Map<QuantityUnit, double> householdUnitMlByUnit() =>
      _catalog.householdUnitMlByUnit();

  List<FoodCatalogEntry> _matchingPersonalProducts(String foodQuery) {
    final normalized = normalizeFoodText(foodQuery);
    if (normalized.isEmpty) return const [];
    return _personalProducts
        .where((p) => normalizeFoodText(p.nameEs).contains(normalized))
        .map(personalProductToFoodCatalogEntry)
        .toList();
  }

  /// SPEC-034 R4: productos cuyo nombre o nombre alternativo es igual a la
  /// consulta (normalizados).
  List<FoodCatalogEntry> _exactPersonalProducts(String foodQuery) {
    final normalized = normalizeFoodText(foodQuery);
    if (normalized.isEmpty) return const [];
    bool isExact(PersonalProduct p) =>
        normalizeFoodText(p.nameEs) == normalized ||
        (_aliases[p.id] ?? const []).any(
          (term) => normalizeFoodText(term) == normalized,
        );
    return _personalProducts
        .where(isExact)
        .map(personalProductToFoodCatalogEntry)
        .toList();
  }

  /// SPEC-025 R2: palabras normalizadas de [text].
  static List<String> _words(String text) =>
      normalizeFoodText(text)
          .split(RegExp(r'[^a-z0-9]+'))
          .where((w) => w.isNotEmpty)
          .toList();

  /// Índice donde empieza [part] como palabras seguidas dentro de [words],
  /// o -1.
  static int _indexOfWords(List<String> words, List<String> part) {
    for (var i = 0; i + part.length <= words.length; i++) {
      var all = true;
      for (var j = 0; j < part.length; j++) {
        if (words[i + j] != part[j]) {
          all = false;
          break;
        }
      }
      if (all) return i;
    }
    return -1;
  }

  /// SPEC-025 R2: las marcas de mis productos que aparecen como palabra(s)
  /// completa(s) en [mention] o [foodQuery] (la más larga primero), cada una
  /// con el resto de la consulta sin la marca. Se omiten las que dejan el
  /// resto vacío.
  List<({String brand, List<String> rest})> _brandsIn(
    String foodQuery,
    String mention,
  ) {
    final brands =
        {
            for (final p in _personalProducts)
              if (p.brand case final b? when _words(b).isNotEmpty) b,
          }.toList()
          // La marca más larga primero ("Doña Arepa" antes que "Doña").
          ..sort((a, b) => _words(b).length.compareTo(_words(a).length));
    final queryWords = _words(foodQuery);
    final mentionWords = _words(mention);
    return [
      for (final brand in brands)
        if (_restWithout(queryWords, mentionWords, _words(brand))
            case final rest?)
          (brand: brand, rest: rest),
    ];
  }

  static List<String>? _restWithout(
    List<String> queryWords,
    List<String> mentionWords,
    List<String> brandWords,
  ) {
    final inQuery = _indexOfWords(queryWords, brandWords);
    if (inQuery < 0 && _indexOfWords(mentionWords, brandWords) < 0) {
      return null;
    }
    final rest = [...queryWords];
    if (inQuery >= 0) rest.removeRange(inQuery, inQuery + brandWords.length);
    return rest.isEmpty ? null : rest;
  }

  /// SPEC-025 R2: la primera marca dicha que tiene productos que
  /// coinciden, con ellos; `null` si ninguna.
  List<FoodCatalogEntry>? _brandMatches(String foodQuery, String mention) {
    for (final found in _brandsIn(foodQuery, mention)) {
      final ofBrand = _productsOfBrand(found.brand, found.rest);
      if (ofBrand.isNotEmpty) return ofBrand;
    }
    return null;
  }

  /// SPEC-025 R2: mis productos de [brand] cuyo nombre o nombre alternativo
  /// contiene, como comienzo de palabra, cada palabra de [rest].
  List<FoodCatalogEntry> _productsOfBrand(String brand, List<String> rest) {
    final query = rest.join(' ');
    final key = _words(brand).join(' ');
    return _personalProducts
        .where(
          (p) =>
              p.brand != null &&
              _words(p.brand!).join(' ') == key &&
              (matchesWordPrefixes(p.nameEs, query) ||
                  (_aliases[p.id] ?? const []).any(
                    (a) => matchesWordPrefixes(a, query),
                  )),
        )
        .map(personalProductToFoodCatalogEntry)
        .toList();
  }

  /// SPEC-025 R3: la marca de mis productos que se dijo sin que ninguno de
  /// ellos coincida, y lo que se buscó sin la marca; `null` si no aplica.
  ({String brand, String query})? brandWithoutProduct(
    String foodQuery,
    String mention,
  ) {
    if (_exactPersonalProducts(foodQuery).isNotEmpty) return null;
    final found = _brandsIn(foodQuery, mention);
    if (found.isEmpty || _brandMatches(foodQuery, mention) != null) {
      return null;
    }
    final first = found.first;
    final brandWords = _words(first.brand).toSet();
    final query = foodQuery
        .split(RegExp(r'\s+'))
        .where(
          (w) => w.isNotEmpty && !brandWords.contains(normalizeFoodText(w)),
        )
        .join(' ');
    return (brand: first.brand, query: query.isEmpty ? foodQuery : query);
  }

  /// SPEC-034 R5: "g" o "ml" de un producto personal; "g" para el resto.
  String servingUnitOf(String foodId) {
    final personalId = personalProductIdFrom(foodId);
    if (personalId == null) return 'g';
    for (final p in _personalProducts) {
      if (p.id == personalId) return p.servingUnit;
    }
    return 'g';
  }

  FoodMatchResult resolve(
    String foodQuery, {

    /// SPEC-025 R2: la frase del ítem, donde también puede venir la marca.
    String mention = '',
  }) {
    // SPEC-034 R4: el nombre exacto (o un alias) de un producto personal
    // gana sobre el catálogo; si son varios, se pregunta entre ellos.
    final exact = _exactPersonalProducts(foodQuery);
    if (exact.length == 1) return FoodMatched(exact.single);
    if (exact.length > 1) {
      return FoodAmbiguous(
        exact
            .map((f) => FoodCandidate(id: f.id, nameEs: f.nameEs))
            .take(3)
            .toList(),
      );
    }

    // SPEC-025 R2: la marca de mis productos dicha en la frase.
    final ofBrand = _brandMatches(foodQuery, mention);
    if (ofBrand != null) {
      if (ofBrand.length == 1) return FoodMatched(ofBrand.single);
      return FoodAmbiguous(
        ofBrand
            .map((f) => FoodCandidate(id: f.id, nameEs: f.nameEs))
            .take(3)
            .toList(),
      );
    }

    final catalogResult = _catalog.resolve(foodQuery);
    final personalMatches = _matchingPersonalProducts(foodQuery);

    if (catalogResult is FoodMatched) {
      if (personalMatches.isEmpty) return catalogResult;
      // Coincide exacto en el catálogo Y por nombre con algún producto
      // personal: no se elige por el usuario en silencio, se desambigua.
      return FoodAmbiguous(
        [
          FoodCandidate(
            id: catalogResult.food.id,
            nameEs: catalogResult.food.nameEs,
          ),
          ...personalMatches.map(
            (f) => FoodCandidate(id: f.id, nameEs: f.nameEs),
          ),
        ].take(3).toList(),
      );
    }

    final catalogCandidates = catalogResult is FoodAmbiguous
        ? catalogResult.candidates
        : const <FoodCandidate>[];
    final personalCandidates = personalMatches
        .map((f) => FoodCandidate(id: f.id, nameEs: f.nameEs))
        .toList();
    final combined = [...catalogCandidates, ...personalCandidates];

    if (combined.isEmpty) return FoodNotFound();
    if (combined.length == 1) {
      final food = getFoodById(combined.first.id);
      return food != null ? FoodMatched(food) : FoodNotFound();
    }
    return FoodAmbiguous(combined.take(3).toList());
  }

  /// SPEC-018 R1/AC6: catálogo y productos personales, hasta [limit] en
  /// total; los productos personales van primero. SPEC-035 R1: un producto
  /// también aparece si la consulta está en uno de sus nombres
  /// alternativos (una sola vez, con su nombre).
  List<FoodSearchHit> search(String query, {int limit = 20}) {
    if (!isSearchableQuery(query)) return const [];
    final normalized = normalizeFoodText(query);
    bool matches(PersonalProduct p) =>
        normalizeFoodText(p.nameEs).contains(normalized) ||
        (_aliases[p.id] ?? const []).any(
          (term) => normalizeFoodText(term).contains(normalized),
        );
    final personal = _personalProducts
        .where(matches)
        .map(
          (p) => FoodSearchHit(
            id: '$personalProductIdPrefix${p.id}',
            nameEs: p.nameEs,
            energyKcal100g: p.energyKcal100,
          ),
        );
    return [
      ...personal,
      ..._catalog.search(query, limit: limit),
    ].take(limit).toList();
  }

  FoodCatalogEntry? getFoodById(String id) {
    final personalId = personalProductIdFrom(id);
    if (personalId == null) return _catalog.getFoodById(id);
    final product = _personalProducts.where((p) => p.id == personalId).toList();
    if (product.isEmpty) return null;
    return personalProductToFoodCatalogEntry(product.first);
  }
}

import 'package:build_catalog/models.dart';
import 'package:build_catalog/validators.dart';
import 'package:test/test.dart';

FoodRow _food({
  String id = 'test-food',
  String nameEs = 'alimento de prueba',
  String sourceId = 'usda_fdc',
  String sourceRef = 'fixture de prueba',
  double energyKcal = 100,
  double proteinG = 10,
  double carbsG = 10,
  double fatG = 3.33, // 4*10 + 4*10 + 9*3.33 ≈ 110, dentro de ±20% de 100
  bool atwaterReview = false,
}) => FoodRow(
  id: id,
  nameEs: nameEs,
  category: 'prueba',
  sourceId: sourceId,
  sourceRef: sourceRef,
  energyKcal: energyKcal,
  proteinG: proteinG,
  carbsG: carbsG,
  fatG: fatG,
  licenseStatus: 'ok',
  atwaterReview: atwaterReview,
);

void main() {
  group('validateFoods', () {
    test('una fila válida no produce errores', () {
      final issues = validateFoods([_food()]);
      expect(issues.where((i) => i.severity == IssueSeverity.error), isEmpty);
    });

    test('rechaza source_id o source_ref vacíos', () {
      final issues = validateFoods([_food(sourceRef: '')]);
      expect(issues.any((i) => i.severity == IssueSeverity.error), isTrue);
    });

    test('rechaza name_es duplicado', () {
      final issues = validateFoods([
        _food(id: 'a', nameEs: 'Arepa'),
        _food(
          id: 'b',
          nameEs: 'arepa',
        ), // mismo nombre, distinta capitalización
      ]);
      expect(issues.any((i) => i.severity == IssueSeverity.error), isTrue);
    });

    test('rechaza una fila fuera de ±20% Atwater sin atwater_review', () {
      final issues = validateFoods([
        _food(energyKcal: 500, proteinG: 1, carbsG: 1, fatG: 1),
      ]);
      expect(issues.any((i) => i.severity == IssueSeverity.error), isTrue);
    });

    test(
      'acepta la misma fila si atwater_review = true (queda advertencia)',
      () {
        final issues = validateFoods([
          _food(
            energyKcal: 500,
            proteinG: 1,
            carbsG: 1,
            fatG: 1,
            atwaterReview: true,
          ),
        ]);
        expect(issues.where((i) => i.severity == IssueSeverity.error), isEmpty);
        expect(issues.any((i) => i.severity == IssueSeverity.warning), isTrue);
      },
    );
  });

  group('validateSynonyms', () {
    test('rechaza un synonym que apunta a un food_id inexistente', () {
      final foods = [_food(id: 'a')];
      final issues = validateSynonyms([
        const SynonymRow(foodId: 'no-existe', term: 'x'),
      ], foods);
      expect(issues, isNotEmpty);
    });

    test('rechaza el mismo término apuntando a dos alimentos', () {
      final foods = [_food(id: 'a'), _food(id: 'b', nameEs: 'otro')];
      final issues = validateSynonyms([
        const SynonymRow(foodId: 'a', term: 'tinto'),
        const SynonymRow(foodId: 'b', term: 'Tinto'), // mismo normalizado
      ], foods);
      expect(issues, isNotEmpty);
    });

    test('SPEC-028 AC4: un sinónimo que coincide sin tildes con el nombre de '
        'otro alimento falla y nombra el término y los dos alimentos', () {
      final foods = [
        _food(id: 'papa', nameEs: 'Papá de prueba'),
        _food(id: 'otro', nameEs: 'otro'),
      ];
      final issues = validateSynonyms([
        const SynonymRow(foodId: 'otro', term: 'Papa de prueba'),
      ], foods);
      expect(issues, hasLength(1));
      expect(issues.single.severity, IssueSeverity.error);
      expect(issues.single.message, contains('papa de prueba'));
      expect(issues.single.message, contains('papa'));
      expect(issues.single.message, contains('otro'));
    });

    test('SPEC-028: el sinónimo igual al nombre de su propio alimento no '
        'falla', () {
      final foods = [_food(id: 'cafe', nameEs: 'Café')];
      final issues = validateSynonyms([
        const SynonymRow(foodId: 'cafe', term: 'cafe'),
      ], foods);
      expect(issues, isEmpty);
    });

    test('el mismo alimento puede repetir su propio término sin error', () {
      final foods = [_food(id: 'a')];
      final issues = validateSynonyms([
        const SynonymRow(foodId: 'a', term: 'tinto'),
        const SynonymRow(foodId: 'a', term: 'tinto'),
      ], foods);
      expect(issues, isEmpty);
    });
  });

  group('validateNoTcacSource (SPEC-003 R2)', () {
    test('rechaza un food con source_id que referencia tcac', () {
      final issues = validateNoTcacSource([_food(sourceId: 'tcac2018')], []);
      expect(issues, isNotEmpty);
      expect(issues.first.severity, IssueSeverity.error);
    });

    test('rechaza una portion con source_id que referencia tcac', () {
      final foods = [_food(id: 'a')];
      final issues = validateNoTcacSource(foods, [
        const PortionRow(
          foodId: 'a',
          descriptor: 'unidad',
          grams: 50,
          sourceId: 'tcac2018',
          sourceRef: 'fixture',
          isCuratedEstimate: false,
        ),
      ]);
      expect(issues, isNotEmpty);
    });

    test('acepta usda_fdc_* sin error', () {
      final issues = validateNoTcacSource([
        _food(sourceId: 'usda_fdc_sr_legacy'),
      ], []);
      expect(issues, isEmpty);
    });
  });

  group('validatePortions', () {
    test('rechaza grams <= 0', () {
      final foods = [_food(id: 'a')];
      final issues = validatePortions([
        const PortionRow(
          foodId: 'a',
          descriptor: 'unidad',
          grams: 0,
          sourceId: 'usda_fdc',
          sourceRef: 'fixture',
          isCuratedEstimate: false,
        ),
      ], foods);
      expect(issues, isNotEmpty);
    });

    test('rechaza food_id que no existe en foods', () {
      final issues = validatePortions([
        const PortionRow(
          foodId: 'no-existe',
          descriptor: 'unidad',
          grams: 50,
          sourceId: 'usda_fdc',
          sourceRef: 'fixture',
          isCuratedEstimate: false,
        ),
      ], []);
      expect(issues, isNotEmpty);
    });

    test('una porción válida no produce errores', () {
      final foods = [_food(id: 'a')];
      final issues = validatePortions([
        const PortionRow(
          foodId: 'a',
          descriptor: 'unidad',
          grams: 50,
          sourceId: 'usda_fdc',
          sourceRef: 'fixture',
          isCuratedEstimate: false,
        ),
      ], foods);
      expect(issues, isEmpty);
    });
  });

  test('SPEC-028: normalizeFoodTerm, mismos casos que normalizeFoodText de '
      'la app', () {
    expect(normalizeFoodTerm(' PINGÜINO '), 'pinguino');
    expect(normalizeFoodTerm('Ñame cocido'), 'name cocido');
    expect(normalizeFoodTerm('Café'), 'cafe');
    expect(normalizeFoodTerm('üa'), 'ua');
    expect(normalizeFoodTerm('agüü'), 'aguu');
  });
}

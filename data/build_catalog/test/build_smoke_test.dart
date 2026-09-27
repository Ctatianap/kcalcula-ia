import 'dart:io';

import 'package:build_catalog/build.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('build_catalog_test_');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  void writeCsv(String name, String content) {
    File('${tempDir.path}/$name').writeAsStringSync(content);
  }

  void writeFixtureCsvs() {
    writeCsv('sources.csv', '''
id,name,license,url,version
usda_fdc,USDA FoodData Central,CC0 1.0,https://fdc.nal.usda.gov,fixture
''');
    writeCsv('foods.csv', '''
id,name_es,category,source_id,source_ref,energy_kcal,protein_g,carbs_g,fat_g,fiber_g,sugar_g,sodium_mg,density_g_per_ml,license_status,atwater_review
huevo-test,huevo (fixture de prueba),huevos,usda_fdc,dato de prueba no real,150,12,1,10,,,,,ok,false
''');
    writeCsv('food_synonyms.csv', '''
food_id,term
huevo-test,huevos
''');
    writeCsv('portions.csv', '''
food_id,descriptor,grams,source_id,source_ref,is_curated_estimate
huevo-test,unidad,50,usda_fdc,dato de prueba no real,false
''');
    writeCsv('household_units.csv', '''
unit,ml,source_ref
cucharada,15,fixture de prueba
''');
  }

  test('genera catalog.db con las tablas y filas esperadas', () {
    writeFixtureCsvs();
    final outputPath = '${tempDir.path}/catalog.db';

    final report = buildCatalog(
      curatedDir: tempDir.path,
      outputDbPath: outputPath,
      now: DateTime(2026, 9, 27),
    );

    expect(report.catalogVersion, '2026-09-27-1');
    expect(report.addedFoodIds, ['huevo-test']);
    expect(report.removedFoodIds, isEmpty);

    final db = sqlite3.open(outputPath, mode: OpenMode.readOnly);
    try {
      final foods = db.select('SELECT * FROM foods');
      expect(foods, hasLength(1));
      expect(foods.first['name_es'], 'huevo (fixture de prueba)');

      final portions = db.select('SELECT * FROM portions');
      expect(portions, hasLength(1));
      expect(portions.first['grams'], 50);

      final synonyms = db.select('SELECT * FROM food_synonyms');
      expect(synonyms, hasLength(1));

      final householdUnits = db.select('SELECT * FROM household_units');
      expect(householdUnits, hasLength(1));

      final searchResults = db.select(
        "SELECT * FROM food_search WHERE food_search MATCH 'huevos'",
      );
      expect(searchResults, isNotEmpty);
    } finally {
      db.close();
    }
  });

  test(
    'un segundo build en el mismo día incrementa el contador de versión',
    () {
      writeFixtureCsvs();
      final outputPath = '${tempDir.path}/catalog.db';
      buildCatalog(
        curatedDir: tempDir.path,
        outputDbPath: outputPath,
        now: DateTime(2026, 9, 27),
      );
      final second = buildCatalog(
        curatedDir: tempDir.path,
        outputDbPath: outputPath,
        now: DateTime(2026, 9, 27),
      );
      expect(second.catalogVersion, '2026-09-27-2');
      expect(second.addedFoodIds, isEmpty);
      expect(second.changedFoodIds, isEmpty);
    },
  );

  test(
    'rechaza el build si hay errores de validación (no escribe catalog.db)',
    () {
      writeCsv('sources.csv', 'id,name,license,url,version\n');
      writeCsv('foods.csv', '''
id,name_es,category,source_id,source_ref,energy_kcal,protein_g,carbs_g,fat_g,fiber_g,sugar_g,sodium_mg,density_g_per_ml,license_status,atwater_review
sin-fuente,alimento sin fuente,prueba,,,100,10,10,3,,,,,ok,false
''');
      writeCsv('food_synonyms.csv', 'food_id,term\n');
      writeCsv(
        'portions.csv',
        'food_id,descriptor,grams,source_id,source_ref,is_curated_estimate\n',
      );
      writeCsv('household_units.csv', 'unit,ml,source_ref\n');

      final outputPath = '${tempDir.path}/catalog.db';
      expect(
        () => buildCatalog(curatedDir: tempDir.path, outputDbPath: outputPath),
        throwsA(isA<CatalogValidationError>()),
      );
      expect(File(outputPath).existsSync(), isFalse);
    },
  );
}

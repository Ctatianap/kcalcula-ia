import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import 'csv_loader.dart';
import 'schema.dart';
import 'validators.dart';

class BuildReport {
  final String catalogVersion;
  final List<String> addedFoodIds;
  final List<String> removedFoodIds;
  final List<String> changedFoodIds;
  final List<ValidationIssue> warnings;

  const BuildReport({
    required this.catalogVersion,
    required this.addedFoodIds,
    required this.removedFoodIds,
    required this.changedFoodIds,
    required this.warnings,
  });

  @override
  String toString() {
    final buffer = StringBuffer()
      ..writeln('catalog_version: $catalogVersion')
      ..writeln('alimentos añadidos: ${addedFoodIds.length} $addedFoodIds')
      ..writeln(
        'alimentos eliminados: ${removedFoodIds.length} $removedFoodIds',
      )
      ..writeln(
        'alimentos cambiados: ${changedFoodIds.length} $changedFoodIds',
      );
    if (warnings.isNotEmpty) {
      buffer.writeln('advertencias:');
      for (final warning in warnings) {
        buffer.writeln('  - $warning');
      }
    }
    return buffer.toString();
  }
}

/// Excepción cuando la validación encuentra errores bloqueantes. El build
/// nunca escribe `catalog.db` si esto se lanza.
class CatalogValidationError implements Exception {
  final List<ValidationIssue> issues;
  CatalogValidationError(this.issues);

  @override
  String toString() =>
      'Validación del catálogo falló:\n${issues.map((i) => '  - $i').join('\n')}';
}

Map<String, Map<String, Object?>> _readPreviousFoods(String dbPath) {
  final file = File(dbPath);
  if (!file.existsSync()) return {};
  final db = sqlite3.open(dbPath, mode: OpenMode.readOnly);
  try {
    final result = db.select('SELECT * FROM foods');
    final byId = <String, Map<String, Object?>>{};
    for (final row in result) {
      byId[row['id'] as String] = row;
    }
    return byId;
  } catch (_) {
    // catalog.db previo con un esquema incompatible: se trata como si no
    // existiera para el reporte de diff (el build igual lo sobrescribe).
    return {};
  } finally {
    db.close();
  }
}

String _previousCatalogVersion(String dbPath) {
  final file = File(dbPath);
  if (!file.existsSync()) return '';
  final db = sqlite3.open(dbPath, mode: OpenMode.readOnly);
  try {
    final result = db.select('SELECT catalog_version FROM meta LIMIT 1');
    if (result.isEmpty) return '';
    return result.first['catalog_version'] as String;
  } catch (_) {
    return '';
  } finally {
    db.close();
  }
}

String _nextCatalogVersion(String previousVersion, DateTime now) {
  final today =
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final prefix = '$today-';
  if (previousVersion.startsWith(prefix)) {
    final counter = int.tryParse(previousVersion.substring(prefix.length)) ?? 0;
    return '$prefix${counter + 1}';
  }
  return '${prefix}1';
}

/// Construye `catalog.db` desde `curatedDir` hacia `outputDbPath`. Offline y
/// determinista: nunca hace peticiones de red (nutrition-data skill).
BuildReport buildCatalog({
  required String curatedDir,
  required String outputDbPath,
  DateTime? now,
}) {
  final data = loadCuratedData(curatedDir);
  final issues = validateCuratedData(data);
  final errors = issues
      .where((i) => i.severity == IssueSeverity.error)
      .toList();
  if (errors.isNotEmpty) {
    throw CatalogValidationError(errors);
  }
  final warnings = issues
      .where((i) => i.severity == IssueSeverity.warning)
      .toList();

  final previousFoods = _readPreviousFoods(outputDbPath);
  final previousVersion = _previousCatalogVersion(outputDbPath);
  final catalogVersion = _nextCatalogVersion(
    previousVersion,
    now ?? DateTime.now(),
  );

  final outputFile = File(outputDbPath);
  if (outputFile.existsSync()) outputFile.deleteSync();
  outputFile.parent.createSync(recursive: true);

  final db = sqlite3.open(outputDbPath);
  try {
    for (final statement in catalogSchemaStatements) {
      db.execute(statement);
    }

    db.execute('INSERT INTO meta (catalog_version, built_at) VALUES (?, ?)', [
      catalogVersion,
      (now ?? DateTime.now()).toIso8601String(),
    ]);

    for (final source in data.sources) {
      db.execute(
        'INSERT INTO sources (id, name, license, url, version) VALUES (?, ?, ?, ?, ?)',
        [source.id, source.name, source.license, source.url, source.version],
      );
    }

    for (final food in data.foods) {
      db.execute(
        '''
        INSERT INTO foods (
          id, name_es, category, source_id, source_ref, energy_kcal,
          protein_g, carbs_g, fat_g, fiber_g, sugar_g, sodium_mg,
          density_g_per_ml, license_status, atwater_review
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          food.id,
          food.nameEs,
          food.category,
          food.sourceId,
          food.sourceRef,
          food.energyKcal,
          food.proteinG,
          food.carbsG,
          food.fatG,
          food.fiberG,
          food.sugarG,
          food.sodiumMg,
          food.densityGPerMl,
          food.licenseStatus,
          food.atwaterReview ? 1 : 0,
        ],
      );
      db.execute(
        'INSERT INTO food_search (food_id, name_es, term) VALUES (?, ?, ?)',
        [food.id, food.nameEs, food.nameEs],
      );
    }

    for (final synonym in data.synonyms) {
      db.execute('INSERT INTO food_synonyms (food_id, term) VALUES (?, ?)', [
        synonym.foodId,
        synonym.term,
      ]);
      final food = data.foods.firstWhere((f) => f.id == synonym.foodId);
      db.execute(
        'INSERT INTO food_search (food_id, name_es, term) VALUES (?, ?, ?)',
        [synonym.foodId, food.nameEs, synonym.term],
      );
    }

    for (final portion in data.portions) {
      db.execute(
        '''
        INSERT INTO portions (
          food_id, descriptor, grams, source_id, source_ref, is_curated_estimate
        ) VALUES (?, ?, ?, ?, ?, ?)
        ''',
        [
          portion.foodId,
          portion.descriptor,
          portion.grams,
          portion.sourceId,
          portion.sourceRef,
          portion.isCuratedEstimate ? 1 : 0,
        ],
      );
    }

    for (final unit in data.householdUnits) {
      db.execute(
        'INSERT INTO household_units (unit, ml, source_ref) VALUES (?, ?, ?)',
        [unit.unit, unit.ml, unit.sourceRef],
      );
    }
  } finally {
    db.close();
  }

  final newFoodIds = data.foods.map((f) => f.id).toSet();
  final oldFoodIds = previousFoods.keys.toSet();
  final added = newFoodIds.difference(oldFoodIds).toList()..sort();
  final removed = oldFoodIds.difference(newFoodIds).toList()..sort();
  final changed = <String>[];
  for (final food in data.foods) {
    final previous = previousFoods[food.id];
    if (previous == null) continue;
    if (previous['energy_kcal'] != food.energyKcal ||
        previous['protein_g'] != food.proteinG ||
        previous['carbs_g'] != food.carbsG ||
        previous['fat_g'] != food.fatG ||
        previous['name_es'] != food.nameEs) {
      changed.add(food.id);
    }
  }
  changed.sort();

  return BuildReport(
    catalogVersion: catalogVersion,
    addedFoodIds: added,
    removedFoodIds: removed,
    changedFoodIds: changed,
    warnings: warnings,
  );
}

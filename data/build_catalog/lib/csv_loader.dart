import 'dart:io';

import 'package:csv/csv.dart' as csv_pkg;

import 'models.dart';

double? _parseNullableDouble(dynamic value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return null;
  return double.parse(text);
}

double _parseDouble(dynamic value) => double.parse(value.toString().trim());

bool _parseBool(dynamic value) {
  final text = value?.toString().trim().toLowerCase() ?? '';
  return text == 'true' || text == '1';
}

String _parseString(dynamic value) => value?.toString().trim() ?? '';

List<csv_pkg.CsvRow> _readRows(File file) {
  if (!file.existsSync()) return const [];
  final content = file.readAsStringSync();
  if (content.trim().isEmpty) return const [];
  return csv_pkg.csv.decodeWithHeaders(content);
}

CuratedData loadCuratedData(String curatedDir) {
  final sources = _readRows(File('$curatedDir/sources.csv'))
      .map(
        (row) => SourceRow(
          id: _parseString(row['id']),
          name: _parseString(row['name']),
          license: _parseString(row['license']),
          url: _parseString(row['url']),
          version: _parseString(row['version']),
        ),
      )
      .toList();

  final foods = _readRows(File('$curatedDir/foods.csv'))
      .map(
        (row) => FoodRow(
          id: _parseString(row['id']),
          nameEs: _parseString(row['name_es']),
          category: _parseString(row['category']),
          sourceId: _parseString(row['source_id']),
          sourceRef: _parseString(row['source_ref']),
          energyKcal: _parseDouble(row['energy_kcal']),
          proteinG: _parseDouble(row['protein_g']),
          carbsG: _parseDouble(row['carbs_g']),
          fatG: _parseDouble(row['fat_g']),
          fiberG: _parseNullableDouble(row['fiber_g']),
          sugarG: _parseNullableDouble(row['sugar_g']),
          sodiumMg: _parseNullableDouble(row['sodium_mg']),
          densityGPerMl: _parseNullableDouble(row['density_g_per_ml']),
          licenseStatus: _parseString(row['license_status']).isEmpty
              ? 'ok'
              : _parseString(row['license_status']),
          atwaterReview: _parseBool(row['atwater_review']),
        ),
      )
      .toList();

  final synonyms = _readRows(File('$curatedDir/food_synonyms.csv'))
      .map(
        (row) => SynonymRow(
          foodId: _parseString(row['food_id']),
          term: _parseString(row['term']),
        ),
      )
      .toList();

  final portions = _readRows(File('$curatedDir/portions.csv'))
      .map(
        (row) => PortionRow(
          foodId: _parseString(row['food_id']),
          descriptor: _parseString(row['descriptor']),
          grams: _parseDouble(row['grams']),
          sourceId: _parseString(row['source_id']),
          sourceRef: _parseString(row['source_ref']),
          isCuratedEstimate: _parseBool(row['is_curated_estimate']),
        ),
      )
      .toList();

  final householdUnits = _readRows(File('$curatedDir/household_units.csv'))
      .map(
        (row) => HouseholdUnitRow(
          unit: _parseString(row['unit']),
          ml: _parseDouble(row['ml']),
          sourceRef: _parseString(row['source_ref']),
        ),
      )
      .toList();

  return CuratedData(
    sources: sources,
    foods: foods,
    synonyms: synonyms,
    portions: portions,
    householdUnits: householdUnits,
  );
}

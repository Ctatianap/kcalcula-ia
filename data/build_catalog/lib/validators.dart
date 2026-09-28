import 'models.dart';

enum IssueSeverity { error, warning }

class ValidationIssue {
  final IssueSeverity severity;
  final String message;

  const ValidationIssue(this.severity, this.message);

  @override
  String toString() =>
      '${severity == IssueSeverity.error ? "ERROR" : "WARNING"}: $message';
}

String _normalize(String text) {
  const withAccents = 'áéíóúÁÉÍÓÚñÑ';
  const withoutAccents = 'aeiouAEIOUnN';
  var result = text.trim().toLowerCase();
  for (var i = 0; i < withAccents.length; i++) {
    result = result.replaceAll(withAccents[i], withoutAccents[i].toLowerCase());
  }
  return result;
}

/// Reglas de la skill `nutrition-data`: `source_id`/`source_ref`
/// obligatorios, Atwater ±20% (o `atwater_review = true`), sin `name_es`
/// duplicados.
List<ValidationIssue> validateFoods(List<FoodRow> foods) {
  final issues = <ValidationIssue>[];
  final namesSeen = <String, String>{}; // nombre normalizado -> id

  for (final food in foods) {
    if (food.id.isEmpty) {
      issues.add(ValidationIssue(IssueSeverity.error, 'Fila de foods sin id.'));
      continue;
    }
    if (food.sourceId.isEmpty || food.sourceRef.isEmpty) {
      issues.add(
        ValidationIssue(
          IssueSeverity.error,
          'foods "${food.id}": source_id y source_ref son obligatorios.',
        ),
      );
    }

    final normalizedName = _normalize(food.nameEs);
    final existing = namesSeen[normalizedName];
    if (existing != null) {
      issues.add(
        ValidationIssue(
          IssueSeverity.error,
          'foods "${food.id}" duplica el name_es de "$existing" ("${food.nameEs}").',
        ),
      );
    } else {
      namesSeen[normalizedName] = food.id;
    }

    final atwaterKcal = 4 * food.proteinG + 4 * food.carbsG + 9 * food.fatG;
    final tolerance = food.energyKcal.abs() * 0.20;
    final withinTolerance = (atwaterKcal - food.energyKcal).abs() <= tolerance;
    if (!withinTolerance) {
      if (food.atwaterReview) {
        issues.add(
          ValidationIssue(
            IssueSeverity.warning,
            'foods "${food.id}": fuera de ±20% Atwater '
            '(calculado ${atwaterKcal.toStringAsFixed(1)} kcal vs. '
            '${food.energyKcal} kcal declaradas), aceptada por atwater_review.',
          ),
        );
      } else {
        issues.add(
          ValidationIssue(
            IssueSeverity.error,
            'foods "${food.id}": fuera de ±20% Atwater '
            '(calculado ${atwaterKcal.toStringAsFixed(1)} kcal vs. '
            '${food.energyKcal} kcal declaradas). Corrige el dato o marca '
            'atwater_review=true si es una excepción aceptada.',
          ),
        );
      }
    }
  }

  return issues;
}

List<ValidationIssue> validateSynonyms(
  List<SynonymRow> synonyms,
  List<FoodRow> foods,
) {
  final issues = <ValidationIssue>[];
  final validFoodIds = foods.map((f) => f.id).toSet();
  final termToFoodIds = <String, Set<String>>{};

  for (final synonym in synonyms) {
    if (!validFoodIds.contains(synonym.foodId)) {
      issues.add(
        ValidationIssue(
          IssueSeverity.error,
          'food_synonyms: "${synonym.term}" apunta a food_id '
          '"${synonym.foodId}", que no existe en foods.csv.',
        ),
      );
      continue;
    }
    final normalizedTerm = _normalize(synonym.term);
    termToFoodIds.putIfAbsent(normalizedTerm, () => {}).add(synonym.foodId);
  }

  for (final entry in termToFoodIds.entries) {
    if (entry.value.length > 1) {
      issues.add(
        ValidationIssue(
          IssueSeverity.error,
          'food_synonyms: el término "${entry.key}" apunta a varios '
          'alimentos sin desambiguar (${entry.value.join(", ")}).',
        ),
      );
    }
  }

  return issues;
}

List<ValidationIssue> validatePortions(
  List<PortionRow> portions,
  List<FoodRow> foods,
) {
  final issues = <ValidationIssue>[];
  final validFoodIds = foods.map((f) => f.id).toSet();

  for (final portion in portions) {
    if (!validFoodIds.contains(portion.foodId)) {
      issues.add(
        ValidationIssue(
          IssueSeverity.error,
          'portions: food_id "${portion.foodId}" no existe en foods.csv.',
        ),
      );
    }
    if (portion.sourceId.isEmpty || portion.sourceRef.isEmpty) {
      issues.add(
        ValidationIssue(
          IssueSeverity.error,
          'portions "${portion.foodId}/${portion.descriptor}": source_id y '
          'source_ref son obligatorios.',
        ),
      );
    }
    if (portion.grams <= 0) {
      issues.add(
        ValidationIssue(
          IssueSeverity.error,
          'portions "${portion.foodId}/${portion.descriptor}": grams debe '
          'ser mayor que 0 (es ${portion.grams}).',
        ),
      );
    }
  }

  return issues;
}

/// SPEC-003 R2: la TCAC/ICBF sigue bloqueada por licencia (PV-01, sin
/// autorización escrita del ICBF). Ningún `source_id` puede referenciarla
/// mientras eso no cambie explícitamente.
List<ValidationIssue> validateNoTcacSource(
  List<FoodRow> foods,
  List<PortionRow> portions,
) {
  final issues = <ValidationIssue>[];
  for (final food in foods) {
    if (food.sourceId.toLowerCase().contains('tcac')) {
      issues.add(
        ValidationIssue(
          IssueSeverity.error,
          'foods "${food.id}": source_id "${food.sourceId}" referencia la '
          'TCAC/ICBF, bloqueada por licencia (PV-01). No se puede usar hasta '
          'que exista autorización escrita.',
        ),
      );
    }
  }
  for (final portion in portions) {
    if (portion.sourceId.toLowerCase().contains('tcac')) {
      issues.add(
        ValidationIssue(
          IssueSeverity.error,
          'portions "${portion.foodId}/${portion.descriptor}": source_id '
          '"${portion.sourceId}" referencia la TCAC/ICBF, bloqueada por '
          'licencia (PV-01). No se puede usar hasta que exista autorización '
          'escrita.',
        ),
      );
    }
  }
  return issues;
}

List<ValidationIssue> validateCuratedData(CuratedData data) => [
  ...validateFoods(data.foods),
  ...validateSynonyms(data.synonyms, data.foods),
  ...validatePortions(data.portions, data.foods),
  ...validateNoTcacSource(data.foods, data.portions),
];

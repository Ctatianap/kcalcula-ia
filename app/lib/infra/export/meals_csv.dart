import 'package:nutrition_core/nutrition_core.dart';

import '../storage/storage_repository.dart';

/// SPEC-016 R2: CSV para Excel en es-CO: UTF-8 con BOM, separador `;`,
/// decimales con coma y fin de línea CRLF (RFC 4180). Una fila por ítem.
const csvHeader = [
  'Fecha',
  'Hora',
  'Tipo de comida',
  'Alimento',
  'Gramos',
  'kcal',
  'Proteína (g)',
  'Carbohidratos (g)',
  'Grasa (g)',
  'Confianza',
  'Fuente',
];

const _mealTypes = {
  'desayuno': 'Desayuno',
  'almuerzo': 'Almuerzo',
  'cena': 'Cena',
  'snack': 'Snack',
};

const _confidence = {
  'altaPrecision': 'Alta precisión',
  'buenaEstimacion': 'Buena estimación',
  'estimacion': 'Estimación',
};

/// RFC 4180: entre comillas si lleva `;`, comillas o saltos de línea; las
/// comillas internas se duplican.
String csvField(String value) {
  if (value.contains(RegExp('[;"\r\n]'))) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

String _two(int n) => n.toString().padLeft(2, '0');

String buildMealsCsv(List<MealWithItems> meals) {
  final rows = <List<String>>[csvHeader];
  for (final meal in meals) {
    final at = meal.meal.eatenAt;
    for (final item in meal.items) {
      rows.add([
        '${_two(at.day)}/${_two(at.month)}/${at.year}',
        '${_two(at.hour)}:${_two(at.minute)}',
        _mealTypes[meal.meal.mealType] ?? 'Snack',
        item.nameSnapshot,
        formatMacroEs(item.grams),
        // Reglas de presentación: kcal enteras, macros con 1 decimal.
        '${presentKcal(item.energyKcal)}',
        formatMacroEs(item.proteinG),
        formatMacroEs(item.carbsG),
        formatMacroEs(item.fatG),
        _confidence[item.confidence] ?? item.confidence,
        item.sourceRef,
      ]);
    }
  }
  final body = rows.map((r) => r.map(csvField).join(';')).join('\r\n');
  return '﻿$body\r\n';
}

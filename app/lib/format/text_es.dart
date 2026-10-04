/// "Huevo", "Huevo y Arepa", "Huevo, Arepa y Queso" (lo comparten el
/// detalle de comida y Recientes).
String joinNamesEs(List<String> names) {
  if (names.length <= 1) return names.join();
  return '${names.sublist(0, names.length - 1).join(', ')} y ${names.last}';
}

/// SPEC-020 R1/R2: normalización única de texto de alimentos para el
/// catálogo, la búsqueda y los productos personales: minúsculas, sin tildes,
/// "ñ" → "n" y "ü" → "u". El índice FTS5 (`unicode61`) ya quita esas marcas
/// al indexar; esto deja la consulta igual.
String normalizeFoodText(String text) {
  const withMarks = 'áéíóúüñ';
  const withoutMarks = 'aeiouun';
  var result = text.trim().toLowerCase();
  for (var i = 0; i < withMarks.length; i++) {
    result = result.replaceAll(withMarks[i], withoutMarks[i]);
  }
  return result;
}

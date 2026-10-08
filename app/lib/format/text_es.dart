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

/// SPEC-018 R1: se busca desde 2 letras o números (sin contar espacios ni
/// signos). Única regla para la pantalla, el resolver, el catálogo y el
/// historial (SPEC-036).
bool isSearchableQuery(String query) =>
    normalizeFoodText(query).replaceAll(RegExp('[^a-z0-9]'), '').length >= 2;

/// SPEC-036: como la búsqueda del catálogo (SPEC-018), cada palabra de
/// [query] tiene que ser el comienzo de alguna palabra de [name]
/// (normalizados). "queso arepa" encuentra "Arepa de queso"; "pa" no
/// encuentra "Arepa".
bool matchesWordPrefixes(String name, String query) {
  List<String> words(String text) =>
      normalizeFoodText(text)
          .split(RegExp(r'[^a-z0-9]+'))
          .where((w) => w.isNotEmpty)
          .toList();
  final nameWords = words(name);
  return words(query).every((q) => nameWords.any((w) => w.startsWith(q)));
}

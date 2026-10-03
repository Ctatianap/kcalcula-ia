/// "Huevo", "Huevo y Arepa", "Huevo, Arepa y Queso" (lo comparten el
/// detalle de comida y Recientes).
String joinNamesEs(List<String> names) {
  if (names.length <= 1) return names.join();
  return '${names.sublist(0, names.length - 1).join(', ')} y ${names.last}';
}

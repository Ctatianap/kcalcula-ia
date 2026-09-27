// Utilidad de CURACIÓN, no de build: consulta la API pública de USDA FDC
// (CC0) y muestra candidatos con sus nutrientes por 100 g para copiar a
// data/curated/foods.csv con una cita exacta. bin/build_catalog.dart nunca
// llama a esto ni a la red (nutrition-data skill: el build es offline).
//
// Uso:
//   dart run tool/fetch_fdc.dart "arepa"
//   FDC_API_KEY=tu_clave dart run tool/fetch_fdc.dart "queso fresco"
//
// Sin FDC_API_KEY usa DEMO_KEY, que tiene un límite de tasa muy bajo
// (~30 solicitudes/hora/IP). Para curar los ~30 alimentos de R7 sin
// bloquearte, regístrate en https://fdc.nal.usda.gov/api-key-signup (clave
// gratuita, 1000 solicitudes/hora) y exporta FDC_API_KEY.
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Uso: dart run tool/fetch_fdc.dart "<término de búsqueda>"');
    exitCode = 64;
    return;
  }
  final query = args.join(' ');
  final apiKey = Platform.environment['FDC_API_KEY'] ?? 'DEMO_KEY';
  final uri = Uri.https('api.nal.usda.gov', '/fdc/v1/foods/search', {
    'api_key': apiKey,
    'query': query,
    'pageSize': '10',
  });

  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode != 200) {
      stderr.writeln('HTTP ${response.statusCode}: $body');
      exitCode = 1;
      return;
    }

    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final foods = (decoded['foods'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    if (foods.isEmpty) {
      stdout.writeln('Sin resultados para "$query".');
      return;
    }

    for (final food in foods) {
      final fdcId = food['fdcId'];
      final description = food['description'];
      final dataType = food['dataType'];
      stdout.writeln('--- fdcId $fdcId | $dataType | $description ---');
      stdout.writeln(
        'source_ref sugerido: FDC ID $fdcId — $description — '
        'https://fdc.nal.usda.gov/food-details/$fdcId/nutrients — '
        'consultado ${DateTime.now().toIso8601String().substring(0, 10)}',
      );
      final nutrients = (food['foodNutrients'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      for (final nutrient in nutrients) {
        final name = nutrient['nutrientName'];
        final number = nutrient['nutrientNumber'];
        final value = nutrient['value'];
        final unit = nutrient['unitName'];
        // Los que importan para foods.csv: Energy (208), Protein (203),
        // Carbohydrate (205), Total lipid/fat (204), Fiber (291),
        // Sugars (269), Sodium (307).
        const relevant = {'203', '204', '205', '208', '269', '291', '307'};
        if (relevant.contains(number)) {
          stdout.writeln('  [$number] $name: $value $unit');
        }
      }
      stdout.writeln();
    }
  } finally {
    client.close();
  }
}

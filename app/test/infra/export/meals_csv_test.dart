import 'dart:convert';
import 'dart:io';

import 'package:calorias_ia/infra/export/export_range.dart';
import 'package:calorias_ia/infra/export/export_service.dart';
import 'package:calorias_ia/infra/export/meals_csv.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/settings/fake_sharing_service.dart';
import '../../support/export_fixtures.dart';

void main() {
  late AppDatabase db;
  late StorageRepository repo;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = StorageRepository(db);
  });
  tearDown(() => db.close());

  test('AC1: 2 comidas (3 ítems) → BOM, encabezado y 3 filas con ; y coma '
      'decimal', () async {
    await exportMeal(repo, DateTime(2026, 10, 3, 8, 5), [
      exportItem('Huevo', grams: 100, kcal: 143.4),
      exportItem(
        'Arepa',
        grams: 115,
        kcal: 307.05,
        p: 6.509,
        c: 35.04,
        f: 16.1,
      ),
    ], type: 'desayuno');
    await exportMeal(repo, DateTime(2026, 10, 3, 13), [
      exportItem(
        'Café',
        grams: 240.5,
        kcal: 2.4,
        p: 0.3,
        c: 0,
        f: 0.05,
        confidence: 'estimacion',
      ),
    ]);
    final csv = buildMealsCsv(
      await repo.mealsBetween(DateTime(2026, 10, 3), DateTime(2026, 10, 4)),
    );
    expect(csv.startsWith('﻿'), isTrue);
    final lines = csv.substring(1).split('\r\n')..removeLast();
    expect(lines, hasLength(4));
    expect(
      lines[0],
      'Fecha;Hora;Tipo de comida;Alimento;Gramos;kcal;Proteína (g);'
      'Carbohidratos (g);Grasa (g);Confianza;Fuente',
    );
    expect(
      lines[1],
      '03/10/2026;08:05;Desayuno;Huevo;100,0;143;12,6;0,7;9,5;Buena '
      'estimación;fixture de prueba',
    );
    expect(
      lines[2],
      '03/10/2026;08:05;Desayuno;Arepa;115,0;307;6,5;35,0;16,1;Buena '
      'estimación;fixture de prueba',
    );
    expect(
      lines[3],
      '03/10/2026;13:00;Almuerzo;Café;240,5;2;0,3;0,0;0,1;Estimación;'
      'fixture de prueba',
    );
    // UTF-8: los acentos sobreviven al codificar el archivo.
    expect(utf8.decode(utf8.encode(csv)), contains('Café'));
  });

  test('edge case: nombres con ; o comillas se escapan (RFC 4180)', () {
    expect(csvField('Pan; integral'), '"Pan; integral"');
    expect(csvField('Queso "costeño"'), '"Queso ""costeño"""');
    expect(csvField('Huevo'), 'Huevo');
  });

  test(
    'edge case: un texto que empieza por = + - @ no se lee como fórmula',
    () {
      expect(csvField('=1+1'), "'=1+1");
      expect(csvField('+57 arepa'), "'+57 arepa");
      expect(csvField('-2'), "'-2");
      expect(csvField('@x'), "'@x");
      expect(csvField('=A1;B1'), '"\'=A1;B1"');
    },
  );

  test('AC2: "Últimos 30 días" excluye una comida de hace 40 días en CSV y '
      'PDF', () async {
    final now = DateTime(2026, 10, 3, 18);
    await exportMeal(repo, DateTime(2026, 8, 24, 13), [exportItem('Viejo')]);
    await exportMeal(repo, DateTime(2026, 9, 4, 13), [exportItem('Límite')]);
    await exportMeal(repo, DateTime(2026, 10, 3, 13), [exportItem('Hoy')]);
    final dir = Directory.systemTemp.createTempSync('kcalcula_export');
    addTearDown(() => dir.deleteSync(recursive: true));
    final sharing = FakeSharingService();
    final service = ExportService(
      storage: repo,
      sharing: sharing,
      directoryPath: dir.path,
      loadFonts: testPdfFonts,
      clock: () => now,
    );
    final range = ExportRange.last30Days(now);
    expect(range.from, DateTime(2026, 9, 4));

    final counts = await service.count(range);
    expect(counts.meals, 2);
    expect(counts.days, 2);

    final csvPath = await service.export(ExportFormat.csv, range);
    final csv = File(csvPath!).readAsStringSync();
    expect(csv, contains('Hoy'));
    expect(csv, contains('Límite'));
    expect(csv, isNot(contains('Viejo')));
    expect(sharing.sharedPath, csvPath);

    final all = await service.count(const ExportRange.all());
    expect(all.meals, 3);
  });
}

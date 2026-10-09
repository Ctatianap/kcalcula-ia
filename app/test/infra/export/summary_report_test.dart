import 'dart:io';

import 'package:calorias_ia/infra/export/export_range.dart';
import 'package:calorias_ia/infra/export/export_service.dart';
import 'package:calorias_ia/infra/export/summary_pdf.dart';
import 'package:calorias_ia/infra/export/summary_report.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/settings/fake_sharing_service.dart';
import '../../support/export_fixtures.dart';

final _now = DateTime(2026, 10, 3, 18);

void main() {
  late AppDatabase db;
  late StorageRepository repo;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = StorageRepository(db);
    // Perfil con datos que NO deben salir en el PDF.
    await repo.saveUserProfile(
      sex: 'female',
      birthDate: DateTime(1996, 10, 15),
      heightCm: 165,
      weightKg: 62.4,
      activityLevel: 'lightlyActive',
      measuredMaintenanceKcal: 1890,
    );
    await repo.saveNutritionGoal((
      objective: 'maintain',
      isManual: true,
      energyKcal: 2000,
      proteinG: 100,
      carbsG: 250,
      fatG: 60,
    ));
    await repo.logWeight(day: DateTime(2026, 9, 26), kg: 62.4);
    await repo.logWeight(day: DateTime(2026, 10, 3), kg: 62.0);
    await exportMeal(repo, DateTime(2026, 8, 24, 13), [
      exportItem('Viejo', kcal: 999),
    ]);
    await exportMeal(repo, DateTime(2026, 10, 2, 8, 5), [
      exportItem('Huevo', kcal: 900, p: 50, c: 100, f: 30),
      exportItem('Arepa', grams: 115, kcal: 1000, p: 50, c: 150, f: 30),
    ], type: 'desayuno');
    await exportMeal(repo, DateTime(2026, 10, 3, 13), [
      exportItem('Pollo', kcal: 1500, p: 100, c: 0, f: 40),
    ]);
  });
  tearDown(() => db.close());

  Future<SummaryReport> report(ExportRange range) async => buildSummaryReport(
    meals: await repo.mealsBetween(range.start, range.endExclusive),
    range: range,
    goal: await repo.getNutritionGoal(),
    weights: (await repo.weightEntries())
        .where((w) => range.contains(w.day))
        .toList(),
  );

  test('AC3: periodo, meta, promedio, días en meta y tabla por día', () async {
    final r = await report(ExportRange.last30Days(_now));
    expect(
      r.period,
      'Periodo: del 4 de septiembre de 2026 al 3 de octubre de 2026',
    );
    expect(
      r.goal,
      'Meta diaria actual: 2.000 kcal · Proteína 100,0 g · Carbohidratos '
      '250,0 g · Grasa 60,0 g',
    );
    // (1.900 + 1.500) / 2 días = 1.700.
    expect(
      r.average,
      'Promedio diario: ~1.700 kcal · Proteína 100,0 g · Carbohidratos '
      '125,0 g · Grasa 50,0 g (sobre 2 días con registros)',
    );
    expect(
      r.daysOnGoal,
      'Días en meta: 1 de 2 (del 90 % al 110 % de la meta actual)',
    );
    expect(r.days.map((d) => d.cells), [
      ['viernes 2/10/2026', '1.900', '100,0', '250,0', '60,0'],
      ['sábado 3/10/2026', '1.500', '100,0', '0,0', '40,0'],
    ]);
    expect(r.days.first.meals, [
      '8:05 · Desayuno · Huevo 100 g, Arepa 115 g · 1.900 kcal',
    ]);
    expect(r.weights, [
      'Peso del 26 de septiembre de 2026: 62,4 kg',
      'Peso del 3 de octubre de 2026: 62,0 kg',
    ]);
    expect(r.footer, reportFooter);
  });

  test('AC3/R3: el PDF no contiene fecha de nacimiento, sexo ni '
      'mantenimiento medido', () async {
    final r = await report(const ExportRange.all());
    final text = r.allText.join('\n').toLowerCase();
    for (final forbidden in [
      '1996',
      '15/10',
      'nacimiento',
      'female',
      'mujer',
      'sexo',
      'mantenimiento',
      '1.890',
      'estatura',
      '165',
    ]) {
      expect(text, isNot(contains(forbidden)), reason: forbidden);
    }
    expect(text, contains('viejo'));
  });

  test('AC2: el PDF de los últimos 30 días no incluye la comida de hace 40 '
      'días', () async {
    final r = await report(ExportRange.last30Days(_now));
    expect(r.allText.join('\n'), isNot(contains('Viejo')));
  });

  test('el PDF se genera (A4) y pagina con 100 días', () async {
    final fonts = await testPdfFonts();
    final r = await report(ExportRange.last30Days(_now));
    final bytes = await renderSummaryPdf(
      r,
      regular: fonts.regular,
      bold: fonts.bold,
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');

    for (var i = 0; i < 100; i++) {
      await exportMeal(repo, DateTime(2026, 6, 1 + i, 12), [
        exportItem('Comida $i', kcal: 1800),
      ]);
    }
    final big = await report(const ExportRange.all());
    final bigBytes = await renderSummaryPdf(
      big,
      regular: fonts.regular,
      bold: fonts.bold,
    );
    final pages = RegExp(r'/Type\s*/Page\b')
        .allMatches(String.fromCharCodes(bigBytes))
        .length;
    expect(pages, greaterThan(2));
  });

  test('AC4: el servicio entrega .pdf al share sheet', () async {
    final dir = Directory.systemTemp.createTempSync('kcalcula_pdf');
    addTearDown(() => dir.deleteSync(recursive: true));
    final sharing = FakeSharingService();
    final service = ExportService(
      storage: repo,
      sharing: sharing,
      directoryPath: dir.path,
      loadFonts: testPdfFonts,
      clock: () => _now,
    );
    final path = await service.export(
      ExportFormat.pdf,
      ExportRange.last30Days(_now),
    );
    expect(path, endsWith('.pdf'));
    expect(File(path!).readAsBytesSync().take(4), '%PDF'.codeUnits);
    expect(sharing.sharedPath, path);
  });
}

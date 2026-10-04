import 'dart:io';

import 'package:calorias_ia/infra/export/export_range.dart';
import 'package:calorias_ia/infra/export/export_service.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/settings/fake_sharing_service.dart';
import '../../support/export_fixtures.dart';

void main() {
  late AppDatabase db;
  late StorageRepository repo;
  late Directory dir;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = StorageRepository(db);
    dir = Directory.systemTemp.createTempSync('kcalcula_cleanup');
  });
  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  ExportService service() => ExportService(
    storage: repo,
    sharing: FakeSharingService(),
    directoryPath: dir.path,
    loadFonts: testPdfFonts,
    clock: () => DateTime(2026, 10, 4, 9),
  );

  List<String> names() =>
      dir.listSync().map((e) => e.uri.pathSegments.last).toList()..sort();

  test('T-022: reconoce solo los nombres de las exportaciones de la app', () {
    expect(
      isExportFileName('calorias_ia_export_2026-10-03T10-00.json'),
      isTrue,
    );
    expect(
      isExportFileName('kcalcula_ia_comidas_2026-10-03T10-00.csv'),
      isTrue,
    );
    expect(
      isExportFileName('kcalcula_ia_resumen_2026-10-03T10-00.pdf'),
      isTrue,
    );
    expect(isExportFileName('kcalcula_ia_resumen_x.csv'), isFalse);
    expect(isExportFileName('foto_etiqueta.jpg'), isFalse);
    expect(isExportFileName('user.db'), isFalse);
    expect(isExportFileName('mi_calorias_ia_export_1.json'), isFalse);
  });

  test('T-022: al exportar se borran las exportaciones anteriores y nada '
      'más', () async {
    await exportMeal(repo, DateTime(2026, 10, 3, 13), [exportItem('Huevo')]);
    for (final old in [
      'calorias_ia_export_2026-10-01T10-00-00.json',
      'kcalcula_ia_comidas_2026-10-02T10-00-00.csv',
      'kcalcula_ia_resumen_2026-10-02T11-00-00.pdf',
    ]) {
      File('${dir.path}/$old').writeAsStringSync('datos viejos');
    }
    File('${dir.path}/otra_cosa.txt').writeAsStringSync('no se toca');

    final path = await service().export(
      ExportFormat.csv,
      const ExportRange.all(),
    );
    expect(names(), [
      'kcalcula_ia_comidas_2026-10-04T09-00-00.000.csv',
      'otra_cosa.txt',
    ]);
    expect(File(path!).existsSync(), isTrue);
  });

  test('T-022: también limpia cuando no hay comidas en el periodo', () async {
    File('${dir.path}/kcalcula_ia_comidas_2026-10-02T10-00-00.csv')
        .writeAsStringSync('datos viejos');
    final path = await service().export(
      ExportFormat.csv,
      ExportRange.last30Days(DateTime(2026, 10, 4)),
    );
    expect(path, isNull);
    expect(names(), isEmpty);
  });

  test('T-022: un directorio inexistente no impide exportar', () async {
    final missing = ExportService(
      storage: repo,
      sharing: FakeSharingService(),
      directoryPath: '${dir.path}/no-existe',
      loadFonts: testPdfFonts,
    );
    await missing.deletePreviousExports();
  });
}

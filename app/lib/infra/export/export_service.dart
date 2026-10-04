import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:pdf/widgets.dart' as pw;

import '../sharing/sharing_service.dart';
import '../storage/storage_repository.dart';
import 'export_range.dart';
import 'meals_csv.dart';
import 'summary_pdf.dart';
import 'summary_report.dart';

/// SPEC-016 R1: los tres formatos de "Exportar mis datos".
enum ExportFormat { csv, pdf, json }

typedef PdfFonts = ({pw.Font regular, pw.Font bold});

/// Outfit embebida (la misma de la app): nunca se descarga.
Future<PdfFonts> loadPdfFonts() async {
  final regular = await rootBundle.load('assets/fonts/Outfit-Regular.ttf');
  final bold = await rootBundle.load('assets/fonts/Outfit-Medium.ttf');
  return (regular: pw.Font.ttf(regular), bold: pw.Font.ttf(bold));
}

/// T-022: nombres que crea [ExportService] (JSON, CSV y PDF).
final _exportFileName = RegExp(
  r'^(calorias_ia_export_.+\.json|kcalcula_ia_comidas_.+\.csv|'
  r'kcalcula_ia_resumen_.+\.pdf)$',
);

bool isExportFileName(String name) => _exportFileName.hasMatch(name);

class ExportCounts {
  final int meals;
  final int days;

  const ExportCounts({required this.meals, required this.days});
}

/// SPEC-016 R4/R5: arma el archivo en el teléfono (directorio temporal) y
/// lo entrega al share sheet; la app no lo envía a ningún lado.
class ExportService {
  final StorageRepository _storage;
  final SharingService _sharing;
  final String _directoryPath;
  final Future<PdfFonts> Function() _loadFonts;
  final DateTime Function() _clock;

  ExportService({
    required this._storage,
    required this._sharing,
    required this._directoryPath,
    this._loadFonts = loadPdfFonts,
    this._clock = DateTime.now,
  });

  Future<List<MealWithItems>> _meals(ExportRange range) =>
      _storage.mealsBetween(range.start, range.endExclusive);

  /// R1/AC5: comidas y días con registros del periodo.
  Future<ExportCounts> count(ExportRange range) async {
    final meals = await _meals(range);
    final days = {
      for (final m in meals)
        DateTime(m.meal.eatenAt.year, m.meal.eatenAt.month, m.meal.eatenAt.day),
    };
    return ExportCounts(meals: meals.length, days: days.length);
  }

  /// T-022: los archivos de exportaciones anteriores (con datos de salud)
  /// se borran al empezar una nueva. Solo los que crea esta app, por su
  /// nombre; nunca otros archivos del directorio. Un fallo al borrar no
  /// impide exportar.
  Future<void> deletePreviousExports() async {
    try {
      final dir = Directory(_directoryPath);
      if (!await dir.exists()) return;
      await for (final entity in dir.list()) {
        if (entity is File && isExportFileName(p.basename(entity.path))) {
          try {
            await entity.delete();
          } catch (_) {
            // Ver comentario arriba.
          }
        }
      }
    } catch (_) {
      // Ver comentario arriba.
    }
  }

  /// Devuelve la ruta del archivo compartido, o `null` si no había comidas
  /// en el periodo (CSV y PDF; AC6: no se crea archivo). El JSON siempre
  /// exporta todo, sin filtro.
  Future<String?> export(ExportFormat format, ExportRange range) async {
    await deletePreviousExports();
    final stamp = _clock().toIso8601String().replaceAll(':', '-');
    final String path;
    switch (format) {
      case ExportFormat.json:
        final json = await _storage.exportUserData();
        path = '$_directoryPath/calorias_ia_export_$stamp.json';
        await File(path)
            .writeAsString(const JsonEncoder.withIndent('  ').convert(json));
      case ExportFormat.csv:
        final meals = await _meals(range);
        if (meals.isEmpty) return null;
        path = '$_directoryPath/kcalcula_ia_comidas_$stamp.csv';
        await File(path).writeAsString(buildMealsCsv(meals));
      case ExportFormat.pdf:
        final meals = await _meals(range);
        if (meals.isEmpty) return null;
        final weights = (await _storage.weightEntries(from: range.from))
            .where((w) => range.contains(w.day))
            .toList();
        final report = buildSummaryReport(
          meals: meals,
          range: range,
          goal: await _storage.getNutritionGoal(),
          weights: weights,
        );
        final fonts = await _loadFonts();
        final Uint8List bytes = await renderSummaryPdf(
          report,
          regular: fonts.regular,
          bold: fonts.bold,
        );
        path = '$_directoryPath/kcalcula_ia_resumen_$stamp.pdf';
        await File(path).writeAsBytes(bytes);
    }
    await _sharing.shareFile(path, subject: 'Mis datos de KCalcula IA');
    return path;
  }
}

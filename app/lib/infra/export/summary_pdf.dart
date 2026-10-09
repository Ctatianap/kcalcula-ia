import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'summary_report.dart';

/// SPEC-016 R3: PDF A4 del resumen, con Outfit embebida (la misma fuente de
/// la app, OFL 1.1) para los acentos y la "ñ". Pagina solo (MultiPage).
Future<Uint8List> renderSummaryPdf(
  SummaryReport report, {
  required pw.Font regular,
  required pw.Font bold,
}) {
  final doc = pw.Document(
    title: report.title,
    author: 'KCalcula IA',
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );
  const grey = PdfColor.fromInt(0xFF5F6B7A);
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      footer: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Divider(color: grey),
          pw.Text(
            report.footer,
            style: const pw.TextStyle(fontSize: 9, color: grey),
          ),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              '${context.pageNumber} / ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: grey),
            ),
          ),
        ],
      ),
      build: (context) => [
        pw.Text(
          report.title,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(report.period),
        pw.SizedBox(height: 12),
        if (report.goal != null) pw.Text(report.goal!),
        pw.Text(report.average),
        if (report.daysOnGoal != null) pw.Text(report.daysOnGoal!),
        if (report.weights.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          for (final w in report.weights) pw.Text(w),
        ],
        if (report.days.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          pw.Text(
            'Totales por día',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: reportTableHeader,
            data: [for (final day in report.days) day.cells],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellAlignments: {
              for (var i = 1; i < reportTableHeader.length; i++)
                i: pw.Alignment.centerRight,
            },
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Comidas por día',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          for (final day in report.days) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              day.cells.first,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            for (final meal in day.meals)
              pw.Text(meal, style: const pw.TextStyle(fontSize: 10)),
          ],
        ],
      ],
    ),
  );
  return doc.save();
}

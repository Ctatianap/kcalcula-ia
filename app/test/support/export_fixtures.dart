import 'dart:io';

import 'package:calorias_ia/infra/export/export_service.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:pdf/widgets.dart' as pw;

MealItemRecord exportItem(
  String name, {
  double grams = 100,
  double kcal = 143,
  double p = 12.56,
  double c = 0.72,
  double f = 9.51,
  String confidence = 'buenaEstimacion',
  String sourceRef = 'fixture de prueba',
}) => MealItemRecord(
  mention: name.toLowerCase(),
  foodId: name.toLowerCase(),
  nameSnapshot: name,
  grams: grams,
  quantityBasis: 'unitPortion',
  energyKcal: kcal,
  proteinG: p,
  carbsG: c,
  fatG: f,
  confidence: confidence,
  sourceRef: sourceRef,
);

Future<void> exportMeal(
  StorageRepository repo,
  DateTime at,
  List<MealItemRecord> items, {
  String type = 'almuerzo',
}) => repo.registerMeal(
  eatenAt: at,
  mealType: type,
  confidence: 'buenaEstimacion',
  catalogVersion: 'test-1',
  items: items,
);

/// Outfit leída del disco (sin depender del bundle de assets).
Future<PdfFonts> testPdfFonts() async {
  pw.Font font(String name) => pw.Font.ttf(
    File('assets/fonts/$name').readAsBytesSync().buffer.asByteData(),
  );
  return (regular: font('Outfit-Regular.ttf'), bold: font('Outfit-Medium.ttf'));
}

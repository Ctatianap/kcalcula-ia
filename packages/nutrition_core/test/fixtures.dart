import 'package:nutrition_core/nutrition_core.dart';

/// Alimentos de prueba deterministas (no son datos reales del catálogo).
FoodCatalogEntry buildFood({
  String id = 'test-food',
  String nameEs = 'alimento de prueba',
  double energyKcal100g = 100,
  double proteinG100g = 10,
  double carbsG100g = 10,
  double fatG100g = 5,
  double? densityGPerMl,
  List<PortionOption> portions = const [],
}) => FoodCatalogEntry(
  id: id,
  nameEs: nameEs,
  sourceId: 'usda_fdc',
  sourceRef: 'fixture de prueba',
  energyKcal100g: energyKcal100g,
  proteinG100g: proteinG100g,
  carbsG100g: carbsG100g,
  fatG100g: fatG100g,
  densityGPerMl: densityGPerMl,
  portions: portions,
);

PortionOption buildPortion({
  required String descriptor,
  required double grams,
  bool isCuratedEstimate = false,
}) => PortionOption(
  descriptor: descriptor,
  grams: grams,
  sourceId: 'usda_fdc',
  sourceRef: 'fixture de prueba',
  isCuratedEstimate: isCuratedEstimate,
);

import 'package:calorias_ia/features/capture/label_confirmation_controller.dart';
import 'package:calorias_ia/infra/ai_client/label_extraction_dto.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:calorias_ia/infra/food_resolution/food_query_resolver.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_core/nutrition_core.dart';

LabelExtractionDto _extraction({
  String? productName = 'Producto de prueba',
  LabelServingSizeDto? servingSize = const LabelServingSizeDto(
    quantity: 30,
    unit: 'g',
  ),
  LabelNutrientSetDto? perServing = const LabelNutrientSetDto(
    energyKcal: 140,
    proteinG: 2,
    carbsG: 20,
    fatG: 6,
  ),
  LabelNutrientSetDto? per100,
  List<String> unreadableFields = const [],
}) => LabelExtractionDto(
  productName: productName,
  servingSize: servingSize,
  perServing: perServing,
  per100: per100,
  unreadableFields: unreadableFields,
);

void main() {
  late AppDatabase db;
  late StorageRepository storage;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    storage = StorageRepository(db);
  });

  tearDown(() => db.close());

  test(
    'AC2: valores dentro de Atwater -> canSave sin necesitar confirmación',
    () {
      final controller = LabelConfirmationController(
        extraction: _extraction(),
        storage: storage,
      );
      expect(controller.needsAtwaterConfirmation, isFalse);
      expect(controller.canSave, isTrue);
    },
  );

  test('AC3: valores fuera de Atwater bloquean canSave hasta confirmar', () {
    final controller = LabelConfirmationController(
      extraction: _extraction(
        perServing: const LabelNutrientSetDto(
          energyKcal: 500,
          proteinG: 1,
          carbsG: 1,
          fatG: 1,
        ),
      ),
      storage: storage,
    );
    expect(controller.needsAtwaterConfirmation, isTrue);
    expect(controller.canSave, isFalse);

    controller.setAtwaterConfirmedDespiteWarning(true);
    expect(controller.canSave, isTrue);
  });

  test('AC4: campo no legible queda null y no bloquea otros campos', () {
    final controller = LabelConfirmationController(
      extraction: _extraction(
        perServing: const LabelNutrientSetDto(
          energyKcal: 140,
          proteinG: 2,
          carbsG: 20,
          fatG: null,
        ),
        unreadableFields: const ['fat_g'],
      ),
      storage: storage,
    );
    expect(controller.fatG, isNull);
    expect(controller.unreadableFields, contains('fat_g'));
    // R3: los 4 macros son obligatorios -> no se puede guardar hasta
    // completar el que no se pudo leer.
    expect(controller.canSave, isFalse);
    controller.setFatG(6);
    expect(controller.canSave, isTrue);
  });

  test('deriva "por porción" cuando la etiqueta solo dio "por 100"', () {
    final controller = LabelConfirmationController(
      extraction: _extraction(
        perServing: null,
        per100: const LabelNutrientSetDto(
          energyKcal: 466.7,
          proteinG: 6.7,
          carbsG: 66.7,
          fatG: 20,
        ),
      ),
      storage: storage,
    );
    // 30 g de porción -> factor 0.3
    expect(controller.energyKcal, closeTo(140.01, 0.1));
    expect(controller.fatG, closeTo(6, 0.01));
  });

  test('porción faltante o <= 0 bloquea canSave (R3)', () {
    final controller = LabelConfirmationController(
      extraction: _extraction(servingSize: null),
      storage: storage,
    );
    expect(controller.canSave, isFalse);
    controller.setServingQuantity(0);
    expect(controller.canSave, isFalse);
    controller.setServingQuantity(30);
    expect(controller.canSave, isTrue);
  });

  test(
    'AC5: save() normaliza a por-100g ("30 g = 140 kcal" -> 466.67 kcal/100g)',
    () async {
      final controller = LabelConfirmationController(
        extraction: _extraction(),
        storage: storage,
      );
      expect(controller.canSave, isTrue);

      final name = await controller.save();
      expect(name, 'Producto de prueba');

      final saved = await storage.getAllPersonalProducts();
      expect(saved, hasLength(1));
      expect(saved.first.energyKcal100, closeTo(466.67, 0.01));
      expect(saved.first.proteinG100, closeTo(6.67, 0.01));
      expect(saved.first.servingGrams, 30);
      expect(saved.first.sourceRef, contains('confirmada por el usuario'));
    },
  );

  test('consumedQuantity por defecto es la porción (R5)', () {
    final controller = LabelConfirmationController(
      extraction: _extraction(),
      storage: storage,
    );
    expect(controller.consumedQuantity, 30);
  });

  group('SPEC-030 R4: missingForSave', () {
    test('lista lo que falta en el orden de la pantalla', () {
      final controller = LabelConfirmationController(
        extraction: _extraction(
          productName: null,
          servingSize: null,
          perServing: const LabelNutrientSetDto(
            energyKcal: null,
            proteinG: null,
            carbsG: null,
            fatG: null,
          ),
        ),
        storage: storage,
      );
      expect(controller.missingForSave, [
        'nombre del producto',
        'porción',
        'calorías',
        'proteína',
        'carbohidratos',
        'grasa',
        'cuánto comiste',
      ]);
      expect(controller.canSave, isFalse);
    });

    test('Atwater sin confirmar es lo único que falta, hasta confirmarlo', () {
      final controller = LabelConfirmationController(
        extraction: _extraction(
          perServing: const LabelNutrientSetDto(
            energyKcal: 500,
            proteinG: 1,
            carbsG: 1,
            fatG: 1,
          ),
        ),
        storage: storage,
      );
      expect(controller.missingForSave, [
        'confirmar que los valores son correctos',
      ]);
      controller.setAtwaterConfirmedDespiteWarning(true);
      expect(controller.missingForSave, isEmpty);
      expect(controller.canSave, isTrue);
    });
  });

  test(
    'SPEC-032 AC4: la vista previa da lo mismo que Revisar para 3 porciones',
    () async {
      final controller = LabelConfirmationController(
        extraction: _extraction(
          servingSize: const LabelServingSizeDto(quantity: 27, unit: 'g'),
          perServing: const LabelNutrientSetDto(
            energyKcal: 70,
            proteinG: 2.8,
            carbsG: 15,
            fatG: 0.2,
          ),
        ),
        storage: storage,
      );
      controller.setPortionsCount(3);
      expect(controller.registeredQuantity, 81);
      final preview = controller.preview!;

      // Revisar: el producto guardado, leído y convertido como en la app,
      // con la misma resolución de cantidad (SPEC-004 R6).
      await controller.save();
      final saved = (await storage.getAllPersonalProducts()).single;
      final food = personalProductToFoodCatalogEntry(saved);
      final grams = resolveGrams(
        input: const QuantityInput(
          quantity: 81,
          unit: QuantityUnit.gramos,
          isVague: false,
        ),
        food: food,
        isLabelProduct: true,
      ).grams!;
      expect(preview.grams, grams);
      expect(preview.nutrients, calculateItemNutrients(food, grams));
    },
  );

  group('SPEC-032 casos borde', () {
    LabelConfirmationController controller27() => LabelConfirmationController(
      extraction: _extraction(
        servingSize: const LabelServingSizeDto(quantity: 27, unit: 'g'),
      ),
      storage: storage,
    );

    test('3 porciones → g → cambiar la porción no reescribe los 81 g', () {
      final c = controller27()..setPortionsCount(3);
      c.setConsumedUnit(ConsumedUnit.servingUnit);
      expect(c.registeredQuantity, 81);
      c.setServingQuantity(30);
      expect(c.registeredQuantity, 81);
    });

    test('1 porción → g sigue a la porción (SPEC-031)', () {
      final c = controller27()..setConsumedUnit(ConsumedUnit.servingUnit);
      c.setServingQuantity(30);
      expect(c.registeredQuantity, 30);
    });

    test('"0" porciones: falta cuánto comiste y no hay vista previa', () {
      final c = controller27()..setPortionsCount(0);
      expect(c.missingForSave, ['cuánto comiste']);
      expect(c.preview, isNull);
    });

    test('porciones sin porción válida: falta porción y cuánto comiste', () {
      final c = controller27()..setServingQuantity(null);
      expect(c.registeredQuantity, 0);
      expect(c.missingForSave, ['porción', 'cuánto comiste']);
      expect(c.preview, isNull);
    });

    test('etiqueta en ml: 2 porciones de 200 ml registran 400 ml', () {
      final c = LabelConfirmationController(
        extraction: _extraction(
          servingSize: const LabelServingSizeDto(quantity: 200, unit: 'ml'),
          perServing: const LabelNutrientSetDto(
            energyKcal: 90,
            proteinG: 6,
            carbsG: 10,
            fatG: 3,
          ),
        ),
        storage: storage,
      )..setPortionsCount(2);
      expect(c.registeredQuantity, 400);
      expect(c.servingUnit, 'ml');
      expect(c.preview, isNotNull);
    });
  });
}

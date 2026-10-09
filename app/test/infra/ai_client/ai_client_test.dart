import 'package:calorias_ia/infra/ai_client/ai_client.dart';
import 'package:calorias_ia/infra/ai_client/ai_client_errors.dart';
import 'package:calorias_ia/infra/ai_client/meal_correction_dto.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'parseMeal devuelve un ParsedMealDto con la respuesta del caller',
    () async {
      final client = AiClient((data) async {
        expect(data, {'text': 'una manzana', 'locale': 'es-CO'});
        return {
          'schema_version': 'parsed_meal.v1',
          'meal_type': null,
          'items': [
            {
              'mention': 'una manzana',
              'food_query': 'manzana',
              'quantity': 1,
              'unit': 'unidad',
              'size': null,
              'preparation': null,
              'is_vague': false,
              'parent_index': null,
            },
          ],
        };
      });

      final result = await client.parseMeal(text: 'una manzana');
      expect(result.items, hasLength(1));
      expect(result.items.first.foodQuery, 'manzana');
    },
  );

  test('una FirebaseException (p. ej. deadline-exceeded) se traduce a AiClientException de red', () async {
    final client = AiClient((data) async {
      throw FirebaseException(
        plugin: 'firebase_functions',
        code: 'deadline-exceeded',
      );
    });

    await expectLater(
      () => client.parseMeal(text: 'arroz'),
      throwsA(
        isA<AiClientException>().having(
          (e) => e.type,
          'type',
          AiClientErrorType.network,
        ),
      ),
    );
  });

  test('cualquier otro error (p. ej. sin red antes de llamar) -> AiClientException de red', () async {
    final client = AiClient((data) async {
      throw Exception('socket error');
    });

    await expectLater(
      () => client.parseMeal(text: 'arroz'),
      throwsA(
        isA<AiClientException>().having(
          (e) => e.type,
          'type',
          AiClientErrorType.network,
        ),
      ),
    );
  });

  test(
    'extractLabel devuelve un LabelExtractionDto con la respuesta del caller',
    () async {
      final client = AiClient((data) async => {}, (data) async {
        expect(data, {'image_base64': 'YWJj', 'mime_type': 'image/jpeg'});
        return {
          'schema_version': 'label_extraction.v1',
          'product_name': 'Producto de prueba',
          'serving_size': {'quantity': 30, 'unit': 'g'},
          'per_serving': {
            'energy_kcal': 140,
            'protein_g': 2,
            'carbs_g': 20,
            'fat_g': 6,
            'fiber_g': null,
            'sugar_g': null,
            'sodium_mg': null,
          },
          'per_100': null,
          'unreadable_fields': [],
        };
      });

      final result = await client.extractLabel(
        imageBase64: 'YWJj',
        mimeType: 'image/jpeg',
      );
      expect(result.productName, 'Producto de prueba');
      expect(result.servingSize?.quantity, 30);
      expect(result.perServing?.energyKcal, 140);
    },
  );

  test('extractLabel sin caller configurado lanza StateError', () async {
    final client = AiClient((data) async => {});
    await expectLater(
      () => client.extractLabel(imageBase64: 'abc', mimeType: 'image/jpeg'),
      throwsA(isA<StateError>()),
    );
  });

  test('extractLabel traduce errores igual que parseMeal', () async {
    final client = AiClient((data) async => {}, (data) async {
      throw FirebaseException(
        plugin: 'firebase_functions',
        code: 'deadline-exceeded',
      );
    });

    await expectLater(
      () => client.extractLabel(imageBase64: 'abc', mimeType: 'image/jpeg'),
      throwsA(
        isA<AiClientException>().having(
          (e) => e.type,
          'type',
          AiClientErrorType.network,
        ),
      ),
    );
  });

  test(
    'SPEC-024: correctMeal envía corrección e ítems y devuelve las operaciones',
    () async {
      final client = AiClient((_) async => {}, null, (data) async {
        expect(data['correction'], 'eran tres huevos');
        expect(data['locale'], 'es-CO');
        expect(data['items'], [
          {
            'mention': 'dos huevos',
            'food_query': 'huevo',
            'quantity': 2.0,
            'unit': 'unidad',
            'size': null,
          },
        ]);
        return {
          'schema_version': 'meal_correction.v1',
          'operations': [
            {
              'op': 'set_quantity',
              'index': 0,
              'item': null,
              'quantity': 3,
              'unit': 'unidad',
              'size': null,
            },
          ],
        };
      });
      final result = await client.correctMeal(
        correction: 'eran tres huevos',
        items: const [
          CorrectionDraftItem(
            mention: 'dos huevos',
            foodQuery: 'huevo',
            quantity: 2,
            unit: 'unidad',
          ),
        ],
      );
      expect(result.operations.single.op, 'set_quantity');
      expect(result.operations.single.quantity, 3);
    },
  );

  test(
    'SPEC-024: sin red, correctMeal lanza el error de red en español',
    () async {
      final client = AiClient((_) async => {}, null, (_) async {
        throw FirebaseException(
          plugin: 'firebase_functions',
          code: 'unavailable',
        );
      });
      await expectLater(
        client.correctMeal(correction: 'x', items: const []),
        throwsA(
          isA<AiClientException>().having(
            (e) => e.type,
            'type',
            AiClientErrorType.network,
          ),
        ),
      );
    },
  );
}

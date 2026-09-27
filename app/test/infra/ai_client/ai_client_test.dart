import 'package:calorias_ia/infra/ai_client/ai_client.dart';
import 'package:calorias_ia/infra/ai_client/ai_client_errors.dart';
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
}

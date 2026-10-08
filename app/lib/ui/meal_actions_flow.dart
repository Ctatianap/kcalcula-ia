import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_routes.dart';
import '../infra/catalog/catalog_providers.dart';
import '../infra/food_resolution/food_query_resolver.dart';
import '../infra/food_resolution/meal_draft.dart';
import '../infra/food_resolution/recent_meals.dart';
import '../infra/storage/storage_providers.dart';
import '../infra/storage/storage_repository.dart';
import 'components/meal_actions.dart';

/// SPEC-037: el menú al mantener presionada una comida, compartido por Hoy
/// e Historial (las features no se importan entre sí).
const repeatUnavailableMessage =
    'No puedo repetir esta comida: algún alimento ya no está en la base.';

/// Muestra el menú en [position] y hace la acción elegida. Llama a
/// [onChanged] cuando la comida se borró o se volvió de editarla/repetirla,
/// para que la pantalla se recargue.
Future<void> handleMealLongPress(
  BuildContext context,
  WidgetRef ref, {
  required MealWithItems meal,
  required RelativeRect position,
  required bool canRepeatToday,
  required VoidCallback onChanged,
}) async {
  final action = await showMealActionsMenu(
    context,
    position: position,
    canRepeatToday: canRepeatToday,
  );
  if (action == null || !context.mounted) return;
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final storage = ref.read(storageRepositoryProvider);
  switch (action) {
    case MealAction.edit:
      await navigator.pushNamed(AppRoutes.editMeal, arguments: meal.meal.id);
      onChanged();
    case MealAction.repeatToday:
      final MealDraft? draft;
      try {
        draft = await loadRepeatDraft(
          storage,
          (products) => FoodQueryResolver(
            catalog: ref.read(catalogRepositoryProvider),
            personalProducts: products,
          ),
          meal,
        );
      } catch (_) {
        // SPEC-009: sin el texto de SQLite.
        messenger.showSnackBar(
          const SnackBar(content: Text(repeatUnavailableMessage)),
        );
        return;
      }
      if (draft == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text(repeatUnavailableMessage)),
        );
        return;
      }
      await navigator.pushNamed(AppRoutes.review, arguments: draft);
      onChanged();
    case MealAction.delete:
      if (!context.mounted) return;
      final confirmed = await confirmDeleteMeal(
        context,
        mealType: meal.meal.mealType,
        eatenAt: meal.meal.eatenAt,
      );
      if (!confirmed) return;
      try {
        await storage.deleteMeal(meal.meal.id);
      } catch (_) {
        // SPEC-009: sin el texto de SQLite.
        messenger.showSnackBar(
          const SnackBar(content: Text(deleteMealErrorMessage)),
        );
        return;
      }
      onChanged();
      messenger.showSnackBar(const SnackBar(content: Text(mealDeletedMessage)));
  }
}

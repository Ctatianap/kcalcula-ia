import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_routes.dart';
import '../infra/catalog/catalog_providers.dart';
import '../infra/food_resolution/food_query_resolver.dart';
import '../infra/food_resolution/meal_draft.dart';
import '../infra/food_resolution/recent_meals.dart';
import '../infra/storage/storage_providers.dart';
import '../format/text_es.dart';
import '../infra/storage/storage_repository.dart';
import 'components/meal_actions.dart';
import 'favorite_flow.dart';

/// SPEC-037: el menú al mantener presionada una comida, compartido por Hoy
/// e Historial (las features no se importan entre sí).
///
/// Muestra el menú en [position] y hace la acción elegida. Llama a
/// [onChanged] cuando la comida se borró o se volvió de editarla/repetirla,
/// para que la pantalla se recargue. "Repetir hoy"/"Repetir ahora" (SPEC-038)
/// solo aparece si
/// [canRepeat] y todos sus alimentos siguen existiendo (como en
/// SPEC-026 R4); "Guardar como favorita" (SPEC-022), si existen.
Future<void> handleMealLongPress(
  BuildContext context,
  WidgetRef ref, {
  required MealWithItems meal,
  required RelativeRect position,
  required bool canRepeat,

  /// SPEC-038 R2: "Repetir ahora" (hoy) o "Repetir hoy" (otro día).
  required bool mealIsToday,
  required VoidCallback onChanged,
}) async {
  final storage = ref.read(storageRepositoryProvider);
  // SPEC-022 R2: el borrador también sirve para "Guardar como favorita".
  MealDraft? draft;
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
    // SPEC-009: sin repetir ni favorita si no se pudo leer; el resto del
    // menú funciona.
    draft = null;
  }
  final repeatDraft = canRepeat ? draft : null;
  if (!context.mounted) return;
  final action = await showMealActionsMenu(
    context,
    position: position,
    canRepeat: repeatDraft != null,
    mealIsToday: mealIsToday,
    canSaveFavorite: draft != null,
  );
  if (action == null || !context.mounted) return;
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  switch (action) {
    case MealAction.edit:
      await navigator.pushNamed(AppRoutes.editMeal, arguments: meal.meal.id);
      onChanged();
    case MealAction.repeatToday:
      await navigator.pushNamed(AppRoutes.review, arguments: repeatDraft);
      onChanged();
    case MealAction.saveFavorite:
      await saveMealAsFavorite(
        context,
        ref,
        draft: draft!,
        defaultName: joinNamesEs([for (final i in meal.items) i.nameSnapshot]),
      );
    case MealAction.delete:
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

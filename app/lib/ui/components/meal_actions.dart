/// Acciones sobre una comida guardada, compartidas por "Editar comida",
/// Hoy e Historial (las features no se importan entre sí).
library;

import 'package:flutter/material.dart';

import '../../format/date_format_es.dart';
import '../theme.dart';

/// SPEC-026 R3 / SPEC-037 R3.
const deleteMealErrorMessage = 'No pude borrar la comida. Intenta de nuevo.';

/// SPEC-037 R2.
const mealDeletedMessage = 'Comida eliminada.';

/// SPEC-037 R1.
const editMealAction = 'Editar comida';
const repeatTodayAction = 'Repetir hoy';

/// SPEC-038 R2: repetir una comida de hoy a la hora actual.
const repeatNowAction = 'Repetir ahora';

/// SPEC-038: el texto de "repetir" según el día de la comida.
String repeatLabelFor({required bool mealIsToday}) =>
    mealIsToday ? repeatNowAction : repeatTodayAction;
const deleteMealAction = 'Eliminar comida';

/// SPEC-022 R2.
const saveFavoriteAction = 'Guardar como favorita';

/// SPEC-037 R4.
const mealCardHint = 'Toca para editar. Mantén presionado para más opciones';
const moreOptionsAction = 'Más opciones';
const longPressOnlyHint = 'Mantén presionado para más opciones';

enum MealAction { edit, repeatToday, saveFavorite, delete }

/// SPEC-026 R3: "el desayuno", "el almuerzo", "la cena", "el snack".
String mealWithArticle(String? mealType) => switch (mealType) {
  'desayuno' => 'el desayuno',
  'almuerzo' => 'el almuerzo',
  'cena' => 'la cena',
  _ => 'el snack',
};

/// SPEC-026 R3 / SPEC-037 R2: "¿Borrar el almuerzo de las 13:00?". `true`
/// solo si la persona confirma.
Future<bool> confirmDeleteMeal(
  BuildContext context, {
  required String? mealType,
  required DateTime eatenAt,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        '¿Borrar ${mealWithArticle(mealType)} de las ${timeEs(eatenAt)}?',
      ),
      content: const Text('No se puede deshacer.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Borrar'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// SPEC-037 R1: menú junto a la tarjeta, con el estilo del ⋮ de los
/// ingredientes (SPEC-033).
Future<MealAction?> showMealActionsMenu(
  BuildContext context, {
  required RelativeRect position,
  required bool canRepeat,
  required bool mealIsToday,

  /// SPEC-022 R2: solo si todos sus alimentos siguen existiendo.
  bool canSaveFavorite = false,
}) {
  return showMenu<MealAction>(
    context: context,
    position: position,
    items: [
      const PopupMenuItem(
        value: MealAction.edit,
        child: ListTile(
          leading: Icon(Icons.edit_outlined),
          title: Text(editMealAction),
        ),
      ),
      if (canRepeat)
        PopupMenuItem(
          value: MealAction.repeatToday,
          child: ListTile(
            leading: const Icon(Icons.replay),
            title: Text(repeatLabelFor(mealIsToday: mealIsToday)),
          ),
        ),
      if (canSaveFavorite)
        const PopupMenuItem(
          value: MealAction.saveFavorite,
          child: ListTile(
            leading: Icon(Icons.star_outline),
            title: Text(saveFavoriteAction),
          ),
        ),
      const PopupMenuItem(
        value: MealAction.delete,
        child: ListTile(
          leading: Icon(Icons.delete_outline, color: KColors.error),
          title: Text(deleteMealAction, style: TextStyle(color: KColors.error)),
        ),
      ),
    ],
  );
}

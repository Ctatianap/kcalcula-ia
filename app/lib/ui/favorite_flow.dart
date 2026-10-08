import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../infra/food_resolution/meal_draft.dart';
import '../infra/food_resolution/recent_meals.dart';
import '../infra/storage/storage_providers.dart';
import '../infra/storage/storage_repository.dart';

/// SPEC-022 R2: "Guardar como favorita", compartido por "¿Qué comiste?",
/// Hoy, Historial y el detalle de una comida guardada (las features no se
/// importan entre sí).
const saveFavoriteAction = 'Guardar como favorita';
const removeFavoriteAction = 'Quitar de favoritas';
const favoriteSavedMessage = 'Guardada en favoritas.';
const favoriteDuplicateMessage = 'Ya la tienes en favoritas.';
const favoriteLimitMessage =
    'Ya tienes $maxFavoriteMeals favoritas. Quita una para añadir otra.';
const favoriteRemovedMessage = 'Quitada de favoritas.';
const favoriteSaveErrorMessage =
    'No pude guardar la favorita. Intenta de nuevo.';
const favoriteRemoveErrorMessage =
    'No pude quitar la favorita. Intenta de nuevo.';
const favoriteUnavailableMessage = 'Algún alimento ya no está en la base';

/// SPEC-022 Edge Cases: nombre de hasta 40 caracteres.
const favoriteNameMaxLength = 40;

/// Pide el nombre (opcional; por defecto [defaultName]) y guarda [draft]
/// como favorita. Muestra el resultado y devuelve `true` si se guardó.
Future<bool> saveMealAsFavorite(
  BuildContext context,
  WidgetRef ref, {
  required MealDraft draft,
  required String defaultName,
}) async {
  final name = await _askFavoriteName(context, defaultName);
  if (name == null || !context.mounted) return false;
  // El aviso nuevo reemplaza al anterior en vez de quedar en cola.
  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
  SaveFavoriteResult result;
  try {
    result = await ref
        .read(storageRepositoryProvider)
        .saveFavoriteMeal(name: name, items: favoriteItemsOf(draft));
  } catch (_) {
    // SPEC-009: sin el texto de SQLite.
    messenger.showSnackBar(
      const SnackBar(content: Text(favoriteSaveErrorMessage)),
    );
    return false;
  }
  messenger.showSnackBar(
    SnackBar(
      content: Text(switch (result) {
        SaveFavoriteResult.saved => favoriteSavedMessage,
        SaveFavoriteResult.duplicate => favoriteDuplicateMessage,
        SaveFavoriteResult.limitReached => favoriteLimitMessage,
      }),
    ),
  );
  return result == SaveFavoriteResult.saved;
}

/// SPEC-022 R2: quita la favorita [id]. Devuelve `true` si se quitó.
Future<bool> removeFavoriteMeal(
  BuildContext context,
  WidgetRef ref,
  int id,
) async {
  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
  try {
    await ref.read(storageRepositoryProvider).deleteFavoriteMeal(id);
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text(favoriteRemoveErrorMessage)),
    );
    return false;
  }
  messenger.showSnackBar(const SnackBar(content: Text(favoriteRemovedMessage)));
  return true;
}

/// El nombre escrito (recortado) o [defaultName] si quedó vacío; `null` si
/// se cancela.
Future<String?> _askFavoriteName(BuildContext context, String defaultName) {
  final fallback = defaultName.length > favoriteNameMaxLength
      ? defaultName.substring(0, favoriteNameMaxLength)
      : defaultName;
  return showDialog<String>(
    context: context,
    builder: (context) => _FavoriteNameDialog(defaultName: fallback),
  );
}

class _FavoriteNameDialog extends StatefulWidget {
  final String defaultName;

  const _FavoriteNameDialog({required this.defaultName});

  @override
  State<_FavoriteNameDialog> createState() => _FavoriteNameDialogState();
}

class _FavoriteNameDialogState extends State<_FavoriteNameDialog> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final text = _name.text.trim();
    Navigator.of(context).pop(text.isEmpty ? widget.defaultName : text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(saveFavoriteAction),
      content: TextField(
        key: const Key('favorite-name'),
        controller: _name,
        autofocus: true,
        maxLength: favoriteNameMaxLength,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: 'Nombre (opcional)',
          hintText: widget.defaultName,
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}

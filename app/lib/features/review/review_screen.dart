import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infra/ai_client/parsed_meal_dto.dart';
import '../../infra/catalog/catalog_providers.dart';
import '../../infra/clock.dart';
import '../../infra/food_resolution/food_query_resolver.dart';
import '../../infra/food_resolution/meal_draft.dart';
import '../../format/text_es.dart';
import '../../infra/food_resolution/recent_meals.dart' show draftFromMeal;
import '../../app_routes.dart';
import '../../infra/storage/app_database.dart' show PersonalProduct;
import '../../infra/storage/storage_repository.dart' show MealWithItems;
import '../../infra/storage/storage_providers.dart';
import '../../ui/components/meal_actions.dart'
    show repeatLabelFor, repeatTodayAction;
import '../../ui/favorite_flow.dart';
import 'meal_analysis_controller.dart' show readErrorMessage;
import 'meal_detail_view.dart';
import 'review_controller.dart';

export 'meal_analysis_controller.dart' show readErrorMessage;
export 'meal_detail_view.dart' show registerErrorMessage;

/// SPEC-026: la comida que se pidió editar ya no existe.
const mealGoneMessage = 'Esa comida ya no existe.';

/// Detalle de una comida que ya llega estructurada sin pasar por
/// "Analizando": la etiqueta confirmada de SPEC-004 ([parsedMeal]), una
/// comida reciente de SPEC-017 ([draft]) o una comida guardada para
/// editarla (SPEC-026, [editMealId]).
class ReviewScreen extends ConsumerStatefulWidget {
  final ParsedMealDto? parsedMeal;
  final MealDraft? draft;
  final int? editMealId;

  const ReviewScreen({super.key, this.parsedMeal, this.draft, this.editMealId})
    : assert(
        (parsedMeal != null ? 1 : 0) +
                (draft != null ? 1 : 0) +
                (editMealId != null ? 1 : 0) ==
            1,
      );

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  // SPEC-009 R4: errores de `user.db` con mensaje en español, sin
  // relanzar (el texto de SQLite trae los datos de la comida).
  bool _loadFailed = false;

  /// SPEC-026: la comida a editar se borró en otra pantalla.
  bool _mealGone = false;

  ReviewController? _controller;

  /// SPEC-026 R4 / SPEC-038 R2: la comida guardada como borrador, para
  /// repetirla ("Repetir hoy" o "Repetir ahora").
  MealDraft? _repeatDraft;
  String _repeatLabel = repeatTodayAction;

  /// SPEC-022 R2: nombre por defecto de la favorita.
  String _favoriteName = '';

  @override
  void initState() {
    super.initState();
    _loadController();
  }

  /// SPEC-004 R7 (búsqueda integrada): los productos personales viven en
  /// `user.db` (Drift, async) — se cargan una vez aquí como una lista en
  /// memoria para que el resto de `ReviewController`/`FoodQueryResolver`
  /// siga siendo síncrono.
  Future<void> _loadController() async {
    final storage = ref.read(storageRepositoryProvider);
    final List<PersonalProduct> personalProducts;
    final Map<int, List<String>> aliases;
    MealWithItems? savedMeal;
    try {
      personalProducts = await storage.getAllPersonalProducts();
      aliases = await storage.getPersonalProductAliases();
      final editId = widget.editMealId;
      if (editId != null) {
        savedMeal = await storage.getMealWithItems(editId);
        if (savedMeal == null) {
          if (mounted) setState(() => _mealGone = true);
          return;
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
      return;
    }
    if (!mounted) return;
    final resolver = FoodQueryResolver(
      catalog: ref.read(catalogRepositoryProvider),
      personalProducts: personalProducts,
      aliases: aliases,
    );
    final now = ref.read(clockProvider)();
    final draft = widget.draft;
    setState(() {
      _loadFailed = false;
      if (savedMeal != null) {
        _controller = ReviewController.forEdit(
          meal: savedMeal,
          resolver: resolver,
          storage: storage,
        );
        final day = savedMeal.meal.eatenAt;
        final isToday =
            day.year == now.year &&
            day.month == now.month &&
            day.day == now.day;
        // SPEC-038 R2: también las de hoy ("Repetir ahora").
        _repeatDraft = draftFromMeal(savedMeal, resolver);
        _repeatLabel = repeatLabelFor(mealIsToday: isToday);
        _favoriteName = joinNamesEs([
          for (final i in savedMeal.items) i.nameSnapshot,
        ]);
        return;
      }
      _controller = draft != null
          ? ReviewController.fromDraft(
              draft: draft,
              resolver: resolver,
              storage: storage,
              now: now,
            )
          : ReviewController(
              parsedMeal: widget.parsedMeal!,
              resolver: resolver,
              storage: storage,
              now: now,
            );
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller != null) {
      final repeatDraft = _repeatDraft;
      return MealDetailView(
        controller: controller,
        onCorrect: () => Navigator.of(context).maybePop(),
        // SPEC-026 R4 / SPEC-038 R2: solo si sus alimentos existen.
        repeatLabel: _repeatLabel,
        onRepeatToday: repeatDraft == null
            ? null
            : () => Navigator.of(
                context,
              ).pushReplacementNamed(AppRoutes.review, arguments: repeatDraft),
        // SPEC-022 R2: con los mismos alimentos que repetir.
        onSaveFavorite: repeatDraft == null
            ? null
            : () => saveMealAsFavorite(
                context,
                ref,
                draft: repeatDraft,
                defaultName: _favoriteName,
              ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de comida')),
      body: _mealGone
          ? const Center(child: Text(mealGoneMessage))
          : _loadFailed
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(readErrorMessage),
                  TextButton(
                    onPressed: () {
                      setState(() => _loadFailed = false);
                      _loadController();
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

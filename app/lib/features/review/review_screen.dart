import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infra/ai_client/parsed_meal_dto.dart';
import '../../infra/catalog/catalog_providers.dart';
import '../../infra/clock.dart';
import '../../infra/food_resolution/food_query_resolver.dart';
import '../../infra/food_resolution/meal_draft.dart';
import '../../infra/storage/app_database.dart' show PersonalProduct;
import '../../infra/storage/storage_providers.dart';
import 'meal_analysis_controller.dart' show readErrorMessage;
import 'meal_detail_view.dart';
import 'review_controller.dart';

export 'meal_analysis_controller.dart' show readErrorMessage;
export 'meal_detail_view.dart' show registerErrorMessage;

/// Detalle de una comida que ya llega estructurada sin pasar por
/// "Analizando": la etiqueta confirmada de SPEC-004 ([parsedMeal]) o una
/// comida reciente de SPEC-017 ([draft]).
class ReviewScreen extends ConsumerStatefulWidget {
  final ParsedMealDto? parsedMeal;
  final MealDraft? draft;

  const ReviewScreen({super.key, this.parsedMeal, this.draft})
    : assert((parsedMeal == null) != (draft == null));

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  // SPEC-009 R4: errores de `user.db` con mensaje en español, sin
  // relanzar (el texto de SQLite trae los datos de la comida).
  bool _loadFailed = false;

  ReviewController? _controller;

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
    try {
      personalProducts = await storage.getAllPersonalProducts();
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
      return;
    }
    if (!mounted) return;
    final resolver = FoodQueryResolver(
      catalog: ref.read(catalogRepositoryProvider),
      personalProducts: personalProducts,
    );
    final now = ref.read(clockProvider)();
    final draft = widget.draft;
    setState(() {
      _loadFailed = false;
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
      return MealDetailView(
        controller: controller,
        onCorrect: () => Navigator.of(context).maybePop(),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de comida')),
      body: _loadFailed
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

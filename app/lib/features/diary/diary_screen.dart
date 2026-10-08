import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrition_core/nutrition_core.dart';

import '../../app_routes.dart';
import '../../infra/clock.dart';
import '../../infra/storage/storage_providers.dart';
import '../../ui/components/k_card.dart';
import '../../ui/components/macro_cards.dart';
import '../../ui/components/main_nav_bar.dart';
import '../../ui/components/meal_card.dart';
import '../../ui/components/progress_ring.dart';
import '../../ui/theme.dart';
import 'diary_controller.dart';
import 'diary_format.dart';
import 'streak.dart';

/// SPEC-011: "Hoy" (saludo, semana, kcal, macros y comidas del día).
class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key});

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  late Future<DiarySummary> _summaryFuture;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _now = ref.read(clockProvider)();
    _summaryFuture = loadDiarySummary(
      ref.read(storageRepositoryProvider),
      _now,
    );
  }

  Future<void> _openCapture() async {
    await Navigator.of(context).pushNamed(AppRoutes.capture);
    if (mounted) setState(_reload);
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).pushNamed(AppRoutes.settings);
    if (mounted) setState(_reload);
  }

  Future<void> _openObjective() async {
    await Navigator.of(context).pushNamed(AppRoutes.objective);
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // SPEC-010 R4: barra inferior con Hoy / Historial / Progreso y +.
      bottomNavigationBar: MainNavBar(
        current: MainTab.today,
        onAdd: _openCapture,
      ),
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<DiarySummary>(
          future: _summaryFuture,
          builder: (context, snapshot) {
            // SPEC-009 R4: una lectura fallida no deja el spinner para siempre.
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No pude leer tus datos. Intenta de nuevo.'),
                    TextButton(
                      onPressed: () => setState(_reload),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final summary = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _Header(
                  now: _now,
                  streak: summary.streak,
                  onSettings: _openSettings,
                ),
                _WeekStrip(week: summary.week),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: _KcalCard(summary: summary, onSetGoal: _openObjective),
                ),
                if (summary.goal != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _MacroCards(summary: summary),
                  ),
                if (summary.meals.isEmpty)
                  const _EmptyDay()
                else
                  _TodayMeals(meals: summary.meals),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// R1: saludo, fecha y Ajustes.
class _Header extends StatelessWidget {
  final DateTime now;
  final int streak;
  final VoidCallback onSettings;

  const _Header({
    required this.now,
    required this.streak,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greetingFor(now),
                  key: const Key('diary-greeting'),
                  style: text.headlineLarge?.copyWith(fontSize: 34),
                ),
                const SizedBox(height: 2),
                // La píldora va con la fecha (no junto al saludo): con
                // texto grande el saludo conserva todo el ancho y baja de
                // línea entre palabras; si no cabe, la píldora pasa abajo.
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      longDateEs(now),
                      style: text.bodyMedium?.copyWith(
                        color: KColors.textSecondary,
                      ),
                    ),
                    _StreakPill(days: streak),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Ajustes',
            onPressed: onSettings,
          ),
        ],
      ),
    );
  }
}

/// SPEC-019 R2/R3: días seguidos registrando, en tono neutro (sin mensajes
/// de pérdida; con 0 muestra 0).
class _StreakPill extends StatelessWidget {
  final int days;

  const _StreakPill({required this.days});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: streakSemantics(days),
      excludeSemantics: true,
      child: Container(
        key: const Key('streak-pill'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: KColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_fire_department_outlined,
              size: 18,
              color: KColors.accent,
            ),
            const SizedBox(width: 4),
            Text(
              '$days',
              key: const Key('streak-count'),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: KColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// R2: lunes a domingo, con un anillo por día pasado con registros.
class _WeekStrip extends StatelessWidget {
  final List<WeekDaySummary> week;

  const _WeekStrip({required this.week});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [for (final day in week) Expanded(child: _WeekDay(day: day))],
      ),
    );
  }
}

class _WeekDay extends StatelessWidget {
  final WeekDaySummary day;

  const _WeekDay({required this.day});

  static const _statusColors = {
    DayStatus.belowGoal: DayGoalStatus.belowGoal,
    DayStatus.onGoal: DayGoalStatus.onGoal,
    DayStatus.aboveGoal: DayGoalStatus.aboveGoal,
  };

  String get _semantics {
    final base = longDateEs(day.date);
    if (day.isToday) return '$base, hoy';
    if (!day.hasMeals) return '$base, sin registros';
    final status = _statusColors[day.status]?.label;
    return status == null ? '$base, con registros' : '$base, $status';
  }

  @override
  Widget build(BuildContext context) {
    final number = Text(
      '${day.date.day}',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: day.isToday
            ? KColors.background
            : day.isFuture
            ? KColors.textSecondary
            : KColors.text,
      ),
    );
    final Widget circle;
    if (day.isToday) {
      circle = Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: KColors.accent,
          shape: BoxShape.circle,
        ),
        child: number,
      );
    } else if (day.hasMeals && day.status != null) {
      final status = _statusColors[day.status]!;
      circle = ProgressRing(
        key: Key('week-ring-${day.date.day}'),
        fraction: day.fraction,
        size: 40,
        strokeWidth: 2,
        color: status.color,
        center: number,
      );
    } else if (day.hasMeals) {
      // Sin meta: no hay anillo de meta (R7); un fondo suave marca que hubo
      // registros.
      circle = Container(
        key: Key('week-day-logged-${day.date.day}'),
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: KColors.surface,
          shape: BoxShape.circle,
        ),
        child: number,
      );
    } else {
      circle = SizedBox(width: 40, height: 40, child: Center(child: number));
    }
    // Un nodo por día: sin `container`, los siete se fusionaban en uno.
    final tap = day.isFuture
        ? null
        : () => Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.history,
            (route) => false,
            arguments: day.date,
          );
    // La acción va en el nodo semántico con la etiqueta del día; con
    // `excludeSemantics` la del InkWell no llegaría al lector de pantalla.
    final column = Semantics(
      container: true,
      label: _semantics,
      excludeSemantics: true,
      button: !day.isFuture,
      onTap: tap,
      child: Column(
        children: [
          Text(
            weekdayInitials[day.date.weekday - 1],
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: KColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          circle,
        ],
      ),
    );
    // SPEC-013 AC5: tocar un día abre el Historial en ese día; los días
    // futuros no hacen nada.
    if (day.isFuture) return column;
    return InkWell(
      key: Key('week-day-${day.date.day}'),
      borderRadius: BorderRadius.circular(20),
      // El nodo de arriba ya expone la acción: este no crea otro sin
      // etiqueta.
      excludeFromSemantics: true,
      onTap: tap,
      child: column,
    );
  }
}

/// R4/R7: kcal consumidas frente a la meta (o sin meta).
class _KcalCard extends StatelessWidget {
  final DiarySummary summary;
  final VoidCallback onSetGoal;

  const _KcalCard({required this.summary, required this.onSetGoal});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final goal = summary.goal;
    final consumed = summary.dayTotals.energyKcal;
    final approx = summary.isApproximate ? '~' : '';
    String k(double v) => formatThousandsEs(presentKcal(v));
    final big = Text(
      '$approx${k(consumed)}',
      key: const Key('kcal-consumed'),
      style: const TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w300,
        height: 1,
        letterSpacing: -1,
      ),
    );
    if (goal == null) {
      return KCard(
        radius: 28,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            big,
            const SizedBox(height: 6),
            Text(
              'kcal consumidas hoy',
              style: text.bodyMedium?.copyWith(color: KColors.textSecondary),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onSetGoal,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: const Text('Calcular mi meta'),
            ),
          ],
        ),
      );
    }
    final progress = GoalProgress(consumed: consumed, goal: goal.energyKcal);
    final detail = progress.isOverGoal
        ? '${k(progress.excess)} por encima de la meta'
        : 'quedan ${k(progress.remaining)}';
    return KCard(
      radius: 28,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 4,
                  children: [
                    big,
                    Text(
                      '/${k(goal.energyKcal)}',
                      key: const Key('kcal-goal'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: KColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'kcal consumidas · $detail',
                  key: const Key('kcal-detail'),
                  style: text.bodyMedium?.copyWith(
                    color: KColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ProgressRing(
            fraction: progress.fraction,
            size: 84,
            strokeWidth: 5,
            semanticsLabel:
                '${k(consumed)} de ${k(goal.energyKcal)} kcal, $detail',
            center: const Icon(
              Icons.local_fire_department_outlined,
              color: KColors.accent,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

/// R5: un anillo por macro, en su color.
class _MacroCards extends StatelessWidget {
  final DiarySummary summary;

  const _MacroCards({required this.summary});

  @override
  Widget build(BuildContext context) {
    final goal = summary.goal!;
    final totals = summary.dayTotals;
    return MacroCards(
      macros: [
        (
          label: 'Proteína',
          grams: totals.proteinG,
          goal: goal.proteinG,
          color: KColors.protein,
        ),
        (
          label: 'Carbohidratos',
          grams: totals.carbsG,
          goal: goal.carbsG,
          color: KColors.carbs,
        ),
        (
          label: 'Grasa',
          grams: totals.fatG,
          goal: goal.fatG,
          color: KColors.fat,
        ),
      ],
    );
  }
}

/// R8: sin comidas hoy.
class _EmptyDay extends StatelessWidget {
  const _EmptyDay();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 0),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: KColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant_outlined,
              size: 48,
              color: KColors.text,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Todavía no registras nada hoy',
            textAlign: TextAlign.center,
            style: text.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Toca + y cuéntame qué comiste: con una foto, por texto o con tu '
            'voz.',
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: KColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// R6: tarjetas por comida, en orden por hora.
class _TodayMeals extends StatelessWidget {
  final List<DiaryMealSummary> meals;

  const _TodayMeals({required this.meals});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Agregado hoy', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          for (final meal in meals) ...[
            _MealCard(summary: meal),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final DiaryMealSummary summary;

  const _MealCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final meal = summary.meal.meal;
    return MealCard(
      label: mealTypeLabels[meal.mealType] ?? 'Snack',
      time: timeEs(meal.eatenAt),
      items: [
        for (final i in summary.meal.items)
          (name: i.nameSnapshot, grams: i.grams),
      ],
      totals: summary.totals,
      // SPEC-026 R1.
      onTap: () =>
          Navigator.of(context)
              .pushNamed(AppRoutes.editMeal, arguments: meal.id),
    );
  }
}

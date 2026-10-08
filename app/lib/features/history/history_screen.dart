import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrition_core/nutrition_core.dart';

import '../../app_routes.dart';
import '../../infra/clock.dart';
import '../../infra/storage/storage_providers.dart';
import '../../ui/components/k_card.dart';
import '../../ui/components/main_nav_bar.dart';
import '../../ui/components/meal_card.dart';
import '../../format/date_format_es.dart';
import '../../ui/theme.dart';
import 'history_controller.dart';

/// SPEC-013: calendario del mes con el estado de cada día y el detalle del
/// día elegido.
class HistoryScreen extends ConsumerStatefulWidget {
  /// R3: día que llega desde la semana de "Hoy" (por defecto, hoy).
  final DateTime? initialDay;

  const HistoryScreen({super.key, this.initialDay});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

const _statusStyles = {
  DayStatus.belowGoal: DayGoalStatus.belowGoal,
  DayStatus.onGoal: DayGoalStatus.onGoal,
  DayStatus.aboveGoal: DayGoalStatus.aboveGoal,
};

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  late final DateTime _today;
  late DateTime _month;
  DateTime? _selected;
  late Future<HistoryMonth> _future;

  @override
  void initState() {
    super.initState();
    _today = _dayOf(ref.read(clockProvider)());
    final initial = widget.initialDay == null
        ? _today
        : _dayOf(widget.initialDay!);
    _selected = initial.isAfter(_today) ? _today : initial;
    _month = DateTime(_selected!.year, _selected!.month);
    _load();
  }

  void _load() {
    _future = loadHistoryMonth(ref.read(storageRepositoryProvider), _month);
  }

  bool get _isCurrentMonth =>
      _month.year == _today.year && _month.month == _today.month;

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _selected = _isCurrentMonth ? _today : null;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Atrás vuelve a Hoy en vez de cerrar la app (SPEC-010, Edge Cases).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) backToToday(context);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Historial')),
        bottomNavigationBar: MainNavBar(
          current: MainTab.history,
          onAdd: () => openCaptureFromTab(context),
        ),
        body: FutureBuilder<HistoryMonth>(
          future: _future,
          builder: (context, snapshot) {
            // SPEC-009 R4: una lectura fallida no deja el spinner.
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No pude leer tus datos. Intenta de nuevo.'),
                    TextButton(
                      onPressed: () => setState(_load),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }
            final data = snapshot.data;
            if (data == null ||
                snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final selected = _selected;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MonthHeader(
                    month: _month,
                    canGoNext: !_isCurrentMonth,
                    onPrevious: () => _changeMonth(-1),
                    onNext: () => _changeMonth(1),
                  ),
                  const SizedBox(height: 8),
                  _CalendarGrid(
                    data: data,
                    today: _today,
                    selected: selected,
                    onSelect: (day) => setState(() => _selected = day),
                  ),
                  const SizedBox(height: 12),
                  _Legend(hasGoal: data.goal != null),
                  const SizedBox(height: 16),
                  if (selected == null)
                    Text(
                      'Toca un día para ver qué comiste.',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: KColors.textSecondary),
                    )
                  else
                    _DayDetail(
                      date: selected,
                      day: data.days[selected.day],
                      goal: data.goal?.energyKcal,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// R1: "septiembre 2026" con Mes anterior / Mes siguiente.
class _MonthHeader extends StatelessWidget {
  final DateTime month;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _MonthHeader({
    required this.month,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Mes anterior',
          onPressed: onPrevious,
        ),
        Expanded(
          child: Text(
            '${monthsEs[month.month - 1]} ${month.year}',
            key: const Key('history-month'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Mes siguiente',
          onPressed: canGoNext ? onNext : null,
        ),
      ],
    );
  }
}

/// R1/R2: grilla de lunes a domingo.
class _CalendarGrid extends StatelessWidget {
  final HistoryMonth data;
  final DateTime today;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelect;

  const _CalendarGrid({
    required this.data,
    required this.today,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final month = data.month;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Edge case: la grilla siempre empieza en lunes.
    final leading = month.weekday - 1;
    final cells = <Widget>[
      for (var i = 0; i < leading; i++) const SizedBox.shrink(),
      for (var d = 1; d <= daysInMonth; d++)
        _DayCell(
          date: DateTime(month.year, month.month, d),
          day: data.days[d],
          isToday: DateTime(month.year, month.month, d) == today,
          isFuture: DateTime(month.year, month.month, d).isAfter(today),
          isSelected: selected == DateTime(month.year, month.month, d),
          onTap: onSelect,
        ),
    ];
    while (cells.length % 7 != 0) {
      cells.add(const SizedBox.shrink());
    }
    return Column(
      children: [
        Row(
          children: [
            for (final initial in weekdayInitials)
              Expanded(
                child: Text(
                  initial,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: KColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var row = 0; row < cells.length; row += 7)
          Row(
            children: [
              for (final cell in cells.sublist(row, row + 7))
                Expanded(child: cell),
            ],
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final HistoryDay? day;
  final bool isToday;
  final bool isFuture;
  final bool isSelected;
  final ValueChanged<DateTime> onTap;

  const _DayCell({
    required this.date,
    required this.day,
    required this.isToday,
    required this.isFuture,
    required this.isSelected,
    required this.onTap,
  });

  String get _semantics {
    final base = longDateEs(date);
    if (isFuture) return base;
    final d = day;
    if (d == null) return '$base, sin registros';
    final status = d.status;
    return status == null
        ? '$base, con registros'
        : '$base, ${_statusStyles[status]!.label}';
  }

  @override
  Widget build(BuildContext context) {
    final d = day;
    final status = d?.status;
    final Color? fill;
    final Color? border;
    if (d == null || isFuture) {
      fill = null;
      border = null;
    } else if (status != null) {
      final color = _statusStyles[status]!.color;
      fill = color.withValues(alpha: 0.16);
      border = color;
    } else {
      // R4: sin meta, un solo color neutro para los días con registros.
      fill = KColors.surface;
      border = KColors.textSecondary;
    }
    final circle = Container(
      key: Key('history-day-${date.day}'),
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: border == null ? null : Border.all(color: border, width: 2),
      ),
      child: Text(
        '${date.day}',
        style: TextStyle(
          fontSize: 14,
          fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
          color: isFuture
              ? KColors.textSecondary.withValues(alpha: 0.5)
              : KColors.text,
        ),
      ),
    );
    final tap = isFuture ? null : () => onTap(date);
    // La acción va en el propio nodo semántico: con `excludeSemantics` la del
    // InkWell no llegaría a TalkBack/VoiceOver.
    return Semantics(
      container: true,
      label: _semantics,
      selected: isSelected,
      button: !isFuture,
      onTap: tap,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: tap,
          // 36 + 2 × 6 = 48 px de alto tocable (SPEC-010 R7).
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? KColors.navSelected : null,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: circle),
          ),
        ),
      ),
    );
  }
}

/// R2: leyenda de estados (sin rojo ni verde) y nota de la meta actual.
class _Legend extends StatelessWidget {
  final bool hasGoal;

  const _Legend({required this.hasGoal});

  @override
  Widget build(BuildContext context) {
    const secondary = TextStyle(fontSize: 12, color: KColors.textSecondary);
    if (!hasGoal) {
      return const Text(
        'Los días con registros van marcados. Fija una meta para ver cómo '
        'te fue cada día.',
        style: secondary,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            for (final status in [
              DayGoalStatus.onGoal,
              DayGoalStatus.belowGoal,
              DayGoalStatus.aboveGoal,
            ])
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: status.color.withValues(alpha: 0.16),
                      border: Border.all(color: status.color, width: 2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(status.label, style: const TextStyle(fontSize: 13)),
                ],
              ),
          ],
        ),
        const SizedBox(height: 6),
        // Edge case: sin historial de metas (SPEC-008).
        const Text('Comparado con tu meta actual', style: secondary),
      ],
    );
  }
}

/// R3: fecha, % de la meta, kcal, totales por tipo de comida y comidas.
class _DayDetail extends StatelessWidget {
  final DateTime date;
  final HistoryDay? day;
  final double? goal;

  const _DayDetail({required this.date, required this.day, required this.goal});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final d = day;
    const secondary = TextStyle(fontSize: 14, color: KColors.textSecondary);
    String k(double v) => formatThousandsEs(presentKcal(v));
    final header = Text(
      longDateEs(date),
      key: const Key('history-selected-date'),
      style: text.titleLarge,
    );
    if (d == null) {
      return KCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            const SizedBox(height: 6),
            const Text('Sin registros este día.', style: secondary),
          ],
        ),
      );
    }
    final approx = d.isApproximate ? '~' : '';
    final consumed = d.totals.energyKcal;
    final g = goal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KCard(
          radius: 28,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              const SizedBox(height: 8),
              if (g != null) ...[
                Text(
                  '${presentPercent(GoalProgress(consumed: consumed, goal: g).ratio)}'
                  ' % de tu meta',
                  key: const Key('history-percent'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                Text(
                  '$approx${k(consumed)} de ${k(g)} kcal',
                  key: const Key('history-kcal'),
                  style: secondary,
                ),
                // El estado en texto, no solo en color (SPEC-010): evita leer
                // un "90 %" redondeado como si fuera "en tu meta".
                if (d.status != null)
                  Text(
                    _statusStyles[d.status]!.label,
                    key: const Key('history-status'),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
              ] else
                Text(
                  '$approx${k(consumed)} kcal',
                  key: const Key('history-kcal'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              const SizedBox(height: 12),
              for (final type in historyMealTypes)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(child: Text(mealTypeLabels[type]!)),
                      Text(
                        '${k(d.byMealType[type]!.energyKcal)} kcal',
                        key: Key('history-type-$type'),
                        style: secondary,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Comidas', style: text.titleMedium),
        const SizedBox(height: 10),
        for (final meal in d.meals) ...[
          MealCard(
            label: mealTypeLabels[meal.meal.mealType] ?? 'Snack',
            time: timeEs(meal.meal.eatenAt),
            items: [
              for (final i in meal.items)
                (name: i.nameSnapshot, grams: i.grams),
            ],
            totals: meal.totals,
            // SPEC-026 R1.
            onTap: () =>
                Navigator.of(context)
                    .pushNamed(AppRoutes.editMeal, arguments: meal.meal.id),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:nutrition_core/nutrition_core.dart';

import '../../ui/components/k_card.dart';
import '../../ui/date_format_es.dart';
import '../../ui/number_input_es.dart';
import '../../ui/theme.dart';

const weightSaveErrorMessage = 'No pude guardar tu peso. Intenta de nuevo.';
const weightDeleteErrorMessage =
    'No pude borrar el registro. Intenta de nuevo.';
const weightGoalNotRecalculatedMessage =
    'Guardé tu peso, pero con él tu objetivo quedaría fuera del rango que '
    'maneja la app (800 a 6.000 kcal), así que tu meta no cambió.';

/// "62,0 kg".
String formatKg(double kg) => '${formatMacroEs(kg)} kg';

/// SPEC-015 R4: "−0,4 kg esta semana", "+0,3 kg esta semana" o "sin
/// cambios". Tono neutro: el signo no lleva color.
String weightChangeText(double change) {
  final rounded = presentMacro(change);
  if (rounded == 0) return 'sin cambios';
  final sign = rounded < 0 ? '−' : '+';
  return '$sign${formatMacroEs(rounded.abs())} kg esta semana';
}

/// Lectura para el lector de pantalla, sin depender de cómo pronuncie "−".
String weightChangeSemantics(double change) {
  final rounded = presentMacro(change);
  if (rounded == 0) return 'Sin cambios esta semana';
  final verb = rounded < 0 ? 'Bajaste' : 'Subiste';
  return '$verb ${formatMacroEs(rounded.abs())} kg esta semana';
}

/// SPEC-015 R2: `null` si el texto no es un peso válido (30–300 kg, un
/// decimal).
double? parseWeightKg(String text) {
  final kg = parseDecimal(text);
  if (kg == null || kg < estimationWeightMinKg || kg > estimationWeightMaxKg) {
    return null;
  }
  return kg;
}

/// Diálogo "Anotar peso"; devuelve los kg válidos o `null` si se cancela.
Future<double?> showLogWeightDialog(BuildContext context, {double? initial}) {
  return showDialog<double>(
    context: context,
    builder: (context) => _LogWeightDialog(initial: initial),
  );
}

class _LogWeightDialog extends StatefulWidget {
  final double? initial;

  const _LogWeightDialog({this.initial});

  @override
  State<_LogWeightDialog> createState() => _LogWeightDialogState();
}

class _LogWeightDialogState extends State<_LogWeightDialog> {
  late final _controller = TextEditingController(
    text: widget.initial == null ? '' : formatMacroEs(widget.initial!),
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final kg = parseWeightKg(_controller.text);
    if (kg == null) {
      setState(() => _error = weightRangeMessage);
      return;
    }
    Navigator.of(context).pop(kg);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Con texto grande el contenido se desplaza en vez de desbordarse.
      scrollable: true,
      title: const Text('Anotar peso'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Se guarda con la fecha de hoy.'),
          const SizedBox(height: 12),
          TextField(
            key: const Key('weight-input'),
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Peso (kg)',
              errorText: _error,
              errorMaxLines: 3,
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _save(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}

/// SPEC-015 R4/R5: último peso, cambio de la semana, gráfico del periodo y
/// registros del periodo con la opción de borrar.
class WeightCard extends StatelessWidget {
  final List<WeightEntry> allWeights;
  final List<WeightEntry> periodWeights;

  /// Si el último registro tiene más de 7 días, "esta semana" ya no aplica:
  /// se muestra su fecha en lugar del cambio.
  final DateTime today;
  final VoidCallback onLogWeight;
  final ValueChanged<WeightEntry> onDelete;

  const WeightCard({
    super.key,
    required this.allWeights,
    required this.periodWeights,
    required this.today,
    required this.onLogWeight,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const secondary = TextStyle(fontSize: 14, color: KColors.textSecondary);
    final latest = latestWeight(allWeights);
    final latestIsRecent =
        latest != null &&
        !latest.date.isBefore(DateTime(today.year, today.month, today.day - 7));
    final change = latestIsRecent ? weeklyWeightChange(allWeights) : null;
    return KCard(
      radius: 28,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text('Peso', style: text.titleMedium)),
          const SizedBox(height: 4),
          if (latest == null)
            const Text('Todavía no anotas tu peso.', style: secondary)
          else ...[
            Text(
              formatKg(latest.kg),
              key: const Key('weight-latest'),
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w300),
            ),
            if (change != null)
              Semantics(
                label: weightChangeSemantics(change),
                excludeSemantics: true,
                child: Text(
                  weightChangeText(change),
                  key: const Key('weight-change'),
                  style: secondary,
                ),
              )
            else if (!latestIsRecent)
              Text(
                'Último registro: ${longDateEs(latest.date)}',
                key: const Key('weight-last-date'),
                style: secondary,
              ),
          ],
          if (periodWeights.length >= 2) ...[
            const SizedBox(height: 16),
            _WeightLineChart(entries: periodWeights),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onLogWeight,
            icon: const Icon(Icons.monitor_weight_outlined),
            label: const Text('Anotar peso'),
          ),
          if (periodWeights.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Registros del periodo', style: text.titleSmall),
            for (final entry in periodWeights.reversed)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${longDateEs(entry.date)} · ${formatKg(entry.kg)}',
                    ),
                  ),
                  IconButton(
                    key: Key(
                      'weight-delete-${entry.date.day}-${entry.date.month}',
                    ),
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Borrar registro del ${longDateEs(entry.date)}',
                    onPressed: () => onDelete(entry),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

/// Línea simple de los registros del periodo, con su lectura en una sola
/// etiqueta semántica.
class _WeightLineChart extends StatelessWidget {
  final List<WeightEntry> entries;

  const _WeightLineChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    // Resumen corto: el detalle está en la lista "Registros del periodo".
    String at(WeightEntry e) =>
        '${formatKg(e.kg)} el ${e.date.day} de ${monthsEs[e.date.month - 1]}';
    final kgs = entries.map((e) => e.kg);
    final minKg = kgs.reduce((a, b) => a < b ? a : b);
    final maxKg = kgs.reduce((a, b) => a > b ? a : b);
    final label =
        'Gráfico de peso con ${entries.length} registros: de '
        '${at(entries.first)} a ${at(entries.last)}; mínimo '
        '${formatKg(minKg)}, máximo ${formatKg(maxKg)}.';
    return Semantics(
      key: const Key('weight-chart'),
      container: true,
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        height: 90,
        width: double.infinity,
        child: CustomPaint(painter: _WeightLinePainter(entries)),
      ),
    );
  }
}

class _WeightLinePainter extends CustomPainter {
  final List<WeightEntry> entries;

  _WeightLinePainter(this.entries);

  @override
  void paint(Canvas canvas, Size size) {
    final first = entries.first.date;
    final spanDays = entries.last.date.difference(first).inHours / 24;
    final kgs = entries.map((e) => e.kg);
    final minKg = kgs.reduce((a, b) => a < b ? a : b);
    final maxKg = kgs.reduce((a, b) => a > b ? a : b);
    // Al menos 1 kg de rango para que una variación mínima no se vea enorme.
    final range = (maxKg - minKg) < 1 ? 1.0 : maxKg - minKg;
    final mid = (maxKg + minKg) / 2;
    Offset point(WeightEntry e) {
      final x = spanDays <= 0
          ? size.width / 2
          : e.date.difference(first).inHours / 24 / spanDays * size.width;
      final y = size.height / 2 - (e.kg - mid) / range * (size.height - 12);
      return Offset(x, y);
    }

    final line = Paint()
      ..color = KColors.accent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (final (i, e) in entries.indexed) {
      final p = point(e);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, line);
    final dot = Paint()..color = KColors.accent;
    for (final e in entries) {
      canvas.drawCircle(point(e), 3.5, dot);
    }
  }

  @override
  bool shouldRepaint(_WeightLinePainter old) => old.entries != entries;
}

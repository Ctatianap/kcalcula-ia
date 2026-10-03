import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infra/clock.dart';
import '../../infra/export/export_range.dart';
import '../../infra/export/export_service.dart';
import '../../infra/sharing/sharing_providers.dart';
import '../../infra/storage/storage_providers.dart';
import '../../ui/components/k_card.dart';
import '../../format/date_format_es.dart';
import '../../ui/theme.dart';

const noMealsInPeriodMessage = 'No hay comidas en este periodo.';
const exportErrorMessage = 'No pude crear el archivo. Intenta de nuevo.';
const exportReadyMessage = 'Exportación lista.';
const exportNote =
    'El archivo se crea en tu teléfono y tú eliges dónde guardarlo.';

/// SPEC-016 R1: periodo de CSV y PDF.
enum ExportPeriodChoice { all, last30, custom }

/// Proveedor inyectable de la carga de fuentes del PDF (los tests la
/// reemplazan para no depender del bundle).
final pdfFontsLoaderProvider = Provider<Future<PdfFonts> Function()>(
  (ref) => loadPdfFonts,
);

/// SPEC-016: "Exportar mis datos" con periodo y formato.
class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  late final ExportService _service;
  late final DateTime _today;
  ExportFormat _format = ExportFormat.csv;
  ExportPeriodChoice _period = ExportPeriodChoice.all;
  DateTimeRange? _customRange;
  late Future<ExportCounts> _counts;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final now = ref.read(clockProvider)();
    _today = DateTime(now.year, now.month, now.day);
    _service = ExportService(
      storage: ref.read(storageRepositoryProvider),
      sharing: ref.read(sharingServiceProvider),
      directoryPath: ref.read(exportDirectoryPathProvider),
      loadFonts: ref.read(pdfFontsLoaderProvider),
      clock: ref.read(clockProvider),
    );
    _loadCounts();
  }

  /// El JSON siempre exporta todo (R1).
  ExportRange get _range {
    if (_format == ExportFormat.json) return const ExportRange.all();
    return switch (_period) {
      ExportPeriodChoice.all => const ExportRange.all(),
      ExportPeriodChoice.last30 => ExportRange.last30Days(_today),
      ExportPeriodChoice.custom => ExportRange(
        from: _customRange?.start,
        to: _customRange?.end,
      ),
    };
  }

  void _loadCounts() => _counts = _service.count(_range);

  void _update(VoidCallback change) => setState(() {
    change();
    _loadCounts();
  });

  Future<void> _pickDates() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: _today,
      initialDateRange:
          _customRange ??
          DateTimeRange(
            start: DateTime(_today.year, _today.month, _today.day - 6),
            end: _today,
          ),
      helpText: 'Elige las fechas',
    );
    if (picked == null) return;
    _update(() {
      _customRange = picked;
      _period = ExportPeriodChoice.custom;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _export() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final path = await _service.export(_format, _range);
      if (mounted) {
        _showMessage(
          path == null ? noMealsInPeriodMessage : exportReadyMessage,
        );
      }
    } catch (_) {
      // SPEC-009: sin relanzar (el error puede traer datos del diario).
      if (mounted) _showMessage(exportErrorMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _dateEs(DateTime d) =>
      '${d.day} de ${monthsEs[d.month - 1]} de ${d.year}';

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final isJson = _format == ExportFormat.json;
    final custom = _customRange;
    return Scaffold(
      appBar: AppBar(title: const Text('Exportar mis datos')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FutureBuilder<ExportCounts>(
                future: _counts,
                builder: (context, snapshot) {
                  final counts = snapshot.data;
                  return KCard(
                    color: KColors.surfaceSoft,
                    child: snapshot.hasError
                        // SPEC-009 R4: mensaje y Reintentar.
                        ? Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'No pude leer tus datos. Intenta de nuevo.',
                                ),
                              ),
                              TextButton(
                                onPressed: () => _update(() {}),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          )
                        : counts == null
                        ? const Text('Contando tus registros…')
                        : counts.meals == 0
                        ? const Text(
                            noMealsInPeriodMessage,
                            key: Key('export-summary'),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${counts.meals} '
                                '${counts.meals == 1 ? 'comida' : 'comidas'} · '
                                '${counts.days} '
                                '${counts.days == 1 ? 'día' : 'días'}',
                                key: const Key('export-summary'),
                                style: text.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(switch (_format) {
                                ExportFormat.json =>
                                  'Perfil, objetivo, peso y diario completo',
                                ExportFormat.pdf =>
                                  'Meta, promedios, peso y comidas por día',
                                ExportFormat.csv =>
                                  'Una fila por alimento registrado',
                              }, style: text.bodySmall),
                            ],
                          ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Text('Periodo', style: text.titleMedium),
              const SizedBox(height: 8),
              if (isJson)
                Text(
                  'La copia completa siempre incluye todo tu registro.',
                  style: text.bodySmall,
                )
              else ...[
                SegmentedButton<ExportPeriodChoice>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: ExportPeriodChoice.all,
                      label: Text('Todo'),
                    ),
                    ButtonSegment(
                      value: ExportPeriodChoice.last30,
                      label: Text('Últimos 30 días'),
                    ),
                    ButtonSegment(
                      value: ExportPeriodChoice.custom,
                      label: Text('Elegir fechas'),
                    ),
                  ],
                  selected: {_period},
                  onSelectionChanged: (value) {
                    if (value.first == ExportPeriodChoice.custom) {
                      _pickDates();
                    } else {
                      _update(() => _period = value.first);
                    }
                  },
                ),
                if (_period == ExportPeriodChoice.custom && custom != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Del ${_dateEs(custom.start)} al '
                            '${_dateEs(custom.end)}',
                            key: const Key('export-custom-range'),
                            style: text.bodySmall,
                          ),
                        ),
                        // El segmento ya elegido no responde a otro toque:
                        // este botón permite cambiar las fechas.
                        TextButton(
                          onPressed: _pickDates,
                          child: const Text('Cambiar fechas'),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 20),
              Text('Formato', style: text.titleMedium),
              RadioGroup<ExportFormat>(
                groupValue: _format,
                onChanged: (value) {
                  if (value != null) _update(() => _format = value);
                },
                child: const Column(
                  children: [
                    RadioListTile(
                      key: Key('export-format-csv'),
                      value: ExportFormat.csv,
                      contentPadding: EdgeInsets.zero,
                      title: Text('Hoja de cálculo (CSV)'),
                      subtitle: Text('Ábrelo en Excel o Google Sheets'),
                    ),
                    RadioListTile(
                      key: Key('export-format-pdf'),
                      value: ExportFormat.pdf,
                      contentPadding: EdgeInsets.zero,
                      title: Text('Resumen para imprimir (PDF)'),
                      subtitle: Text('Ideal para tu nutricionista'),
                    ),
                    RadioListTile(
                      key: Key('export-format-json'),
                      value: ExportFormat.json,
                      contentPadding: EdgeInsets.zero,
                      title: Text('Copia completa (JSON)'),
                      subtitle: Text('Para guardar o mover tus datos'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: KColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(exportNote, style: text.bodySmall)),
                ],
              ),
              const SizedBox(height: 16),
              FutureBuilder<ExportCounts>(
                future: _counts,
                builder: (context, snapshot) {
                  final empty = !isJson && (snapshot.data?.meals ?? 1) == 0;
                  return FilledButton(
                    onPressed: _busy || empty ? null : _export,
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              semanticsLabel: 'Exportando…',
                            ),
                          )
                        : const Text('Exportar'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

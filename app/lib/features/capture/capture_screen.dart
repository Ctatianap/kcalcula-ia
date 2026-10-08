import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nutrition_core/nutrition_core.dart';

import '../../app_routes.dart';
import '../../infra/catalog/catalog_providers.dart';
import '../../infra/clock.dart';
import '../../infra/food_resolution/food_query_resolver.dart';
import '../../infra/food_resolution/recent_meals.dart';
import '../../infra/storage/storage_providers.dart';
import '../../ui/components/k_card.dart';
import '../../ui/components/meal_actions.dart'
    show longPressOnlyHint, moreOptionsAction;
import '../../ui/components/privacy_note.dart';
import '../../ui/favorite_flow.dart';
import '../../ui/theme.dart';
import 'label_capture_controller.dart';
import 'label_confirmation_screen.dart';
import 'voice_input_controller.dart';

/// SPEC-012 R1: pestañas de "¿Qué comiste?".
enum CaptureTab { text, voice, photo }

const maxMealTextLength = 500;

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  final _textController = TextEditingController();
  CaptureTab _tab = CaptureTab.text;

  /// Edge case: un doble toque en "Analizar" no abre dos análisis.
  bool _analysisOpen = false;

  /// SPEC-017/022: favoritas, recientes y frecuentes para repetir sin IA.
  /// Si la lectura falla, las secciones simplemente no aparecen (escribir
  /// sigue funcionando).
  late Future<QuickMeals> _quickMeals = _loadQuickMeals();

  static const QuickMeals _noQuickMeals = (
    favorites: <FavoriteQuickMeal>[],
    recents: <RecentMeal>[],
    frequents: <RecentMeal>[],
  );

  Future<QuickMeals> _loadQuickMeals() async {
    try {
      return await loadQuickMeals(
        ref.read(storageRepositoryProvider),
        (personalProducts) => FoodQueryResolver(
          catalog: ref.read(catalogRepositoryProvider),
          personalProducts: personalProducts,
        ),
        now: ref.read(clockProvider)(),
      );
    } catch (_) {
      return _noQuickMeals;
    }
  }

  void _reloadQuickMeals() {
    final next = _loadQuickMeals();
    setState(() {
      _quickMeals = next;
    });
  }

  /// SPEC-022 R2: "Guardar como favorita" desde Recientes o Frecuentes.
  Future<void> _saveFavorite(RecentMeal meal) async {
    final saved = await saveMealAsFavorite(
      context,
      ref,
      draft: meal.draft,
      defaultName: meal.name,
    );
    if (saved && mounted) _reloadQuickMeals();
  }

  /// SPEC-022 R2: "Quitar de favoritas".
  Future<void> _removeFavorite(FavoriteQuickMeal favorite) async {
    final removed = await removeFavoriteMeal(context, ref, favorite.id);
    if (removed && mounted) _reloadQuickMeals();
  }

  /// R3: abre el detalle con los alimentos y gramos ya resueltos.
  Future<void> _openRecent(RecentMeal recent) async {
    if (_analysisOpen) return;
    setState(() => _analysisOpen = true);
    await Navigator.of(context)
        .pushNamed(AppRoutes.review, arguments: recent.draft);
    if (mounted) setState(() => _analysisOpen = false);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// R2: "Analizando" se abre encima; al volver (Cancelar, Volver o
  /// Corregir) el texto sigue aquí intacto.
  Future<void> _analyze() async {
    final text = _textController.text.trim();
    if (_analysisOpen || text.isEmpty || text.length > maxMealTextLength) {
      return;
    }
    setState(() => _analysisOpen = true);
    await Navigator.of(context).pushNamed(AppRoutes.analysis, arguments: text);
    if (mounted) setState(() => _analysisOpen = false);
  }

  void _selectTab(CaptureTab tab) {
    if (tab == _tab) return;
    final voiceState = ref.read(voiceInputControllerProvider);
    if (voiceState is VoiceInputListening) {
      ref.read(voiceInputControllerProvider.notifier).stopListening();
    }
    setState(() => _tab = tab);
  }

  void _toggleListening(VoiceInputState voiceState) {
    final controller = ref.read(voiceInputControllerProvider.notifier);
    if (voiceState is VoiceInputListening) {
      controller.stopListening();
    } else {
      controller.startListening(existingText: _textController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceInputControllerProvider);
    final labelState = ref.watch(labelCaptureControllerProvider);

    // SPEC-004 R1/R2/R7: foto de etiqueta -> extractLabel -> confirmación
    // (nunca directo al detalle: primero el usuario confirma los valores,
    // invariante 2).
    ref.listen<LabelCaptureState>(labelCaptureControllerProvider, (
      previous,
      next,
    ) {
      if (next is LabelCaptureSuccess) {
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (_) =>
                    LabelConfirmationScreen(extraction: next.extraction),
              ),
            )
            .then(
              (_) => ref.read(labelCaptureControllerProvider.notifier).reset(),
            );
      }
    });

    // SPEC-002 R4/R5/R9: la transcripción (parcial o final) rellena el mismo
    // campo de texto que se usa para escribir; sigue siendo editable.
    ref.listen<VoiceInputState>(voiceInputControllerProvider, (previous, next) {
      final text = switch (next) {
        VoiceInputListening(:final text) => text,
        VoiceInputIdle(:final text?) => text,
        _ => null,
      };
      if (text != null) {
        _textController.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
        setState(() {});
      }
    });

    final isAnalyzingLabel = labelState is LabelCaptureLoading;
    final isListening = voiceState is VoiceInputListening;
    final text = _textController.text.trim();
    final canAnalyze =
        !_analysisOpen &&
        !isAnalyzingLabel &&
        !isListening &&
        text.isNotEmpty &&
        text.length <= maxMealTextLength;

    final body = switch (_tab) {
      CaptureTab.text => <Widget>[
        _textField(isListening: false, enabled: !isAnalyzingLabel),
        const SizedBox(height: 12),
        _analyzeButton(canAnalyze),
        FutureBuilder<QuickMeals>(
          future: _quickMeals,
          builder: (context, snapshot) {
            final quick = snapshot.data ?? _noQuickMeals;
            // SPEC-017 R5 / SPEC-022 R5: una sección vacía no se muestra.
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (quick.favorites.isNotEmpty)
                  _QuickMealSection(
                    title: 'Favoritas',
                    keyPrefix: 'favorite-meal',
                    icon: Icons.star,
                    entries: [
                      for (final f in quick.favorites)
                        (
                          name: f.name,
                          meal: f.meal,
                          menuAction: removeFavoriteAction,
                          onMenu: () => _removeFavorite(f),
                        ),
                    ],
                    onOpen: _openRecent,
                  ),
                if (quick.recents.isNotEmpty)
                  _QuickMealSection(
                    title: 'Recientes',
                    keyPrefix: 'recent-meal',
                    icon: Icons.history,
                    entries: [
                      for (final r in quick.recents)
                        (
                          name: r.name,
                          meal: r,
                          menuAction: saveFavoriteAction,
                          onMenu: () => _saveFavorite(r),
                        ),
                    ],
                    onOpen: _openRecent,
                  ),
                if (quick.frequents.isNotEmpty)
                  _QuickMealSection(
                    title: 'Frecuentes',
                    keyPrefix: 'frequent-meal',
                    icon: Icons.repeat,
                    entries: [
                      for (final r in quick.frequents)
                        (
                          name: r.name,
                          meal: r,
                          menuAction: saveFavoriteAction,
                          onMenu: () => _saveFavorite(r),
                        ),
                    ],
                    onOpen: _openRecent,
                  ),
              ],
            );
          },
        ),
      ],
      CaptureTab.voice => <Widget>[
        _VoicePanel(
          voiceState: voiceState,
          enabled: !isAnalyzingLabel,
          onToggle: () => _toggleListening(voiceState),
        ),
        const SizedBox(height: 16),
        _textField(isListening: isListening, enabled: !isAnalyzingLabel),
        const SizedBox(height: 12),
        _analyzeButton(canAnalyze),
      ],
      CaptureTab.photo => <Widget>[
        LabelPhotoPanel(
          labelState: labelState,
          onCamera: () => ref
              .read(labelCaptureControllerProvider.notifier)
              .captureFromCamera(),
          onGallery: () => ref
              .read(labelCaptureControllerProvider.notifier)
              .captureFromGallery(),
        ),
      ],
    };

    return Scaffold(
      appBar: AppBar(title: const Text('¿Qué comiste?')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TabSelector(selected: _tab, onSelected: _selectTab),
                    const SizedBox(height: 20),
                    ...body,
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: PrivacyNote(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField({required bool isListening, required bool enabled}) {
    return TextField(
      controller: _textController,
      // R1: el contador "0/500" lo pinta el propio campo.
      maxLength: maxMealTextLength,
      minLines: 3,
      maxLines: 6,
      enabled: enabled,
      decoration: InputDecoration(
        hintText: 'Ej: dos huevos revueltos y una arepa pequeña con queso',
        // SPEC-002 R10: vaciar el campo para empezar de cero.
        suffixIcon: _textController.text.isNotEmpty && !isListening
            ? IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Borrar texto',
                onPressed: () {
                  ref
                      .read(voiceInputControllerProvider.notifier)
                      .discardPendingResult();
                  setState(_textController.clear);
                },
              )
            : null,
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _analyzeButton(bool canAnalyze) {
    return FilledButton(
      onPressed: canAnalyze ? _analyze : null,
      child: const Text('Analizar'),
    );
  }
}

/// SPEC-022: una tarjeta de Favoritas, Recientes o Frecuentes. [meal] es
/// `null` si algún alimento ya no existe (R4).
typedef _QuickMealEntry = ({
  String name,
  RecentMeal? meal,
  String menuAction,
  VoidCallback onMenu,
});

/// SPEC-017 R1/R2 / SPEC-022 R1/R2: hasta 5 (o 10 favoritas) comidas, con
/// sus kcal de hoy. Mantener presionada abre la acción de favorita.
class _QuickMealSection extends StatelessWidget {
  final String title;
  final String keyPrefix;
  final IconData icon;
  final List<_QuickMealEntry> entries;
  final ValueChanged<RecentMeal> onOpen;

  const _QuickMealSection({
    required this.title,
    required this.keyPrefix,
    required this.icon,
    required this.entries,
    required this.onOpen,
  });

  Future<void> _showMenu(BuildContext context, _QuickMealEntry entry) async {
    final chosen = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: ListTile(
          leading: Icon(
            entry.menuAction == removeFavoriteAction
                ? Icons.star_border
                : Icons.star_outline,
          ),
          title: Text(entry.menuAction),
          onTap: () => Navigator.of(context).pop(true),
        ),
      ),
    );
    if (chosen ?? false) entry.onMenu();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        const SizedBox(height: 8),
        for (final (i, entry) in entries.indexed) ...[
          KCard(
            padding: EdgeInsets.zero,
            radius: 20,
            // Material propio: si no, la tarjeta tapa el efecto del toque.
            child: Material(
              type: MaterialType.transparency,
              // SPEC-022: la acción de favorita también para el lector de
              // pantalla (como las tarjetas de SPEC-037 R4).
              child: Semantics(
                hint: longPressOnlyHint,
                customSemanticsActions: {
                  const CustomSemanticsAction(label: moreOptionsAction): () =>
                      _showMenu(context, entry),
                },
                child: ListTile(
                  key: Key('$keyPrefix-$i'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  leading: Icon(icon, color: KColors.accent),
                  title: Text(entry.name),
                  // SPEC-022 R4: no se abre si algún alimento ya no existe.
                  subtitle: entry.meal == null
                      ? const Text(
                          favoriteUnavailableMessage,
                          style: TextStyle(color: KColors.textSecondary),
                        )
                      : null,
                  trailing: entry.meal == null
                      ? null
                      : Text(
                          // "~" salvo con "Alta precisión" (regla del 15 %,
                          // como el detalle).
                          '${entry.meal!.confidence == ConfidenceLevel.altaPrecision ? '' : '~'}'
                          '${formatThousandsEs(presentKcal(entry.meal!.kcal))} kcal',
                          key: Key('$keyPrefix-kcal-$i'),
                        ),
                  onTap: entry.meal == null ? null : () => onOpen(entry.meal!),
                  onLongPress: () => _showMenu(context, entry),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _TabSelector extends StatelessWidget {
  final CaptureTab selected;
  final ValueChanged<CaptureTab> onSelected;

  const _TabSelector({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<CaptureTab>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: CaptureTab.text,
          icon: Icon(Icons.edit_outlined),
          label: Text('Texto'),
        ),
        ButtonSegment(
          value: CaptureTab.voice,
          icon: Icon(Icons.mic_none),
          label: Text('Voz'),
        ),
        ButtonSegment(
          value: CaptureTab.photo,
          icon: Icon(Icons.photo_camera_outlined),
          label: Text('Foto'),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (value) => onSelected(value.first),
    );
  }
}

/// R1, pestaña Voz: micrófono de SPEC-002.
class _VoicePanel extends StatelessWidget {
  final VoiceInputState voiceState;
  final bool enabled;
  final VoidCallback onToggle;

  const _VoicePanel({
    required this.voiceState,
    required this.enabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isListening = voiceState is VoiceInputListening;
    final error = voiceState;
    return Column(
      children: [
        IconButton.filled(
          iconSize: 40,
          style: IconButton.styleFrom(
            minimumSize: const Size(88, 88),
            backgroundColor: KColors.accent,
            foregroundColor: KColors.background,
          ),
          icon: Icon(isListening ? Icons.stop : Icons.mic),
          tooltip: isListening ? 'Detener' : 'Hablar',
          onPressed: enabled ? onToggle : null,
        ),
        const SizedBox(height: 10),
        Text(
          isListening
              ? 'Escuchando…'
              : 'Toca el micrófono y cuéntame qué comiste.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: KColors.textSecondary),
        ),
        if (error is VoiceInputError)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              error.message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: KColors.error),
            ),
          ),
      ],
    );
  }
}

/// R1, pestaña Foto: tabla nutricional (SPEC-004). La foto del plato es F2.
class LabelPhotoPanel extends StatelessWidget {
  final LabelCaptureState labelState;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const LabelPhotoPanel({
    super.key,
    required this.labelState,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    final loading = labelState is LabelCaptureLoading;
    final state = labelState;
    final textTheme = Theme.of(context).textTheme;
    return KCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 40,
            color: KColors.accent,
          ),
          const SizedBox(height: 10),
          Text(
            'Foto de la tabla nutricional',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'La IA transcribe los valores impresos y tú los confirmas antes de '
            'usarlos.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: KColors.textSecondary),
          ),
          const SizedBox(height: 16),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Analizando foto…'),
                ],
              ),
            )
          else ...[
            FilledButton.icon(
              onPressed: onCamera,
              icon: const Icon(Icons.photo_camera),
              label: const Text('Tomar foto'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('Elegir de la galería'),
            ),
          ],
          if (state is LabelCaptureError)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                state.message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: KColors.error),
              ),
            ),
        ],
      ),
    );
  }
}

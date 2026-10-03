import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../theme.dart';

enum MainTab { today, history, progress }

/// SPEC-010: desde Historial o Progreso, el + abre la captura encima de Hoy
/// (al guardar, la revisión vuelve a un Hoy recién cargado).
void openCaptureFromTab(BuildContext context) {
  Navigator.of(context)
    ..pushNamedAndRemoveUntil(AppRoutes.today, (route) => false)
    ..pushNamed(AppRoutes.capture);
}

/// SPEC-010: Atrás en Historial o Progreso vuelve a Hoy.
void backToToday(BuildContext context) {
  Navigator.of(context)
      .pushNamedAndRemoveUntil(AppRoutes.today, (route) => false);
}

/// SPEC-010 R4: barra inferior de las tres pantallas principales: píldora con
/// Hoy / Historial / Progreso y botón + para registrar. Va en el
/// `bottomNavigationBar` de cada pantalla principal, así no tapa contenido.
class MainNavBar extends StatelessWidget {
  final MainTab current;
  final VoidCallback onAdd;

  const MainNavBar({super.key, required this.current, required this.onAdd});

  static const _routes = {
    MainTab.today: AppRoutes.today,
    MainTab.history: AppRoutes.history,
    MainTab.progress: AppRoutes.progress,
  };

  /// Cambiar de pestaña deja la pila con una sola pantalla principal.
  void _go(BuildContext context, MainTab tab) {
    if (tab == current) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(_routes[tab]!, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // T-021: con texto muy grande la pastilla cede espacio y la
            // etiqueta activa se reduce en vez de desbordar la barra.
            Flexible(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: KColors.background,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: kCardShadow,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: _NavItem(
                          icon: Icons.home_outlined,
                          label: 'Hoy',
                          selected: current == MainTab.today,
                          onTap: () => _go(context, MainTab.today),
                        ),
                      ),
                      Flexible(
                        child: _NavItem(
                          icon: Icons.calendar_month_outlined,
                          label: 'Historial',
                          selected: current == MainTab.history,
                          onTap: () => _go(context, MainTab.history),
                        ),
                      ),
                      Flexible(
                        child: _NavItem(
                          icon: Icons.bar_chart_outlined,
                          label: 'Progreso',
                          selected: current == MainTab.progress,
                          onTap: () => _go(context, MainTab.progress),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Semantics(
              button: true,
              label: 'Agregar comida',
              excludeSemantics: true,
              child: SizedBox.square(
                dimension: 60,
                child: FilledButton(
                  key: const Key('nav-add'),
                  onPressed: onAdd,
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size.square(60),
                  ),
                  child: const Icon(Icons.add, size: 28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La pestaña activa muestra su texto; las demás, solo el icono (con su
/// etiqueta semántica en español).
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? KColors.navSelected : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          key: Key('nav-$label'),
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: selected ? KColors.accent : KColors.text,
                  ),
                  if (selected) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: const TextStyle(
                            color: KColors.accent,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

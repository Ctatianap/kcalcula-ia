import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../ui/components/empty_state.dart';
import '../../ui/components/main_nav_bar.dart';

/// SPEC-010 R5: pestaña provisional hasta su SPEC (sin datos inventados).
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Atrás vuelve a Hoy en vez de cerrar la app (Edge Cases).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.diary);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Progreso')),
        body: const EmptyState(
          icon: Icons.bar_chart_outlined,
          title: 'Aquí verás tus promedios y tu progreso.',
        ),
        bottomNavigationBar: MainNavBar(
          current: MainTab.progress,
          onAdd: () => Navigator.of(context).pushNamed(AppRoutes.capture),
        ),
      ),
    );
  }
}

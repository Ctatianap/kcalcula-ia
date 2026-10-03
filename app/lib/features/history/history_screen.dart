import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../ui/components/empty_state.dart';
import '../../ui/components/main_nav_bar.dart';

/// SPEC-010 R5: pestaña provisional hasta su SPEC (sin datos inventados).
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

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
        appBar: AppBar(title: const Text('Historial')),
        body: const EmptyState(
          icon: Icons.calendar_month_outlined,
          title: 'Aquí verás tu historial día por día.',
        ),
        bottomNavigationBar: MainNavBar(
          current: MainTab.history,
          onAdd: () => Navigator.of(context).pushNamed(AppRoutes.capture),
        ),
      ),
    );
  }
}

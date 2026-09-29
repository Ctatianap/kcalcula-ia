import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_routes.dart';
import '../../infra/sharing/sharing_providers.dart';
import '../../infra/storage/storage_providers.dart';
import 'settings_controller.dart';

/// R4: pantalla de Ajustes con las tres acciones sobre datos del usuario
/// (borrar todo, exportar, revocar consentimiento) y el enlace a la
/// política completa.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final SettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SettingsController(
      storage: ref.read(storageRepositoryProvider),
      sharing: ref.read(sharingServiceProvider),
      exportDirectoryPath: ref.read(exportDirectoryPathProvider),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// R5/AC5-AC6.
  Future<void> _deleteAllData() async {
    final confirmed = await _confirm(
      title: 'Borrar todos mis datos',
      message:
          'Esto elimina todas tus comidas registradas y productos guardados. '
          'No se puede deshacer.',
      confirmLabel: 'Borrar todo',
    );
    if (!confirmed) return;
    await _controller.deleteAllData();
    if (!mounted) return;
    _showSnackBar('Tus datos se borraron.');
  }

  /// R7/AC7-AC9.
  Future<void> _exportData() async {
    await _controller.exportData();
    if (!mounted) return;
    _showSnackBar('Exportación lista.');
  }

  /// R8/AC13-AC14: revocar re-bloquea la app hasta que el usuario vuelva a
  /// aceptar (mismo camino que "primer lanzamiento" — ver `_RootGate`).
  Future<void> _revokeConsent() async {
    final confirmed = await _confirm(
      title: 'Revocar consentimiento',
      message:
          'Dejarás de poder usar el análisis con IA hasta que vuelvas a '
          'aceptar. Tus datos ya guardados no se borran.',
      confirmLabel: 'Revocar',
    );
    if (!confirmed) return;
    await _controller.revokeConsent();
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.diary, (route) => false);
  }

  void _openFullPolicy() {
    Navigator.of(context).pushNamed(AppRoutes.privacyPolicy);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.ios_share),
              title: const Text('Exportar mis datos'),
              enabled: !_controller.busy,
              onTap: _exportData,
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever),
              title: const Text('Borrar todos mis datos'),
              enabled: !_controller.busy,
              onTap: _deleteAllData,
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Revocar consentimiento'),
              enabled: !_controller.busy,
              onTap: _revokeConsent,
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Ver política de privacidad completa'),
              onTap: _openFullPolicy,
            ),
            if (_controller.busy)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

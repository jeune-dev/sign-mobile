import 'package:flutter/material.dart';

import '../../injection_container.dart' as di;
import '../services/app_update_launcher.dart';
import '../services/app_version_config.dart';
import '../services/app_version_service.dart';
import 'force_update_screen.dart';
import 'update_dialog.dart';

/// Point d'entrée unique qui vérifie la version au démarrage AVANT
/// d'afficher l'écran principal. Timeout de sécurité inclus pour ne
/// jamais bloquer indéfiniment l'app si le réseau est lent/indisponible.
class AppStartupGate extends StatefulWidget {
  final Widget child;
  const AppStartupGate({super.key, required this.child});

  @override
  State<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<AppStartupGate> {
  bool _checking = true;
  AppVersionCheckResult _result = const AppVersionCheckResult(AppUpdateStatus.upToDate, null);

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final service = di.sl<AppVersionService>();
    final result = await service.checkForUpdate().timeout(
      const Duration(seconds: 5),
      onTimeout: () => const AppVersionCheckResult(AppUpdateStatus.error, null),
    );

    if (!mounted) return;
    setState(() {
      _result = result;
      _checking = false;
    });

    if (result.status == AppUpdateStatus.optional && result.config != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showOptionalDialog(result.config!);
      });
    }
  }

  void _showOptionalDialog(AppVersionConfig config) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => UpdateDialog(
        config: config,
        onUpdate: () {
          Navigator.of(dialogContext).pop();
          AppUpdateLauncher.openStore(config.storeUrl);
        },
        onLater: () async {
          Navigator.of(dialogContext).pop();
          await di.sl<AppVersionService>().dismissUpdate(config.latestVersion);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      // Écran de chargement minimal — la vérification prend généralement
      // quelques centaines de ms, jamais plus de 5s (timeout).
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_result.status == AppUpdateStatus.forced && _result.config != null) {
      return ForceUpdateScreen(config: _result.config!);
    }

    return widget.child;
  }
}

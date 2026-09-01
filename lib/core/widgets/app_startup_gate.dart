import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/parcours/data/datasources/parcours_remote_datasource.dart';
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
  AppVersionCheckResult _result = const AppVersionCheckResult(AppUpdateStatus.upToDate, null);

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    // Aligne le validateur local sur le référentiel du backend (plages
    // téléphoniques, longueurs…). Volontairement non attendu : c'est un
    // confort de saisie, jamais un prérequis au démarrage — et le serveur
    // reste de toute façon l'autorité sur la validation.
    unawaited(di.sl<ParcoursRemoteDataSource>().synchroniserReferentiels());

    final service = di.sl<AppVersionService>();
    final result = await service.checkForUpdate().timeout(
      const Duration(seconds: 5),
      onTimeout: () => const AppVersionCheckResult(AppUpdateStatus.error, null),
    );

    if (!mounted) return;
    setState(() => _result = result);

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
    // Plus d'écran d'attente ici. La vérification de version bloquait le
    // démarrage derrière un simple indicateur de chargement : jusqu'à 5 s
    // (le timeout) AVANT même que le premier écran de marque n'apparaisse,
    // puis encore la durée des deux écrans. Sur un réseau lent, l'ouverture
    // dépassait les dix secondes.
    //
    // L'écran de marque s'affiche désormais tout de suite et la vérification
    // se poursuit derrière — elle prend quelques centaines de ms, largement
    // couvertes par l'animation d'ouverture. Seule une mise à jour OBLIGATOIRE
    // reprend la main, en remplaçant l'écran en cours.
    if (_result.status == AppUpdateStatus.forced && _result.config != null) {
      return ForceUpdateScreen(config: _result.config!);
    }

    return widget.child;
  }
}

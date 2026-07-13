import 'dart:io';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ouvre la mise à jour via Google Play In-App Updates quand c'est possible
/// (expérience intégrée, sans quitter l'app), avec repli automatique et
/// silencieux vers l'ouverture directe de la fiche Play Store en cas
/// d'échec (API indisponible, iOS, émulateur sans Play Store, etc.).
class AppUpdateLauncher {
  AppUpdateLauncher._();

  /// Mise à jour immédiate (bloquante) — utilisée pour l'écran obligatoire.
  static Future<void> openImmediateUpdate(String storeUrl) async {
    if (Platform.isAndroid) {
      try {
        final info = await InAppUpdate.checkForUpdate();
        if (info.updateAvailability == UpdateAvailability.updateAvailable) {
          await InAppUpdate.performImmediateUpdate();
          return;
        }
      } catch (_) {
        // Repli silencieux vers le Store ci-dessous.
      }
    }
    await _openStoreUrl(storeUrl);
  }

  /// Mise à jour flexible (en arrière-plan) — utilisée pour le popup facultatif.
  static Future<void> openFlexibleUpdate(String storeUrl) async {
    if (Platform.isAndroid) {
      try {
        final info = await InAppUpdate.checkForUpdate();
        if (info.updateAvailability == UpdateAvailability.updateAvailable) {
          await InAppUpdate.startFlexibleUpdate();
          return;
        }
      } catch (_) {
        // Repli silencieux vers le Store ci-dessous.
      }
    }
    await _openStoreUrl(storeUrl);
  }

  static Future<void> _openStoreUrl(String storeUrl) async {
    if (storeUrl.isEmpty) return;
    final uri = Uri.tryParse(storeUrl);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

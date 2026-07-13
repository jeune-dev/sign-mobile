import 'package:url_launcher/url_launcher.dart';

/// Ouvre directement la fiche Play Store (store_url) — comportement
/// identique dans tous les cas (popup facultatif ou écran obligatoire).
class AppUpdateLauncher {
  AppUpdateLauncher._();

  static Future<void> openStore(String storeUrl) async {
    if (storeUrl.isEmpty) return;
    final uri = Uri.tryParse(storeUrl);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

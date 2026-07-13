/// Configuration de mise à jour renvoyée par GET /app-version.
class AppVersionConfig {
  final String latestVersion;
  final String minimumVersion;
  final bool forceUpdate;
  final String title;
  final String subtitle;
  final String message;
  final String updateButton;
  final String laterButton;
  final String? illustration;
  final String storeUrl;

  const AppVersionConfig({
    required this.latestVersion,
    required this.minimumVersion,
    required this.forceUpdate,
    required this.title,
    required this.subtitle,
    required this.message,
    required this.updateButton,
    required this.laterButton,
    this.illustration,
    required this.storeUrl,
  });

  factory AppVersionConfig.fromJson(Map<String, dynamic> json) {
    return AppVersionConfig(
      latestVersion: (json['latestVersion'] ?? '0.0.0').toString(),
      minimumVersion: (json['minimumVersion'] ?? '0.0.0').toString(),
      forceUpdate: json['forceUpdate'] == true,
      title: (json['title'] ?? 'Nouvelle version disponible').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      updateButton: (json['updateButton'] ?? 'Mettre à jour').toString(),
      laterButton: (json['laterButton'] ?? 'Plus tard').toString(),
      illustration: json['illustration']?.toString(),
      storeUrl: (json['storeUrl'] ?? '').toString(),
    );
  }
}

enum AppUpdateStatus { upToDate, optional, forced, error }

class AppVersionCheckResult {
  final AppUpdateStatus status;
  final AppVersionConfig? config;
  const AppVersionCheckResult(this.status, this.config);
}

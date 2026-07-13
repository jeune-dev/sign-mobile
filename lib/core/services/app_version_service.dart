import 'dart:io';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/env.dart';
import '../utils/semver.dart';
import 'app_version_config.dart';

/// Vérifie au démarrage si une mise à jour est disponible/obligatoire, en
/// comparant la version installée à la configuration renvoyée par le
/// backend. Gère aussi la règle des 24h pour ne pas re-solliciter
/// l'utilisateur à chaque ouverture après un "Plus tard".
class AppVersionService {
  final Dio dio;
  AppVersionService({required this.dio});

  static const _kDismissedVersionKey = 'app_update_dismissed_version';
  static const _kLastReminderAtKey = 'app_update_last_reminder_at';
  static const _reminderCooldown = Duration(hours: 24);

  Future<AppVersionCheckResult> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await dio.get(
        Env.appVersion,
        queryParameters: {'platform': Platform.isIOS ? 'ios' : 'android'},
      );

      final data = response.data is Map ? response.data['data'] : null;
      if (data == null) {
        // Pas de configuration active côté backend → rien à vérifier.
        return const AppVersionCheckResult(AppUpdateStatus.upToDate, null);
      }

      final config = AppVersionConfig.fromJson(Map<String, dynamic>.from(data));

      // 1. Mise à jour obligatoire — priorité absolue, ignore tout le reste.
      if (config.forceUpdate || SemVer.isLowerThan(currentVersion, config.minimumVersion)) {
        return AppVersionCheckResult(AppUpdateStatus.forced, config);
      }

      // 2. Mise à jour facultative disponible ?
      if (SemVer.isLowerThan(currentVersion, config.latestVersion)) {
        if (await _isWithinCooldown(config.latestVersion)) {
          return AppVersionCheckResult(AppUpdateStatus.upToDate, config);
        }
        return AppVersionCheckResult(AppUpdateStatus.optional, config);
      }

      return AppVersionCheckResult(AppUpdateStatus.upToDate, config);
    } catch (_) {
      // Erreur réseau ou backend indisponible : ne jamais bloquer le
      // démarrage de l'app pour une vérification non critique.
      return const AppVersionCheckResult(AppUpdateStatus.error, null);
    }
  }

  /// true si l'utilisateur a déjà refusé CETTE version il y a moins de 24h.
  /// Une nouvelle version publiée entre-temps réinitialise automatiquement
  /// le compteur (le "dismissedVersion" stocké ne correspond alors plus à
  /// latestVersion).
  Future<bool> _isWithinCooldown(String latestVersion) async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedVersion = prefs.getString(_kDismissedVersionKey);
    if (dismissedVersion != latestVersion) return false;

    final lastReminderStr = prefs.getString(_kLastReminderAtKey);
    if (lastReminderStr == null) return false;

    final lastReminder = DateTime.tryParse(lastReminderStr);
    if (lastReminder == null) return false;

    return DateTime.now().difference(lastReminder) < _reminderCooldown;
  }

  /// Appelé quand l'utilisateur clique "Plus tard".
  Future<void> dismissUpdate(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDismissedVersionKey, version);
    await prefs.setString(_kLastReminderAtKey, DateTime.now().toIso8601String());
  }
}

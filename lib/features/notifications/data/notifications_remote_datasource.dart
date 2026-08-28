import 'package:dio/dio.dart';

import 'package:sign_application/core/config/env.dart';

import 'notification_signs.dart';

/// notifications_remote_datasource.dart — Appels de la cloche.
///
/// Le compteur a son propre appel : il est interrogé à chaque retour au
/// premier plan, alors que la liste complète n'est chargée qu'à l'ouverture
/// du panneau.
///
/// Aucune de ces méthodes ne lève : une cloche est un élément d'ambiance, elle
/// ne doit jamais faire échouer l'écran qui la porte. En cas de souci réseau,
/// le compteur reste à sa dernière valeur connue et la liste s'affiche vide.
class NotificationsRemoteDataSource {
  final Dio dio;

  NotificationsRemoteDataSource({required this.dio});

  Map<String, dynamic> _donnees(Response reponse) {
    final corps = reponse.data;
    if (corps is Map && corps['data'] is Map) {
      return Map<String, dynamic>.from(corps['data'] as Map);
    }
    if (corps is Map) return Map<String, dynamic>.from(corps);
    return const {};
  }

  /// Nombre de notifications non lues. `null` si l'appel échoue — l'appelant
  /// conserve alors la valeur qu'il affichait.
  Future<int?> compterNonLues() async {
    try {
      final reponse = await dio.get(Env.notificationsCompteur);
      final valeur = _donnees(reponse)['nonLues'];
      return valeur is int ? valeur : int.tryParse('$valeur');
    } catch (_) {
      return null;
    }
  }

  /// Liste des notifications, les plus récentes d'abord.
  Future<({List<NotificationSigns> notifications, int nonLues})> lister({
    bool nonLuesSeulement = false,
  }) async {
    try {
      final reponse = await dio.get(
        Env.notificationsBase,
        queryParameters: nonLuesSeulement ? {'nonLues': '1'} : null,
      );
      final donnees = _donnees(reponse);
      final brut = donnees['notifications'];

      final notifications = brut is List
          ? brut
              .whereType<Map>()
              .map((e) => NotificationSigns.depuisJson(Map<String, dynamic>.from(e)))
              .toList()
          : <NotificationSigns>[];

      final nonLues = donnees['nonLues'];
      return (
        notifications: notifications,
        nonLues: nonLues is int ? nonLues : int.tryParse('$nonLues') ?? 0,
      );
    } catch (_) {
      return (notifications: <NotificationSigns>[], nonLues: 0);
    }
  }

  /// Marque une notification comme lue. Retourne le compteur mis à jour,
  /// ou `null` si l'appel a échoué.
  Future<int?> marquerLue(String id) async {
    try {
      final reponse = await dio.patch(Env.notificationLue(id));
      final valeur = _donnees(reponse)['nonLues'];
      return valeur is int ? valeur : int.tryParse('$valeur');
    } catch (_) {
      return null;
    }
  }

  /// Vide le compteur d'un coup. Retourne `true` si l'appel a abouti.
  Future<bool> toutMarquerLu() async {
    try {
      await dio.patch(Env.notificationsToutLu);
      return true;
    } catch (_) {
      return false;
    }
  }
}

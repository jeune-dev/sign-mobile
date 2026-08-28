import 'package:flutter/material.dart';

/// notification_signs.dart — Une notification telle que la renvoie le backend.
///
/// Nommée `NotificationSigns` et non `Notification` : Flutter expose déjà une
/// classe `Notification` dans `widgets`, et l'ambiguïté se paierait à chaque
/// import.
class NotificationSigns {
  final String id;

  /// Nature de l'événement — détermine l'icône et la couleur.
  ///
  ///   'document_recu'       — un document m'a été adressé
  ///   'document_signe'      — un document que j'ai émis vient d'être signé
  ///   'compte_valide'       — mon inscription a été validée
  ///   'compte_rejete'       — mon inscription a été rejetée
  ///   'justificatif_traite' — une pièce déposée a été traitée
  ///   'information'         — message général
  final String type;

  final String titre;
  final String message;

  /// Famille du document visé, quand la notification en désigne un.
  final String? cibleType;
  final String? cibleId;

  /// Date de lecture. `null` tant que la notification n'a pas été ouverte.
  final DateTime? luLe;

  final DateTime? creeLe;

  const NotificationSigns({
    required this.id,
    required this.type,
    required this.titre,
    required this.message,
    this.cibleType,
    this.cibleId,
    this.luLe,
    this.creeLe,
  });

  bool get nonLue => luLe == null;

  factory NotificationSigns.depuisJson(Map<String, dynamic> json) {
    DateTime? date(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

    return NotificationSigns(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'information',
      titre: json['titre']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      cibleType: json['cibleType']?.toString(),
      cibleId: json['cibleId']?.toString(),
      luLe: date(json['luLe']),
      creeLe: date(json['createdAt']),
    );
  }

  /// Icône associée au type. Le détail visuel vit ici plutôt que dans la page :
  /// la cloche et la liste doivent afficher la même chose.
  IconData get icone {
    switch (type) {
      case 'document_recu':
        return Icons.mark_email_unread_outlined;
      case 'document_signe':
        return Icons.draw_outlined;
      case 'compte_valide':
        return Icons.verified_outlined;
      case 'compte_rejete':
        return Icons.gpp_bad_outlined;
      case 'justificatif_traite':
        return Icons.badge_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  /// Âge lisible — « à l'instant », « il y a 3 h », « le 14/02 ».
  ///
  /// Une date absolue au-delà d'une semaine : « il y a 23 jours » demande un
  /// calcul mental que la date brute évite.
  String get quand {
    final date = creeLe;
    if (date == null) return '';

    final ecart = DateTime.now().difference(date);
    if (ecart.inMinutes < 1) return "à l'instant";
    if (ecart.inMinutes < 60) return 'il y a ${ecart.inMinutes} min';
    if (ecart.inHours < 24) return 'il y a ${ecart.inHours} h';
    if (ecart.inDays < 7) {
      return ecart.inDays == 1 ? 'hier' : 'il y a ${ecart.inDays} jours';
    }
    final j = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return 'le $j/$m';
  }
}

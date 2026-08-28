import 'package:flutter/material.dart';

import 'package:sign_application/core/models/document_cree.dart';

import 'pages/document_genere_page.dart';

/// afficher_document_genere.dart — Passage de la création à la confirmation.
///
/// Point d'entrée unique appelé par chaque écran de création lorsque le bloc
/// signale un succès. Il ouvre l'écran de confirmation (§ 9), puis referme
/// l'écran de création en renvoyant `true` — signal attendu par
/// `ParcoursDocument` pour enchaîner sur la proposition de compte complet
/// (§ 10).
///
/// Si l'API n'a rien renvoyé d'exploitable, on referme directement : le
/// document est bien créé, il serait absurde d'afficher une erreur à ce stade.
/// L'utilisateur le retrouve dans sa liste, exactement comme avant.
Future<void> afficherDocumentGenere(
  BuildContext context, {
  required String libelle,
  required DocumentCree? document,

  /// Récupère les octets du PDF à partir de l'identifiant du document.
  required Future<List<int>> Function(String id) telecharger,

  /// Accord du participe : « prête » pour une facture, « prêt » pour un contrat.
  bool feminin = false,

  /// Envoi par e-mail, quand la fonctionnalité le permet.
  Future<void> Function()? envoyerParEmail,
}) async {
  if (document == null || !document.exploitable) {
    Navigator.of(context).pop(true);
    return;
  }

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => DocumentGenerePage(
        libelle: libelle,
        feminin: feminin,
        reference: document.reference,
        telecharger: () => telecharger(document.id!),
        envoyerParEmail: envoyerParEmail,
      ),
    ),
  );

  if (context.mounted) Navigator.of(context).pop(true);
}

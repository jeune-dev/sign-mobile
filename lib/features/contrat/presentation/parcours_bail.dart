import 'package:flutter/material.dart';

import 'package:sign_application/core/theme/app_color.dart';
import 'package:sign_application/core/widgets/confirmation_dialog.dart';
import 'package:sign_application/features/etat_logement/presentation/pages/etats_logement_liste_page.dart';
import 'package:sign_application/features/parcours/presentation/parcours_document.dart';
import 'package:sign_application/features/parcours/type_document_signs.dart';

/// parcours_bail.dart — Création d'un contrat de bail, de bout en bout.
///
/// Le bail a une suite que les autres documents n'ont pas : l'état des lieux
/// du logement. Elle était proposée depuis la page de création elle-même, qui
/// remplaçait alors sa route par le module état des lieux — `ParcoursDocument`
/// ne recevait jamais le `true` attendu et s'arrêtait là : ni annonce des
/// documents restants, ni accord d'enregistrement, ni compte complet.
///
/// La proposition vient désormais APRÈS le parcours commun, ici, au seul
/// endroit qui sait que le document créé est un bail. Les écrans qui ouvrent
/// la création d'un bail passent par ce point d'entrée et non par
/// `ParcoursDocument.ouvrir` directement.
class ParcoursBail {
  ParcoursBail._();

  /// Ouvre le formulaire de bail, déroule le parcours commun, puis propose
  /// l'état des lieux si un bail a été créé.
  static Future<void> ouvrir(
    BuildContext context, {
    required WidgetBuilder page,
  }) async {
    final bailCree = await ParcoursDocument.ouvrir(
      context,
      typeDocument: TypeDocumentSigns.contratBail,
      page: page,
    );
    if (!bailCree || !context.mounted) return;

    await _proposerEtatDesLieux(context);
  }

  /// Le bail tout juste créé apparaît dans le sélecteur du module, ouvert
  /// d'emblée pour ne pas faire chercher l'utilisateur.
  static Future<void> _proposerEtatDesLieux(BuildContext context) async {
    final creerEtat = await showConfirmationDialog(
      context,
      title: 'Contrat de bail créé',
      message: 'Voulez-vous créer l\'état des lieux de ce logement maintenant ?',
      confirmLabel: 'État des lieux',
      cancelLabel: 'Plus tard',
      confirmColor: AppColor.kTexte,
      icon: Icons.fact_check_outlined,
    );
    if (!creerEtat || !context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const EtatsLogementListePage(autoSelectBail: true),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:sign_application/core/theme/app_color.dart';
import 'package:sign_application/core/theme/app_dimensions.dart';
import 'package:sign_application/core/theme/app_typo.dart';
import 'package:sign_application/core/widgets/app_bouton.dart';
import 'package:sign_application/core/widgets/toastNotif.dart';
import 'package:sign_application/injection_container.dart';
import 'package:toastification/toastification.dart';

import '../../data/datasources/parcours_remote_datasource.dart';
import '../../data/dernieres_informations_saisies.dart';
import '../../data/suivi_profil_service.dart';

/// proposition_enregistrement_dialog.dart — « Enregistrer vos informations ? »
///
/// Rien de ce que l'utilisateur saisit pour un document n'est écrit sur son
/// compte sans son accord. Cette fenêtre est le seul endroit où il le donne :
/// elle s'affiche après CHAQUE création, dès lors qu'une saisie a eu lieu, et
/// ne dépend de rien d'autre — ni de l'état du profil, ni du quota.
///
/// Elle était auparavant confondue avec la proposition de compte complet
/// (§ 10), qui ne s'ouvre que pour un profil incomplet : quiconque avait déjà
/// un profil complet ne voyait jamais la question, et sa saisie était jetée
/// en silence. Les deux questions sont désormais distinctes.
///
/// « Non » vide le tampon : la saisie n'a servi qu'au document, et les mêmes
/// informations seront redemandées la prochaine fois — c'est exactement ce
/// que l'utilisateur a choisi.
class PropositionEnregistrementDialog extends StatelessWidget {
  const PropositionEnregistrementDialog({super.key});

  /// Pose la question si — et seulement si — quelque chose a été saisi pour
  /// le document qui vient d'être créé.
  static Future<void> afficherSiNecessaire(BuildContext context) async {
    final depot = sl<DernieresInformationsSaisies>();
    if (!depot.disponible) return;

    final accepte = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PropositionEnregistrementDialog(),
    );

    if (!context.mounted) return;

    if (accepte == true) {
      await _enregistrerLaSaisie(context, depot);
    } else {
      depot.vider();
    }
  }

  /// Pousse la saisie vers le profil.
  ///
  /// L'échec est signalé : c'est l'objet même de la fenêtre, se taire
  /// laisserait croire que l'accord a été suivi d'effet. Le tampon est alors
  /// conservé pour que la question puisse être reposée au prochain document.
  static Future<void> _enregistrerLaSaisie(
    BuildContext context,
    DernieresInformationsSaisies depot,
  ) async {
    try {
      await sl<ParcoursRemoteDataSource>().enregistrerInformations(depot.valeurs!);
      depot.vider();
      // La pastille et les compteurs de complétion lisent cet état : sans le
      // rafraîchir, ils continueraient d'annoncer des champs manquants.
      sl<SuiviProfilService>().rafraichir();
      if (!context.mounted) return;
      showToast(
        context,
        'Informations enregistrées',
        'Elles seront préremplies dans vos prochains documents.',
        ToastificationType.success,
      );
    } on ParcoursException catch (e) {
      if (!context.mounted) return;
      showToast(context, 'Enregistrement impossible', e.message,
          ToastificationType.error);
    } catch (_) {
      if (!context.mounted) return;
      showToast(
        context,
        'Enregistrement impossible',
        "Vos informations n'ont pas pu être enregistrées. Elles vous seront "
            'redemandées au prochain document.',
        ToastificationType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColor.kSurface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRayon.feuille)),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppEspace.xl),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppEspace.xl, AppEspace.xxl, AppEspace.xl, AppEspace.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColor.kBackground2,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_added_outlined,
                size: 30,
                color: AppColor.kTexte,
              ),
            ),
            const SizedBox(height: AppEspace.xl),
            Text(
              'Enregistrer vos informations ?',
              textAlign: TextAlign.center,
              style: AppTypo.jakarta(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColor.kTexte,
                height: 1.3,
              ),
            ),
            const SizedBox(height: AppEspace.m),
            Text(
              'Conservez les informations saisies dans ce document : elles '
              'seront préremplies automatiquement la prochaine fois, vous '
              'n’aurez plus à les écrire. Sans votre accord, rien n’est '
              'enregistré.',
              textAlign: TextAlign.center,
              style: AppTypo.jakarta(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColor.kTexteMoyen,
                height: 1.55,
              ),
            ),
            const SizedBox(height: AppEspace.xl),
            AppBouton(
              libelle: 'Oui, enregistrer',
              onPressed: () => Navigator.of(context).pop(true),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Non, pas cette fois',
                style: AppTypo.jakarta(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColor.kTexteMoyen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

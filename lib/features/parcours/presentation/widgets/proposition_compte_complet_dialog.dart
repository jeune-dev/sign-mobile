import 'package:flutter/material.dart';

import 'package:sign_application/core/routes/app_router.dart';
import 'package:sign_application/core/theme/app_color.dart';
import 'package:sign_application/core/widgets/toastNotif.dart';
import 'package:sign_application/injection_container.dart';
import 'package:toastification/toastification.dart';

import '../../data/datasources/parcours_remote_datasource.dart';
import '../../data/dernieres_informations_saisies.dart';
import 'package:sign_application/core/theme/app_typo.dart';

/// proposition_compte_complet_dialog.dart — « Enregistrer mes informations »
/// après génération (§ 10 du cahier des charges).
///
/// S'affiche APRÈS la génération et le partage d'un document, jamais avant :
/// l'utilisateur a alors constaté ce que l'application lui apporte, et
/// l'argument « ne les ressaisissez plus » prend tout son sens.
///
/// ⚠️ Compléter son inscription n'est PAS optionnel : au-delà du quota de
/// documents, le compte est suspendu jusqu'à validation par un
/// administrateur. « Plus tard » ne fait donc que reporter la proposition au
/// prochain document — il ne l'éteint pas définitivement, sans quoi
/// l'utilisateur se retrouverait bloqué sans avoir jamais compris pourquoi.
/// Le compteur de documents restants est rappelé dans la fenêtre.
class PropositionCompteCompletDialog extends StatelessWidget {
  const PropositionCompteCompletDialog({super.key, this.documentsRestants});

  /// Nombre de documents encore créables avant suspension du compte, ou null
  /// si l'information n'est pas connue.
  final int? documentsRestants;

  /// Affiche la proposition si — et seulement si — le profil n'est pas déjà
  /// complet.
  ///
  /// [profilDejaComplet] permet d'éviter l'appel réseau quand l'appelant
  /// connaît déjà l'état du profil via l'utilisateur en session.
  /// [documentsRestants] alimente le rappel de quota.
  static Future<void> afficherSiNecessaire(
    BuildContext context, {
    bool profilDejaComplet = false,
    int? documentsRestants,
  }) async {
    if (profilDejaComplet) return;

    try {
      final profil = await sl<ParcoursRemoteDataSource>().prereemplissage();
      if (profil['profil_complet'] == true) return;
    } catch (_) {
      // Backend injoignable : on ne propose rien plutôt que de risquer de
      // reproposer la création à quelqu'un qui l'a déjà faite.
      return;
    }

    if (!context.mounted) return;

    final accepte = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PropositionCompteCompletDialog(
        documentsRestants: documentsRestants,
      ),
    );

    if (accepte != true || !context.mounted) return;

    // « Oui » enregistre vraiment ce que l'utilisateur vient de saisir : sans
    // cela, la proposition n'aurait aucun effet et il devrait tout retaper
    // dans le parcours de compte complet.
    await _enregistrerLaSaisie(context);

    if (!context.mounted) return;
    // Compléter son inscription reste obligatoire : on enchaîne sur le
    // parcours complet, désormais prérempli avec ce qui vient d'être saisi.
    Navigator.of(context).pushNamed(AppRouter.compteCompletRoute);
  }

  /// Pousse la dernière saisie vers le profil.
  ///
  /// Échec silencieux, volontairement : le document est déjà créé et
  /// l'utilisateur va de toute façon arriver sur le parcours de compte
  /// complet, où il pourra reprendre la main. Afficher une erreur ici
  /// n'apporterait rien qu'une inquiétude.
  static Future<void> _enregistrerLaSaisie(BuildContext context) async {
    final depot = sl<DernieresInformationsSaisies>();
    if (!depot.disponible) return;

    try {
      await sl<ParcoursRemoteDataSource>().enregistrerInformations(depot.valeurs!);
      depot.vider();
      if (!context.mounted) return;
      showToast(
        context,
        'Informations enregistrées',
        'Elles seront préremplies dans vos prochains documents.',
        ToastificationType.success,
      );
    } catch (_) {
      // Le parcours de compte complet prendra le relais.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
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
                color: AppColor.kGrayscaleDark100,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Enregistrer vos informations ?',
              textAlign: TextAlign.center,
              style: AppTypo.jakarta(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColor.kGrayscaleDark100,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Conservez les informations saisies dans ce document : elles '
              'seront préremplies automatiquement la prochaine fois, vous '
              'n’aurez plus à les écrire.',
              textAlign: TextAlign.center,
              style: AppTypo.jakarta(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColor.kGrayscale40,
                height: 1.55,
              ),
            ),
            if (documentsRestants != null && documentsRestants! > 0) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColor.fondEtat(AppColor.kAlerte),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  documentsRestants == 1
                      ? 'Il vous reste 1 document avant que votre compte doive '
                          'être validé.'
                      : 'Il vous reste $documentsRestants documents avant que '
                          'votre compte doive être validé.',
                  textAlign: TextAlign.center,
                  style: AppTypo.jakarta(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColor.kAlerte,
                    height: 1.45,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(true),
                  borderRadius: BorderRadius.circular(14),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: AppColor.kPrimary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        'Oui, je souhaite créer mon compte',
                        textAlign: TextAlign.center,
                        style: AppTypo.jakarta(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Plus tard',
                style: AppTypo.jakarta(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColor.kGrayscale40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

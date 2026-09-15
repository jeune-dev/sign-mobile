import 'package:flutter/material.dart';

import 'package:sign_application/core/routes/app_router.dart';
import 'package:sign_application/core/theme/app_color.dart';
import 'package:sign_application/core/theme/app_typo.dart';
import 'package:sign_application/injection_container.dart';

import '../../data/datasources/parcours_remote_datasource.dart';

/// proposition_compte_complet_dialog.dart — « Créer votre compte complet ? »
/// après génération (§ 10 du cahier des charges).
///
/// S'affiche APRÈS la génération et le partage d'un document, jamais avant :
/// l'utilisateur a alors constaté ce que l'application lui apporte, et
/// l'argument « complétez votre inscription » prend tout son sens.
///
/// Cette fenêtre ne porte QUE sur le compte complet. L'accord pour enregistrer
/// la saisie du document est demandé à part, par
/// `PropositionEnregistrementDialog`, à tout le monde — profil complet ou non.
/// Les deux étaient auparavant confondus : la question d'enregistrement
/// disparaissait avec celle-ci dès que le profil était complet.
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

    // Le parcours de compte complet se préremplit depuis le profil : ce que
    // l'utilisateur vient d'accepter d'enregistrer s'y retrouve donc déjà.
    Navigator.of(context).pushNamed(AppRouter.compteCompletRoute);
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
                Icons.verified_user_outlined,
                size: 30,
                color: AppColor.kGrayscaleDark100,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Créer votre compte complet ?',
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
              'Au-delà d’un certain nombre de documents, votre compte doit '
              'être validé pour continuer. Complétez votre inscription dès '
              'maintenant : ce que vous avez déjà enregistré y sera prérempli.',
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

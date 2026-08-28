import 'package:flutter/material.dart';

import 'package:sign_application/core/routes/app_router.dart';
import 'package:sign_application/core/theme/app_color.dart';
import 'package:sign_application/core/theme/app_dimensions.dart';
import 'package:sign_application/core/theme/app_typo.dart';
import 'package:sign_application/core/widgets/app_bouton.dart';

import '../../data/models/exigences_document.dart';

/// quota_atteint_dialog.dart — Le compte doit être validé pour continuer.
///
/// Un compte non validé peut produire trois contrats et trois factures. Au
/// delà, la création est suspendue jusqu'à ce qu'un administrateur ait
/// examiné les justificatifs.
///
/// Le message est celui rédigé par le backend : il connaît les plafonds
/// réels, configurables par variable d'environnement. La fenêtre mène
/// directement au dépôt des justificatifs — sans ce raccourci, l'utilisateur
/// se retrouve bloqué sans savoir quoi faire.
class QuotaAtteintDialog extends StatelessWidget {
  final QuotaDocument quota;

  const QuotaAtteintDialog({super.key, required this.quota});

  /// Affiche la fenêtre de blocage. Retourne toujours après fermeture ;
  /// l'appelant ne doit pas poursuivre vers le formulaire de création.
  static Future<void> afficher(BuildContext context, QuotaDocument quota) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => QuotaAtteintDialog(quota: quota),
    );
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
                color: AppColor.fondEtat(AppColor.kAlerte),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.verified_user_outlined,
                  size: 30, color: AppColor.kAlerte),
            ),
            const SizedBox(height: AppEspace.xl),
            Text(
              'Votre compte doit être validé',
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
              quota.message ??
                  'Vous avez atteint le nombre de documents autorisés avant la '
                      'validation de votre compte. Transmettez vos justificatifs '
                      'pour continuer.',
              textAlign: TextAlign.center,
              style: AppTypo.jakarta(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColor.kTexteMoyen,
                height: 1.55,
              ),
            ),
            if (quota.plafond > 0) ...[
              const SizedBox(height: AppEspace.l),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppEspace.l, vertical: AppEspace.m),
                decoration: BoxDecoration(
                  color: AppColor.kChamp,
                  borderRadius: BorderRadius.circular(AppRayon.champ),
                ),
                child: Text(
                  '${quota.utilises} / ${quota.plafond} documents utilisés',
                  style: AppTypo.jakarta(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColor.kTexte,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppEspace.xl),
            AppBouton(
              libelle: 'Transmettre mes justificatifs',
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(AppRouter.justificatifsRoute);
              },
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Fermer',
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

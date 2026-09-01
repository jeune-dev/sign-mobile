import 'package:flutter/material.dart';

import 'package:sign_application/core/theme/app_color.dart';
import 'package:sign_application/injection_container.dart';

import '../../data/suivi_profil_service.dart';

/// pastille_profil.dart — Le point rouge posé sur l'accès aux réglages.
///
/// Il ne s'allume que lorsqu'il reste réellement quelque chose à faire :
/// une information d'identité à saisir, ou une pièce à déposer. Une pastille
/// permanente ne veut plus rien dire — celle-ci s'éteint dès que le dossier
/// est constitué, et se rallume si une pièce est refusée.
///
/// Le décompte lui-même n'est pas affiché ici : à cet endroit, l'utilisateur
/// a besoin de savoir OÙ aller, pas combien il lui reste. Le nombre l'attend
/// sur les écrans concernés.
class PastilleProfil extends StatelessWidget {
  /// L'élément sur lequel la pastille se pose — icône de réglage, onglet…
  final Widget child;

  /// Décalage du point par rapport au coin haut-droit de [child].
  final double decalageHaut;
  final double decalageDroite;

  /// Diamètre du point, bord blanc compris.
  final double taille;

  const PastilleProfil({
    super.key,
    required this.child,
    this.decalageHaut = 2,
    this.decalageDroite = 2,
    this.taille = 10,
  });

  @override
  Widget build(BuildContext context) {
    final suivi = sl<SuiviProfilService>();

    return AnimatedBuilder(
      animation: suivi,
      builder: (context, enfant) {
        final aCompleter = suivi.etat?.aQuelqueChoseACompleter ?? false;
        if (!aCompleter) return enfant!;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            enfant!,
            Positioned(
              top: decalageHaut,
              right: decalageDroite,
              child: Container(
                width: taille,
                height: taille,
                decoration: BoxDecoration(
                  color: AppColor.kDanger,
                  shape: BoxShape.circle,
                  // Liseré clair : sans lui, le point se confond avec une
                  // icône sombre au lieu de s'en détacher.
                  border: Border.all(color: AppColor.kSurface, width: 1.6),
                ),
              ),
            ),
          ],
        );
      },
      child: child,
    );
  }
}

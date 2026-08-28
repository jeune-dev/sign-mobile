import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_typo.dart';

/// app_bouton.dart — Bouton principal de l'application.
///
/// Chaque écran réimplémentait le sien : on trouvait des hauteurs de 52, 54,
/// 56 et 58 px, des rayons de 12, 14 et 16, et trois traitements différents de
/// l'état de chargement. Ce composant fixe le contrat une fois.
///
/// ⚠️ `core/widgets/` contient déjà `primary_button.dart` et
/// `secondary_button.dart`, qui ne sont référencés par aucun écran. Ils sont
/// conservés le temps que la migration soit terminée, mais c'est bien
/// [AppBouton] qui doit être utilisé pour tout nouvel écran.
class AppBouton extends StatelessWidget {
  final String libelle;

  /// `null` désactive le bouton.
  final VoidCallback? onPressed;

  /// Remplace le libellé par un indicateur de progression et bloque l'appui.
  final bool enChargement;

  /// Icône affichée à droite, alignée sur le bord — la flèche d'un parcours
  /// par étapes, par exemple.
  final IconData? iconeFin;

  /// Bouton secondaire : contour seul, sans aplat.
  final bool secondaire;

  /// Le bouton occupe toute la largeur disponible (cas courant en bas d'écran).
  final bool pleineLargeur;

  const AppBouton({
    super.key,
    required this.libelle,
    this.onPressed,
    this.enChargement = false,
    this.iconeFin,
    this.secondaire = false,
    this.pleineLargeur = true,
  });

  bool get _actif => onPressed != null && !enChargement;

  @override
  Widget build(BuildContext context) {
    final couleurFond = secondaire
        ? Colors.transparent
        : (_actif ? AppColor.kPrimary : AppColor.kTexteFaible);
    final couleurTexte = secondaire ? AppColor.kTexte : AppColor.kTexteInverse;

    return SizedBox(
      width: pleineLargeur ? double.infinity : null,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _actif ? onPressed : null,
          borderRadius: BorderRadius.circular(AppRayon.bouton),
          child: Ink(
            decoration: BoxDecoration(
              color: couleurFond,
              borderRadius: BorderRadius.circular(AppRayon.bouton),
              border: secondaire
                  ? Border.all(color: AppColor.kBordure, width: 1.3)
                  : null,
              // L'ombre disparaît dès que le bouton n'est plus actionnable :
              // un bouton grisé mais surélevé continue d'inviter à l'appui.
              boxShadow: _actif && !secondaire
                  ? [
                      BoxShadow(
                        color: AppColor.kPrimary.withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (enChargement)
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(couleurTexte),
                    ),
                  )
                else ...[
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: iconeFin == null ? AppEspace.l : AppEspace.xxl,
                    ),
                    child: Text(
                      libelle,
                      textAlign: TextAlign.center,
                      style: AppTypo.jakarta(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: couleurTexte,
                      ),
                    ),
                  ),
                  if (iconeFin != null)
                    Positioned(
                      right: AppEspace.xl,
                      child: Icon(iconeFin, color: couleurTexte, size: 22),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

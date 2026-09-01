import 'package:flutter/material.dart';

import '../theme/app_color.dart';

/// Un onglet de la barre de navigation.
class OngletNavigation {
  final IconData icone;

  /// Icône pleine, affichée quand l'onglet est actif.
  final IconData iconeActive;

  final String libelle;

  /// Point rouge posé sur l'icône : quelque chose attend l'utilisateur de ce
  /// côté-là. Utilisé pour signaler un profil encore incomplet, sur l'onglet
  /// qui y mène.
  final bool pastille;

  const OngletNavigation(
    this.icone,
    this.iconeActive,
    this.libelle, {
    this.pastille = false,
  });
}

/// barre_navigation_flottante.dart — La barre du bas.
///
/// Elle occupait toute la largeur, collée au bord de l'écran, et se lisait
/// comme une bordure de la page. Détachée et arrondie, elle devient un objet
/// posé au-dessus du contenu.
///
/// L'onglet actif porte un trait sous son libellé. La couleur seule ne
/// suffisait pas : entre le gris des onglets inactifs et le noir de l'actif,
/// la distinction tenait à une nuance, et disparaissait au soleil comme pour
/// un œil qui distingue mal les contrastes.
class BarreNavigationFlottante extends StatelessWidget {
  final int indexCourant;
  final ValueChanged<int> onChange;
  final List<OngletNavigation> onglets;

  const BarreNavigationFlottante({
    super.key,
    required this.indexCourant,
    required this.onChange,
    required this.onglets,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColor.kSurface,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < onglets.length; i++)
              Expanded(child: _onglet(i, onglets[i])),
          ],
        ),
      ),
    );
  }

  Widget _onglet(int index, OngletNavigation onglet) {
    final actif = indexCourant == index;
    final couleur = actif ? AppColor.kPrimary : AppColor.kTexteFaible;

    return InkWell(
      onTap: () => onChange(index),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(actif ? onglet.iconeActive : onglet.icone,
                    color: couleur, size: 23),
                if (onglet.pastille)
                  Positioned(
                    top: -1,
                    right: -2,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColor.kDanger,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColor.kSurface, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              onglet.libelle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
                color: couleur,
              ),
            ),
            const SizedBox(height: 4),
            // Toujours réservé, même inactif : sans cela la barre se
            // décalerait d'un onglet à l'autre.
            Container(
              width: 18,
              height: 2.5,
              decoration: BoxDecoration(
                color: actif ? AppColor.kPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

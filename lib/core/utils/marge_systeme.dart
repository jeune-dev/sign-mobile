/// marge_systeme.dart — Laisser passer la barre système du bas.
///
/// Android dessine sa barre de navigation (trois boutons, ou la barre de geste)
/// PAR-DESSUS l'application. Un bouton posé tout en bas d'un écran, ou la
/// dernière ligne d'une zone défilante, se retrouve donc partiellement sous
/// elle : lisible à moitié, et parfois intouchable.
///
/// La hauteur exacte de cette barre varie selon l'appareil et le mode de
/// navigation choisi par l'utilisateur — une marge en dur ne peut pas la
/// couvrir. Le système la donne, il suffit de l'ajouter.
///
/// ⚠️ À n'utiliser que sur les écrans qui ne sont pas déjà protégés :
/// [SafeArea] et la barre de navigation d'un [Scaffold] retirent eux-mêmes
/// cette marge du `MediaQuery` de leur contenu. Dans ces cas-là la valeur vaut
/// zéro et l'appel reste sans effet — le helper ne double donc jamais la marge.
library;

import 'package:flutter/widgets.dart';

/// Hauteur occupée par la barre système en bas de l'écran, en pixels logiques.
double margeBasseSysteme(BuildContext context) =>
    MediaQuery.paddingOf(context).bottom;

/// Le même encart, rallongé en bas de la hauteur de la barre système.
///
/// ```dart
/// padding: avecMargeBasse(context, const EdgeInsets.fromLTRB(16, 20, 16, 40)),
/// ```
EdgeInsets avecMargeBasse(BuildContext context, EdgeInsets base) =>
    base.copyWith(bottom: base.bottom + margeBasseSysteme(context));

import 'package:flutter/material.dart';

/// app_color.dart — Jetons de couleur de l'application.
///
/// Les couleurs sont nommées par **rôle** et non par teinte : `kTexteFaible`
/// plutôt que `kGris9CA3AF`. On peut ainsi ajuster une valeur sans avoir à
/// relire chaque écran pour savoir si le changement a du sens.
///
/// Historique : l'application comptait 90 couleurs différentes écrites en dur
/// dans les écrans, dont huit nuances de noir presque identiques employées
/// comme couleur principale. Les jetons ci-dessous les regroupent par usage.
/// Les couleurs d'accent propres à une fonctionnalité (types de contrat,
/// graphiques du tableau de bord) restent volontairement hors de cette liste :
/// ce sont des choix de signalétique, pas des couleurs de système.
class AppColor {
  AppColor._();

  // ─── Historique (conservés : utilisés dans toute l'application) ──────────
  static const Color kPrimary = Color(0xFF121212);
  static const Color kWhite = Color(0XFFFFFFFF);
  static const Color kOnBoardingColor = Color(0XFFFEFEFE);
  static const Color kGrayscale40 = Color.fromARGB(255, 97, 97, 97);
  static const Color kLine = Color(0XFFEBEBEB);
  // Aligne sur kPrimary : l'application n'a plus qu'une seule encre.
  static const Color kGrayscaleDark100 = Color(0xFF121212);
  static const Color kBackground = Color(0XFFFAFAFA);
  static const Color kBackground2 = Color(0XFFF6F6F6);

  // ─── Texte ──────────────────────────────────────────────────────────────

  /// Titres et contenu principal. Meme encre que [kPrimary] : la
  /// distinction est de role, pas de teinte.
  static const Color kTexte = Color(0xFF121212);

  /// Texte secondaire : sous-titres, libellés, aides de saisie.
  static const Color kTexteMoyen = Color(0xFF6B7280);

  /// Texte discret : indications, valeurs vides, éléments désactivés.
  static const Color kTexteFaible = Color(0xFF9CA3AF);

  /// Texte secondaire appuyé, quand le contraste doit rester fort.
  static const Color kTexteFort = Color(0xFF374151);

  /// Texte posé sur un fond sombre.
  static const Color kTexteInverse = Color(0xFFFFFFFF);

  // ─── Surfaces ───────────────────────────────────────────────────────────

  /// Fond des cartes et des feuilles.
  static const Color kSurface = Color(0xFFFFFFFF);

  /// Fond d'écran, légèrement en retrait de la surface.
  static const Color kFond = Color(0xFFF2F2F7);

  /// Fond des champs de saisie et des zones d'information.
  static const Color kChamp = Color(0xFFF8F8FA);

  /// Aplat neutre : pastilles, séparateurs pleins, états inactifs.
  static const Color kNeutreClair = Color(0xFFF3F4F6);

  // ─── Bordures ───────────────────────────────────────────────────────────

  /// Contour standard des champs et des cartes.
  static const Color kBordure = Color(0xFFE5E7EB);

  /// Contour appuyé, au survol ou à la sélection.
  static const Color kBordureForte = Color(0xFFD1D5DB);

  // ─── États ──────────────────────────────────────────────────────────────
  //
  // Ces trois couleurs portent un sens et ne doivent pas servir de décoration.
  // Elles correspondent aux trois niveaux du moteur de validation :
  // valide / format valide non verifie / invalide.

  /// Succès, validation confirmée.
  static const Color kSucces = Color(0xFF1B7F4B);

  /// Avertissement : correct sur la forme, non vérifiable sur le fond.
  static const Color kAlerte = Color(0xFFB26A00);

  /// Erreur, refus, action destructive.
  static const Color kDanger = Color(0xFFC62828);

  /// Fond adouci pour un bandeau d'état — 10 % de la couleur porteuse.
  static Color fondEtat(Color couleur) => couleur.withValues(alpha: 0.10);
}

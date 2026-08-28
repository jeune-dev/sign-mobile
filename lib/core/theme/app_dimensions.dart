/// app_dimensions.dart — Échelles d'espacement et de rayon.
///
/// L'application employait jusqu'ici des valeurs libres : on trouvait des
/// marges de 3, 5, 6, 14, 18, 22 et 28 px côte à côte, et des rayons de 10,
/// 12, 14, 16, 18, 20 et 24. Pris isolément chaque écran paraît correct ;
/// enchaînés, ils donnent cette impression de « presque aligné » difficile à
/// nommer.
///
/// Les deux échelles ci-dessous sont volontairement courtes : une échelle qui
/// propose douze valeurs ne contraint rien.
library;

/// Espacements — multiples de 4, la trame la plus courante sur mobile.
class AppEspace {
  AppEspace._();

  /// 4 — écart minimal, entre une icône et son libellé.
  static const double xs = 4;

  /// 8 — entre un libellé et son champ.
  static const double s = 8;

  /// 12 — à l'intérieur d'un composant.
  static const double m = 12;

  /// 16 — marge intérieure standard d'une carte.
  static const double l = 16;

  /// 24 — marge latérale d'un écran, écart entre deux blocs.
  static const double xl = 24;

  /// 32 — séparation entre deux sections.
  static const double xxl = 32;

  /// 48 — respiration avant un titre principal.
  static const double xxxl = 48;
}

/// Rayons de coin, par famille de composant.
class AppRayon {
  AppRayon._();

  /// 12 — champs de saisie, pastilles.
  static const double champ = 12;

  /// 14 — boutons.
  static const double bouton = 14;

  /// 16 — cartes et blocs.
  static const double carte = 16;

  /// 24 — feuilles glissantes et boîtes de dialogue.
  static const double feuille = 24;
}

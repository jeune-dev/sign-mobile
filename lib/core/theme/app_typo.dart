import 'package:flutter/material.dart';

/// app_typo.dart — Typographie de l'application.
///
/// ## Pourquoi ce fichier existe
///
/// L'application appelait la fabrique de styles du paquet `google_fonts` sur
/// 226 sites, alors que trois conditions rendaient ce chargement impossible :
///
///   * `allowRuntimeFetching = false` interdisait le téléchargement de la
///     police à l'exécution ;
///   * le paquet cherche ses fichiers dans un dossier d'assets `google_fonts/`,
///     absent du projet — les `.ttf` étaient rangés dans `assets/fonts/` ;
///   * le thème ne déclarait aucun `fontFamily`, il passait lui aussi par la
///     même fabrique.
///
/// Résultat : le paquet ne trouvait rien, renvoyait un style pointant sur une
/// famille non enregistrée, et Flutter retombait sur la police système —
/// Roboto sur Android, San Francisco sur iOS. L'application embarquait le
/// poids des polices sans jamais les afficher, et son rendu différait d'une
/// plateforme à l'autre.
///
/// [AppTypo] s'appuie directement sur la famille `PlusJakartaSans` déclarée
/// dans `pubspec.yaml`, dont les cinq graisses sont réellement embarquées.
/// Plus de réseau, plus de repli silencieux : ce qui est écrit est ce qui
/// s'affiche.
class AppTypo {
  AppTypo._();

  /// Nom de la famille déclarée dans `pubspec.yaml`.
  static const String famille = 'PlusJakartaSans';

  /// Style de base dans la police de l'application.
  ///
  /// Signature volontairement alignée sur celle qu'utilisaient les écrans,
  /// pour que la substitution reste purement mécanique sur les 226 sites
  /// d'appel.
  ///
  /// Graisses réellement embarquées : 400, 500, 600, 700, 800. Toute autre
  /// valeur serait synthétisée par le moteur de rendu, avec un résultat moins
  /// net — d'où [_graisseEmbarquee], qui ramène à la graisse la plus proche.
  static TextStyle jakarta({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    double? wordSpacing,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    Color? decorationColor,
    Color? backgroundColor,
    List<Shadow>? shadows,
    TextOverflow? overflow,
  }) {
    return TextStyle(
      fontFamily: famille,
      fontSize: fontSize,
      fontWeight: fontWeight == null ? null : _graisseEmbarquee(fontWeight),
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      fontStyle: fontStyle,
      decoration: decoration,
      decorationColor: decorationColor,
      backgroundColor: backgroundColor,
      shadows: shadows,
      overflow: overflow,
    );
  }

  /// Ramène une graisse demandée à celle qui est réellement embarquée.
  ///
  /// w100 à w400 sont rendues en Regular, w900 en ExtraBold : mieux vaut une
  /// graisse voisine authentique qu'un gras synthétique, qui épaissit les
  /// contours de façon irrégulière.
  static FontWeight _graisseEmbarquee(FontWeight demandee) {
    if (demandee.value <= 400) return FontWeight.w400;
    if (demandee.value <= 500) return FontWeight.w500;
    if (demandee.value <= 600) return FontWeight.w600;
    if (demandee.value <= 700) return FontWeight.w700;
    return FontWeight.w800;
  }

  /// Applique la police à tout un `TextTheme` — utilisé par `AppTheme`.
  static TextTheme theme(TextTheme base) => base.apply(fontFamily: famille);
}

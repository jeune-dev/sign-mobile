import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_typo.dart';

/// app_entete_formulaire.dart — Barre haute des écrans de création.
///
/// L'application affichait trois barres différentes selon l'écran : un
/// bandeau noir à coins droits pour les contrats, une `AppBar` Material
/// standard pour la facture et la fiche de paie, une variante encore autre
/// pour la quittance. Passer d'un document à l'autre donnait l'impression de
/// changer d'application.
///
/// Cette barre unique porte :
///   - le retour, toujours au même endroit ;
///   - le titre du document et, en dessous, ce que l'étape en cours attend ;
///   - une pastille d'icône, seul endroit où la couleur propre au type de
///     document subsiste ;
///   - l'indicateur d'étapes, quand l'écran en comporte plusieurs.
///
/// Le bas est arrondi : le contenu semble glisser sous la barre plutôt que de
/// buter contre une arête.
class AppEnteteFormulaire extends StatelessWidget {
  /// Nom du document — « Contrat de prestation », « Facture »…
  final String titre;

  /// Ce que l'étape en cours attend de l'utilisateur. Court : il est lu en
  /// diagonale.
  final String? sousTitre;

  /// Icône du type de document, affichée dans la pastille.
  final IconData? icone;

  /// Couleur propre au type de document. N'intervient que sur la pastille :
  /// les champs, eux, sont identiques partout.
  final Color? accent;

  final VoidCallback onRetour;

  /// Étape courante, à partir de 0. Null pour un écran d'une seule étape.
  final int? etapeCourante;
  final int? totalEtapes;

  /// Libellés des étapes. Affichés seulement s'ils tiennent — au-delà de
  /// quatre étapes, l'indicateur se réduit à des segments.
  final List<String> libellesEtapes;

  const AppEnteteFormulaire({
    super.key,
    required this.titre,
    required this.onRetour,
    this.sousTitre,
    this.icone,
    this.accent,
    this.etapeCourante,
    this.totalEtapes,
    this.libellesEtapes = const [],
  });

  bool get _aDesEtapes =>
      etapeCourante != null && totalEtapes != null && totalEtapes! > 1;

  /// Variante `AppBar`, pour les écrans dont le `Scaffold` en attend une.
  ///
  /// Même palette, même typographie, même bouton de retour et mêmes coins
  /// arrondis que le bandeau — l'utilisateur ne doit pas voir de différence
  /// selon le document. On passe par une vraie `AppBar` plutôt que par un
  /// `PreferredSize` maison : elle gère seule la barre d'état, quelle que
  /// soit l'encoche du téléphone.
  static PreferredSizeWidget barre({
    required String titre,
    required VoidCallback onRetour,
    String? sousTitre,
    IconData? icone,
    Color? accent,
  }) {
    final couleurAccent = accent ?? AppColor.kTexteInverse;

    return AppBar(
      backgroundColor: AppColor.kPrimary,
      surfaceTintColor: AppColor.kPrimary,
      foregroundColor: AppColor.kTexteInverse,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      toolbarHeight: sousTitre != null && sousTitre.isNotEmpty ? 72 : 60,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRayon.feuille),
        ),
      ),
      leadingWidth: 40 + AppEspace.l + AppEspace.m,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppEspace.l),
        child: Material(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRayon.champ),
          child: InkWell(
            onTap: onRetour,
            borderRadius: BorderRadius.circular(AppRayon.champ),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(Icons.arrow_back_rounded,
                  color: AppColor.kTexteInverse, size: 20),
            ),
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            titre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypo.jakarta(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColor.kTexteInverse,
              height: 1.2,
            ),
          ),
          if (sousTitre != null && sousTitre.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              sousTitre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypo.jakarta(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.62),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (icone != null)
          Padding(
            padding: const EdgeInsets.only(right: AppEspace.l),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: couleurAccent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRayon.champ),
              ),
              child: Icon(icone, color: couleurAccent, size: 19),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hautSysteme = MediaQuery.paddingOf(context).top;
    final couleurAccent = accent ?? AppColor.kTexteInverse;

    return Container(
      decoration: const BoxDecoration(
        color: AppColor.kPrimary,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRayon.feuille),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppEspace.l,
              hautSysteme + AppEspace.m,
              AppEspace.l,
              _aDesEtapes ? AppEspace.l : AppEspace.xl,
            ),
            child: Row(
              children: [
                _boutonRetour(),
                const SizedBox(width: AppEspace.m),
                Expanded(child: _titres()),
                if (icone != null) ...[
                  const SizedBox(width: AppEspace.m),
                  _pastilleIcone(couleurAccent),
                ],
              ],
            ),
          ),
          if (_aDesEtapes)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppEspace.l, 0, AppEspace.l, AppEspace.l),
              child: _indicateurEtapes(couleurAccent),
            ),
        ],
      ),
    );
  }

  Widget _boutonRetour() {
    return Material(
      color: Colors.white.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(AppRayon.champ),
      child: InkWell(
        onTap: onRetour,
        borderRadius: BorderRadius.circular(AppRayon.champ),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.arrow_back_rounded,
              color: AppColor.kTexteInverse, size: 20),
        ),
      ),
    );
  }

  Widget _titres() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          titre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypo.jakarta(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColor.kTexteInverse,
            height: 1.2,
          ),
        ),
        if (sousTitre != null && sousTitre!.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            sousTitre!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypo.jakarta(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.62),
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }

  Widget _pastilleIcone(Color couleurAccent) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: couleurAccent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRayon.champ),
      ),
      child: Icon(icone, color: couleurAccent, size: 19),
    );
  }

  /// Segments d'avancement, avec le libellé de l'étape courante à droite.
  ///
  /// Des segments plutôt que des pastilles numérotées : ils restent lisibles
  /// quel que soit le nombre d'étapes, et disent d'un coup d'œil la part du
  /// parcours déjà faite.
  Widget _indicateurEtapes(Color couleurAccent) {
    final courante = etapeCourante!;
    final total = totalEtapes!;
    final libelle = (courante >= 0 && courante < libellesEtapes.length)
        ? libellesEtapes[courante]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(total, (index) {
            final atteinte = index <= courante;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index == total - 1 ? 0 : 5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  height: 4,
                  decoration: BoxDecoration(
                    color: atteinte
                        ? couleurAccent
                        : Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: AppEspace.s),
        Row(
          children: [
            Text(
              'Étape ${courante + 1} sur $total',
              style: AppTypo.jakarta(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
            if (libelle != null) ...[
              const SizedBox(width: AppEspace.s),
              Expanded(
                child: Text(
                  '· $libelle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypo.jakarta(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

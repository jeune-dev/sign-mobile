import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_color.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_typo.dart';

/// app_champ_texte.dart — Champ de saisie avec libellé et aide.
///
/// La même `InputDecoration` d'une dizaine de lignes était recopiée dans
/// chaque formulaire, avec à chaque fois de petites divergences : champ
/// tantôt rempli, tantôt bordé, rayon variable, message d'erreur limité à une
/// ligne (donc tronqué pour les messages du moteur de validation, qui sont
/// volontairement explicites).
///
/// Ce composant fixe le contrat : libellé au-dessus, mention « facultatif »
/// quand le champ ne l'est pas, aide en dessous, erreur sur trois lignes.
class AppChampTexte extends StatelessWidget {
  final String libelle;
  final TextEditingController? controleur;

  /// Texte d'exemple affiché dans le champ vide.
  final String? indication;

  /// Consigne affichée sous le champ (instruction de saisie, format attendu).
  final String? aide;

  /// Un champ non obligatoire porte la mention « facultatif » à côté du
  /// libellé : plus lisible qu'un astérisque sur les champs requis, et cela
  /// évite un écran couvert d'astérisques.
  final bool obligatoire;

  final String? Function(String?)? validateur;
  final TextInputType typeClavier;
  final TextInputAction actionClavier;
  final bool majuscules;
  final IconData? icone;
  final int maxLignes;
  final ValueChanged<String>? surChangement;

  /// Mise en forme appliquee pendant la frappe — la casse des noms, par
  /// exemple (voir core/utils/normalisation_nom.dart).
  final List<TextInputFormatter>? formateurs;

  const AppChampTexte({
    super.key,
    required this.libelle,
    this.controleur,
    this.indication,
    this.aide,
    this.obligatoire = true,
    this.validateur,
    this.typeClavier = TextInputType.text,
    this.actionClavier = TextInputAction.next,
    this.majuscules = false,
    this.icone,
    this.maxLignes = 1,
    this.surChangement,
    this.formateurs,
  });

  /// Décoration partagée, exposée pour les champs qui ne peuvent pas utiliser
  /// ce composant — le sélecteur de téléphone international, notamment, qui
  /// impose son propre widget.
  static InputDecoration decoration({
    String? indication,
    IconData? icone,
    Widget? suffixe,
    Widget? prefixe,
    bool dense = false,
  }) {
    OutlineInputBorder bordure(Color couleur, double epaisseur) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRayon.champ),
          borderSide: BorderSide(color: couleur, width: epaisseur),
        );

    return InputDecoration(
      hintText: indication,
      hintStyle: AppTypo.jakarta(fontSize: 15, color: AppColor.kTexteFaible),
      prefixIcon: prefixe ??
          (icone == null
              ? null
              : Icon(icone, size: 19, color: AppColor.kTexteMoyen)),
      suffixIcon: suffixe,
      filled: true,
      fillColor: AppColor.kSurface,
      // `dense` sert aux champs qui cohabitent sur une même ligne (montant +
      // unité, jour + mois) : même style, hauteur réduite.
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppEspace.l,
        vertical: dense ? AppEspace.m + 1 : AppEspace.l,
      ),
      border: bordure(AppColor.kBordure, 1.2),
      enabledBorder: bordure(AppColor.kBordure, 1.2),
      focusedBorder: bordure(AppColor.kPrimary, 1.5),
      errorBorder: bordure(AppColor.kDanger, 1.4),
      focusedErrorBorder: bordure(AppColor.kDanger, 1.4),
      // Les messages du moteur de validation sont explicites (« doit comporter
      // 9 chiffres — 8 saisis ») : les tronquer les rendrait inutiles.
      errorMaxLines: 3,
      errorStyle: AppTypo.jakarta(fontSize: 12, color: AppColor.kDanger),
      counterText: '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppEspace.l + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  libelle,
                  style: AppTypo.jakarta(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColor.kTexte,
                  ),
                ),
              ),
              if (!obligatoire) ...[
                const SizedBox(width: AppEspace.s),
                Text(
                  'facultatif',
                  style: AppTypo.jakarta(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColor.kTexteFaible,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppEspace.s),
          TextFormField(
            controller: controleur,
            keyboardType: typeClavier,
            textInputAction: actionClavier,
            textCapitalization: majuscules
                ? TextCapitalization.characters
                : TextCapitalization.none,
            maxLines: maxLignes,
            inputFormatters: formateurs,
            onChanged: surChangement,
            style: AppTypo.jakarta(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColor.kTexte,
            ),
            decoration: decoration(indication: indication, icone: icone),
            validator: validateur,
          ),
          if (aide != null) ...[
            const SizedBox(height: 7),
            Text(
              aide!,
              style: AppTypo.jakarta(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: AppColor.kTexteMoyen,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

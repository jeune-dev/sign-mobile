import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_typo.dart';
import 'app_champ_texte.dart';

/// app_champ_mot_de_passe.dart — Saisie d'un mot de passe.
///
/// Reprend la décoration partagée de [AppChampTexte] et y ajoute ce qui lui
/// manque : masquage, bouton afficher/masquer, et — à l'inscription — la
/// liste des règles qui se cochent au fur et à mesure de la frappe.
///
/// Les règles reproduisent exactement celles du backend
/// (`validations/common.js` → `motDePasse`) : au moins 8 caractères, une
/// minuscule, une majuscule et un chiffre. Les afficher évite le va-et-vient
/// « je valide, le serveur refuse, je recommence ».
class AppChampMotDePasse extends StatefulWidget {
  final String libelle;
  final TextEditingController controleur;
  final String? indication;

  /// Affiche la liste des règles sous le champ. Utile à l'inscription, inutile
  /// à la connexion où le mot de passe est déjà choisi.
  final bool afficherRegles;

  /// Contrôle la robustesse. À désactiver à la connexion : un compte créé
  /// avant un durcissement des règles doit pouvoir continuer à se connecter.
  final bool verifierRobustesse;

  final String? Function(String?)? validateurSupplementaire;
  final TextInputAction actionClavier;

  const AppChampMotDePasse({
    super.key,
    required this.controleur,
    this.libelle = 'Mot de passe',
    this.indication,
    this.afficherRegles = false,
    this.verifierRobustesse = false,
    this.validateurSupplementaire,
    this.actionClavier = TextInputAction.next,
  });

  /// Règles du backend, exposées pour être réutilisées ailleurs.
  static bool longueurSuffisante(String v) => v.length >= 8;
  static bool contientMinuscule(String v) => RegExp(r'[a-z]').hasMatch(v);
  static bool contientMajuscule(String v) => RegExp(r'[A-Z]').hasMatch(v);
  static bool contientChiffre(String v) => RegExp(r'\d').hasMatch(v);

  static bool estRobuste(String v) =>
      longueurSuffisante(v) &&
      contientMinuscule(v) &&
      contientMajuscule(v) &&
      contientChiffre(v);

  @override
  State<AppChampMotDePasse> createState() => _AppChampMotDePasseState();
}

class _AppChampMotDePasseState extends State<AppChampMotDePasse> {
  bool _masque = true;
  String _valeur = '';

  @override
  void initState() {
    super.initState();
    _valeur = widget.controleur.text;
  }

  String? _valider(String? valeur) {
    final saisie = valeur ?? '';
    if (saisie.isEmpty) return 'Le mot de passe est obligatoire';
    if (widget.verifierRobustesse && !AppChampMotDePasse.estRobuste(saisie)) {
      return 'Le mot de passe ne respecte pas encore toutes les règles ci-dessous';
    }
    return widget.validateurSupplementaire?.call(valeur);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppEspace.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.libelle,
            style: AppTypo.jakarta(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColor.kTexte,
            ),
          ),
          const SizedBox(height: AppEspace.s),
          TextFormField(
            controller: widget.controleur,
            obscureText: _masque,
            textInputAction: widget.actionClavier,
            style: AppTypo.jakarta(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColor.kTexte,
            ),
            decoration: AppChampTexte.decoration(
              indication: widget.indication ?? 'Votre mot de passe',
              icone: Icons.lock_outline_rounded,
            ).copyWith(
              suffixIcon: IconButton(
                onPressed: () => setState(() => _masque = !_masque),
                icon: Icon(
                  _masque
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: AppColor.kTexteMoyen,
                ),
                tooltip: _masque ? 'Afficher' : 'Masquer',
              ),
            ),
            onChanged: (v) {
              if (widget.afficherRegles) setState(() => _valeur = v);
            },
            validator: _valider,
          ),
          if (widget.afficherRegles) ...[
            const SizedBox(height: AppEspace.m),
            _regle('Au moins 8 caractères',
                AppChampMotDePasse.longueurSuffisante(_valeur)),
            _regle('Une lettre minuscule',
                AppChampMotDePasse.contientMinuscule(_valeur)),
            _regle('Une lettre majuscule',
                AppChampMotDePasse.contientMajuscule(_valeur)),
            _regle('Un chiffre', AppChampMotDePasse.contientChiffre(_valeur)),
          ],
        ],
      ),
    );
  }

  Widget _regle(String texte, bool satisfaite) {
    final couleur = satisfaite ? AppColor.kSucces : AppColor.kTexteFaible;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(
            satisfaite ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 15,
            color: couleur,
          ),
          const SizedBox(width: AppEspace.s),
          Text(
            texte,
            style: AppTypo.jakarta(
              fontSize: 12.5,
              fontWeight: satisfaite ? FontWeight.w600 : FontWeight.w400,
              color: couleur,
            ),
          ),
        ],
      ),
    );
  }
}

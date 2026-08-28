import 'package:flutter/material.dart';

import 'package:sign_application/core/theme/app_color.dart';
import 'package:sign_application/core/validation/identifiant_validator.dart';

import '../../data/models/exigences_document.dart';
import 'package:sign_application/core/theme/app_typo.dart';

/// informations_manquantes_sheet.dart — Demande progressive des informations
/// administratives (§ 4 à § 7 du cahier des charges).
///
/// S'ouvre juste avant le formulaire de création d'un document, et ne réclame
/// QUE ce que ce document exige réellement et que le profil ne contient pas
/// encore : pièce d'identité, NIN, RCCM, NINEA, adresse…
///
/// C'est le backend qui décrit les champs à afficher (libellé, aide,
/// instruction, validateur) — cette feuille se contente de les rendre et de
/// renvoyer les valeurs saisies.
///
/// Retourne `true` si l'utilisateur peut poursuivre vers le document.
class InformationsManquantesSheet extends StatefulWidget {
  final ExigencesDocument exigences;

  const InformationsManquantesSheet({super.key, required this.exigences});

  /// Ouvre la feuille.
  ///
  /// Retourne les informations saisies — éventuellement vides — si le
  /// parcours peut continuer, et `null` si l'utilisateur a renoncé alors
  /// qu'une information indispensable manquait.
  ///
  /// Ces informations ne sont pas enregistrées : elles servent au document en
  /// cours, et ne rejoindront le compte que si l'utilisateur l'autorise.
  static Future<Map<String, dynamic>?> afficher(
    BuildContext context,
    ExigencesDocument exigences,
  ) async {
    final resultat = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // La feuille se ferme toujours : par la croix, en touchant à côté, en
      // la faisant glisser ou avec le bouton retour.
      //
      // Elle était auparavant verrouillée dès qu'une information obligatoire
      // manquait — la poignée en haut laissait croire à une fermeture
      // possible, et seul le bouton retour du téléphone en sortait. Renoncer
      // à créer un document est légitime : c'est la génération qui doit être
      // refusée, pas la sortie de l'écran.
      isDismissible: true,
      enableDrag: true,
      builder: (_) => InformationsManquantesSheet(exigences: exigences),
    );

    if (resultat != null) return resultat;

    // Fermeture sans choix explicite : on poursuit vers le formulaire
    // seulement si rien ne bloquait — sinon le document ne pourrait pas être
    // généré de toute façon.
    return exigences.champsBloquants.isEmpty ? const <String, dynamic>{} : null;
  }

  @override
  State<InformationsManquantesSheet> createState() =>
      _InformationsManquantesSheetState();
}

class _InformationsManquantesSheetState
    extends State<InformationsManquantesSheet> {
  final _cleFormulaire = GlobalKey<FormState>();

  /// Contrôleurs indexés par clé de champ backend.
  final Map<String, TextEditingController> _controleurs = {};

  /// Valeurs des champs à choix (type de pièce…).
  final Map<String, String> _choix = {};

  bool _enregistrement = false;
  String? _erreurGlobale;

  @override
  void initState() {
    super.initState();
    _preparerChamps();
  }

  void _preparerChamps() {
    for (final champ in widget.exigences.champsManquants) {
      switch (champ.saisie) {
        case 'piece_identite':
          // Le type déjà choisi est repris ; sinon la CNI est présélectionnée,
          // c'est de loin la pièce la plus répandue.
          _choix['type_document_identite'] = champ.typePieceActuel ?? 'carte_identite';
          _controleurs['carte_identite_national_num'] = TextEditingController();
          break;
        case 'groupe_au_choix':
          for (final option in champ.options) {
            _controleurs[option.valeur] = TextEditingController();
          }
          break;
        default:
          _controleurs[champ.cle] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (final controleur in _controleurs.values) {
      controleur.dispose();
    }
    super.dispose();
  }

  // ── Enregistrement ──────────────────────────────────────────────────────

  /// Type de validation à appliquer au numéro de pièce, selon le type choisi.
  String get _typeValidationPiece =>
      _choix['type_document_identite'] == 'passeport' ? 'passeport' : 'cni';

  Future<void> _enregistrer() async {
    setState(() => _erreurGlobale = null);
    if (!(_cleFormulaire.currentState?.validate() ?? false)) return;

    // Contrôle transverse : un groupe « au choix » exige au moins une valeur.
    for (final champ in widget.exigences.champsManquants) {
      if (champ.saisie != 'groupe_au_choix' || !champ.estRequis) continue;
      final auMoinsUn = champ.options.any(
        (o) => (_controleurs[o.valeur]?.text.trim().isNotEmpty ?? false),
      );
      if (!auMoinsUn) {
        setState(() => _erreurGlobale =
            'Renseignez au moins un des deux : ${champ.options.map((o) => o.label).join(' ou ')}.');
        return;
      }
    }

    final donnees = <String, dynamic>{};
    for (final champ in widget.exigences.champsManquants) {
      if (champ.saisie == 'piece_identite') {
        final numero = _controleurs['carte_identite_national_num']?.text.trim() ?? '';
        if (numero.isEmpty) continue;
        donnees['type_document_identite'] = _choix['type_document_identite'];
        donnees['carte_identite_national_num'] = numero;
        continue;
      }
      if (champ.saisie == 'groupe_au_choix') {
        for (final option in champ.options) {
          final valeur = _controleurs[option.valeur]?.text.trim() ?? '';
          if (valeur.isNotEmpty) donnees[option.valeur] = valeur;
        }
        continue;
      }
      final valeur = _controleurs[champ.cle]?.text.trim() ?? '';
      if (valeur.isNotEmpty) donnees[champ.cle] = valeur;
    }

    if (donnees.isEmpty) {
      // Rien de saisi et rien de bloquant : l'utilisateur a simplement passé
      // les champs recommandés.
      if (mounted) Navigator.of(context).pop(<String, dynamic>{});
      return;
    }

    // Rien n'est envoyé au compte ici. Ces informations servent au document
    // en cours ; elles ne seront enregistrées que si l'utilisateur l'autorise
    // depuis la proposition affichée après la génération. Les identifiants
    // « format valide mais non vérifiable » sont signalés juste après, par le
    // contrôle avant génération, qui tient compte de cette saisie.
    Navigator.of(context).pop(donnees);
  }

  void _passer() => Navigator.of(context).pop(<String, dynamic>{});

  /// Fermeture par la croix : on renonce à saisir maintenant.
  ///
  /// Tant qu'une information obligatoire manque, le parcours s'arrête là —
  /// mais l'utilisateur sort de l'écran, ce qui était le vrai problème.
  void _fermer() => Navigator.of(context).pop(
      widget.exigences.champsBloquants.isEmpty ? <String, dynamic>{} : null);

  // ── Construction ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hauteurClavier = MediaQuery.viewInsetsOf(context).bottom;
    final peutPasser = widget.exigences.champsBloquants.isEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: hauteurClavier),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // La poignée seule ne suffit pas : beaucoup d'utilisateurs
            // cherchent une croix. Les deux cohabitent, la croix étant
            // alignée à droite sans décaler la poignée centrée.
            //
            // La largeur est forcée : un Stack prend sinon la taille de son
            // plus grand enfant — ici la poignée de 42 px — et le
            // `Positioned(right:)` collait la croix contre elle, au centre.
            SizedBox(
              width: double.infinity,
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColor.kLine,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    child: IconButton(
                      onPressed: _fermer,
                      icon: const Icon(Icons.close_rounded, size: 22),
                      color: AppColor.kGrayscale40,
                      tooltip: 'Fermer',
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Form(
                  key: _cleFormulaire,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _entete(),
                      const SizedBox(height: 24),
                      ...widget.exigences.champsManquants.map(_construireChamp),
                      if (_erreurGlobale != null) _bandeauErreur(),
                    ],
                  ),
                ),
              ),
            ),
            _pied(peutPasser),
          ],
        ),
      ),
    );
  }

  Widget _entete() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Encore une information',
          style: AppTypo.jakarta(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColor.kGrayscaleDark100,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Pour établir votre ${widget.exigences.libelle.toLowerCase()}, SIGNS a '
          'besoin des éléments ci-dessous. Ils seront conservés et repris '
          'automatiquement dans vos prochains documents.',
          style: AppTypo.jakarta(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColor.kGrayscale40,
            height: 1.55,
          ),
        ),
      ],
    );
  }

  Widget _bandeauErreur() {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 18, color: AppColor.kDanger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _erreurGlobale!,
              style: AppTypo.jakarta(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColor.kDanger,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pied(bool peutPasser) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, 16 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColor.kLine)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _enregistrement ? null : _enregistrer,
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  decoration: BoxDecoration(
                    color: _enregistrement ? AppColor.kGrayscale40 : AppColor.kPrimary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: _enregistrement
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(
                            'Enregistrer et continuer',
                            style: AppTypo.jakarta(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
          if (peutPasser)
            TextButton(
              onPressed: _enregistrement ? null : _passer,
              child: Text(
                'Plus tard',
                style: AppTypo.jakarta(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColor.kGrayscale40,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Rendu d'un champ ────────────────────────────────────────────────────

  Widget _construireChamp(ChampManquant champ) {
    switch (champ.saisie) {
      case 'piece_identite':
        return _champPieceIdentite(champ);
      case 'groupe_au_choix':
        return _champGroupeAuChoix(champ);
      default:
        return _champSimple(champ);
    }
  }

  /// § 5 et § 6 : type de pièce puis numéro, avec l'instruction adaptée.
  Widget _champPieceIdentite(ChampManquant champ) {
    final sousChampNumero = champ.sousChamps.firstWhere(
      (sc) => sc.cle == 'carte_identite_national_num',
      orElse: () => const SousChamp(
        cle: 'carte_identite_national_num',
        label: 'Numéro de la pièce d’identité',
        saisie: 'texte',
      ),
    );

    final estPasseport = _choix['type_document_identite'] == 'passeport';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _libelle("Type de pièce d'identité", champ.estRequis),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _boutonChoix(
                label: 'CNI',
                selectionne: !estPasseport,
                onTap: () => setState(
                    () => _choix['type_document_identite'] = 'carte_identite'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _boutonChoix(
                label: 'Passeport',
                selectionne: estPasseport,
                onTap: () =>
                    setState(() => _choix['type_document_identite'] = 'passeport'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _libelle(
          estPasseport ? 'Numéro du passeport' : 'Numéro de la CNI',
          champ.estRequis,
        ),
        const SizedBox(height: 8),
        TextFormField(
          // La cle change avec le type de piece : sans elle, Flutter reutilise
          // le champ existant et conserve la connexion de saisie deja ouverte
          // — le clavier reste numerique alors qu'un passeport commence par
          // une lettre.
          key: ValueKey('numero_piece_${estPasseport ? 'passeport' : 'cni'}'),
          controller: _controleurs['carte_identite_national_num'],
          keyboardType:
              estPasseport ? TextInputType.text : TextInputType.number,
          textCapitalization:
              estPasseport ? TextCapitalization.characters : TextCapitalization.none,
          style: _styleSaisie,
          decoration: _decoration(
            estPasseport ? 'Ex. A1234567' : 'Ex. 20419920515984519',
          ),
          validator: (valeur) => _validerAvecMoteur(
            valeur,
            typeValidation: _typeValidationPiece,
            requis: champ.estRequis,
          ),
        ),
        // § 5 : instruction obligatoire sous le champ pour le passeport.
        _instruction(
          estPasseport
              ? (sousChampNumero.instruction ??
                  'Saisissez le numéro indiqué sur la photo de votre passeport, '
                      'exactement comme il apparaît sur le document.')
              : 'Saisissez les 17 chiffres figurant sur votre carte nationale '
                  'd’identité biométrique.',
          illustration: estPasseport,
        ),
        const SizedBox(height: 22),
      ],
    );
  }

  /// § 7 : RCCM, NINEA, ou les deux — l'utilisateur choisit.
  Widget _champGroupeAuChoix(ChampManquant champ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _libelle(champ.label, champ.estRequis),
        if (champ.aide != null) ...[
          const SizedBox(height: 6),
          Text(
            champ.aide!,
            style: AppTypo.jakarta(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: AppColor.kGrayscale40,
              height: 1.45,
            ),
          ),
        ],
        const SizedBox(height: 12),
        for (final option in champ.options) ...[
          Text(
            option.label,
            style: AppTypo.jakarta(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColor.kGrayscaleDark100,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _controleurs[option.valeur],
            textCapitalization: TextCapitalization.characters,
            style: _styleSaisie,
            decoration: _decoration(
              option.valeur == 'rc' ? 'Ex. SN.DKR.2017.A.19778' : 'Ex. 005812511 2G3',
            ),
            // Facultatif individuellement : la contrainte « au moins un » est
            // contrôlée globalement à l'enregistrement.
            validator: (valeur) => _validerAvecMoteur(
              valeur,
              typeValidation: option.typeValidation ?? option.valeur,
              requis: false,
            ),
          ),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _champSimple(ChampManquant champ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _libelle(champ.label, champ.estRequis),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controleurs[champ.cle],
          keyboardType: champ.typeValidation == 'nin'
              ? TextInputType.number
              : TextInputType.text,
          style: _styleSaisie,
          decoration: _decoration(champ.aide ?? ''),
          validator: (valeur) => _validerAvecMoteur(
            valeur,
            typeValidation: champ.typeValidation,
            requis: champ.estRequis,
          ),
        ),
        if (champ.aide != null) _instruction(champ.aide!),
        const SizedBox(height: 22),
      ],
    );
  }

  // ── Briques ─────────────────────────────────────────────────────────────

  /// Applique le moteur de validation local. Un résultat « format valide »
  /// n'est jamais une erreur de formulaire : c'est le niveau orange du § 15.
  String? _validerAvecMoteur(
    String? valeur, {
    String? typeValidation,
    required bool requis,
  }) {
    final saisie = valeur?.trim() ?? '';
    if (saisie.isEmpty) {
      return requis ? 'Cette information est nécessaire pour ce document' : null;
    }
    if (typeValidation == null || typeValidation.isEmpty) return null;
    return IdentifiantValidator.parType(typeValidation, saisie).erreurFormulaire;
  }

  TextStyle get _styleSaisie => AppTypo.jakarta(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColor.kGrayscaleDark100,
      );

  Widget _libelle(String texte, bool requis) {
    return Row(
      children: [
        Flexible(
          child: Text(
            texte,
            style: AppTypo.jakarta(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColor.kGrayscaleDark100,
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (!requis)
          Text(
            'facultatif',
            style: AppTypo.jakarta(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppColor.kGrayscale40,
            ),
          ),
      ],
    );
  }

  Widget _instruction(String texte, {bool illustration = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColor.kBackground2,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              illustration ? Icons.badge_outlined : Icons.info_outline_rounded,
              size: 16,
              color: AppColor.kGrayscale40,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                texte,
                style: AppTypo.jakarta(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: AppColor.kGrayscale40,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _boutonChoix({
    required String label,
    required bool selectionne,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selectionne ? AppColor.kPrimary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selectionne ? AppColor.kPrimary : AppColor.kLine,
              width: 1.3,
            ),
          ),
          child: Text(
            label,
            style: AppTypo.jakarta(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: selectionne ? Colors.white : AppColor.kGrayscaleDark100,
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String indication) {
    OutlineInputBorder bordure(Color couleur, double epaisseur) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: couleur, width: epaisseur),
        );

    return InputDecoration(
      hintText: indication,
      hintStyle: AppTypo.jakarta(
        fontSize: 14.5,
        color: AppColor.kGrayscale40,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: bordure(AppColor.kLine, 1.2),
      enabledBorder: bordure(AppColor.kLine, 1.2),
      focusedBorder: bordure(AppColor.kPrimary, 1.5),
      errorBorder: bordure(Colors.redAccent, 1.4),
      focusedErrorBorder: bordure(Colors.redAccent, 1.4),
      errorMaxLines: 3,
    );
  }
}

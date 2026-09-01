import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toastification/toastification.dart';

import 'package:sign_application/core/routes/app_router.dart';
import 'package:sign_application/core/theme/app_color.dart';
import 'package:sign_application/core/utils/normalisation_nom.dart';
import 'package:sign_application/core/validation/identifiant_validator.dart';
import 'package:sign_application/core/widgets/toastNotif.dart';
import 'package:sign_application/injection_container.dart';

import '../../data/datasources/parcours_remote_datasource.dart';
import '../../data/suivi_profil_service.dart';
import '../../domain/etat_profil.dart';
import 'package:sign_application/core/theme/app_typo.dart';

/// compte_complet_page.dart — Création du compte complet (§ 11).
///
/// Accessible depuis la proposition affichée après le premier document
/// (§ 10) ou depuis le profil. À ce stade seulement, les informations
/// administratives deviennent obligatoires — et elles diffèrent selon le
/// profil :
///
///   Particulier    : identité + pièce d'identité (+ NIN si disponible)
///   Professionnel  : idem + entreprise + RCCM et/ou NINEA
///
/// Le formulaire est prérempli avec tout ce que SIGNS connaît déjà
/// (`GET /profil/prereemplissage`), pour que l'utilisateur n'ait à compléter
/// que ce qui manque réellement.
///
/// Il n'est pas obligatoire de tout remplir d'un coup : « Enregistrer et
/// continuer plus tard » écrit ce qui est saisi et rend la main. Le compte
/// n'est marqué complet qu'au bouton principal, mais rien n'est perdu entre
/// deux passages — ce qui a été enregistré revient prérempli.
class CompteCompletPage extends StatefulWidget {
  const CompteCompletPage({super.key});

  @override
  State<CompteCompletPage> createState() => _CompteCompletPageState();
}

class _CompteCompletPageState extends State<CompteCompletPage> {
  final _cleFormulaire = GlobalKey<FormState>();

  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _numeroPieceCtrl = TextEditingController();
  final _ninCtrl = TextEditingController();
  final _rccmCtrl = TextEditingController();
  final _nineaCtrl = TextEditingController();
  final _nomEntrepriseCtrl = TextEditingController();
  final _adresseEntrepriseCtrl = TextEditingController();

  String _typePiece = 'carte_identite';
  bool _estProfessionnel = false;
  bool _chargement = true;
  bool _envoi = false;
  /// Enregistrement partiel en cours — distinct de [_envoi] pour que seul le
  /// bouton concerné passe en attente.
  bool _enregistrementPartiel = false;
  /// Au moins un champ a été touché depuis le dernier enregistrement : c'est
  /// ce qui justifie de prévenir avant de quitter l'écran.
  bool _modifie = false;
  String? _erreur;

  bool get _estPasseport => _typePiece == 'passeport';

  /// Les champs dont dépend le décompte affiché en tête d'écran.
  List<TextEditingController> get _controleursSuivis => [
        _nomCtrl, _prenomCtrl, _villeCtrl, _telephoneCtrl, _emailCtrl,
        _numeroPieceCtrl, _rccmCtrl, _nineaCtrl, _nomEntrepriseCtrl,
      ];

  @override
  void initState() {
    super.initState();
    // Le compteur doit suivre la saisie : sans ces écoutes, il resterait figé
    // sur son état d'ouverture et annoncerait des champs déjà remplis.
    for (final controleur in _controleursSuivis) {
      controleur.addListener(_surSaisie);
    }
    _chargerPreremplissage();
  }

  void _surSaisie() {
    if (!mounted) return;
    setState(() => _modifie = true);
  }

  /// Ce qu'il reste à renseigner, calculé sur la saisie en cours — donc à
  /// jour à chaque frappe, sans aller-retour avec le serveur.
  ///
  /// Les règles sont celles d'[EtatProfil], les mêmes que celles appliquées
  /// par le backend au moment de finaliser : le nombre annoncé ici est
  /// exactement ce qui sera réclamé.
  List<ElementManquant> get _champsRestants {
    final saisie = <String, dynamic>{
      'role': _estProfessionnel ? 'Professionnel' : 'Particulier',
      'nom': _nomCtrl.text,
      'prenom': _prenomCtrl.text,
      'ville': _villeCtrl.text,
      'telephone': _telephoneCtrl.text,
      'email': _emailCtrl.text,
      'type_document_identite': _typePiece,
      'carte_identite_national_num': _numeroPieceCtrl.text,
      'nomEntreprise': _nomEntrepriseCtrl.text,
      'rc': _rccmCtrl.text,
      'ninea': _nineaCtrl.text,
    };
    // Les justificatifs se comptent sur l'autre écran : ici on ne parle que
    // des informations à saisir.
    return EtatProfil.analyser(profil: saisie, justificatifs: const [])
        .champsManquants;
  }

  @override
  void dispose() {
    for (final controleur in _controleursSuivis) {
      controleur.removeListener(_surSaisie);
    }
    for (final c in [
      _nomCtrl, _prenomCtrl, _villeCtrl, _adresseCtrl, _telephoneCtrl,
      _emailCtrl, _numeroPieceCtrl, _ninCtrl, _rccmCtrl, _nineaCtrl,
      _nomEntrepriseCtrl, _adresseEntrepriseCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// § 16 : tout ce que SIGNS sait déjà est réinjecté dans le formulaire.
  Future<void> _chargerPreremplissage() async {
    try {
      final donnees = await sl<ParcoursRemoteDataSource>().prereemplissage();
      if (!mounted) return;
      setState(() {
        _nomCtrl.text = donnees['nom']?.toString() ?? '';
        _prenomCtrl.text = donnees['prenom']?.toString() ?? '';
        _villeCtrl.text = donnees['ville']?.toString() ?? '';
        _adresseCtrl.text = donnees['adresse']?.toString() ?? '';
        _telephoneCtrl.text = donnees['telephone']?.toString() ?? '';
        _emailCtrl.text = donnees['email']?.toString() ?? '';
        _numeroPieceCtrl.text = donnees['carte_identite_national_num']?.toString() ?? '';
        _ninCtrl.text = donnees['nin']?.toString() ?? '';
        _rccmCtrl.text = donnees['rc']?.toString() ?? '';
        _nineaCtrl.text = donnees['ninea']?.toString() ?? '';
        _nomEntrepriseCtrl.text = donnees['nomEntreprise']?.toString() ?? '';
        _adresseEntrepriseCtrl.text = donnees['adresseEntreprise']?.toString() ?? '';

        final type = donnees['type_document_identite']?.toString();
        if (type == 'passeport') _typePiece = 'passeport';

        // Le rôle fait foi quand le backend le transmet. Le repli — la
        // présence d'informations d'entreprise — reste là pour les serveurs
        // pas encore à jour, mais il se trompait sur un professionnel qui
        // n'avait encore rien saisi.
        final role = donnees['role']?.toString();
        _estProfessionnel = (role != null && role.isNotEmpty)
            ? role != 'Particulier'
            : (donnees['nomEntreprise']?.toString().isNotEmpty ?? false) ||
                (donnees['rc']?.toString().isNotEmpty ?? false) ||
                (donnees['ninea']?.toString().isNotEmpty ?? false);

        // Le préremplissage n'est pas une modification de l'utilisateur.
        _modifie = false;
        _chargement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _chargement = false);
    }
  }

  /// Rassemble ce qui est saisi, sans exiger que tout le soit.
  ///
  /// Les champs laissés vides ne sont pas envoyés : sur cette route, une
  /// valeur vide EFFACE la donnée en base. Un enregistrement partiel ne doit
  /// jamais faire disparaître ce qui a été saisi lors d'un passage précédent.
  Map<String, dynamic> _saisieNonVide() {
    final donnees = <String, dynamic>{'type_document_identite': _typePiece};

    void ajouter(String cle, TextEditingController controleur) {
      final valeur = controleur.text.trim();
      if (valeur.isNotEmpty) donnees[cle] = valeur;
    }

    ajouter('nom', _nomCtrl);
    ajouter('prenom', _prenomCtrl);
    ajouter('ville', _villeCtrl);
    ajouter('adresse', _adresseCtrl);
    ajouter('telephone', _telephoneCtrl);
    ajouter('email', _emailCtrl);
    ajouter('carte_identite_national_num', _numeroPieceCtrl);
    ajouter('nin', _ninCtrl);

    if (_estProfessionnel) {
      ajouter('rc', _rccmCtrl);
      ajouter('ninea', _nineaCtrl);
      ajouter('nomEntreprise', _nomEntrepriseCtrl);
      ajouter('adresseEntreprise', _adresseEntrepriseCtrl);
    }

    return donnees;
  }

  /// « Enregistrer et continuer plus tard » (§ 11).
  ///
  /// Le compte n'est pas marqué complet — c'est le bouton principal qui s'en
  /// charge, une fois tout réuni. Ici on ne fait que garder ce qui est déjà
  /// saisi, pour que l'utilisateur retrouve son dossier là où il l'a laissé.
  ///
  /// Aucune validation de formulaire : réclamer les champs obligatoires
  /// reviendrait à refuser précisément ce que ce bouton propose. Le format de
  /// ce qui EST saisi reste contrôlé par le backend, dont les messages sont
  /// affichés tels quels.
  Future<void> _enregistrerPartiellement() async {
    setState(() {
      _erreur = null;
      _enregistrementPartiel = true;
    });

    try {
      await sl<ParcoursRemoteDataSource>().enregistrerInformations(_saisieNonVide());
      await sl<SuiviProfilService>().rafraichir();
      if (!mounted) return;

      final restants = _champsRestants.length;
      setState(() {
        _enregistrementPartiel = false;
        _modifie = false;
      });
      showToast(
        context,
        'Informations enregistrées',
        restants == 0
            ? 'Il ne reste plus qu’à déposer vos justificatifs.'
            : 'Vous pourrez reprendre plus tard : il reste '
                '$restants information${restants > 1 ? 's' : ''} à renseigner.',
        ToastificationType.success,
      );
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    } on ParcoursException catch (e) {
      if (!mounted) return;
      setState(() {
        _enregistrementPartiel = false;
        _erreur = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _enregistrementPartiel = false;
        _erreur = 'Enregistrement impossible. Vérifiez votre connexion.';
      });
    }
  }

  /// Sortie de l'écran avec des saisies non enregistrées.
  ///
  /// Trois issues, parce que les trois intentions existent : garder ce qui est
  /// saisi, partir sans rien garder, ou revenir au formulaire.
  Future<bool> _confirmerSortie() async {
    if (!_modifie || _envoi || _enregistrementPartiel) return true;

    final choix = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Enregistrer avant de quitter ?',
          style: AppTypo.jakarta(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColor.kGrayscaleDark100,
          ),
        ),
        content: Text(
          'Vos informations seront conservées et vous pourrez reprendre là où '
          'vous vous êtes arrêté.',
          style: AppTypo.jakarta(
            fontSize: 14,
            color: AppColor.kGrayscale40,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('annuler'),
            child: Text('Continuer la saisie',
                style: AppTypo.jakarta(color: AppColor.kGrayscale40)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('quitter'),
            child: Text('Quitter',
                style: AppTypo.jakarta(color: AppColor.kDanger)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('enregistrer'),
            child: Text('Enregistrer',
                style: AppTypo.jakarta(
                    color: AppColor.kGrayscaleDark100,
                    fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (choix == 'enregistrer') {
      // L'enregistrement referme l'écran lui-même en cas de succès ; en cas
      // d'échec, le message d'erreur doit rester visible.
      await _enregistrerPartiellement();
      return false;
    }
    return choix == 'quitter';
  }

  Future<void> _enregistrer() async {
    setState(() => _erreur = null);
    if (!(_cleFormulaire.currentState?.validate() ?? false)) return;

    if (_estProfessionnel &&
        _rccmCtrl.text.trim().isEmpty &&
        _nineaCtrl.text.trim().isEmpty) {
      setState(() => _erreur =
          'Renseignez au moins votre RCCM ou votre NINEA pour finaliser votre compte professionnel.');
      return;
    }

    final donnees = <String, dynamic>{
      'nom': _nomCtrl.text.trim(),
      'prenom': _prenomCtrl.text.trim(),
      'ville': _villeCtrl.text.trim(),
      'telephone': _telephoneCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'type_document_identite': _typePiece,
      'carte_identite_national_num': _numeroPieceCtrl.text.trim(),
      if (_adresseCtrl.text.trim().isNotEmpty) 'adresse': _adresseCtrl.text.trim(),
      if (_ninCtrl.text.trim().isNotEmpty) 'nin': _ninCtrl.text.trim(),
      if (_estProfessionnel) ...{
        if (_rccmCtrl.text.trim().isNotEmpty) 'rc': _rccmCtrl.text.trim(),
        if (_nineaCtrl.text.trim().isNotEmpty) 'ninea': _nineaCtrl.text.trim(),
        if (_nomEntrepriseCtrl.text.trim().isNotEmpty)
          'nomEntreprise': _nomEntrepriseCtrl.text.trim(),
        if (_adresseEntrepriseCtrl.text.trim().isNotEmpty)
          'adresseEntreprise': _adresseEntrepriseCtrl.text.trim(),
      },
    };

    setState(() => _envoi = true);
    try {
      await sl<ParcoursRemoteDataSource>().completerProfil(donnees);
      await sl<SuiviProfilService>().rafraichir();
      if (!mounted) return;
      _modifie = false;
      showToast(
        context,
        'Profil complété',
        'Vos informations seront désormais préremplies automatiquement.',
        ToastificationType.success,
      );
      // § 12 : on enchaîne sur la vérification des justificatifs.
      Navigator.of(context).pushReplacementNamed(AppRouter.justificatifsRoute);
    } on ParcoursException catch (e) {
      if (!mounted) return;
      setState(() {
        _envoi = false;
        _erreur = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _envoi = false;
        _erreur = 'Enregistrement impossible. Vérifiez votre connexion.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Quitter en cours de saisie ne doit pas coûter ce qui a déjà été tapé :
    // le geste de retour propose d'abord de l'enregistrer.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (dejaFerme, _) async {
        if (dejaFerme) return;
        final peutSortir = await _confirmerSortie();
        if (peutSortir && context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      child: _formulaire(),
    );
  }

  /// Le formulaire lui-meme, sorti de [build] pour que le garde-fou de sortie
  /// n'ajoute pas un niveau d'indentation a tout l'ecran.
  Widget _formulaire() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColor.kGrayscaleDark100,
        title: Text(
          'Mon compte SIGNS',
          style: AppTypo.jakarta(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColor.kGrayscaleDark100,
          ),
        ),
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      child: Form(
                        key: _cleFormulaire,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _introduction(),
                            const SizedBox(height: 18),
                            _compteurChampsRestants(),
                            const SizedBox(height: 22),
                            _section('Identité'),
                            _champ('Nom', _nomCtrl,
                                obligatoire: true,
                                formateurs: const [FormateurNomFamille()]),
                            _champ('Prénom', _prenomCtrl,
                                obligatoire: true,
                                formateurs: const [FormateurPrenom()]),
                            _champ('Ville', _villeCtrl, obligatoire: true),
                            _champ('Adresse complète', _adresseCtrl),
                            _champ(
                              'Numéro de téléphone',
                              _telephoneCtrl,
                              obligatoire: true,
                              typeValidation: 'telephone',
                              typeClavier: TextInputType.phone,
                            ),
                            _champ(
                              'Adresse e-mail',
                              _emailCtrl,
                              obligatoire: true,
                              typeValidation: 'email',
                              typeClavier: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 12),
                            _section("Pièce d'identité"),
                            _selecteurTypePiece(),
                            const SizedBox(height: 18),
                            _champ(
                              _estPasseport ? 'Numéro du passeport' : 'Numéro de la CNI',
                              _numeroPieceCtrl,
                              obligatoire: true,
                              typeValidation: _estPasseport ? 'passeport' : 'cni',
                              typeClavier: _estPasseport
                                  ? TextInputType.text
                                  : TextInputType.number,
                              majuscules: _estPasseport,
                              instruction: _estPasseport
                                  ? 'Saisissez le numéro indiqué sur la photo de votre '
                                      'passeport, exactement comme il apparaît sur le document.'
                                  : 'Les 17 chiffres figurant sur votre carte biométrique.',
                            ),
                            _champ(
                              'NIN / Numéro personnel',
                              _ninCtrl,
                              typeValidation: 'nin',
                              typeClavier: TextInputType.number,
                              instruction: 'Facultatif — 13 chiffres (ex. 1915199200088).',
                            ),
                            if (_estProfessionnel) ...[
                              const SizedBox(height: 12),
                              _section('Activité professionnelle'),
                              _champ("Nom de l'entreprise", _nomEntrepriseCtrl,
                                  obligatoire: true),
                              _champ("Adresse de l'entreprise", _adresseEntrepriseCtrl),
                              _champ(
                                'RCCM / Registre du Commerce',
                                _rccmCtrl,
                                typeValidation: 'rccm',
                                majuscules: true,
                                instruction: 'Format attendu : SN.DKR.2017.A.19778',
                              ),
                              _champ(
                                'NINEA',
                                _nineaCtrl,
                                typeValidation: 'ninea',
                                majuscules: true,
                                instruction:
                                    'Ex. 005812511 2G3 — au moins l’un des deux (RCCM ou NINEA) est requis.',
                              ),
                            ],
                            if (_erreur != null) _bandeauErreur(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _pied(),
                ],
              ),
            ),
    );
  }

  Widget _introduction() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Finalisez votre compte',
          style: AppTypo.jakarta(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColor.kGrayscaleDark100,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Ces informations seront reprises automatiquement dans tous vos '
          'documents. Vous n’aurez plus à les saisir.',
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

  /// Le nombre d'informations encore attendues, en tête de formulaire.
  ///
  /// Un formulaire de douze champs ne dit pas de lui-même où l'on en est :
  /// ce bandeau répond à la seule question que se pose l'utilisateur — combien
  /// de fois encore. Il se met à jour à chaque frappe, et énumère les deux
  /// premiers champs restants pour éviter la chasse au champ vide.
  Widget _compteurChampsRestants() {
    final restants = _champsRestants;

    if (restants.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5EE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBFE3CE)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                size: 18, color: Color(0xFF1B7F4B)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Toutes les informations sont renseignées.',
                style: AppTypo.jakarta(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF14603A),
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final apercu = restants.take(2).map((c) => c.libelle).join(', ');
    final reste = restants.length - 2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3DCB0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.edit_note_rounded, size: 19, color: AppColor.kAlerte),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${restants.length} information${restants.length > 1 ? 's' : ''} '
                  'restante${restants.length > 1 ? 's' : ''} à renseigner',
                  style: AppTypo.jakarta(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF7A4E00),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  reste > 0 ? '$apercu et $reste autre${reste > 1 ? 's' : ''}.' : '$apercu.',
                  style: AppTypo.jakarta(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF7A4E00),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String titre) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        titre.toUpperCase(),
        style: AppTypo.jakarta(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: AppColor.kGrayscale40,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _selecteurTypePiece() {
    Widget bouton(String label, String valeur) {
      final selectionne = _typePiece == valeur;
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _typePiece = valeur),
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
        ),
      );
    }

    return Row(
      children: [
        bouton('CNI', 'carte_identite'),
        const SizedBox(width: 12),
        bouton('Passeport', 'passeport'),
      ],
    );
  }

  Widget _champ(
    String label,
    TextEditingController controleur, {
    bool obligatoire = false,
    String? typeValidation,
    TextInputType typeClavier = TextInputType.text,
    bool majuscules = false,
    String? instruction,
    List<TextInputFormatter>? formateurs,
  }) {
    OutlineInputBorder bordure(Color couleur, double epaisseur) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: couleur, width: epaisseur),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  style: AppTypo.jakarta(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColor.kGrayscaleDark100,
                  ),
                ),
              ),
              if (!obligatoire) ...[
                const SizedBox(width: 8),
                Text(
                  'facultatif',
                  style: AppTypo.jakarta(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColor.kGrayscale40,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            // La cle depend du clavier : sans elle, Flutter reutilise le champ
            // existant et garde la connexion de saisie deja ouverte — passer
            // de la CNI au passeport laissait un clavier numerique alors qu'un
            // numero de passeport commence par une lettre.
            key: ValueKey('$label-${typeClavier.index}'),
            controller: controleur,
            keyboardType: typeClavier,
            textCapitalization:
                majuscules ? TextCapitalization.characters : TextCapitalization.none,
            inputFormatters: formateurs,
            style: AppTypo.jakarta(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColor.kGrayscaleDark100,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              border: bordure(AppColor.kLine, 1.2),
              enabledBorder: bordure(AppColor.kLine, 1.2),
              focusedBorder: bordure(AppColor.kPrimary, 1.5),
              errorBorder: bordure(Colors.redAccent, 1.4),
              focusedErrorBorder: bordure(Colors.redAccent, 1.4),
              errorMaxLines: 3,
            ),
            validator: (valeur) {
              final saisie = valeur?.trim() ?? '';
              if (saisie.isEmpty) {
                return obligatoire ? 'Cette information est obligatoire' : null;
              }
              if (typeValidation == null) return null;
              return IdentifiantValidator.parType(typeValidation, saisie)
                  .erreurFormulaire;
            },
          ),
          if (instruction != null) ...[
            const SizedBox(height: 7),
            Text(
              instruction,
              style: AppTypo.jakarta(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: AppColor.kGrayscale40,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bandeauErreur() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: AppColor.kDanger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _erreur!,
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

  Widget _pied() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, 16 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColor.kLine)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: (_envoi || _enregistrementPartiel) ? null : _enregistrer,
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  decoration: BoxDecoration(
                    color: _envoi ? AppColor.kGrayscale40 : AppColor.kPrimary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: _envoi
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(
                            'Enregistrer mon compte',
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
          const SizedBox(height: 10),
          // Sortie assumée : ce qui est saisi est conservé, le compte n'est
          // simplement pas encore déclaré complet. Un formulaire de cette
          // longueur se remplit rarement en une fois, surtout quand il faut
          // aller chercher une pièce d'identité dans un tiroir.
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: (_envoi || _enregistrementPartiel)
                  ? null
                  : _enregistrerPartiellement,
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: AppColor.kLine, width: 1.3),
                ),
              ),
              child: _enregistrementPartiel
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : Text(
                      'Enregistrer et continuer plus tard',
                      style: AppTypo.jakarta(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColor.kGrayscaleDark100,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

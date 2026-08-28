import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import 'package:sign_application/core/routes/app_router.dart';
import 'package:sign_application/core/theme/app_color.dart';
import 'package:sign_application/core/validation/identifiant_validator.dart';
import 'package:sign_application/core/widgets/toastNotif.dart';
import 'package:sign_application/injection_container.dart';

import '../../data/datasources/parcours_remote_datasource.dart';
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
  String? _erreur;

  bool get _estPasseport => _typePiece == 'passeport';

  @override
  void initState() {
    super.initState();
    _chargerPreremplissage();
  }

  @override
  void dispose() {
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

        // Un compte disposant d'informations d'entreprise est un compte
        // professionnel : c'est le critère le plus fiable côté client.
        _estProfessionnel = (donnees['nomEntreprise']?.toString().isNotEmpty ?? false) ||
            (donnees['rc']?.toString().isNotEmpty ?? false) ||
            (donnees['ninea']?.toString().isNotEmpty ?? false);

        _chargement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _chargement = false);
    }
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
      if (!mounted) return;
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
                            const SizedBox(height: 26),
                            _section('Identité'),
                            _champ('Nom', _nomCtrl, obligatoire: true),
                            _champ('Prénom', _prenomCtrl, obligatoire: true),
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
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _envoi ? null : _enregistrer,
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
    );
  }
}

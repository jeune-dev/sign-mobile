import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:toastification/toastification.dart';

import 'package:sign_application/core/routes/app_router.dart';
import 'package:sign_application/core/theme/app_color.dart';
import 'package:sign_application/core/theme/app_dimensions.dart';
import 'package:sign_application/core/widgets/app_bouton.dart';
import 'package:sign_application/core/widgets/app_champ_texte.dart';
import 'package:sign_application/core/utils/normalisation_nom.dart';
import 'package:sign_application/core/validation/identifiant_validator.dart';
import 'package:sign_application/core/validation/pays_telephone_ui.dart';
import 'package:sign_application/core/widgets/toastNotif.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'package:sign_application/core/theme/app_typo.dart';
import 'package:sign_application/core/widgets/app_champ_mot_de_passe.dart';

/// inscription_rapide_page.dart — Création rapide du profil (§ 2).
///
/// Ne demande QUE l'essentiel : type de profil, nom, prénom, ville et
/// numéro de téléphone (obligatoire), plus l'e-mail (facultatif mais
/// recommandé). Un professionnel ajoute une étape pour son entreprise.
///
/// Aucune pièce d'identité, aucun NIN, aucun RCCM, aucun NINEA à ce stade :
/// ces informations sont réclamées plus tard, au moment du document qui en a
/// besoin (voir `InformationsManquantesSheet`).
///
/// À la validation, le backend renvoie directement un jeton de session :
/// l'utilisateur entre dans l'application sans passer par l'écran de
/// connexion (§ 3).
class InscriptionRapidePage extends StatefulWidget {
  const InscriptionRapidePage({super.key});

  @override
  State<InscriptionRapidePage> createState() => _InscriptionRapidePageState();
}

class _InscriptionRapidePageState extends State<InscriptionRapidePage> {
  // ── Étape 1 : type de profil ────────────────────────────────────────────
  String? _role;

  // ── Étape 2 : informations personnelles ─────────────────────────────────
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _motDePasseCtrl = TextEditingController();
  final _confirmationCtrl = TextEditingController();
  String? _telephone;

  // ── Étape 3 : informations professionnelles ─────────────────────────────
  final _nomEntrepriseCtrl = TextEditingController();
  final _posteCtrl = TextEditingController();
  final _villeEntrepriseCtrl = TextEditingController();
  final _emailEntrepriseCtrl = TextEditingController();
  String? _telephoneEntreprise;

  int _etape = 0;
  final _cleFormulairePerso = GlobalKey<FormState>();
  final _cleFormulairePro = GlobalKey<FormState>();

  bool get _estProfessionnel => _role == 'Professionnel';

  /// Un particulier ne voit que 2 étapes, un professionnel 3.
  int get _nombreEtapes => _estProfessionnel ? 3 : 2;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _villeCtrl.dispose();
    _emailCtrl.dispose();
    _motDePasseCtrl.dispose();
    _confirmationCtrl.dispose();
    _nomEntrepriseCtrl.dispose();
    _posteCtrl.dispose();
    _villeEntrepriseCtrl.dispose();
    _emailEntrepriseCtrl.dispose();
    super.dispose();
  }

  // ── Navigation entre les étapes ─────────────────────────────────────────

  void _choisirRole(String role) {
    setState(() {
      _role = role;
      _etape = 1;
    });
  }

  /// « J'ai déjà un compte ».
  ///
  /// À la première ouverture, l'application dépose l'utilisateur directement
  /// sur cet écran : quelqu'un qui réinstalle l'application, ou qui change de
  /// téléphone, n'avait aucun moyen de rejoindre la connexion sans repasser
  /// par le bouton retour, qui ressemble à un abandon.
  void _allerVersConnexion() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.loginRoute,
      (route) => false,
    );
  }

  void _etapePrecedente() {
    if (_etape == 0) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.loginRoute,
        (route) => false,
      );
      return;
    }
    setState(() => _etape -= 1);
  }

  void _continuer() {
    if (_etape == 1) {
      if (!(_cleFormulairePerso.currentState?.validate() ?? false)) return;

      // Le numéro n'est pas un TextFormField classique : on le contrôle avec
      // le même moteur que le backend pour afficher le vrai motif du refus.
      final resultat = IdentifiantValidator.telephone(_telephone);
      if (resultat.estBloquant) {
        showToast(context, 'Numéro invalide', resultat.message, ToastificationType.error);
        return;
      }

      if (_estProfessionnel) {
        setState(() => _etape = 2);
        return;
      }
      _soumettre();
      return;
    }

    if (_etape == 2) {
      if (!(_cleFormulairePro.currentState?.validate() ?? false)) return;
      _soumettre();
    }
  }

  void _soumettre() {
    final telephoneNormalise =
        IdentifiantValidator.telephone(_telephone).valeur ?? _telephone ?? '';

    final emailSaisi = _emailCtrl.text.trim();
    final emailEntrepriseSaisi = _emailEntrepriseCtrl.text.trim();

    context.read<AuthBloc>().add(
          RegisterRequested(
            nom: _nomCtrl.text.trim(),
            prenom: _prenomCtrl.text.trim(),
            telephone: telephoneNormalise,
            role: _role ?? 'Particulier',
            ville: _villeCtrl.text.trim(),
            email: emailSaisi,
            mot_de_passe: _motDePasseCtrl.text,
            // Informations d'entreprise : uniquement pour un professionnel.
            nomEntreprise:
                _estProfessionnel && _nomEntrepriseCtrl.text.trim().isNotEmpty
                    ? _nomEntrepriseCtrl.text.trim()
                    : null,
            poste: _estProfessionnel && _posteCtrl.text.trim().isNotEmpty
                ? _posteCtrl.text.trim()
                : null,
            adresseEntreprise:
                _estProfessionnel && _villeEntrepriseCtrl.text.trim().isNotEmpty
                    ? _villeEntrepriseCtrl.text.trim()
                    : null,
            telephoneEntreprise:
                _estProfessionnel ? _telephoneEntreprise : null,
            emailEntreprise:
                _estProfessionnel && emailEntrepriseSaisi.isNotEmpty
                    ? emailEntrepriseSaisi
                    : null,
          ),
        );
  }

  // ── Construction ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (precedent, courant) => precedent != courant,
        listener: (context, state) {
          if (state is AuthSuccess) {
            FocusScope.of(context).unfocus();
            // Le compte est créé mais fermé : aucun jeton n'est délivré tant
            // que le code reçu par e-mail n'est pas confirmé. On enchaîne
            // donc sur l'écran de vérification.
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRouter.verificationEmailRoute,
              (route) => false,
              arguments: state.user.email,
            );
            showToast(
              context,
              'Vérifiez votre e-mail',
              'Un code vient d’être envoyé à ${state.user.email}. '
              'Pensez à regarder dans vos spams.',
              ToastificationType.info,
            );
            context.read<AuthBloc>().add(ResetAuthState());
          } else if (state is AuthFailure) {
            showToast(
              context,
              'Inscription impossible',
              state.message,
              ToastificationType.error,
            );
          }
        },
        builder: (context, state) {
          final enCours = state is AuthLoading || state is AuthUploadProgress;
          return SafeArea(
            child: Column(
              children: [
                _entete(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                        AppEspace.xl, AppEspace.s, AppEspace.xl, AppEspace.xl),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      child: KeyedSubtree(
                        key: ValueKey(_etape),
                        child: _contenuEtape(),
                      ),
                    ),
                  ),
                ),
                if (_etape > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppEspace.xl, 0, AppEspace.xl, AppEspace.s),
                    child: AppBouton(
                      libelle: _etape == _nombreEtapes - 1
                          ? 'Créer mon profil'
                          : 'Continuer',
                      enChargement: enCours,
                      onPressed: _continuer,
                    ),
                  ),
                _lienConnexion(enCours),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Passerelle vers la connexion, en bas de chaque étape.
  ///
  /// Un lien plutôt qu'un second bouton plein : la création de compte reste
  /// l'action de cet écran, la connexion n'est qu'une sortie pour ceux qui
  /// n'avaient rien à y faire.
  Widget _lienConnexion(bool enCours) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppEspace.xl, 0, AppEspace.xl, AppEspace.l),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Vous avez déjà un compte ?',
            style: AppTypo.jakarta(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: AppColor.kGrayscale40,
            ),
          ),
          TextButton(
            onPressed: enCours ? null : _allerVersConnexion,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Se connecter',
              style: AppTypo.jakarta(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppColor.kGrayscaleDark100,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── En-tête : retour, compteur d'étapes, points ─────────────────────────

  Widget _entete() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppEspace.l, AppEspace.s, AppEspace.xl, 0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _etapePrecedente,
                icon: const Icon(Icons.arrow_back_rounded, size: 22),
                color: AppColor.kGrayscaleDark100,
                tooltip: 'Retour',
              ),
              const Spacer(),
              Text(
                'Étape ${_etape + 1} sur $_nombreEtapes',
                style: AppTypo.jakarta(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColor.kGrayscale40,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _pointsEtapes(),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _pointsEtapes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_nombreEtapes * 2 - 1, (index) {
        // Les indices pairs sont des points, les impairs des traits de liaison.
        if (index.isOdd) {
          final positionTrait = (index - 1) ~/ 2;
          return Container(
            width: 44,
            height: 2,
            color: _etape > positionTrait ? AppColor.kPrimary : AppColor.kLine,
          );
        }
        final positionPoint = index ~/ 2;
        final atteint = _etape >= positionPoint;
        return Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: atteint ? AppColor.kPrimary : AppColor.kLine,
          ),
        );
      }),
    );
  }

  // ── Contenu selon l'étape ───────────────────────────────────────────────

  Widget _contenuEtape() {
    switch (_etape) {
      case 0:
        return _etapeChoixProfil();
      case 1:
        return _etapeInformationsPersonnelles();
      default:
        return _etapeInformationsProfessionnelles();
    }
  }

  Widget _titreEtape(String titre, String sousTitre) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          titre,
          textAlign: TextAlign.center,
          style: AppTypo.jakarta(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColor.kGrayscaleDark100,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          sousTitre,
          textAlign: TextAlign.center,
          style: AppTypo.jakarta(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColor.kGrayscale40,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ── Étape 1 : profil ────────────────────────────────────────────────────

  Widget _etapeChoixProfil() {
    return Column(
      children: [
        _titreEtape(
          'Choisissez votre profil',
          'Cela nous permet de personnaliser votre expérience.',
        ),
        const SizedBox(height: 36),
        _carteProfil(
          icone: Icons.person_outline_rounded,
          premiereLigne: 'Je suis',
          seconde: 'Particulier',
          onTap: () => _choisirRole('Particulier'),
        ),
        const SizedBox(height: 16),
        _carteProfil(
          icone: Icons.work_outline_rounded,
          premiereLigne: 'Je suis',
          seconde: 'Professionnel',
          onTap: () => _choisirRole('Professionnel'),
        ),
      ],
    );
  }

  Widget _carteProfil({
    required IconData icone,
    required String premiereLigne,
    required String seconde,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppEspace.l + 4, vertical: AppEspace.xl - 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColor.kLine, width: 1.4),
          ),
          child: Row(
            children: [
              Icon(icone, size: 28, color: AppColor.kGrayscaleDark100),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      premiereLigne,
                      style: AppTypo.jakarta(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: AppColor.kGrayscaleDark100,
                      ),
                    ),
                    Text(
                      seconde,
                      style: AppTypo.jakarta(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColor.kGrayscaleDark100,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 24, color: AppColor.kGrayscale40),
            ],
          ),
        ),
      ),
    );
  }

  // ── Étape 2 : informations personnelles ─────────────────────────────────

  Widget _etapeInformationsPersonnelles() {
    return Form(
      key: _cleFormulairePerso,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titreEtape(
            'Informations personnelles',
            'Remplissez les informations essentielles.',
          ),
          const SizedBox(height: 28),
          AppChampTexte(
            libelle: 'Nom',
            controleur: _nomCtrl,
            indication: 'Votre nom',
            // Le serveur normalise de toute façon à l'enregistrement : la
            // mise en forme pendant la frappe évite que l'utilisateur
            // découvre après coup que son nom s'écrit autrement.
            formateurs: const [FormateurNomFamille()],
            validateur: (valeur) => (valeur == null || valeur.trim().length < 2)
                ? 'Indiquez votre nom'
                : null,
          ),
          AppChampTexte(
            libelle: 'Prénom',
            controleur: _prenomCtrl,
            indication: 'Votre prénom',
            formateurs: const [FormateurPrenom()],
            validateur: (valeur) => (valeur == null || valeur.trim().length < 2)
                ? 'Indiquez votre prénom'
                : null,
          ),
          AppChampTexte(
            libelle: 'Ville',
            controleur: _villeCtrl,
            indication: 'Votre ville',
            validateur: (valeur) => (valeur == null || valeur.trim().length < 2)
                ? 'Indiquez votre ville'
                : null,
          ),
          _champTelephone(
            label: 'Numéro de téléphone',
            surChangement: (numero) => _telephone = numero,
          ),
          _mentionNumero(),
          const SizedBox(height: 20),
          AppChampTexte(
            libelle: 'Adresse e-mail',
            controleur: _emailCtrl,
            indication: 'exemple@email.com',
            typeClavier: TextInputType.emailAddress,
            icone: Icons.mail_outline_rounded,
            validateur: _validerEmail,
          ),
          _mentionEmailRecommande(),
          const SizedBox(height: AppEspace.l),
          AppChampMotDePasse(
            controleur: _motDePasseCtrl,
            afficherRegles: true,
            verifierRobustesse: true,
          ),
          AppChampMotDePasse(
            libelle: 'Confirmez le mot de passe',
            controleur: _confirmationCtrl,
            indication: 'Saisissez-le à nouveau',
            actionClavier: TextInputAction.done,
            validateurSupplementaire: (valeur) =>
                valeur != _motDePasseCtrl.text
                    ? 'Les deux mots de passe ne correspondent pas'
                    : null,
          ),
        ],
      ),
    );
  }

  // ── Étape 3 : informations professionnelles ─────────────────────────────

  Widget _etapeInformationsProfessionnelles() {
    return Form(
      key: _cleFormulairePro,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titreEtape(
            'Informations professionnelles',
            'Remplissez les informations essentielles.',
          ),
          const SizedBox(height: 28),
          AppChampTexte(
            libelle: "Nom de l'entreprise",
            controleur: _nomEntrepriseCtrl,
            indication: "Nom de l'entreprise",
            validateur: (valeur) => (valeur == null || valeur.trim().length < 2)
                ? "Indiquez le nom de l'entreprise"
                : null,
          ),
          AppChampTexte(
            libelle: 'Poste',
            obligatoire: false,
            controleur: _posteCtrl,
            indication: 'Ex. Gérant, Directeur commercial…',
          ),
          AppChampTexte(
            libelle: 'Ville',
            controleur: _villeEntrepriseCtrl,
            indication: "Ville de l'entreprise",
            validateur: (valeur) => (valeur == null || valeur.trim().length < 2)
                ? "Indiquez la ville de l'entreprise"
                : null,
          ),
          _champTelephone(
            label: 'Numéro de téléphone',
            surChangement: (numero) => _telephoneEntreprise = numero,
            // Une entreprise peut donner un numéro fixe : le champ est
            // facultatif et le contrôle de plage y est plus large.
            obligatoire: false,
          ),
          const SizedBox(height: 20),
          AppChampTexte(
            libelle: 'Adresse e-mail',
            obligatoire: false,
            controleur: _emailEntrepriseCtrl,
            indication: 'exemple@entreprise.com',
            typeClavier: TextInputType.emailAddress,
            icone: Icons.mail_outline_rounded,
            validateur: _validerEmailFacultatif,
          ),
          const SizedBox(height: 8),
          Text(
            'Le RCCM et le NINEA ne sont pas demandés maintenant : SIGNS vous '
            'les réclamera uniquement lorsqu’un document en aura besoin.',
            style: AppTypo.jakarta(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: AppColor.kGrayscale40,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// L'e-mail est obligatoire : c'est le seul canal de récupération d'un mot
  /// de passe oublié. Sans lui, un compte devient irrécupérable.
  String? _validerEmail(String? valeur) {
    if (valeur == null || valeur.trim().isEmpty) {
      return 'L’adresse e-mail est obligatoire';
    }
    return IdentifiantValidator.email(valeur, obligatoire: true).erreurFormulaire;
  }

  /// L'e-mail d'entreprise, lui, reste facultatif.
  String? _validerEmailFacultatif(String? valeur) {
    if (valeur == null || valeur.trim().isEmpty) return null;
    return IdentifiantValidator.email(valeur).erreurFormulaire;
  }

  // ── Mentions sous les champs ────────────────────────────────────────────

  /// ⚠️ La maquette annonçait « Vérification par SMS/OTP ». L'OTP n'étant pas
  /// branché, afficher cette promesse induirait l'utilisateur en erreur : on
  /// dit donc simplement à quoi sert le numéro. Le jour où l'OTP est activé,
  /// c'est ici qu'il faut remettre la mention.
  Widget _mentionNumero() {
    return Padding(
      padding: const EdgeInsets.only(top: AppEspace.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, size: 14, color: AppColor.kGrayscale40),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Ce numéro vous servira à retrouver votre compte et vos documents.',
              style: AppTypo.jakarta(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: AppColor.kGrayscale40,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mentionEmailRecommande() {
    return Padding(
      padding: const EdgeInsets.only(top: AppEspace.s),
      child: Text(
        'Votre e-mail sert à recevoir vos documents et à récupérer votre mot '
        'de passe en cas d’oubli.',
        style: AppTypo.jakarta(
          fontSize: 12.5,
          fontWeight: FontWeight.w400,
          color: AppColor.kGrayscale40,
          height: 1.45,
        ),
      ),
    );
  }

  // ── Briques de formulaire ───────────────────────────────────────────────

  Widget _champTelephone({
    required String label,
    required ValueChanged<String?> surChangement,
    bool obligatoire = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypo.jakarta(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColor.kGrayscaleDark100,
          ),
        ),
        const SizedBox(height: 8),
        IntlPhoneField(
          // Seuls les pays dont SIGNS connaît les règles sont proposés :
          // ailleurs, le numéro saisi aurait été refusé juste après.
          countries: paysTelephoneAutorises(),
          initialCountryCode: paysTelephoneInitial(),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppTypo.jakarta(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColor.kGrayscaleDark100,
          ),
          dropdownTextStyle: AppTypo.jakarta(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColor.kGrayscaleDark100,
          ),
          decoration: AppChampTexte.decoration(
            indication: '77 123 45 67',
            icone: Icons.phone_outlined,
          ),
          onChanged: (phone) => surChangement(phone.completeNumber),
          // `disableLengthCheck` : le contrôle de longueur est fait par notre
          // moteur, qui connaît la règle sénégalaise exacte (9 chiffres).
          disableLengthCheck: true,
          validator: (phone) {
            if (phone == null || phone.number.trim().isEmpty) {
              return obligatoire ? 'Le numéro de téléphone est obligatoire' : null;
            }
            final resultat = IdentifiantValidator.telephone(
              phone.completeNumber,
              autoriserFixe: !obligatoire,
            );
            return resultat.erreurFormulaire;
          },
        ),
      ],
    );
  }

}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toastification/toastification.dart';

import 'package:sign_application/core/config/user_role.dart';
import 'package:sign_application/core/routes/app_router.dart';
import 'package:sign_application/core/theme/app_color.dart';
import 'package:sign_application/core/theme/app_dimensions.dart';
import 'package:sign_application/core/theme/app_typo.dart';
import 'package:sign_application/core/widgets/app_bouton.dart';
import 'package:sign_application/core/widgets/toastNotif.dart';
import 'package:sign_application/injection_container.dart';

import '../../data/datasources/auth_remote_datasource.dart';

/// verification_email_page.dart — Confirmation de l'adresse e-mail.
///
/// Étape obligatoire entre l'inscription et l'accès à l'application : le
/// compte existe mais reste fermé tant que le code reçu par e-mail n'a pas
/// été saisi. C'est cette confirmation qui ouvre la session — le backend
/// n'émet aucun jeton avant.
///
/// Même mécanisme que « mot de passe oublié » : un code à usage unique,
/// valable une heure, renvoyable.
class VerificationEmailPage extends StatefulWidget {
  /// Adresse à confirmer, transmise par l'inscription ou par la connexion.
  final String email;

  const VerificationEmailPage({super.key, required this.email});

  @override
  State<VerificationEmailPage> createState() => _VerificationEmailPageState();
}

class _VerificationEmailPageState extends State<VerificationEmailPage> {
  final _codeCtrl = TextEditingController();
  final _cleFormulaire = GlobalKey<FormState>();

  bool _verification = false;
  bool _renvoi = false;
  String? _erreur;

  /// Compte à rebours avant de pouvoir redemander un code. Sans lui, un appui
  /// répété sur « Renvoyer » déclencherait autant d'e-mails.
  int _secondesAvantRenvoi = 0;
  Timer? _minuteur;

  @override
  void initState() {
    super.initState();
    _demarrerAttenteRenvoi();
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _demarrerAttenteRenvoi() {
    _minuteur?.cancel();
    setState(() => _secondesAvantRenvoi = 60);
    _minuteur = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _secondesAvantRenvoi -= 1);
      if (_secondesAvantRenvoi <= 0) t.cancel();
    });
  }

  Future<void> _verifier() async {
    if (!(_cleFormulaire.currentState?.validate() ?? false)) return;

    setState(() {
      _verification = true;
      _erreur = null;
    });

    try {
      final utilisateur = await sl<AuthRemoteDataSource>()
          .verifierEmail(widget.email, _codeCtrl.text.trim());
      if (!mounted) return;

      // La session est ouverte : on entre directement dans l'application.
      final role = UserRoleX.fromString(utilisateur.role);
      Navigator.of(context).pushNamedAndRemoveUntil(
        role.isClient ? AppRouter.clientRoute : AppRouter.professionnelRoute,
        (route) => false,
        arguments: utilisateur,
      );
      showToast(
        context,
        'Compte activé',
        'Bienvenue sur SIGNS, ${utilisateur.prenom}.',
        ToastificationType.success,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verification = false;
        _erreur = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _renvoyer() async {
    setState(() {
      _renvoi = true;
      _erreur = null;
    });
    try {
      await sl<AuthRemoteDataSource>().renvoyerCodeVerification(widget.email);
      if (!mounted) return;
      _demarrerAttenteRenvoi();
      showToast(
        context,
        'Code renvoyé',
        'Consultez votre boîte e-mail, et le dossier « courrier indésirable ».',
        ToastificationType.info,
      );
    } catch (e) {
      if (!mounted) return;
      showToast(context, 'Envoi impossible',
          e.toString().replaceAll('Exception: ', ''), ToastificationType.error);
    } finally {
      if (mounted) setState(() => _renvoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kSurface,
      appBar: AppBar(
        backgroundColor: AppColor.kSurface,
        elevation: 0,
        foregroundColor: AppColor.kTexte,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Retour',
          // Le compte existe déjà : sortir d'ici ramène à la connexion, pas à
          // l'inscription — l'utilisateur n'a pas à ressaisir son profil.
          onPressed: () => Navigator.of(context)
              .pushNamedAndRemoveUntil(AppRouter.loginRoute, (route) => false),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppEspace.xl),
                child: Form(
                  key: _cleFormulaire,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppEspace.l),
                      _pastille(),
                      const SizedBox(height: AppEspace.xl),
                      Text(
                        'Vérifiez votre adresse e-mail',
                        style: AppTypo.jakarta(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColor.kTexte,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: AppEspace.m),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                                text: 'Nous avons envoyé un code à 6 chiffres à '),
                            TextSpan(
                              text: widget.email,
                              style: AppTypo.jakarta(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColor.kTexte,
                              ),
                            ),
                            const TextSpan(
                                text: '. Saisissez-le pour activer votre compte.'),
                          ],
                        ),
                        style: AppTypo.jakarta(
                          fontSize: 14.5,
                          color: AppColor.kTexteMoyen,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: AppEspace.xxl),
                      _champCode(),
                      if (_erreur != null) _bandeauErreur(),
                      const SizedBox(height: AppEspace.l),
                      _lienRenvoi(),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppEspace.xl, AppEspace.s, AppEspace.xl, AppEspace.xxl),
              child: AppBouton(
                libelle: 'Activer mon compte',
                enChargement: _verification,
                onPressed: _verifier,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pastille() {
    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        color: AppColor.kChamp,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.mark_email_unread_outlined,
          size: 30, color: AppColor.kTexte),
    );
  }

  Widget _champCode() {
    OutlineInputBorder bordure(Color couleur, double epaisseur) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRayon.champ),
          borderSide: BorderSide(color: couleur, width: epaisseur),
        );

    return TextFormField(
      controller: _codeCtrl,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      textAlign: TextAlign.center,
      autofocus: true,
      style: AppTypo.jakarta(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColor.kTexte,
        letterSpacing: 12,
      ),
      decoration: InputDecoration(
        hintText: '000000',
        hintStyle: AppTypo.jakarta(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: AppColor.kTexteFaible,
          letterSpacing: 12,
        ),
        filled: true,
        fillColor: AppColor.kChamp,
        contentPadding: const EdgeInsets.symmetric(vertical: AppEspace.l),
        border: bordure(AppColor.kBordure, 1.2),
        enabledBorder: bordure(AppColor.kBordure, 1.2),
        focusedBorder: bordure(AppColor.kPrimary, 1.5),
        errorBorder: bordure(AppColor.kDanger, 1.4),
        focusedErrorBorder: bordure(AppColor.kDanger, 1.4),
      ),
      validator: (valeur) {
        final saisie = valeur?.trim() ?? '';
        if (saisie.isEmpty) return 'Saisissez le code reçu par e-mail';
        if (saisie.length < 6) return 'Le code comporte 6 chiffres';
        return null;
      },
      onFieldSubmitted: (_) => _verifier(),
    );
  }

  Widget _bandeauErreur() {
    return Padding(
      padding: const EdgeInsets.only(top: AppEspace.m),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppEspace.l, vertical: AppEspace.m),
        decoration: BoxDecoration(
          color: AppColor.fondEtat(AppColor.kDanger),
          borderRadius: BorderRadius.circular(AppRayon.champ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, size: 18, color: AppColor.kDanger),
            const SizedBox(width: AppEspace.m),
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
      ),
    );
  }

  Widget _lienRenvoi() {
    final attente = _secondesAvantRenvoi > 0;
    return Center(
      child: TextButton(
        onPressed: (attente || _renvoi) ? null : _renvoyer,
        child: Text(
          _renvoi
              ? 'Envoi en cours…'
              : attente
                  ? 'Renvoyer un code dans ${_secondesAvantRenvoi}s'
                  : 'Je n’ai rien reçu — renvoyer un code',
          style: AppTypo.jakarta(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: attente ? AppColor.kTexteFaible : AppColor.kPrimary,
          ),
        ),
      ),
    );
  }
}

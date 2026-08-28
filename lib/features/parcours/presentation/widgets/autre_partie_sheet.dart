import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toastification/toastification.dart';

import 'package:sign_application/core/theme/app_color.dart';
import 'package:sign_application/core/widgets/toastNotif.dart';
import 'package:sign_application/features/client/domain/entities/client.dart';
import 'package:sign_application/injection_container.dart';

import '../../data/datasources/parcours_remote_datasource.dart';
import '../../data/models/exigences_document.dart';
import 'package:sign_application/core/theme/app_typo.dart';

/// autre_partie_sheet.dart — Rechercher ou inviter la deuxième partie (§ 8).
///
/// Trois voies, exactement comme le prévoit le cahier des charges :
///
///   1. la personne a déjà un compte SIGNS → ses informations sont
///      préremplies, plus rien à ressaisir ;
///   2. elle n'en a pas → on l'invite à en créer un ;
///   3. sinon, l'utilisateur saisit ses informations à la main (voie déjà
///      offerte par l'écran de création).
///
/// ⚠️ Le préremplissage complet n'est renvoyé par le backend que lorsque la
/// recherche porte sur un identifiant fort — numéro de téléphone ou e-mail
/// exact. Une recherche par nom confirme l'existence du compte mais ne
/// divulgue aucun identifiant administratif : on ne veut pas qu'un tiers
/// puisse moissonner des numéros de CNI en tapant des noms courants.
class AutrePartieSheet extends StatefulWidget {
  const AutrePartieSheet({super.key});

  /// Ouvre la feuille et renvoie la personne retenue, ou null.
  static Future<Client?> afficher(BuildContext context) {
    return showModalBottomSheet<Client>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AutrePartieSheet(),
    );
  }

  @override
  State<AutrePartieSheet> createState() => _AutrePartieSheetState();
}

class _AutrePartieSheetState extends State<AutrePartieSheet> {
  final _rechercheCtrl = TextEditingController();

  ResultatRechercheAutrePartie? _resultat;
  bool _recherche = false;
  String? _erreur;

  @override
  void dispose() {
    _rechercheCtrl.dispose();
    super.dispose();
  }

  Future<void> _lancerRecherche() async {
    final terme = _rechercheCtrl.text.trim();
    if (terme.length < 3) {
      setState(() => _erreur = 'Saisissez au moins 3 caractères.');
      return;
    }

    setState(() {
      _recherche = true;
      _erreur = null;
      _resultat = null;
    });

    try {
      final resultat =
          await sl<ParcoursRemoteDataSource>().rechercherAutrePartie(terme);
      if (!mounted) return;
      setState(() {
        _resultat = resultat;
        _recherche = false;
      });
    } on ParcoursException catch (e) {
      if (!mounted) return;
      setState(() {
        _recherche = false;
        _erreur = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recherche = false;
        _erreur = 'Recherche impossible. Vérifiez votre connexion.';
      });
    }
  }

  void _retenir(PartieTrouvee partie) {
    final donnees = partie.donnees;
    Navigator.of(context).pop(
      Client(
        id: partie.id,
        nom: partie.nom,
        prenom: partie.prenom,
        email: donnees['email']?.toString(),
        telephone: donnees['telephone']?.toString(),
        adresse: donnees['adresse']?.toString(),
        carteIdentiteNationalNum:
            donnees['carte_identite_national_num']?.toString(),
        photoProfil: partie.photoProfil,
      ),
    );
  }

  /// Option 2 : inviter la personne à créer son compte.
  Future<void> _inviter() async {
    final terme = _rechercheCtrl.text.trim();
    final estEmail = terme.contains('@');

    try {
      final texte = await sl<ParcoursRemoteDataSource>().inviterAutrePartie(
        email: estEmail ? terme : null,
        telephone: estEmail ? null : terme,
      );
      if (!mounted) return;

      // Le texte est copié dans le presse-papiers : l'utilisateur le colle
      // dans WhatsApp ou un SMS, canal réellement utilisé ici.
      if (texte.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: texte));
      }
      if (!mounted) return;
      showToast(
        context,
        'Invitation prête',
        texte.isEmpty
            ? 'Invitation envoyée.'
            : 'Le message a été copié : collez-le dans WhatsApp ou un SMS.',
        ToastificationType.success,
      );
    } on ParcoursException catch (e) {
      if (!mounted) return;
      showToast(context, 'Invitation impossible', e.message, ToastificationType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hauteurClavier = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: hauteurClavier),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColor.kLine,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rechercher la personne',
                      style: AppTypo.jakarta(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: AppColor.kGrayscaleDark100,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Si elle possède déjà un compte SIGNS, ses informations '
                      'seront reprises automatiquement. Recherchez avec son '
                      'numéro de téléphone ou son e-mail pour un préremplissage '
                      'complet.',
                      style: AppTypo.jakarta(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        color: AppColor.kGrayscale40,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _champRecherche(),
                    if (_erreur != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _erreur!,
                        style: AppTypo.jakarta(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColor.kDanger,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (_recherche)
                      const Center(child: CircularProgressIndicator())
                    else if (_resultat != null)
                      _affichageResultat(_resultat!),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _champRecherche() {
    OutlineInputBorder bordure(Color couleur, double epaisseur) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: couleur, width: epaisseur),
        );

    return TextField(
      controller: _rechercheCtrl,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _lancerRecherche(),
      style: AppTypo.jakarta(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColor.kGrayscaleDark100,
      ),
      decoration: InputDecoration(
        hintText: 'Téléphone, e-mail, ou nom et prénom',
        hintStyle: AppTypo.jakarta(
          fontSize: 14.5,
          color: AppColor.kGrayscale40,
        ),
        prefixIcon: Icon(Icons.search_rounded, color: AppColor.kGrayscale40, size: 20),
        suffixIcon: IconButton(
          onPressed: _lancerRecherche,
          icon: Icon(Icons.arrow_forward_rounded, color: AppColor.kPrimary, size: 20),
          tooltip: 'Rechercher',
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: bordure(AppColor.kLine, 1.2),
        enabledBorder: bordure(AppColor.kLine, 1.2),
        focusedBorder: bordure(AppColor.kPrimary, 1.5),
      ),
    );
  }

  Widget _affichageResultat(ResultatRechercheAutrePartie resultat) {
    if (!resultat.trouve) {
      return _blocInvitation(resultat.message);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          resultat.message,
          style: AppTypo.jakarta(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: resultat.identificationForte
                ? AppColor.kSucces
                : AppColor.kAlerte,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        ...resultat.resultats.map(_cartePersonne),
      ],
    );
  }

  Widget _cartePersonne(PartieTrouvee partie) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.kLine, width: 1.2),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColor.kPrimary,
            child: Text(
              partie.prenom.isNotEmpty ? partie.prenom[0].toUpperCase() : '?',
              style: AppTypo.jakarta(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partie.nomComplet,
                  style: AppTypo.jakarta(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColor.kGrayscaleDark100,
                  ),
                ),
                if (partie.ville != null && partie.ville!.isNotEmpty)
                  Text(
                    partie.ville!,
                    style: AppTypo.jakarta(
                      fontSize: 12.5,
                      color: AppColor.kGrayscale40,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _retenir(partie),
            child: Text(
              'Choisir',
              style: AppTypo.jakarta(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColor.kPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blocInvitation(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.kBackground2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: AppTypo.jakarta(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: AppColor.kGrayscale40,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _inviter,
              icon: const Icon(Icons.person_add_alt_outlined, size: 18),
              label: Text(
                'Inviter cette personne',
                style: AppTypo.jakarta(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColor.kGrayscaleDark100,
                side: BorderSide(color: AppColor.kLine, width: 1.3),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

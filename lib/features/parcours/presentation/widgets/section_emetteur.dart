import 'package:flutter/material.dart';
import 'package:sign_application/core/utils/normalisation_nom.dart';

import 'package:sign_application/core/theme/app_color.dart';
import 'package:sign_application/core/theme/app_dimensions.dart';
import 'package:sign_application/core/theme/app_typo.dart';
import 'package:sign_application/core/validation/identifiant_validator.dart';
import 'package:sign_application/core/widgets/app_champ_texte.dart';
import 'package:sign_application/injection_container.dart';

import '../../data/datasources/parcours_remote_datasource.dart';
import '../../data/dernieres_informations_saisies.dart';

/// section_emetteur.dart — « Vos informations » dans un formulaire de document.
///
/// Les informations de l'émetteur (nom, adresse, CNI, RCCM…) étaient
/// auparavant reprises silencieusement du profil au moment de fabriquer le
/// PDF : l'utilisateur ne les voyait pas et ne pouvait pas les corriger pour
/// un document précis.
///
/// Elles deviennent des champs du formulaire comme les autres — préremplis
/// avec ce que SIGNS connaît déjà, et modifiables. Les valeurs retenues sont
/// figées avec le document côté serveur : une régénération à la signature
/// reproduit exactement le même document.
///
/// Utilisation :
/// ```dart
/// final _emetteur = ControleurEmetteur();          // dans le State
/// @override void initState() { _emetteur.charger(); }
/// @override void dispose()   { _emetteur.dispose(); }
/// // dans le formulaire :
/// SectionEmetteur(controleur: _emetteur, professionnel: true),
/// // à l'envoi :
/// 'emetteur': _emetteur.valeursPourEnvoi(),
/// ```
class ControleurEmetteur extends ChangeNotifier {
  /// Champs communs à tous les profils.
  static const champsCommuns = [
    'nom',
    'prenom',
    'telephone',
    'email',
    'adresse',
    'ville',
    'carte_identite_national_num',
  ];

  /// Champs supplémentaires d'un professionnel.
  static const champsProfessionnels = ['nomEntreprise', 'rc', 'ninea'];

  final Map<String, TextEditingController> _controleurs = {
    for (final cle in [...champsCommuns, ...champsProfessionnels])
      cle: TextEditingController(),
  };

  /// Type de pièce déjà enregistré, transmis tel quel : la section ne le fait
  /// pas changer, c'est la feuille des informations manquantes qui s'en charge.
  String? _typePieceIdentite;

  bool _chargement = true;
  bool get chargement => _chargement;

  TextEditingController controleurDe(String cle) => _controleurs[cle]!;

  /// Récupère le profil pour préremplir la section. Échec silencieux : les
  /// champs restent vides et l'utilisateur les saisit — mieux que de bloquer
  /// la création d'un document sur un souci réseau.
  Future<void> charger() async {
    try {
      final profil = await sl<ParcoursRemoteDataSource>().prereemplissage();
      for (final entree in _controleurs.entries) {
        final valeur = profil[entree.key];
        if (valeur != null && valeur.toString().trim().isNotEmpty) {
          entree.value.text = valeur.toString();
        }
      }
      _typePieceIdentite = profil['type_document_identite']?.toString();
    } catch (_) {
      // Rien à faire : la section s'affiche vide.
    } finally {
      // Ce que l'utilisateur vient de saisir pour ce document recouvre le
      // profil : la feuille des informations manquantes s'ouvre avant ce
      // formulaire, et ce qu'elle a recueilli n'est pas enregistré. Sans ce
      // report, il devrait le retaper ici.
      final saisie = sl<DernieresInformationsSaisies>().valeurs;
      if (saisie != null) {
        for (final entree in _controleurs.entries) {
          final valeur = saisie[entree.key];
          if (valeur != null && valeur.toString().trim().isNotEmpty) {
            entree.value.text = valeur.toString();
          }
        }
        final type = saisie['type_document_identite']?.toString();
        if (type != null && type.isNotEmpty) _typePieceIdentite = type;
      }

      _chargement = false;
      notifyListeners();
    }
  }

  /// Bloc à envoyer au backend, appelé au moment de la soumission.
  ///
  /// Les champs vides sont omis : le serveur retombe alors sur le profil.
  ///
  /// La saisie est au passage retenue par [DernieresInformationsSaisies] :
  /// après la génération, SIGNS proposera de l'enregistrer dans le profil, et
  /// l'écran du formulaire sera déjà refermé à ce moment-là.
  Map<String, dynamic> valeursPourEnvoi() {
    final depot = sl<DernieresInformationsSaisies>();

    // On part de ce qui a été recueilli en amont pour ce document — la
    // feuille des informations manquantes couvre des champs que cette
    // section n'affiche pas (NIN, type de pièce…). Rien de tout cela n'est
    // enregistré sur le compte : ces valeurs accompagnent le document, et le
    // serveur les fige avec lui.
    final donnees = <String, dynamic>{...?depot.valeurs};

    for (final entree in _controleurs.entries) {
      final valeur = entree.value.text.trim();
      if (valeur.isNotEmpty) donnees[entree.key] = valeur;
    }
    if (_typePieceIdentite != null && _typePieceIdentite!.isNotEmpty) {
      donnees['type_document_identite'] = _typePieceIdentite;
    }

    // Retenu pour la proposition d'enregistrement affichée après la
    // génération : c'est là, et seulement là, que l'utilisateur autorise.
    depot.memoriser(donnees);
    return donnees;
  }

  /// Validateur du numéro de pièce, accordé au type enregistré.
  String? validerPiece(String? valeur) {
    final saisie = valeur?.trim() ?? '';
    if (saisie.isEmpty) return null;
    final type = _typePieceIdentite == 'passeport' ? 'passeport' : 'cni';
    return IdentifiantValidator.parType(type, saisie).erreurFormulaire;
  }

  @override
  void dispose() {
    for (final c in _controleurs.values) {
      c.dispose();
    }
    super.dispose();
  }
}

class SectionEmetteur extends StatelessWidget {
  final ControleurEmetteur controleur;

  /// Affiche les champs d'entreprise (raison sociale, RCCM, NINEA).
  final bool professionnel;

  /// Titre de la section, adaptable selon le document (« Vos informations »,
  /// « Informations du bailleur »…).
  final String titre;

  const SectionEmetteur({
    super.key,
    required this.controleur,
    this.professionnel = false,
    this.titre = 'Vos informations',
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controleur,
      builder: (context, _) {
        if (controleur.chargement) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppEspace.xl),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titre.toUpperCase(),
              style: AppTypo.jakarta(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColor.kTexteMoyen,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: AppEspace.xs),
            Text(
              'Ces informations figureront sur le document. Corrigez-les si '
              'besoin — elles ne changeront pas votre profil.',
              style: AppTypo.jakarta(
                fontSize: 12.5,
                color: AppColor.kTexteMoyen,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppEspace.l),
            AppChampTexte(
              libelle: 'Nom',
              controleur: controleur.controleurDe('nom'),
              // Ce bloc est recopié tel quel sur le document : le nom y suit la
              // même règle d'écriture que partout ailleurs.
              formateurs: const [FormateurNomFamille()],
            ),
            AppChampTexte(
              libelle: 'Prénom',
              controleur: controleur.controleurDe('prenom'),
              formateurs: const [FormateurPrenom()],
            ),
            AppChampTexte(
              libelle: 'Téléphone',
              controleur: controleur.controleurDe('telephone'),
              typeClavier: TextInputType.phone,
              validateur: (v) => (v == null || v.trim().isEmpty)
                  ? null
                  : IdentifiantValidator.telephone(v).erreurFormulaire,
            ),
            AppChampTexte(
              libelle: 'Adresse e-mail',
              controleur: controleur.controleurDe('email'),
              typeClavier: TextInputType.emailAddress,
              validateur: (v) => (v == null || v.trim().isEmpty)
                  ? null
                  : IdentifiantValidator.email(v).erreurFormulaire,
            ),
            AppChampTexte(
              libelle: 'Adresse',
              obligatoire: false,
              controleur: controleur.controleurDe('adresse'),
            ),
            AppChampTexte(
              libelle: 'Ville',
              obligatoire: false,
              controleur: controleur.controleurDe('ville'),
            ),
            AppChampTexte(
              libelle: 'Numéro de pièce d’identité',
              obligatoire: false,
              controleur: controleur.controleurDe('carte_identite_national_num'),
              validateur: controleur.validerPiece,
            ),
            if (professionnel) ...[
              AppChampTexte(
                libelle: "Nom de l'entreprise",
                obligatoire: false,
                controleur: controleur.controleurDe('nomEntreprise'),
              ),
              AppChampTexte(
                libelle: 'RCCM',
                obligatoire: false,
                majuscules: true,
                controleur: controleur.controleurDe('rc'),
                aide: 'Ex. SN.DKR.2017.A.19778',
                validateur: (v) => (v == null || v.trim().isEmpty)
                    ? null
                    : IdentifiantValidator.rccm(v).erreurFormulaire,
              ),
              AppChampTexte(
                libelle: 'NINEA',
                obligatoire: false,
                majuscules: true,
                controleur: controleur.controleurDe('ninea'),
                aide: 'Ex. 005812511 2G3',
                validateur: (v) => (v == null || v.trim().isEmpty)
                    ? null
                    : IdentifiantValidator.ninea(v).erreurFormulaire,
              ),
            ],
          ],
        );
      },
    );
  }
}

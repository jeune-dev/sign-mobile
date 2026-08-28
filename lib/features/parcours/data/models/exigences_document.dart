/// exigences_document.dart — Ce que le backend répond à « de quoi ai-je
/// besoin pour ce document ? » (§ 4 du cahier des charges).
///
/// Aucune règle métier n'est dupliquée ici : le serveur décrit les champs à
/// afficher (libellé, aide, instruction, validateur à appliquer), l'app se
/// contente de les rendre. Ajouter une exigence côté backend suffit donc à la
/// faire apparaître dans l'application, sans nouvelle version.
library;

/// Niveau d'exigence d'un champ.
enum NiveauExigence {
  /// La génération est bloquée tant que le champ est vide.
  requis,

  /// Demandé, mais l'utilisateur peut passer outre.
  recommande,
}

NiveauExigence _niveauDepuis(String? valeur) =>
    valeur == 'requis' ? NiveauExigence.requis : NiveauExigence.recommande;

/// Une option d'un champ à choix (type de pièce, RCCM vs NINEA…).
class OptionChamp {
  final String valeur;
  final String label;

  /// Type de validation à appliquer si cette option est choisie.
  final String? typeValidation;

  const OptionChamp({
    required this.valeur,
    required this.label,
    this.typeValidation,
  });

  factory OptionChamp.depuisJson(Map<String, dynamic> json) => OptionChamp(
        valeur: json['valeur']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
        typeValidation: json['typeValidation']?.toString(),
      );
}

/// Sous-champ d'un champ composite (le couple type de pièce + numéro).
class SousChamp {
  final String cle;
  final String label;
  final String saisie;
  final List<OptionChamp> options;

  /// Consigne affichée sous le champ — pour le passeport, c'est le texte
  /// imposé par le cahier des charges (§ 5).
  final String? instruction;

  /// Identifiant de l'illustration à afficher à côté de l'instruction.
  final String? illustration;

  final String? typeValidation;

  const SousChamp({
    required this.cle,
    required this.label,
    required this.saisie,
    this.options = const [],
    this.instruction,
    this.illustration,
    this.typeValidation,
  });

  factory SousChamp.depuisJson(Map<String, dynamic> json) => SousChamp(
        cle: json['cle']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
        saisie: json['saisie']?.toString() ?? 'texte',
        options: (json['options'] as List?)
                ?.map((o) => OptionChamp.depuisJson(Map<String, dynamic>.from(o as Map)))
                .toList() ??
            const [],
        instruction: json['instruction']?.toString(),
        illustration: json['illustration']?.toString(),
        typeValidation: json['typeValidation']?.toString(),
      );
}

/// Un champ manquant, tel que décrit par le backend.
class ChampManquant {
  final String cle;
  final String label;
  final String saisie;
  final NiveauExigence niveau;
  final String? aide;
  final List<OptionChamp> options;
  final List<SousChamp> sousChamps;
  final String? typeValidation;

  /// Type de pièce déjà choisi par l'utilisateur, s'il y en a un.
  final String? typePieceActuel;

  const ChampManquant({
    required this.cle,
    required this.label,
    required this.saisie,
    required this.niveau,
    this.aide,
    this.options = const [],
    this.sousChamps = const [],
    this.typeValidation,
    this.typePieceActuel,
  });

  bool get estRequis => niveau == NiveauExigence.requis;

  factory ChampManquant.depuisJson(Map<String, dynamic> json) => ChampManquant(
        cle: json['cle']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
        saisie: json['saisie']?.toString() ?? 'texte',
        niveau: _niveauDepuis(json['niveau']?.toString()),
        aide: json['aide']?.toString(),
        options: (json['options'] as List?)
                ?.map((o) => OptionChamp.depuisJson(Map<String, dynamic>.from(o as Map)))
                .toList() ??
            const [],
        sousChamps: (json['sousChamps'] as List?)
                ?.map((sc) => SousChamp.depuisJson(Map<String, dynamic>.from(sc as Map)))
                .toList() ??
            const [],
        typeValidation: json['typeValidation']?.toString(),
        typePieceActuel: json['typePieceActuel']?.toString(),
      );
}

/// Exigences portant sur la deuxième partie du document (§ 8).
class ExigencesAutrePartie {
  final bool requise;
  final List<ChampManquant> champs;

  const ExigencesAutrePartie({required this.requise, required this.champs});

  factory ExigencesAutrePartie.depuisJson(Map<String, dynamic> json) =>
      ExigencesAutrePartie(
        requise: json['requise'] == true,
        champs: (json['champs'] as List?)
                ?.map((c) => ChampManquant.depuisJson(Map<String, dynamic>.from(c as Map)))
                .toList() ??
            const [],
      );
}

/// Quota d'usage avant validation du compte par un administrateur.
///
/// Un compte non validé peut produire un nombre limité de documents dans
/// chaque famille (contrats d'un côté, factures de l'autre). Le backend
/// renvoie l'état du compteur en même temps que les exigences, ce qui évite
/// un second appel avant d'ouvrir un formulaire.
class QuotaDocument {
  /// Faux pour un compte validé : aucune limite ne s'applique.
  final bool limite;

  /// Faux quand le plafond est atteint : la création doit être refusée.
  final bool autorise;

  final int utilises;
  final int plafond;
  final int restants;

  /// Message d'explication rédigé par le backend, affichable tel quel.
  final String? message;

  const QuotaDocument({
    required this.limite,
    required this.autorise,
    required this.utilises,
    required this.plafond,
    required this.restants,
    this.message,
  });

  /// Valeur de repli quand le backend ne renvoie pas de quota (ancienne
  /// version d'API) : on ne bloque rien.
  const QuotaDocument.sansLimite()
      : limite = false,
        autorise = true,
        utilises = 0,
        plafond = 0,
        restants = 0,
        message = null;

  /// Vrai quand il ne reste qu'un ou deux documents : l'application le
  /// signale sans bloquer, pour que l'échéance ne surprenne pas.
  bool get bientotAtteint => limite && autorise && restants > 0 && restants <= 2;

  factory QuotaDocument.depuisJson(Map<String, dynamic> json) => QuotaDocument(
        limite: json['limite'] == true,
        autorise: json['autorise'] != false,
        utilises: (json['utilises'] as num?)?.toInt() ?? 0,
        plafond: (json['plafond'] as num?)?.toInt() ?? 0,
        restants: (json['restants'] as num?)?.toInt() ?? 0,
        message: json['message']?.toString(),
      );
}

/// Réponse complète de `GET /profil/exigences/:typeDocument`.
class ExigencesDocument {
  final String typeDocument;
  final String libelle;
  final String role;
  final List<ChampManquant> champsManquants;
  final List<String> champsBloquants;
  final bool pretPourGeneration;
  final ExigencesAutrePartie autrePartie;
  final QuotaDocument quota;

  const ExigencesDocument({
    required this.typeDocument,
    required this.libelle,
    required this.role,
    required this.champsManquants,
    required this.champsBloquants,
    required this.pretPourGeneration,
    required this.autrePartie,
    this.quota = const QuotaDocument.sansLimite(),
  });

  /// Rien à demander : on peut ouvrir le formulaire directement.
  bool get riensADemander => champsManquants.isEmpty;

  factory ExigencesDocument.depuisJson(Map<String, dynamic> json) =>
      ExigencesDocument(
        typeDocument: json['typeDocument']?.toString() ?? '',
        libelle: json['libelle']?.toString() ?? 'Document',
        role: json['role']?.toString() ?? '',
        champsManquants: (json['champsManquants'] as List?)
                ?.map((c) => ChampManquant.depuisJson(Map<String, dynamic>.from(c as Map)))
                .toList() ??
            const [],
        champsBloquants: (json['champsBloquants'] as List?)
                ?.map((c) => c.toString())
                .toList() ??
            const [],
        pretPourGeneration: json['pretPourGeneration'] == true,
        quota: json['quota'] is Map
            ? QuotaDocument.depuisJson(Map<String, dynamic>.from(json['quota'] as Map))
            : const QuotaDocument.sansLimite(),
        autrePartie: json['autrePartie'] is Map
            ? ExigencesAutrePartie.depuisJson(
                Map<String, dynamic>.from(json['autrePartie'] as Map))
            : const ExigencesAutrePartie(requise: false, champs: []),
      );
}

/// Un blocage ou un avertissement du contrôle avant génération (§ 9 / § 15).
class SignalementGeneration {
  final String champ;
  final String message;
  final String? raison;

  const SignalementGeneration({
    required this.champ,
    required this.message,
    this.raison,
  });

  factory SignalementGeneration.depuisJson(Map<String, dynamic> json) =>
      SignalementGeneration(
        champ: json['champ']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
        raison: json['raison']?.toString(),
      );
}

/// Réponse de `GET /profil/verification/:typeDocument`.
class VerificationGeneration {
  final bool autorise;
  final List<SignalementGeneration> blocages;
  final List<SignalementGeneration> avertissements;

  const VerificationGeneration({
    required this.autorise,
    required this.blocages,
    required this.avertissements,
  });

  factory VerificationGeneration.depuisJson(Map<String, dynamic> json) {
    List<SignalementGeneration> lire(String cle) =>
        (json[cle] as List?)
            ?.map((e) => SignalementGeneration.depuisJson(
                Map<String, dynamic>.from(e as Map)))
            .toList() ??
        const [];

    return VerificationGeneration(
      autorise: json['autorise'] == true,
      blocages: lire('blocages'),
      avertissements: lire('avertissements'),
    );
  }
}

/// Une personne trouvée par la recherche de l'autre partie (§ 8).
class PartieTrouvee {
  final String id;
  final String nom;
  final String prenom;
  final String? ville;
  final String? role;
  final String? photoProfil;

  /// Vrai quand la recherche a été faite avec un identifiant fort
  /// (téléphone ou e-mail exact) : les informations administratives sont
  /// alors disponibles pour le préremplissage.
  final bool prereemplissageDisponible;

  /// Bloc complet, uniquement présent si [prereemplissageDisponible].
  final Map<String, dynamic> donnees;

  const PartieTrouvee({
    required this.id,
    required this.nom,
    required this.prenom,
    this.ville,
    this.role,
    this.photoProfil,
    this.prereemplissageDisponible = false,
    this.donnees = const {},
  });

  String get nomComplet => '$prenom $nom'.trim();

  factory PartieTrouvee.depuisJson(Map<String, dynamic> json) => PartieTrouvee(
        id: json['id']?.toString() ?? '',
        nom: json['nom']?.toString() ?? '',
        prenom: json['prenom']?.toString() ?? '',
        ville: json['ville']?.toString(),
        role: json['role']?.toString(),
        photoProfil: json['photoProfil']?.toString(),
        prereemplissageDisponible: json['prereemplissageDisponible'] == true,
        donnees: json,
      );
}

/// Réponse de `GET /autre-partie/recherche`.
class ResultatRechercheAutrePartie {
  final bool trouve;
  final bool identificationForte;
  final List<PartieTrouvee> resultats;
  final String message;

  const ResultatRechercheAutrePartie({
    required this.trouve,
    required this.identificationForte,
    required this.resultats,
    required this.message,
  });

  factory ResultatRechercheAutrePartie.depuisJson(Map<String, dynamic> json) =>
      ResultatRechercheAutrePartie(
        trouve: json['trouve'] == true,
        identificationForte: json['identificationForte'] == true,
        resultats: (json['resultats'] as List?)
                ?.map((r) => PartieTrouvee.depuisJson(Map<String, dynamic>.from(r as Map)))
                .toList() ??
            const [],
        message: json['message']?.toString() ?? '',
      );
}

/// Un justificatif déposé (§ 12).
class Justificatif {
  final String id;
  final String type;
  final String? nomFichier;
  final String statut;
  final String? motifRejet;
  final bool chiffre;
  final DateTime? deposeLe;

  const Justificatif({
    required this.id,
    required this.type,
    required this.statut,
    this.nomFichier,
    this.motifRejet,
    this.chiffre = false,
    this.deposeLe,
  });

  bool get estValide => statut == 'valide';
  bool get estRejete => statut == 'rejete';

  String get libelleType {
    switch (type) {
      case 'cni_recto':
        return 'CNI — recto';
      case 'cni_verso':
        return 'CNI — verso';
      case 'passeport_recto':
        return 'Passeport — page photo';
      case 'passeport_verso':
        return 'Passeport — page opposée';
      case 'rccm':
        return 'Document RCCM';
      case 'ninea':
        return 'Document NINEA';
      default:
        return type;
    }
  }

  String get libelleStatut {
    switch (statut) {
      case 'valide':
        return 'Vérifié';
      case 'rejete':
        return 'Refusé';
      default:
        return 'En cours de vérification';
    }
  }

  factory Justificatif.depuisJson(Map<String, dynamic> json) => Justificatif(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        statut: json['statut']?.toString() ?? 'en_attente',
        nomFichier: json['nom_fichier']?.toString(),
        motifRejet: json['motif_rejet']?.toString(),
        chiffre: json['chiffre'] == true,
        deposeLe: DateTime.tryParse(json['depose_le']?.toString() ?? ''),
      );
}

/// Mentions d'information affichées avant tout dépôt de justificatif (§ 13).
class MentionsJustificatifs {
  final String finalite;
  final String stockage;
  final String acces;
  final String conservation;
  final String suppression;

  const MentionsJustificatifs({
    required this.finalite,
    required this.stockage,
    required this.acces,
    required this.conservation,
    required this.suppression,
  });

  List<String> get toutes => [finalite, stockage, acces, conservation, suppression];

  factory MentionsJustificatifs.depuisJson(Map<String, dynamic> json) =>
      MentionsJustificatifs(
        finalite: json['finalite']?.toString() ?? '',
        stockage: json['stockage']?.toString() ?? '',
        acces: json['acces']?.toString() ?? '',
        conservation: json['conservation']?.toString() ?? '',
        suppression: json['suppression']?.toString() ?? '',
      );
}

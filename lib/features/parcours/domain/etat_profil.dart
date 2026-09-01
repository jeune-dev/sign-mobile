import '../data/models/exigences_document.dart';

/// etat_profil.dart — Ce qu'il reste à faire pour que le compte soit complet.
///
/// Une seule lecture, partagée par tous les écrans qui en parlent : la
/// pastille rouge sur le réglage, le compteur en tête du formulaire d'identité,
/// celui de la page des justificatifs, et les raccourcis du profil. Chacun
/// calculait le sien, et ils finissaient par ne plus dire la même chose.
///
/// Les règles reproduisent exactement celles appliquées par le backend au
/// moment de finaliser le compte (`ProfilService.completerProfil`) : ce qui est
/// annoncé ici comme « restant » est ce qui sera effectivement réclamé.

/// Une information ou une pièce encore attendue.
class ElementManquant {
  /// Clé technique — celle du champ profil ou du type de justificatif.
  final String cle;

  /// Intitulé montré à l'utilisateur.
  final String libelle;

  const ElementManquant(this.cle, this.libelle);
}

class EtatProfil {
  /// Informations d'identité encore vides.
  final List<ElementManquant> champsManquants;

  /// Pièces encore attendues — jamais déposées, ou refusées et à redéposer.
  final List<ElementManquant> documentsManquants;

  /// L'utilisateur a déjà validé le parcours « compte complet » (§ 11).
  final bool profilComplet;

  /// Identité contrôlée par un administrateur (§ 12) — c'est elle, et elle
  /// seule, qui lève la limite de documents.
  final bool compteVerifie;

  const EtatProfil({
    this.champsManquants = const [],
    this.documentsManquants = const [],
    this.profilComplet = false,
    this.compteVerifie = false,
  });

  int get nombreChampsManquants => champsManquants.length;

  int get nombreDocumentsManquants => documentsManquants.length;

  int get totalRestant => nombreChampsManquants + nombreDocumentsManquants;

  /// Vrai tant qu'il reste quelque chose à saisir ou à déposer. C'est ce
  /// drapeau qui allume la pastille sur le bouton de réglage.
  bool get aQuelqueChoseACompleter => totalRestant > 0;

  /// Champs communs à tous les profils, dans l'ordre où le formulaire les
  /// présente — le décompte suit ce que l'utilisateur a sous les yeux.
  static const List<ElementManquant> _champsCommuns = [
    ElementManquant('nom', 'Nom'),
    ElementManquant('prenom', 'Prénom'),
    ElementManquant('ville', 'Ville'),
    ElementManquant('telephone', 'Numéro de téléphone'),
    ElementManquant('email', 'Adresse e-mail'),
    ElementManquant('type_document_identite', 'Type de pièce d’identité'),
    ElementManquant('carte_identite_national_num', 'Numéro de pièce d’identité'),
  ];

  /// Faces attendues selon la pièce choisie — aligné sur FACES_REQUISES côté
  /// backend. Tant qu'aucune pièce n'est choisie, on annonce la CNI : c'est le
  /// cas courant, et le décompte se corrige dès que l'utilisateur tranche.
  static List<ElementManquant> facesAttendues(String? typePiece) {
    if (typePiece == 'passeport') {
      return const [
        ElementManquant('passeport_recto', 'Passeport — page photo'),
        ElementManquant('passeport_verso', 'Passeport — page opposée'),
      ];
    }
    return const [
      ElementManquant('cni_recto', 'CNI — recto'),
      ElementManquant('cni_verso', 'CNI — verso'),
    ];
  }

  static bool _vide(dynamic valeur) =>
      valeur == null || valeur.toString().trim().isEmpty;

  /// Construit l'état à partir du bloc de préremplissage (§ 16) et de la liste
  /// des justificatifs déposés.
  factory EtatProfil.analyser({
    required Map<String, dynamic> profil,
    required List<Justificatif> justificatifs,
  }) {
    final champs = <ElementManquant>[];
    for (final champ in _champsCommuns) {
      if (_vide(profil[champ.cle])) champs.add(champ);
    }

    // Un compte professionnel doit en plus porter son entreprise et au moins
    // l'un des deux identifiants d'activité (§ 7).
    final role = profil['role']?.toString();
    // Sans rôle transmis, on retombe sur le seul indice disponible : la
    // présence d'informations d'entreprise.
    final estProfessionnel = role != null && role.isNotEmpty
        ? role != 'Particulier'
        : !_vide(profil['nomEntreprise']) ||
            !_vide(profil['rc']) ||
            !_vide(profil['ninea']);

    if (estProfessionnel) {
      if (_vide(profil['nomEntreprise'])) {
        champs.add(const ElementManquant('nomEntreprise', 'Nom de l’entreprise'));
      }
      if (_vide(profil['rc']) && _vide(profil['ninea'])) {
        champs.add(const ElementManquant('rc_ou_ninea', 'RCCM ou NINEA'));
      }
    }

    // Une pièce refusée compte comme manquante : elle doit être redéposée,
    // l'afficher comme acquise laisserait l'utilisateur attendre une
    // validation qui ne viendra pas.
    final deposesUtilisables = <String>{
      for (final j in justificatifs)
        if (!j.estRejete) j.type,
    };

    final documents = facesAttendues(profil['type_document_identite']?.toString())
        .where((face) => !deposesUtilisables.contains(face.cle))
        .toList();

    return EtatProfil(
      champsManquants: champs,
      documentsManquants: documents,
      profilComplet: profil['profil_complet'] == true,
      compteVerifie: profil['compte_verifie'] == true,
    );
  }
}

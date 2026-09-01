/// identifiant_validator.dart — Contrôle des identifiants côté application.
///
/// Miroir allégé du moteur backend (`validationIdentifiants.service.js`).
/// Il sert au retour immédiat pendant la saisie : l'utilisateur voit tout de
/// suite qu'il manque un chiffre à sa CNI, sans attendre un aller-retour
/// réseau.
///
/// ⚠️ Le backend reste l'autorité. Ce fichier n'assouplit jamais une règle
/// serveur : en cas de doute il classe en « format valide » plutôt que de
/// rejeter, pour ne jamais bloquer une saisie que le serveur accepterait.
library;

/// Les trois niveaux du cahier des charges (§ 15).
enum NiveauValidation {
  /// 🟢 Le numéro respecte les règles connues.
  valide,

  /// 🟠 La structure est correcte mais SIGNS ne peut pas confirmer
  /// l'existence ou la propriété du numéro.
  formatValide,

  /// 🔴 La structure ou les règles connues ne sont pas respectées.
  invalide,
}

class ResultatValidation {
  final NiveauValidation niveau;

  /// Valeur normalisée, prête à être envoyée au backend (null si invalide).
  final String? valeur;

  /// Message affichable tel quel sous le champ.
  final String message;

  const ResultatValidation._(this.niveau, this.valeur, this.message);

  const ResultatValidation.valide(String valeurNormalisee)
      : this._(NiveauValidation.valide, valeurNormalisee, 'Identifiant valide');

  const ResultatValidation.formatValide(String valeurNormalisee, String raison)
      : this._(NiveauValidation.formatValide, valeurNormalisee, raison);

  const ResultatValidation.invalide(String raison)
      : this._(NiveauValidation.invalide, null, raison);

  bool get estBloquant => niveau == NiveauValidation.invalide;
  bool get estAcceptable => niveau != NiveauValidation.invalide;

  /// Message à passer au `validator:` d'un TextFormField — null si acceptable.
  String? get erreurFormulaire => estBloquant ? message : null;
}

/// Référentiel local, aligné sur les valeurs par défaut du backend.
///
/// Le backend expose ses propres valeurs via `GET /profil/referentiels` :
/// `IdentifiantValidator.appliquerReferentiel()` permet de les injecter au
/// démarrage pour que l'app suive toute évolution sans nouvelle version.
/// Règles téléphoniques d'un pays.
///
/// Le sélecteur d'indicatif ne propose que les pays présents ici : offrir les
/// deux cents pays du monde alors qu'un seul jeu de règles était appliqué
/// derrière revenait à refuser des numéros parfaitement valides, et à en
/// accepter d'impossibles.
class PaysTelephone {
  /// Code ISO à deux lettres — c'est lui qui relie l'entrée au drapeau et au
  /// nom affichés par le sélecteur.
  final String iso;
  final String nom;
  final String indicatif;

  /// Longueur du numéro national, hors indicatif.
  final int longueur;

  /// Plages attribuées. Leur longueur varie d'un pays à l'autre (un chiffre au
  /// Mali, deux au Sénégal) : la comparaison se fait par « commence par ».
  final List<String> prefixesMobiles;

  /// Acceptés uniquement là où un numéro fixe a du sens (téléphone
  /// d'entreprise), jamais pour le numéro de compte personnel.
  final List<String> prefixesFixes;

  const PaysTelephone({
    required this.iso,
    required this.nom,
    required this.indicatif,
    required this.longueur,
    required this.prefixesMobiles,
    required this.prefixesFixes,
  });

  /// Chiffres de l'indicatif, sans le '+'.
  String get indicatifChiffres => indicatif.replaceAll('+', '');

  factory PaysTelephone.depuisJson(Map<String, dynamic> json) => PaysTelephone(
        iso: json['iso']?.toString() ?? '',
        nom: json['nom']?.toString() ?? '',
        indicatif: json['indicatif']?.toString() ?? '',
        longueur: json['longueur'] is int ? json['longueur'] as int : 0,
        prefixesMobiles: (json['prefixesMobiles'] as List?)
                ?.map((p) => p.toString())
                .toList() ??
            const [],
        prefixesFixes: (json['prefixesFixes'] as List?)
                ?.map((p) => p.toString())
                .toList() ??
            const [],
      );
}

class ReferentielIdentifiants {
  static String indicatifTelephone = '+221';
  static int longueurTelephone = 9;
  static List<String> prefixesMobiles = const ['70', '75', '76', '77', '78'];
  static List<String> prefixesFixes = const ['33', '30', '39'];

  /// Valeurs par défaut, alignées sur `PAYS_TELEPHONE` côté backend. Elles
  /// sont remplacées au démarrage par celles que renvoie
  /// `GET /profil/referentiels`, pour qu'une plage nouvellement attribuée
  /// n'attende pas une mise à jour de l'application.
  static List<PaysTelephone> paysTelephone = const [
    PaysTelephone(
      iso: 'SN', nom: 'Sénégal', indicatif: '+221', longueur: 9,
      prefixesMobiles: ['70', '75', '76', '77', '78'],
      prefixesFixes: ['33', '30', '39'],
    ),
    PaysTelephone(
      iso: 'ML', nom: 'Mali', indicatif: '+223', longueur: 8,
      prefixesMobiles: ['6', '7', '8', '9'], prefixesFixes: ['2'],
    ),
    PaysTelephone(
      iso: 'CI', nom: 'Côte d’Ivoire', indicatif: '+225', longueur: 10,
      prefixesMobiles: ['01', '05', '07'], prefixesFixes: ['21', '25', '27'],
    ),
    PaysTelephone(
      iso: 'GN', nom: 'Guinée', indicatif: '+224', longueur: 9,
      prefixesMobiles: ['6'], prefixesFixes: ['3'],
    ),
    PaysTelephone(
      iso: 'GM', nom: 'Gambie', indicatif: '+220', longueur: 7,
      prefixesMobiles: ['2', '3', '5', '6', '7', '9'], prefixesFixes: ['4'],
    ),
    PaysTelephone(
      iso: 'MR', nom: 'Mauritanie', indicatif: '+222', longueur: 8,
      prefixesMobiles: ['2', '3', '4'], prefixesFixes: ['45'],
    ),
    PaysTelephone(
      iso: 'BF', nom: 'Burkina Faso', indicatif: '+226', longueur: 8,
      prefixesMobiles: ['5', '6', '7'], prefixesFixes: ['2'],
    ),
    PaysTelephone(
      iso: 'FR', nom: 'France', indicatif: '+33', longueur: 9,
      prefixesMobiles: ['6', '7'],
      prefixesFixes: ['1', '2', '3', '4', '5', '9'],
    ),
  ];

  /// Pays retenu quand le numéro est saisi sans indicatif.
  static String paysTelephoneDefaut = 'SN';

  /// Le pays par défaut, ou le premier de la liste s'il a disparu du
  /// référentiel envoyé par le serveur.
  static PaysTelephone get paysParDefaut => paysTelephone.firstWhere(
        (p) => p.iso == paysTelephoneDefaut,
        orElse: () => paysTelephone.first,
      );

  static int longueurCni = 17;
  static int longueurNin = 13;
  static int passeportLongueurMin = 6;
  static int passeportLongueurMax = 12;
  static int nineaLongueurMin = 7;
  static int nineaLongueurMax = 9;

  static List<String> categoriesRccm = const ['A', 'B', 'C', 'D', 'E'];
}

class IdentifiantValidator {
  IdentifiantValidator._();

  /// Message unique des refus de numéro d'identité (CNI, NIN).
  ///
  /// Le moteur sait exactement ce qui cloche — longueur, chiffre de sexe, date
  /// de naissance impossible, année hors bornes. Le dire au saisisseur revenait
  /// à lui enseigner la structure du numéro règle par règle : avec quelques
  /// essais, on fabrique un numéro qui passe tous les contrôles sans posséder
  /// la moindre carte.
  ///
  /// Le champ vide garde son propre message : il n'apprend rien à personne.
  static const String _messageIdentiteInvalide =
      'Numéro non valide. Vérifiez le numéro figurant sur votre pièce.';

  /// Remplace le référentiel local par celui renvoyé par le backend.
  /// Tout champ absent de la réponse conserve sa valeur par défaut.
  static void appliquerReferentiel(Map<String, dynamic> donnees) {
    final tel = donnees['telephone'];
    if (tel is Map) {
      final indicatif = tel['indicatif'];
      if (indicatif is String && indicatif.isNotEmpty) {
        ReferentielIdentifiants.indicatifTelephone = indicatif;
      }
      final longueur = tel['longueur'];
      if (longueur is int && longueur > 0) {
        ReferentielIdentifiants.longueurTelephone = longueur;
      }
      final prefixes = tel['prefixesMobiles'];
      if (prefixes is List && prefixes.isNotEmpty) {
        ReferentielIdentifiants.prefixesMobiles =
            prefixes.map((p) => p.toString()).toList();
      }
      final fixes = tel['prefixesFixes'];
      if (fixes is List && fixes.isNotEmpty) {
        ReferentielIdentifiants.prefixesFixes =
            fixes.map((p) => p.toString()).toList();
      }

      // Liste des pays acceptés. Absente des serveurs antérieurs à l'ouverture
      // multi-pays : on garde alors les valeurs embarquées.
      final pays = tel['pays'];
      if (pays is List && pays.isNotEmpty) {
        final liste = pays
            .whereType<Map>()
            .map((p) => PaysTelephone.depuisJson(Map<String, dynamic>.from(p)))
            .where((p) => p.iso.isNotEmpty && p.longueur > 0)
            .toList();
        if (liste.isNotEmpty) ReferentielIdentifiants.paysTelephone = liste;
      }
      final defaut = tel['paysDefaut'];
      if (defaut is String && defaut.isNotEmpty) {
        ReferentielIdentifiants.paysTelephoneDefaut = defaut;
      }
    }

    final cni = donnees['cni'];
    if (cni is Map && cni['longueur'] is int) {
      ReferentielIdentifiants.longueurCni = cni['longueur'] as int;
    }

    final nin = donnees['nin'];
    if (nin is Map && nin['longueur'] is int) {
      ReferentielIdentifiants.longueurNin = nin['longueur'] as int;
    }

    final passeport = donnees['passeport'];
    if (passeport is Map) {
      if (passeport['longueurMin'] is int) {
        ReferentielIdentifiants.passeportLongueurMin = passeport['longueurMin'] as int;
      }
      if (passeport['longueurMax'] is int) {
        ReferentielIdentifiants.passeportLongueurMax = passeport['longueurMax'] as int;
      }
    }

    final ninea = donnees['ninea'];
    if (ninea is Map) {
      if (ninea['longueurMin'] is int) {
        ReferentielIdentifiants.nineaLongueurMin = ninea['longueurMin'] as int;
      }
      if (ninea['longueurMax'] is int) {
        ReferentielIdentifiants.nineaLongueurMax = ninea['longueurMax'] as int;
      }
    }

    final rccm = donnees['rccm'];
    if (rccm is Map && rccm['categoriesAutorisees'] is List) {
      ReferentielIdentifiants.categoriesRccm =
          (rccm['categoriesAutorisees'] as List).map((c) => c.toString()).toList();
    }
  }

  static String _nettoyer(String? valeur) =>
      (valeur ?? '').replaceAll(RegExp(r'[\s.\-()]'), '');

  /// Vrai si la date AAAAMMJJ existe réellement.
  static bool _dateExiste(int annee, int mois, int jour) {
    if (mois < 1 || mois > 12) return false;
    if (jour < 1 || jour > 31) return false;
    final d = DateTime.utc(annee, mois, jour);
    return d.year == annee && d.month == mois && d.day == jour;
  }

  // ── Téléphone ─────────────────────────────────────────────────────────────

  /// Retrouve le pays d'un numéro déjà débarrassé de son '+' ou de son '00'.
  ///
  /// Les indicatifs les plus longs sont essayés en premier, pour qu'un futur
  /// indicatif court n'éclipse pas un indicatif long qui le prolonge.
  static PaysTelephone? _paysDepuisIndicatif(String numero) {
    final tries = [...ReferentielIdentifiants.paysTelephone]
      ..sort((a, b) =>
          b.indicatifChiffres.length.compareTo(a.indicatifChiffres.length));
    for (final pays in tries) {
      if (numero.startsWith(pays.indicatifChiffres)) return pays;
    }
    return null;
  }

  /// Numéro saisi sans '+' ni '00' mais préfixé de son indicatif
  /// (« 221771234567 »).
  ///
  /// On ne retient un pays que si la longueur totale correspond EXACTEMENT à
  /// indicatif + numéro national : sinon un numéro gambien de 7 chiffres
  /// commençant par 2 passerait pour un mauritanien (+222).
  static PaysTelephone? _paysDepuisNumeroComplet(String numero) {
    for (final pays in ReferentielIdentifiants.paysTelephone) {
      final indicatif = pays.indicatifChiffres;
      if (numero.startsWith(indicatif) &&
          numero.length == indicatif.length + pays.longueur) {
        return pays;
      }
    }
    return null;
  }

  /// Préfixe le plus long de [prefixes] par lequel commence [numero].
  static String? _prefixeCorrespondant(String numero, List<String> prefixes) {
    final tries = [...prefixes]..sort((a, b) => b.length.compareTo(a.length));
    for (final prefixe in tries) {
      if (numero.startsWith(prefixe)) return prefixe;
    }
    return null;
  }

  /// Valide un numéro et renvoie sa forme internationale `+XXXNNNNNNNNN`.
  ///
  /// Chaque pays du référentiel porte ses propres règles : un numéro ivoirien
  /// est contrôlé avec les règles ivoiriennes, pas avec celles du Sénégal. Un
  /// indicatif hors référentiel est refusé — le sélecteur de l'application ne
  /// propose de toute façon que ces pays-là.
  ///
  /// Sans indicatif, le numéro est rattaché au pays par défaut, ce qui
  /// préserve les comptes créés avant l'ouverture aux autres pays.
  ///
  /// La propriété du numéro n'est pas vérifiée (pas d'OTP) : un numéro au bon
  /// format est considéré comme acquis.
  static ResultatValidation telephone(String? saisie, {bool autoriserFixe = false}) {
    var brut = _nettoyer(saisie);
    if (brut.isEmpty) {
      return const ResultatValidation.invalide('Numéro de téléphone requis');
    }

    var indicatifExplicite = false;
    if (brut.startsWith('+')) {
      brut = brut.substring(1);
      indicatifExplicite = true;
    } else if (brut.startsWith('00')) {
      brut = brut.substring(2);
      indicatifExplicite = true;
    }

    PaysTelephone pays;
    if (indicatifExplicite) {
      final trouve = _paysDepuisIndicatif(brut);
      if (trouve == null) {
        return ResultatValidation.invalide(
          'Cet indicatif n’est pas pris en charge. Pays acceptés : '
          '${ReferentielIdentifiants.paysTelephone.map((p) => p.nom).join(', ')}.',
        );
      }
      pays = trouve;
      brut = brut.substring(pays.indicatifChiffres.length);
    } else {
      final trouve = _paysDepuisNumeroComplet(brut);
      if (trouve != null) {
        pays = trouve;
        brut = brut.substring(pays.indicatifChiffres.length);
      } else {
        pays = ReferentielIdentifiants.paysParDefaut;
      }
    }

    if (!RegExp(r'^\d+$').hasMatch(brut)) {
      return const ResultatValidation.invalide(
          'Le numéro ne doit contenir que des chiffres');
    }

    if (brut.length != pays.longueur) {
      return ResultatValidation.invalide(
        'Un numéro ${pays.nom} doit comporter ${pays.longueur} chiffres — '
        '${brut.length} saisi${brut.length > 1 ? 's' : ''}',
      );
    }

    final autorises = autoriserFixe
        ? [...pays.prefixesMobiles, ...pays.prefixesFixes]
        : pays.prefixesMobiles;

    if (_prefixeCorrespondant(brut, autorises) == null) {
      return ResultatValidation.invalide(
        'Ce numéro ne correspond à aucune plage ${pays.nom} autorisée '
        '(${autorises.join(', ')})',
      );
    }

    return ResultatValidation.valide('${pays.indicatif}$brut');
  }

  // ── E-mail ────────────────────────────────────────────────────────────────

  /// Contrôle syntaxique. L'e-mail étant facultatif, une saisie vide n'est pas
  /// une erreur sauf si [obligatoire] est vrai.
  static ResultatValidation email(String? saisie, {bool obligatoire = false}) {
    final brut = (saisie ?? '').trim();
    if (brut.isEmpty) {
      return obligatoire
          ? const ResultatValidation.invalide('Adresse e-mail requise')
          : const ResultatValidation.formatValide('', 'Aucune adresse e-mail renseignée');
    }
    if (RegExp(r'\s').hasMatch(brut)) {
      return const ResultatValidation.invalide(
          'L’adresse e-mail ne doit pas contenir d’espace');
    }
    if (!brut.contains('@')) {
      return const ResultatValidation.invalide('L’adresse e-mail doit contenir un @');
    }
    final morceaux = brut.split('@');
    if (morceaux.length != 2) {
      return const ResultatValidation.invalide(
          'L’adresse e-mail doit contenir un seul @');
    }
    final locale = morceaux[0];
    final domaine = morceaux[1];
    if (locale.isEmpty) {
      return const ResultatValidation.invalide('La partie avant le @ est vide');
    }
    if (!RegExp(r'^[A-Za-z0-9.-]+\.[A-Za-z]{2,}$').hasMatch(domaine)) {
      return const ResultatValidation.invalide(
          'Le domaine de l’adresse e-mail est invalide');
    }
    return ResultatValidation.valide(brut.toLowerCase());
  }

  // ── CNI ───────────────────────────────────────────────────────────────────

  /// CNI biométrique CEDEAO : 1 sexe + 2 région + 8 date + 5 séquence + 1 clé.
  static ResultatValidation cni(String? saisie) {
    final brut = _nettoyer(saisie);
    if (brut.isEmpty) return const ResultatValidation.invalide('Numéro de CNI requis');
    if (!RegExp(r'^\d+$').hasMatch(brut)) {
      return const ResultatValidation.invalide(_messageIdentiteInvalide);
    }

    final attendue = ReferentielIdentifiants.longueurCni;
    if (brut.length != attendue) {
      return const ResultatValidation.invalide(_messageIdentiteInvalide);
    }

    final sexe = brut.substring(0, 1);
    if (sexe != '1' && sexe != '2') {
      return const ResultatValidation.invalide(_messageIdentiteInvalide);
    }

    final annee = int.tryParse(brut.substring(3, 7)) ?? 0;
    final mois = int.tryParse(brut.substring(7, 9)) ?? 0;
    final jour = int.tryParse(brut.substring(9, 11)) ?? 0;

    if (!_dateExiste(annee, mois, jour)) {
      return const ResultatValidation.invalide(_messageIdentiteInvalide);
    }

    final anneeCourante = DateTime.now().year;
    if (annee < 1900 || annee > anneeCourante) {
      return const ResultatValidation.invalide(_messageIdentiteInvalide);
    }

    // Le chiffre de contrôle n'est pas vérifiable : l'algorithme officiel de
    // la CNI biométrique CEDEAO n'est pas publié.
    return ResultatValidation.formatValide(
      brut,
      'Structure conforme — le chiffre de contrôle n’est pas vérifiable',
    );
  }

  // ── Passeport ─────────────────────────────────────────────────────────────

  /// Aucun sens n'est déduit des différentes parties du numéro : on ne
  /// contrôle que la longueur et les caractères autorisés.
  static ResultatValidation passeport(String? saisie) {
    final brut = _nettoyer(saisie).toUpperCase();
    if (brut.isEmpty) {
      return const ResultatValidation.invalide('Numéro de passeport requis');
    }
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(brut)) {
      return const ResultatValidation.invalide(
          'Le numéro ne doit contenir que des lettres majuscules et des chiffres');
    }
    final min = ReferentielIdentifiants.passeportLongueurMin;
    final max = ReferentielIdentifiants.passeportLongueurMax;
    if (brut.length < min || brut.length > max) {
      return ResultatValidation.invalide(
        'Le numéro de passeport doit comporter entre $min et $max caractères — ${brut.length} saisi${brut.length > 1 ? 's' : ''}',
      );
    }
    return ResultatValidation.formatValide(
      brut,
      'Format accepté — aucun référentiel officiel de numérotation n’est disponible',
    );
  }

  // ── NIN ───────────────────────────────────────────────────────────────────

  /// NIN : 1 sexe + 3 centre d'état civil + 4 année + 5 séquence.
  static ResultatValidation nin(String? saisie) {
    final brut = _nettoyer(saisie);
    if (brut.isEmpty) return const ResultatValidation.invalide('NIN requis');
    // Même raisonnement que pour la CNI : détailler la règle enfreinte
    // revient à apprendre à fabriquer un numéro qui passe les contrôles.
    if (!RegExp(r'^\d+$').hasMatch(brut)) {
      return const ResultatValidation.invalide(_messageIdentiteInvalide);
    }
    final attendue = ReferentielIdentifiants.longueurNin;
    if (brut.length != attendue) {
      return const ResultatValidation.invalide(_messageIdentiteInvalide);
    }
    final sexe = brut.substring(0, 1);
    if (sexe != '1' && sexe != '2') {
      return const ResultatValidation.invalide(_messageIdentiteInvalide);
    }
    final annee = int.tryParse(brut.substring(4, 8)) ?? 0;
    final anneeCourante = DateTime.now().year;
    if (annee < 1900 || annee > anneeCourante) {
      return const ResultatValidation.invalide(_messageIdentiteInvalide);
    }
    return ResultatValidation.formatValide(
      brut,
      'Structure conforme — l’existence du NIN ne peut pas être confirmée',
    );
  }

  // ── RCCM ──────────────────────────────────────────────────────────────────

  /// RCCM OHADA : PAYS.RESSORT.ANNÉE.CATÉGORIE.SÉQUENCE (ex : SN.DKR.2017.A.19778).
  static ResultatValidation rccm(String? saisie) {
    var brut = (saisie ?? '').trim().toUpperCase();
    if (brut.isEmpty) return const ResultatValidation.invalide('Numéro RCCM requis');

    for (final sep in ['-', '/', ' ']) {
      brut = brut.replaceAll(sep, '.');
    }
    brut = brut.replaceAll(RegExp(r'\.+'), '.');
    brut = brut.replaceAll(RegExp(r'^\.|\.$'), '');

    final segments = brut.split('.');
    if (segments.length != 5) {
      return const ResultatValidation.invalide(
        'Le RCCM doit comporter 5 parties (ex : SN.DKR.2017.A.19778)',
      );
    }

    final pays = segments[0];
    final ressort = segments[1];
    final annee = segments[2];
    final categorie = segments[3];
    final sequence = segments[4];

    if (pays != 'SN') {
      return ResultatValidation.invalide(
          'Le code pays « $pays » n’est pas reconnu (attendu : SN)');
    }
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(ressort)) {
      return ResultatValidation.invalide(
          'Le ressort « $ressort » doit être un code de 3 lettres (ex : DKR)');
    }
    if (!RegExp(r'^\d{4}$').hasMatch(annee)) {
      return ResultatValidation.invalide(
          'L’année « $annee » doit comporter 4 chiffres');
    }
    final anneeNum = int.parse(annee);
    final anneeCourante = DateTime.now().year;
    if (anneeNum < 1960 || anneeNum > anneeCourante) {
      return ResultatValidation.invalide(
          'L’année $annee est hors des bornes admises (1960–$anneeCourante)');
    }
    if (!ReferentielIdentifiants.categoriesRccm.contains(categorie)) {
      return ResultatValidation.invalide(
        'La catégorie « $categorie » n’est pas reconnue (attendu : ${ReferentielIdentifiants.categoriesRccm.join(', ')})',
      );
    }
    if (!RegExp(r'^\d+$').hasMatch(sequence)) {
      return const ResultatValidation.invalide(
          'Le numéro séquentiel doit être numérique');
    }

    return ResultatValidation.formatValide(
      '$pays.$ressort.$annee.$categorie.$sequence',
      'Nomenclature OHADA respectée — vérification officielle non disponible',
    );
  }

  // ── NINEA ─────────────────────────────────────────────────────────────────

  /// NINEA : identifiant numérique, éventuellement suivi du code COFI.
  static ResultatValidation ninea(String? saisie) {
    final brut = (saisie ?? '').trim().toUpperCase();
    if (brut.isEmpty) return const ResultatValidation.invalide('NINEA requis');

    final morceaux = brut.split(RegExp(r'[\s.\-]+')).where((m) => m.isNotEmpty).toList();
    final identifiant = morceaux.isNotEmpty ? morceaux[0] : '';
    final cofi = morceaux.length > 1 ? morceaux[1] : null;

    if (!RegExp(r'^\d+$').hasMatch(identifiant)) {
      return const ResultatValidation.invalide(
          'La partie identifiante du NINEA doit être numérique');
    }
    final min = ReferentielIdentifiants.nineaLongueurMin;
    final max = ReferentielIdentifiants.nineaLongueurMax;
    if (identifiant.length < min || identifiant.length > max) {
      return ResultatValidation.invalide(
        'Le NINEA doit comporter entre $min et $max chiffres — ${identifiant.length} saisi${identifiant.length > 1 ? 's' : ''}',
      );
    }
    if (cofi != null && (!RegExp(r'^[A-Z0-9]{3}$').hasMatch(cofi))) {
      return const ResultatValidation.invalide(
          'Le code COFI doit comporter 3 caractères alphanumériques (ex : 2G3)');
    }
    if (morceaux.length > 2) {
      return const ResultatValidation.invalide(
          'Le NINEA ne doit comporter que l’identifiant et, éventuellement, le code COFI');
    }

    return ResultatValidation.formatValide(
      cofi != null ? '$identifiant $cofi' : identifiant,
      'Format conforme — vérification officielle non disponible',
    );
  }

  // ── Aiguillage ────────────────────────────────────────────────────────────

  /// Valide selon un type nommé — mêmes clés que le backend.
  static ResultatValidation parType(String type, String? valeur) {
    switch (type.toLowerCase()) {
      case 'telephone':
        return telephone(valeur);
      case 'email':
        return email(valeur);
      case 'cni':
      case 'carte_identite':
        return cni(valeur);
      case 'passeport':
        return passeport(valeur);
      case 'nin':
        return nin(valeur);
      case 'rccm':
        return rccm(valeur);
      case 'ninea':
        return ninea(valeur);
      default:
        // Type inconnu du client : on laisse le backend trancher.
        return ResultatValidation.formatValide(
            (valeur ?? '').trim(), 'Vérification effectuée par le serveur');
    }
  }
}

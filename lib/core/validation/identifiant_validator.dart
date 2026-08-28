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
class ReferentielIdentifiants {
  static String indicatifTelephone = '+221';
  static int longueurTelephone = 9;
  static List<String> prefixesMobiles = const ['70', '76', '77', '78'];
  static List<String> prefixesFixes = const ['33', '30', '39'];

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

  /// Valide un numéro sénégalais et renvoie la forme `+221XXXXXXXXX`.
  ///
  /// La propriété du numéro n'est pas vérifiée (pas d'OTP) : un numéro au bon
  /// format est considéré comme acquis.
  static ResultatValidation telephone(String? saisie, {bool autoriserFixe = false}) {
    var brut = _nettoyer(saisie);
    if (brut.isEmpty) return const ResultatValidation.invalide('Numéro de téléphone requis');

    final indicatifChiffres =
        ReferentielIdentifiants.indicatifTelephone.replaceAll('+', '');
    if (brut.startsWith('+')) brut = brut.substring(1);
    if (brut.startsWith('00')) brut = brut.substring(2);
    if (brut.startsWith(indicatifChiffres) &&
        brut.length > ReferentielIdentifiants.longueurTelephone) {
      brut = brut.substring(indicatifChiffres.length);
    }

    if (!RegExp(r'^\d+$').hasMatch(brut)) {
      return const ResultatValidation.invalide(
          'Le numéro ne doit contenir que des chiffres');
    }

    final attendue = ReferentielIdentifiants.longueurTelephone;
    if (brut.length != attendue) {
      return ResultatValidation.invalide(
        'Le numéro doit comporter $attendue chiffres — ${brut.length} saisi${brut.length > 1 ? 's' : ''}',
      );
    }

    final prefixe = brut.substring(0, 2);
    final autorises = autoriserFixe
        ? [...ReferentielIdentifiants.prefixesMobiles, ...ReferentielIdentifiants.prefixesFixes]
        : ReferentielIdentifiants.prefixesMobiles;

    if (!autorises.contains(prefixe)) {
      return ResultatValidation.invalide(
        'Le préfixe $prefixe n’est pas une plage autorisée (${autorises.join(', ')})',
      );
    }

    return ResultatValidation.valide(
        '${ReferentielIdentifiants.indicatifTelephone}$brut');
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
      return const ResultatValidation.invalide(
          'Le numéro de CNI ne doit contenir que des chiffres');
    }

    final attendue = ReferentielIdentifiants.longueurCni;
    if (brut.length != attendue) {
      return ResultatValidation.invalide(
        'Le numéro de CNI doit comporter $attendue chiffres — ${brut.length} saisi${brut.length > 1 ? 's' : ''}',
      );
    }

    final sexe = brut.substring(0, 1);
    if (sexe != '1' && sexe != '2') {
      return ResultatValidation.invalide(
          'Le chiffre de sexe « $sexe » n’est pas valide (attendu : 1 ou 2)');
    }

    final annee = int.tryParse(brut.substring(3, 7)) ?? 0;
    final mois = int.tryParse(brut.substring(7, 9)) ?? 0;
    final jour = int.tryParse(brut.substring(9, 11)) ?? 0;

    if (!_dateExiste(annee, mois, jour)) {
      final mm = brut.substring(7, 9);
      final jj = brut.substring(9, 11);
      final aaaa = brut.substring(3, 7);
      return ResultatValidation.invalide(
          'La date de naissance $jj/$mm/$aaaa n’existe pas');
    }

    final anneeCourante = DateTime.now().year;
    if (annee < 1900 || annee > anneeCourante) {
      return ResultatValidation.invalide(
          'L’année de naissance $annee est hors des bornes admises (1900–$anneeCourante)');
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
    if (!RegExp(r'^\d+$').hasMatch(brut)) {
      return const ResultatValidation.invalide(
          'Le NIN ne doit contenir que des chiffres');
    }
    final attendue = ReferentielIdentifiants.longueurNin;
    if (brut.length != attendue) {
      return ResultatValidation.invalide(
        'Le NIN doit comporter $attendue chiffres — ${brut.length} saisi${brut.length > 1 ? 's' : ''}',
      );
    }
    final sexe = brut.substring(0, 1);
    if (sexe != '1' && sexe != '2') {
      return ResultatValidation.invalide(
          'Le chiffre de sexe « $sexe » n’est pas valide (attendu : 1 ou 2)');
    }
    final annee = int.tryParse(brut.substring(4, 8)) ?? 0;
    final anneeCourante = DateTime.now().year;
    if (annee < 1900 || annee > anneeCourante) {
      return ResultatValidation.invalide(
          'L’année $annee du NIN est hors des bornes admises (1900–$anneeCourante)');
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

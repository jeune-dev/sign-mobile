import '../../domain/entities/fiche_paie.dart';

class FichePaieModel extends FichePaie {

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  const FichePaieModel({
    super.id,
    required super.numeroFiche,
    required super.employeurId,
    required super.salarieId,
    super.numeroIpres,
    super.numeroCss,
    super.poste,
    super.dateEmbauche,
    required super.typeContrat,
    required super.mois,
    required super.annee,
    required super.salaireBrut,
    required super.modeCalcul,
    super.nombreJoursTravailles,
    super.nombreHeuresTravailles,
    required super.absence,
    super.nombreJoursAbsence,
    super.typeAbsence,
    super.autreTypeAbsence,
    required super.aHeuresSupp,
    required super.nombreHeuresSupplementaires,
    required super.aPrimes,
    required super.primeTransport,
    required super.primeLogement,
    required super.primePerformance,
    required super.primeExceptionnelle,
    required super.autresPrimes,
    super.avantagesNature,
    super.autreAvantages,
    super.valeurAvantages,
    required super.congesPris,
    required super.nombreJoursConges,
    super.montantConges,
    required super.aAvanceSalaire,
    required super.montantAvanceSalaire,
    required super.aAutresRetenues,
    super.motifRetenue,
    required super.montantRetenue,
    required super.soumisIpres,
    required super.soumisCss,
    required super.soumisIr,
    required super.aAssurance,
    super.montantAssurance,
    required super.situationFamiliale,
    required super.nombreEnfants,
    required super.modePaiement,
    required super.datePaiement,
    super.totalGains,
    super.totalRetenues,
    super.salaireNet,
    super.fichePdf,
    super.direction,
    super.employeur,
    super.salarie,
  });

  factory FichePaieModel.fromJson(Map<String, dynamic> json) {
    return FichePaieModel(
      id: json['id'],
      numeroFiche: json['numero_fiche'] ?? '',
      employeurId: json['employeurId'] ?? '',
      salarieId: json['salarieId'] ?? '',

      poste: json['poste'],
      dateEmbauche: json['date_embauche'],

      typeContrat: json['type_contrat'] ?? '',
      mois: json['mois'] ?? '',
      annee: _toInt(json['annee']),

      salaireBrut: _toDouble(json['salaire_brut']),
      modeCalcul: json['mode_calcul'] ?? '',

      nombreJoursTravailles: _toInt(json['nombre_jours_travailles']),
      nombreHeuresTravailles: _toDouble(json['nombre_heures_travailles']),

      absence: json['absence'] ?? false,
      nombreJoursAbsence: _toInt(json['nombre_jours_absence']),
      typeAbsence: json['type_absence'],
      autreTypeAbsence: json['autre_type_absence'],

      aHeuresSupp: json['a_heures_supp'] ?? false,
      nombreHeuresSupplementaires: _toDouble(json['nombre_heures_supplementaires']),

      aPrimes: json['a_primes'] ?? false,
      primeTransport: _toDouble(json['prime_transport']),
      primeLogement: _toDouble(json['prime_logement']),
      primePerformance: _toDouble(json['prime_performance']),
      primeExceptionnelle: _toDouble(json['prime_exceptionnelle']),
      autresPrimes: _toDouble(json['autres_primes']),

      avantagesNature: json['avantages_nature'],
      autreAvantages: json['autre_avantages'],
      valeurAvantages: _toDouble(json['valeur_avantages']),

      congesPris: json['conges_pris'] ?? false,
      nombreJoursConges: _toInt(json['nombre_jours_conges']),
      montantConges: _toDouble(json['montant_conges']),

      aAvanceSalaire: json['a_avance_salaire'] ?? false,
      montantAvanceSalaire: _toDouble(json['montant_avance_salaire']),

      aAutresRetenues: json['a_autres_retenues'] ?? false,
      motifRetenue: json['motif_retenue'],
      montantRetenue: _toDouble(json['montant_retenue']),

      soumisIpres: json['soumis_ipres'] ?? true,
      soumisCss: json['soumis_css'] ?? true,
      soumisIr: json['soumis_ir'] ?? true,

      aAssurance: json['a_assurance'] ?? false,
      montantAssurance: _toDouble(json['montant_assurance']),

      situationFamiliale: json['situation_familiale'] ?? '',
      nombreEnfants: _toInt(json['nombre_enfants']),

      modePaiement: json['mode_paiement'] ?? '',
      datePaiement: json['date_paiement'] ?? '',

      totalGains: _toDouble(json['total_gains']),
      totalRetenues: _toDouble(json['total_retenues']),
      salaireNet: _toDouble(json['salaire_net']),

      fichePdf: json['fiche_pdf'],

      direction: json['direction'],
      employeur: json['employeur'] != null
          ? Map<String, dynamic>.from(json['employeur'])
          : null,
      salarie: json['salarie'] != null
          ? Map<String, dynamic>.from(json['salarie'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "numero_fiche": numeroFiche,
      "salarieId": salarieId,
      "employeurId": employeurId,
      "mois": mois,
      "annee": annee,
      "salaire_brut": salaireBrut,
      "type_contrat": typeContrat,
      "mode_calcul": modeCalcul,
      "poste": poste,
      "date_embauche": dateEmbauche,
      "numero_ipres": numeroIpres,
      "numero_css": numeroCss,
      "nombre_jours_travailles": nombreJoursTravailles,
      "nombre_heures_travailles": nombreHeuresTravailles,
      "absence": absence,
      "nombre_jours_absence": nombreJoursAbsence,
      "type_absence": typeAbsence,
      "autre_type_absence": autreTypeAbsence,
      "a_heures_supp": aHeuresSupp,
      "nombre_heures_supplementaires": nombreHeuresSupplementaires,
      "a_primes": aPrimes,
      "prime_transport": primeTransport,
      "prime_logement": primeLogement,
      "prime_performance": primePerformance,
      "prime_exceptionnelle": primeExceptionnelle,
      "autres_primes": autresPrimes,
      "avantages_nature": avantagesNature,
      "autre_avantages": autreAvantages,
      "valeur_avantages": valeurAvantages,
      "conges_pris": congesPris,
      "nombre_jours_conges": nombreJoursConges,
      "montant_conges": montantConges,
      "a_avance_salaire": aAvanceSalaire,
      "montant_avance_salaire": montantAvanceSalaire,
      "a_autres_retenues": aAutresRetenues,
      "motif_retenue": motifRetenue,
      "montant_retenue": montantRetenue,
      "soumis_ipres": soumisIpres,
      "soumis_css": soumisCss,
      "soumis_ir": soumisIr,
      "a_assurance": aAssurance,
      "montant_assurance": montantAssurance,
      "situation_familiale": situationFamiliale,
      "nombre_enfants": nombreEnfants,
      "mode_paiement": modePaiement,
      "date_paiement": datePaiement,
    };
  }
}
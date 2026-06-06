import 'package:equatable/equatable.dart';

class FichePaie extends Equatable {
  final String? id;
  final String numeroFiche;

  final String employeurId;
  final String salarieId;

  final String? numeroIpres;
  final String? numeroCss;
  final String? poste;
  final String? dateEmbauche;

  final String typeContrat;
  final String mois;
  final int annee;

  final double salaireBrut;
  final String modeCalcul;

  final int? nombreJoursTravailles;
  final double? nombreHeuresTravailles;

  final bool absence;
  final int? nombreJoursAbsence;
  final String? typeAbsence;
  final String? autreTypeAbsence; // ✅ AJOUT

  final bool aHeuresSupp;
  final double nombreHeuresSupplementaires;

  final bool aPrimes;
  final double primeTransport;
  final double primeLogement;
  final double primePerformance;
  final double primeExceptionnelle;
  final double autresPrimes;

  // ✅ AVANTAGES
  final String? avantagesNature;
  final String? autreAvantages;
  final double? valeurAvantages;

  // ✅ CONGES
  final bool congesPris;
  final int nombreJoursConges;
  final double? montantConges;

  // ✅ AVANCE
  final bool aAvanceSalaire;
  final double montantAvanceSalaire;

  // ✅ RETENUES
  final bool aAutresRetenues;
  final String? motifRetenue;
  final double montantRetenue;

  // ✅ COTISATIONS
  final bool soumisIpres;
  final bool soumisCss;
  final bool soumisIr;

  // ✅ ASSURANCE
  final bool aAssurance;
  final double? montantAssurance;

  final String situationFamiliale;
  final int nombreEnfants;

  final String modePaiement;
  final String datePaiement;

  final double? totalGains;
  final double? totalRetenues;
  final double? salaireNet;

  final String? fichePdf;

  FichePaie({
    this.id,
    required this.numeroFiche,
    required this.employeurId,
    required this.salarieId,
    this.numeroIpres,
    this.numeroCss,
    this.poste,
    this.dateEmbauche,
    required this.typeContrat,
    required this.mois,
    required this.annee,
    required this.salaireBrut,
    required this.modeCalcul,
    this.nombreJoursTravailles,
    this.nombreHeuresTravailles,
    required this.absence,
    this.nombreJoursAbsence,
    this.typeAbsence,
    this.autreTypeAbsence, // ✅
    required this.aHeuresSupp,
    required this.nombreHeuresSupplementaires,
    required this.aPrimes,
    required this.primeTransport,
    required this.primeLogement,
    required this.primePerformance,
    required this.primeExceptionnelle,
    required this.autresPrimes,

    this.avantagesNature,   // ✅
    this.autreAvantages,    // ✅
    this.valeurAvantages,   // ✅

    required this.congesPris,
    required this.nombreJoursConges,
    this.montantConges,     // ✅

    required this.aAvanceSalaire,
    required this.montantAvanceSalaire,

    required this.aAutresRetenues,
    this.motifRetenue,
    required this.montantRetenue,

    required this.soumisIpres,
    required this.soumisCss,
    required this.soumisIr,

    required this.aAssurance,      // ✅
    this.montantAssurance,         // ✅

    required this.situationFamiliale,
    required this.nombreEnfants,
    required this.modePaiement,
    required this.datePaiement,

    this.totalGains,
    this.totalRetenues,
    this.salaireNet,
    this.fichePdf,
  });

  @override
  List<Object?> get props => [
    id,
    numeroFiche,
    employeurId,
    salarieId,
    numeroIpres,
    numeroCss,
    poste,
    dateEmbauche,
    typeContrat,
    mois,
    annee,
    salaireBrut,
    modeCalcul,
    nombreJoursTravailles,
    nombreHeuresTravailles,
    absence,
    nombreJoursAbsence,
    typeAbsence,
    autreTypeAbsence, // ✅
    aHeuresSupp,
    nombreHeuresSupplementaires,
    aPrimes,
    primeTransport,
    primeLogement,
    primePerformance,
    primeExceptionnelle,
    autresPrimes,

    avantagesNature,  // ✅
    autreAvantages,   // ✅
    valeurAvantages,  // ✅

    congesPris,
    nombreJoursConges,
    montantConges,    // ✅

    aAvanceSalaire,
    montantAvanceSalaire,
    aAutresRetenues,
    motifRetenue,
    montantRetenue,
    soumisIpres,
    soumisCss,
    soumisIr,

    aAssurance,       // ✅
    montantAssurance, // ✅

    situationFamiliale,
    nombreEnfants,
    modePaiement,
    datePaiement,
    totalGains,
    totalRetenues,
    salaireNet,
    fichePdf,
  ];
}
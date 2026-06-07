import 'package:equatable/equatable.dart';

class ContratTravail extends Equatable {
  final String id;
  final String? numeroContrat;
  final String? poste;
  final List<dynamic>? missions;
  final String? lieuTravail;
  final String? typeContrat;
  final List<dynamic>? jourTravail; // [{jour, debut, fin}, ...]
  final String? heureDebut;
  final String? heureFin;
  final String? tempsPause;
  final String? dateDebut;
  final String? dateFin;
  final double? salaireMensuel;
  final String? moyenPaiement;
  final int? nbrJoursConges;
  final String? remunerationJoursFeries;
  final String? remunerationAbsencesMaladie;
  final bool? avanceSalaire;
  final dynamic avantagesSalarial;
  final String? dureePreavis;
  final dynamic assuranceMaladie;
  final dynamic clauses;
  final String? dateSignature;
  final String? lieuSignature;
  final String? signatureEmployeur;
  final String? signatureSalarie;
  final String? statut;
  final Map<String, dynamic>? salarie;
  final String? createdAt;

  const ContratTravail({
    required this.id,
    this.numeroContrat,
    this.poste,
    this.missions,
    this.lieuTravail,
    this.typeContrat,
    this.jourTravail,
    this.heureDebut,
    this.heureFin,
    this.tempsPause,
    this.dateDebut,
    this.dateFin,
    this.salaireMensuel,
    this.moyenPaiement,
    this.nbrJoursConges,
    this.remunerationJoursFeries,
    this.remunerationAbsencesMaladie,
    this.avanceSalaire,
    this.avantagesSalarial,
    this.dureePreavis,
    this.assuranceMaladie,
    this.clauses,
    this.dateSignature,
    this.lieuSignature,
    this.signatureEmployeur,
    this.signatureSalarie,
    this.statut,
    this.salarie,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, numeroContrat];
}

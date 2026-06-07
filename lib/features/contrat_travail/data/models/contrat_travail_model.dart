import '../../domain/entities/contrat_travail.dart';

class ContratTravailModel extends ContratTravail {
  const ContratTravailModel({
    required super.id,
    super.numeroContrat,
    super.poste,
    super.missions,
    super.lieuTravail,
    super.typeContrat,
    super.jourTravail,
    super.heureDebut,
    super.heureFin,
    super.tempsPause,
    super.dateDebut,
    super.dateFin,
    super.salaireMensuel,
    super.moyenPaiement,
    super.nbrJoursConges,
    super.remunerationJoursFeries,
    super.remunerationAbsencesMaladie,
    super.avanceSalaire,
    super.avantagesSalarial,
    super.dureePreavis,
    super.assuranceMaladie,
    super.clauses,
    super.dateSignature,
    super.lieuSignature,
    super.signatureEmployeur,
    super.signatureSalarie,
    super.statut,
    super.salarie,
    super.createdAt,
  });

  factory ContratTravailModel.fromJson(Map<String, dynamic> json) {
    return ContratTravailModel(
      id: json['id']?.toString() ?? '',
      numeroContrat: json['numero_contrat'],
      poste: json['poste'],
      missions: json['missions'],
      lieuTravail: json['lieu_travail'],
      typeContrat: json['type_contrat'],
      jourTravail: json['jour_travail'] is List
          ? List<dynamic>.from(json['jour_travail'] as List)
          : null,
      heureDebut: json['heure_debut'],
      heureFin: json['heure_fin'],
      tempsPause: json['temps_pause'],
      dateDebut: json['date_debut'],
      dateFin: json['date_fin'],
      salaireMensuel: json['salaire_mensuel'] != null
          ? double.tryParse(json['salaire_mensuel'].toString())
          : null,
      moyenPaiement: json['moyen_paiement'],
      nbrJoursConges: json['nbr_jours_conges'],
      remunerationJoursFeries: json['remuneration_jours_feries'],
      remunerationAbsencesMaladie: json['remuneration_absences_maladie'],
      avanceSalaire: json['avance_salaire'],
      avantagesSalarial: json['avantages_salarial'],
      dureePreavis: json['duree_preavis'],
      assuranceMaladie: json['assurance_maladie'],
      clauses: json['clauses'],
      dateSignature: json['date_signature'],
      lieuSignature: json['lieu_signature'],
      signatureEmployeur: json['signature_employeur'],
      signatureSalarie: json['signature_salarie'],
      statut: json['statut'],
      salarie: json['salarie'] != null
          ? Map<String, dynamic>.from(json['salarie'])
          : null,
      createdAt: json['createdAt'],
    );
  }
}

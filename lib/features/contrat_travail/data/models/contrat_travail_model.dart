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
    // Cast sûr pour les sous-objets/tableaux JSON — évite tout crash de type
    Map<String, dynamic>? toMap(dynamic v) =>
        v is Map ? Map<String, dynamic>.from(v) : null;
    List<dynamic>? toList(dynamic v) =>
        v is List ? List<dynamic>.from(v) : null;

    return ContratTravailModel(
      id:              json['id']?.toString() ?? '',
      numeroContrat:   json['numero_contrat']  as String?,
      poste:           json['poste']           as String?,
      // missions est DataTypes.JSON → tableau
      missions:        toList(json['missions']),
      lieuTravail:     json['lieu_travail']    as String?,
      typeContrat:     json['type_contrat']    as String?,
      // jour_travail est DataTypes.JSON → [{jour, debut, fin}, ...]
      jourTravail:     toList(json['jour_travail']),
      heureDebut:      json['heure_debut']     as String?,
      heureFin:        json['heure_fin']       as String?,
      tempsPause:      json['temps_pause']     as String?,
      dateDebut:       json['date_debut']      as String?,
      dateFin:         json['date_fin']        as String?,
      salaireMensuel:  json['salaire_mensuel'] != null
          ? double.tryParse(json['salaire_mensuel'].toString())
          : null,
      moyenPaiement:   json['moyen_paiement']  as String?,
      nbrJoursConges:  (json['nbr_jours_conges'] as num?)?.toInt(),
      remunerationJoursFeries:    json['remuneration_jours_feries'],
      remunerationAbsencesMaladie: json['remuneration_absences_maladie'],
      avanceSalaire:   json['avance_salaire'],
      // avantagesSalarial peut être Map ou String selon le backend
      avantagesSalarial: json['avantages_salarial'],
      dureePreavis:    json['duree_preavis']   as String?,
      // assuranceMaladie peut être bool ou Map
      assuranceMaladie: json['assurance_maladie'],
      // clauses est DataTypes.JSON → peut être List ou Map
      clauses:         json['clauses'],
      dateSignature:   json['date_signature']  as String?,
      lieuSignature:   json['lieu_signature']  as String?,
      signatureEmployeur: json['signature_employeur'] as String?,
      signatureSalarie:   json['signature_salarie']   as String?,
      statut:          json['statut']          as String?,
      // backend alias : as 'salarie' (models/index.js)
      salarie:         toMap(json['salarie']),
      createdAt:       json['createdAt']       as String?,
    );
  }
}

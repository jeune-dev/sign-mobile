import '../../domain/entities/contrat_bail.dart';

class ContratBailModel extends ContratBail {
  const ContratBailModel({
    required super.id,
    super.numeroContrat,
    super.bienAdresse,
    super.bienVille,
    super.bienType,
    super.statut,
    super.loyerMensuel,
    super.devise,
    super.dateDebutBail,
    super.locataires,
    super.proprietaire,
  });

  factory ContratBailModel.fromJson(Map<String, dynamic> json) {
    // Cast sûr pour les sous-objets JSON
    Map<String, dynamic>? _toMap(dynamic v) =>
        v is Map ? Map<String, dynamic>.from(v) : null;

    return ContratBailModel(
      id:            json['id']?.toString() ?? '',
      numeroContrat: json['numero_contrat'] as String?,
      bienAdresse:   json['bien_adresse']   as String?,
      bienVille:     json['bien_ville']     as String?,
      bienType:      json['bien_type']      as String?,
      statut:        json['statut']         as String?,
      loyerMensuel:  json['loyer_mensuel'] != null
          ? double.tryParse(json['loyer_mensuel'].toString())
          : null,
      devise:        json['devise']         as String?,
      dateDebutBail: json['date_debut_bail'] as String?,
      // locataires est un tableau JSON — cast explicite pour éviter le crash
      locataires: json['locataires'] is List
          ? List<dynamic>.from(json['locataires'] as List)
          : null,
      // backend expose le bailleur sous l'alias 'bailleur' (models/index.js)
      // certaines routes peuvent aussi renvoyer 'proprietaire'
      proprietaire: _toMap(json['bailleur']) ?? _toMap(json['proprietaire']),
    );
  }
}

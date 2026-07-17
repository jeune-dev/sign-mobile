import '../../domain/entities/autre_contrat.dart';

class AutreContratModel extends AutreContrat {
  const AutreContratModel({
    required super.id,
    super.numeroContrat,
    required super.type,
    super.statut,
    super.generateur,
    super.autrePartie,
    super.data,
    super.createdAt,
  });

  factory AutreContratModel.fromJson(Map<String, dynamic> json, String type) {
    // Cast sûr : évite le crash si la valeur est Map<dynamic,dynamic>
    Map<String, dynamic>? toMap(dynamic v) =>
        v is Map ? Map<String, dynamic>.from(v) : null;

    return AutreContratModel(
      id:            json['id']?.toString() ?? '',
      numeroContrat: json['numero_contrat'] as String?,
      type:          type,
      statut:        json['statut'] as String?,
      generateur:    toMap(json['generateur']),
      // backend alias peut être 'autrePartie' ou 'autre_partie'
      autrePartie:   toMap(json['autrePartie']) ?? toMap(json['autre_partie']),
      // Stocker TOUT le JSON dans data : clauses, missions, info_prestataire,
      // info_partie1, pouvoirs_accordes… sont tous des DataTypes.JSON retournés
      // au top-level par le backend, pas dans un sous-objet 'data'.
      data:          Map<String, dynamic>.from(json),
      createdAt:     json['createdAt'] as String?,
    );
  }
}

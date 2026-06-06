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
    return AutreContratModel(
      id: json['id']?.toString() ?? '',
      numeroContrat: json['numero_contrat'],
      type: type,
      statut: json['statut'],
      generateur: json['generateur'] != null
          ? Map<String, dynamic>.from(json['generateur'])
          : null,
      autrePartie: json['autrePartie'] != null
          ? Map<String, dynamic>.from(json['autrePartie'])
          : (json['autre_partie'] != null
              ? Map<String, dynamic>.from(json['autre_partie'])
              : null),
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'])
          : null,
      createdAt: json['createdAt'],
    );
  }
}

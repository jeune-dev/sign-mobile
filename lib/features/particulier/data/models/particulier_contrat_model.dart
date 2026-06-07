import '../../domain/entities/particulier_contrat.dart';

class ParticulierContratModel extends ParticulierContrat {
  const ParticulierContratModel({
    required super.id,
    required super.type,
    required super.typeLabel,
    required super.numeroContrat,
    required super.statut,
    required super.peutSigner,
    required super.createdAt,
    super.generateurNom,
    super.generateurEntreprise,
    super.generateurEmail,
    required super.rawData,
  });

  factory ParticulierContratModel.fromJson(Map<String, dynamic> json) {
    // Le générateur peut être sous différents alias
    final Map<String, dynamic>? gen =
        (json['generateur'] ?? json['employeur'] ?? json['bailleur']) as Map<String, dynamic>?;

    String? genNom;
    if (gen != null) {
      final prenom = gen['prenom'] ?? '';
      final nom    = gen['nom']    ?? '';
      genNom = '$prenom $nom'.trim();
    }

    return ParticulierContratModel(
      id:                   json['id']            as String,
      type:                 json['type']          as String? ?? '',
      typeLabel:            json['typeLabel']      as String? ?? '',
      numeroContrat:        json['numero_contrat'] as String? ?? '',
      statut:               json['statut']         as String? ?? 'en_attente',
      peutSigner:           json['peutSigner']     as bool?   ?? false,
      createdAt:            json['createdAt']      as String? ?? '',
      generateurNom:        genNom,
      generateurEntreprise: gen?['nom_entreprise'] as String?,
      generateurEmail:      gen?['email']          as String?,
      rawData:              json,
    );
  }
}

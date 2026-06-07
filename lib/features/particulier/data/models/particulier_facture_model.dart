import '../../domain/entities/particulier_facture.dart';

class ParticulierFactureModel extends ParticulierFacture {
  const ParticulierFactureModel({
    required super.id,
    required super.numeroFacture,
    required super.montant,
    required super.tva,
    super.moyenPaiement,
    super.dateExecution,
    required super.createdAt,
    required super.estSignee,
    super.professionnelNom,
    super.professionnelEntreprise,
    super.professionnelEmail,
  });

  factory ParticulierFactureModel.fromJson(Map<String, dynamic> json) {
    final pro = json['professionnel'] as Map<String, dynamic>?;

    String? proNom;
    if (pro != null) {
      final prenom = pro['prenom'] ?? '';
      final nom    = pro['nom']    ?? '';
      proNom = '$prenom $nom'.trim();
    }

    return ParticulierFactureModel(
      id:                    json['id']             as String,
      numeroFacture:         json['numero_facture'] as String? ?? '',
      montant:               (json['montant'] as num?)?.toDouble() ?? 0.0,
      tva:                   (json['tva'] as num?)?.toInt()        ?? 0,
      moyenPaiement:         json['moyen_paiement'] as String?,
      dateExecution:         json['date_execution'] as String?,
      createdAt:             json['createdAt']      as String? ?? '',
      // signé = a un champ document_pdf ou on n'a pas ce champ mais il était non-null côté backend
      estSignee:             json['document_pdf'] != null,
      professionnelNom:      proNom,
      professionnelEntreprise: pro?['nom_entreprise'] as String?,
      professionnelEmail:    pro?['email']            as String?,
    );
  }
}

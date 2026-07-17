import '../../domain/entities/facture.dart';

class FactureModel extends Facture {
  const FactureModel({
    required super.id,
    super.numeroFacture,
    super.dateExecution,
    super.lieuExecution,
    required super.montant,
    required super.avance,
    super.moyenPaiement,
    super.tva,
    super.delaisExecution,
    super.items,
    super.client,
    super.statut,
    super.dateGeneration,
  });

  factory FactureModel.fromJson(Map<String, dynamic> json) {
    return FactureModel(
      id: json['id']?.toString() ?? '',
      numeroFacture: json['numero_facture'],
      dateExecution: json['date_execution'],
      lieuExecution: json['lieu_execution'],
      montant: (json['montant'] ?? 0).toDouble(),
      avance: (json['avance'] ?? 0).toDouble(),
      moyenPaiement: json['moyen_paiement'],
      tva: json['tva'],
      delaisExecution: json['delais_execution']?.toString(),
      items: json['items'],
      client: json['client'] != null ? Map<String, dynamic>.from(json['client']) : null,
      statut: json['statut']?.toString(),
      dateGeneration: (json['date_generation'] ?? json['createdAt'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'numero_facture': numeroFacture,
        'date_execution': dateExecution,
        'lieu_execution': lieuExecution,
        'montant': montant,
        'avance': avance,
        'moyen_paiement': moyenPaiement,
        'tva': tva,
      };
}

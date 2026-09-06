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
    super.direction,
    super.professionnel,
    super.dateGeneration,
    super.peutModifier,
    super.historiqueVersements,
    super.dossier,
    super.versements,
  });

  factory FactureModel.fromJson(Map<String, dynamic> json) {
    final historique = (json['historique_versements'] as List? ?? [])
        .map((e) => Versement.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final versements = (json['versements'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

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
      direction: json['direction']?.toString(),
      professionnel: json['professionnel'] != null
          ? Map<String, dynamic>.from(json['professionnel'])
          : null,
      dateGeneration: (json['date_generation'] ?? json['createdAt'])?.toString(),
      // Repli sur la direction : les anciennes versions du backend ne
      // renvoient pas `peut_modifier`, et une facture émise reste dans tous
      // les cas modifiable par son émetteur.
      peutModifier: json['peut_modifier'] as bool? ??
          (json['direction']?.toString() != 'recu'),
      historiqueVersements: historique,
      dossier: json['dossier'] != null
          ? DossierFacture.fromJson(Map<String, dynamic>.from(json['dossier']))
          : const DossierFacture(),
      versements: versements,
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

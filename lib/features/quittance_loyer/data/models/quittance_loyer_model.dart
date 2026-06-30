import '../../domain/entities/quittance_loyer.dart';

class QuittanceLoyerModel extends QuittanceLoyer {
  // Sequelize renvoie les DECIMAL en String ("150000.00") et parfois les INT en String.
  static double? _toDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static int? _toIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  const QuittanceLoyerModel({
    required super.id,
    super.numeroQuittance,
    super.adresseLogement,
    super.typeBien,
    super.mois,
    super.annee,
    super.montantLoyer,
    super.montantCharges,
    super.montantTotal,
    super.datePaiement,
    super.modePaiement,
    super.estTotal,
    super.montantPayePartiel,
    super.observations,
    super.villeEmission,
    super.dateEmission,
    super.signatureBailleur,
    super.locataire,
    super.bailleur,
    super.createdAt,
    super.direction,
  });

  factory QuittanceLoyerModel.fromJson(Map<String, dynamic> json) {
    return QuittanceLoyerModel(
      id: json['id']?.toString() ?? '',
      numeroQuittance: json['numero_quittance'],
      adresseLogement: json['adresse_logement'],
      typeBien: json['type_bien'],
      mois: json['mois'],
      annee: _toIntOrNull(json['annee']),
      montantLoyer: _toDoubleOrNull(json['montant_loyer']),
      montantCharges: _toDoubleOrNull(json['montant_charges']),
      montantTotal: _toDoubleOrNull(json['montant_total']),
      datePaiement: json['date_paiement'],
      modePaiement: json['mode_paiement'],
      estTotal: json['est_total'],
      montantPayePartiel: _toDoubleOrNull(json['montant_paye_partiel']),
      observations: json['observations'],
      villeEmission: json['ville_emission'],
      dateEmission: json['date_emission'],
      signatureBailleur: json['signature_bailleur'],
      locataire: json['locataire'] != null
          ? Map<String, dynamic>.from(json['locataire'])
          : null,
      bailleur: json['bailleur'] != null
          ? Map<String, dynamic>.from(json['bailleur'])
          : null,
      createdAt: json['createdAt'],
      direction: json['direction'],
    );
  }
}

import '../../domain/entities/quittance_loyer.dart';

class QuittanceLoyerModel extends QuittanceLoyer {
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
    super.createdAt,
  });

  factory QuittanceLoyerModel.fromJson(Map<String, dynamic> json) {
    return QuittanceLoyerModel(
      id: json['id']?.toString() ?? '',
      numeroQuittance: json['numero_quittance'],
      adresseLogement: json['adresse_logement'],
      typeBien: json['type_bien'],
      mois: json['mois'],
      annee: json['annee'],
      montantLoyer: json['montant_loyer'] != null
          ? (json['montant_loyer'] as num).toDouble()
          : null,
      montantCharges: json['montant_charges'] != null
          ? (json['montant_charges'] as num).toDouble()
          : null,
      montantTotal: json['montant_total'] != null
          ? (json['montant_total'] as num).toDouble()
          : null,
      datePaiement: json['date_paiement'],
      modePaiement: json['mode_paiement'],
      estTotal: json['est_total'],
      montantPayePartiel: json['montant_paye_partiel'] != null
          ? (json['montant_paye_partiel'] as num).toDouble()
          : null,
      observations: json['observations'],
      villeEmission: json['ville_emission'],
      dateEmission: json['date_emission'],
      signatureBailleur: json['signature_bailleur'],
      locataire: json['locataire'] != null
          ? Map<String, dynamic>.from(json['locataire'])
          : null,
      createdAt: json['createdAt'],
    );
  }
}

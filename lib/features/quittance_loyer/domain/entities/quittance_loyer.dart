import 'package:equatable/equatable.dart';

class QuittanceLoyer extends Equatable {
  final String id;
  final String? numeroQuittance;
  final String? adresseLogement;
  final String? typeBien;
  final String? mois;
  final int? annee;
  final double? montantLoyer;
  final double? montantCharges;
  final double? montantTotal;
  final String? datePaiement;
  final String? modePaiement;
  final bool? estTotal;
  final double? montantPayePartiel;
  final String? observations;
  final String? villeEmission;
  final String? dateEmission;
  final String? signatureBailleur;
  final Map<String, dynamic>? locataire;
  final String? createdAt;

  const QuittanceLoyer({
    required this.id,
    this.numeroQuittance,
    this.adresseLogement,
    this.typeBien,
    this.mois,
    this.annee,
    this.montantLoyer,
    this.montantCharges,
    this.montantTotal,
    this.datePaiement,
    this.modePaiement,
    this.estTotal,
    this.montantPayePartiel,
    this.observations,
    this.villeEmission,
    this.dateEmission,
    this.signatureBailleur,
    this.locataire,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, numeroQuittance];
}

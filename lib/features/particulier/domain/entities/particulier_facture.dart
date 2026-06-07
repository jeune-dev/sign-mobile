import 'package:equatable/equatable.dart';

class ParticulierFacture extends Equatable {
  final String id;
  final String numeroFacture;
  final double montant;
  final int tva;
  final String? moyenPaiement;
  final String? dateExecution;
  final String createdAt;
  final bool estSignee; // document_pdf != null
  final String? professionnelNom;
  final String? professionnelEntreprise;
  final String? professionnelEmail;

  const ParticulierFacture({
    required this.id,
    required this.numeroFacture,
    required this.montant,
    required this.tva,
    this.moyenPaiement,
    this.dateExecution,
    required this.createdAt,
    required this.estSignee,
    this.professionnelNom,
    this.professionnelEntreprise,
    this.professionnelEmail,
  });

  @override
  List<Object?> get props => [id, numeroFacture];
}

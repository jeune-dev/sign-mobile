import 'package:equatable/equatable.dart';

class FactureItem extends Equatable {
  final String designation;
  final int quantite;
  final double prixUnitaire;

  const FactureItem({
    required this.designation,
    required this.quantite,
    required this.prixUnitaire,
  });

  @override
  List<Object?> get props => [designation, quantite, prixUnitaire];
}

class Facture extends Equatable {
  final String id;
  final String? numeroFacture;
  final String? dateExecution;
  final String? lieuExecution;
  final double montant;
  final double avance;
  final String? moyenPaiement;
  final int? tva;
  final String? delaisExecution;
  final List<dynamic>? items;
  final Map<String, dynamic>? client;

  const Facture({
    required this.id,
    this.numeroFacture,
    this.dateExecution,
    this.lieuExecution,
    required this.montant,
    required this.avance,
    this.moyenPaiement,
    this.tva,
    this.delaisExecution,
    this.items,
    this.client,
  });

  @override
  List<Object?> get props => [id, numeroFacture];
}

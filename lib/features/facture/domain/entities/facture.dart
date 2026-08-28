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
  final String? statut; // 'en_attente' | 'partiel' | 'payee'
  /// Horodatage automatique serveur — jamais choisi depuis le mobile.
  final String? dateGeneration;

  /// 'envoye' si je suis l'émetteur, 'recu' si la facture m'est adressée.
  ///
  /// Renseigné par le backend : lui seul connaît l'utilisateur courant. Une
  /// facture reçue n'apparaissait pas du tout dans l'application, la requête
  /// ne regardant que les documents émis.
  final String? direction;

  /// L'émetteur, quand la facture m'a été adressée.
  final Map<String, dynamic>? professionnel;

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
    this.statut,
    this.direction,
    this.professionnel,
    this.dateGeneration,
  });

  bool get estRecue => direction == 'recu';

  /// La partie à afficher dans la liste : si la facture est reçue, c'est
  /// l'émetteur qui intéresse l'utilisateur, pas lui-même.
  Map<String, dynamic>? get contrepartie => estRecue ? professionnel : client;

  @override
  List<Object?> get props => [id, numeroFacture, statut, direction];
}

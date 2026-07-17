import 'package:equatable/equatable.dart';

class ContratBail extends Equatable {
  final String id;
  final String? numeroContrat;
  final String? bienAdresse;
  final String? bienVille;
  final String? bienType;
  final String? statut;
  final double? loyerMensuel;
  final String? devise;
  final String? dateDebutBail;
  final List<dynamic>? locataires;
  final Map<String, dynamic>? proprietaire;
  /// Horodatage automatique serveur de la signature (création du contrat
  /// par le bailleur) — jamais choisi depuis le mobile.
  final String? signatureDate;
  /// Taxe d'ordure ménagère — optionnelle, 3,6% du loyer mensuel si activée.
  final bool? taxeOrdureMenagere;
  final double? montantTaxeOrdure;

  const ContratBail({
    required this.id,
    this.numeroContrat,
    this.bienAdresse,
    this.bienVille,
    this.bienType,
    this.statut,
    this.loyerMensuel,
    this.devise,
    this.dateDebutBail,
    this.locataires,
    this.proprietaire,
    this.signatureDate,
    this.taxeOrdureMenagere,
    this.montantTaxeOrdure,
  });

  @override
  List<Object?> get props => [id, numeroContrat];
}

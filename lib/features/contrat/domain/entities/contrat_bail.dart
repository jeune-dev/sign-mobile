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
  });

  @override
  List<Object?> get props => [id, numeroContrat];
}

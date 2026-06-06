import 'package:equatable/equatable.dart';

class AutreContrat extends Equatable {
  final String id;
  final String? numeroContrat;
  final String type;
  final String? statut;
  final Map<String, dynamic>? generateur;
  final Map<String, dynamic>? autrePartie;
  final Map<String, dynamic>? data;
  final String? createdAt;

  const AutreContrat({
    required this.id,
    this.numeroContrat,
    required this.type,
    this.statut,
    this.generateur,
    this.autrePartie,
    this.data,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, numeroContrat, type];
}

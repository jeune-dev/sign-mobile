import 'package:equatable/equatable.dart';

class Client extends Equatable {
  final String id;
  final String nom;
  final String prenom;
  final String? email;
  final String? telephone;
  final String? adresse;
  final String? carteIdentiteNationalNum;
  final String? statut;
  final String? createdAt;
  final String? photoProfil;

  const Client({
    required this.id,
    required this.nom,
    required this.prenom,
    this.email,
    this.telephone,
    this.adresse,
    this.carteIdentiteNationalNum,
    this.statut,
    this.createdAt,
    this.photoProfil,
  });

  @override
  List<Object?> get props => [id, nom, prenom, email, telephone];
}

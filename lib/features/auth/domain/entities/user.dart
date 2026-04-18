import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String mot_de_passe;
  final String adresse;
  final String telephone;
  final String carte_identite_national_num;
  final String role;
  final String? photoProfil;
  final String? logo;
  final String? rc;
  final String? ninea;
  final String? signature;
  final String? token;

  // Champs entreprise
  final String? nomEntreprise;
  final String? adresseEntreprise;
  final String? telephoneEntreprise;
  final String? emailEntreprise;

  const User({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.mot_de_passe,
    required this.adresse,
    required this.telephone,
    required this.carte_identite_national_num,
    required this.role,
    this.photoProfil,
    this.logo,
    this.rc,
    this.ninea,
    this.signature,
    this.nomEntreprise,
    this.adresseEntreprise,
    this.telephoneEntreprise,
    this.emailEntreprise,
    this.token,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'prenom': prenom,
    'email': email,
    'mot_de_passe': mot_de_passe,
    'adresse': adresse,
    'telephone': telephone,
    'carte_identite_national_num': carte_identite_national_num,
    'role': role,
    'photoProfil': photoProfil,
    'logo': logo,
    'rc': rc,
    'ninea': ninea,
    'signature': signature,
    'nomEntreprise': nomEntreprise,
    'adresseEntreprise': adresseEntreprise,
    'telephoneEntreprise': telephoneEntreprise,
    'emailEntreprise': emailEntreprise,
    'token': token,
  };

  @override
  List<Object?> get props => [
    id,
    nom,
    prenom,
    email,
    mot_de_passe,
    adresse,
    telephone,
    carte_identite_national_num,
    role,
    photoProfil,
    logo,
    rc,
    ninea,
    signature,
    nomEntreprise,
    adresseEntreprise,
    telephoneEntreprise,
    emailEntreprise,
    token
  ];
}
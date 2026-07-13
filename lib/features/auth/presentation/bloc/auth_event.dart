import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String identifiant;
  final String mot_de_passe;

  const LoginRequested({
    required this.identifiant,
    required this.mot_de_passe,
  });

  @override
  List<Object?> get props => [identifiant, mot_de_passe];
}

class RegisterRequested extends AuthEvent {
  final String nom;
  final String prenom;
  final String email;
  final String mot_de_passe;
  final String adresse;
  final String telephone;
  final String carte_identite_national_num;
  // Type du document dont carte_identite_national_num est le numéro :
  // 'carte_identite' | 'permis' | 'passeport'. Optionnel pour ne pas
  // casser le flow si jamais absent (cohérent avec le backend, qui
  // l'accepte optionnel pour rester compatible avec les anciennes
  // versions déjà publiées sur le Play Store).
  final String? typeDocumentIdentite;
  final XFile? documentIdentite;
  final String role;
  final XFile? photoProfil;
  final XFile? logo;
  final String? rc;
  final String? ninea;
  final XFile? signature;

  // Champs entreprise ajoutés
  final String? nomEntreprise;
  final String? adresseEntreprise;
  final String? telephoneEntreprise;
  final String? emailEntreprise;

  const RegisterRequested({
    required this.nom,
    required this.prenom,
    required this.email,
    required this.mot_de_passe,
    required this.adresse,
    required this.telephone,
    required this.carte_identite_national_num,
    required this.role,
    this.typeDocumentIdentite,
    this.documentIdentite,
    this.photoProfil,
    this.logo,
    this.rc,
    this.ninea,
    this.signature,
    this.nomEntreprise,
    this.adresseEntreprise,
    this.telephoneEntreprise,
    this.emailEntreprise,
  });

  @override
  List<Object?> get props => [
    nom,
    prenom,
    email,
    mot_de_passe,
    adresse,
    telephone,
    carte_identite_national_num,
    typeDocumentIdentite,
    documentIdentite,
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
  ];
}

class LogoutRequested extends AuthEvent {}

class ResetAuthState extends AuthEvent {}

class ForgotPasswordRequested extends AuthEvent {
  final String email;
  const ForgotPasswordRequested({required this.email});
  @override
  List<Object?> get props => [email];
}

class ResetPasswordRequested extends AuthEvent {
  final String email;
  final String otpRecu;
  final String newPassword;
  const ResetPasswordRequested({
    required this.email,
    required this.otpRecu,
    required this.newPassword,
  });
  @override
  List<Object?> get props => [email, otpRecu, newPassword];
}
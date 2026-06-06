import 'package:equatable/equatable.dart';

class AccountUser extends Equatable {
  final String id;
  final String? nom;
  final String? prenom;
  final String? email;
  final String? telephone;
  final String? adresse;
  final String? role;
  final String? photoProfil;
  final String? logo;
  final String? signature;
  final String? carteIdentiteNationalNum;
  final String? rc;
  final String? ninea;
  final String? nomEntreprise;
  final String? adresseEntreprise;
  final String? telephoneEntreprise;
  final String? emailEntreprise;
  final String? statut;

  const AccountUser({
    required this.id,
    this.nom,
    this.prenom,
    this.email,
    this.telephone,
    this.adresse,
    this.role,
    this.photoProfil,
    this.logo,
    this.signature,
    this.carteIdentiteNationalNum,
    this.rc,
    this.ninea,
    this.nomEntreprise,
    this.adresseEntreprise,
    this.telephoneEntreprise,
    this.emailEntreprise,
    this.statut,
  });

  String get fullName {
    final p = prenom?.trim() ?? '';
    final n = nom?.trim() ?? '';
    if (p.isNotEmpty && n.isNotEmpty) return '$p $n';
    if (p.isNotEmpty) return p;
    if (n.isNotEmpty) return n;
    return 'Utilisateur';
  }

  @override
  List<Object?> get props => [id, nom, prenom, email, role];
}

abstract class AccountEvent {}

class LoadMe extends AccountEvent {}

class ModifierInfoPersonnellesEvent extends AccountEvent {
  final String? nom;
  final String? prenom;
  final String? email;
  final String? telephone;
  final String? adresse;
  final String? carteIdentiteNationalNum;
  final String? rc;
  final String? ninea;
  final String? nomEntreprise;
  final String? adresseEntreprise;
  final String? telephoneEntreprise;
  final String? emailEntreprise;
  final String? photoProfilPath;
  final String? logoPath;
  final String? signaturePath;

  ModifierInfoPersonnellesEvent({
    this.nom,
    this.prenom,
    this.email,
    this.telephone,
    this.adresse,
    this.carteIdentiteNationalNum,
    this.rc,
    this.ninea,
    this.nomEntreprise,
    this.adresseEntreprise,
    this.telephoneEntreprise,
    this.emailEntreprise,
    this.photoProfilPath,
    this.logoPath,
    this.signaturePath,
  });
}

class ChangePasswordEvent extends AccountEvent {
  final String oldPassword;
  final String newPassword;
  ChangePasswordEvent({required this.oldPassword, required this.newPassword});
}

class ResetAccountState extends AccountEvent {}

class DeleteAccountEvent extends AccountEvent {}

import '../../domain/entities/account_user.dart';

class AccountUserModel extends AccountUser {
  const AccountUserModel({
    required super.id,
    super.nom,
    super.prenom,
    super.email,
    super.telephone,
    super.adresse,
    super.role,
    super.photoProfil,
    super.logo,
    super.signature,
    super.carteIdentiteNationalNum,
    super.rc,
    super.ninea,
    super.nomEntreprise,
    super.adresseEntreprise,
    super.telephoneEntreprise,
    super.emailEntreprise,
    super.statut,
  });

  factory AccountUserModel.fromJson(Map<String, dynamic> json) {
    return AccountUserModel(
      id: json['id']?.toString() ?? '',
      nom: json['nom'],
      prenom: json['prenom'],
      email: json['email'],
      telephone: json['telephone'],
      adresse: json['adresse'],
      role: json['role'],
      photoProfil: json['photoProfil'],
      logo: json['logo'],
      signature: json['signature'],
      carteIdentiteNationalNum: json['carte_identite_national_num'],
      rc: json['rc'],
      ninea: json['ninea'],
      nomEntreprise: json['nomEntreprise'],
      adresseEntreprise: json['adresseEntreprise'],
      telephoneEntreprise: json['telephoneEntreprise'],
      emailEntreprise: json['emailEntreprise'],
      statut: json['statut'],
    );
  }
}

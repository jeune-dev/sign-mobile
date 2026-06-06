import '../../domain/entities/client.dart';

class ClientModel extends Client {
  const ClientModel({
    required super.id,
    required super.nom,
    required super.prenom,
    super.email,
    super.telephone,
    super.adresse,
    super.carteIdentiteNationalNum,
    super.statut,
    super.createdAt,
    super.photoProfil,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id']?.toString() ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'],
      telephone: json['telephone'],
      adresse: json['adresse'],
      carteIdentiteNationalNum: json['carte_identite_national_num'],
      statut: json['statut'],
      createdAt: json['createdAt'],
      photoProfil: json['photoProfil'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'telephone': telephone,
        'adresse': adresse,
        'carte_identite_national_num': carteIdentiteNationalNum,
        'statut': statut,
      };
}

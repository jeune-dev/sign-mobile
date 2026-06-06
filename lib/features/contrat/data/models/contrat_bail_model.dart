import '../../domain/entities/contrat_bail.dart';

class ContratBailModel extends ContratBail {
  const ContratBailModel({
    required super.id,
    super.numeroContrat,
    super.bienAdresse,
    super.bienVille,
    super.bienType,
    super.statut,
    super.loyerMensuel,
    super.devise,
    super.dateDebutBail,
    super.locataires,
    super.proprietaire,
  });

  factory ContratBailModel.fromJson(Map<String, dynamic> json) {
    return ContratBailModel(
      id: json['id']?.toString() ?? '',
      numeroContrat: json['numero_contrat'],
      bienAdresse: json['bien_adresse'],
      bienVille: json['bien_ville'],
      bienType: json['bien_type'],
      statut: json['statut'],
      loyerMensuel: json['loyer_mensuel'] != null
          ? double.tryParse(json['loyer_mensuel'].toString())
          : null,
      devise: json['devise'],
      dateDebutBail: json['date_debut_bail'],
      locataires: json['locataires'],
      proprietaire: json['proprietaire'] != null
          ? Map<String, dynamic>.from(json['proprietaire'])
          : null,
    );
  }
}

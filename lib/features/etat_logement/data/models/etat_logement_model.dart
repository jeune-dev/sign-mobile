import '../../domain/entities/etat_logement.dart';

class PieceEtatModel extends PieceEtat {
  const PieceEtatModel({
    required super.nom,
    super.etatSol,
    super.etatMurs,
    super.etatPlafond,
    super.etatFenetres,
    super.etatPortes,
    super.etatElectricite,
    super.etatEclairage,
    super.proprete,
    super.humidite,
    super.degradations,
    super.observations,
    super.photos,
  });

  factory PieceEtatModel.fromJson(Map<String, dynamic> json) {
    return PieceEtatModel(
      nom: json['nom']?.toString() ?? 'Pièce',
      etatSol: json['etat_sol'],
      etatMurs: json['etat_murs'],
      etatPlafond: json['etat_plafond'],
      etatFenetres: json['etat_fenetres'],
      etatPortes: json['etat_portes'],
      etatElectricite: json['etat_electricite'],
      etatEclairage: json['etat_eclairage'],
      proprete: json['proprete'],
      humidite: json['humidite'] == true,
      degradations: json['degradations'] == true,
      observations: json['observations'],
      photos: json['photos'] is List
          ? List<String>.from((json['photos'] as List).map((e) => e.toString()))
          : const [],
    );
  }
}

class EtatLogementModel extends EtatLogement {
  const EtatLogementModel({
    required super.id,
    super.numeroEtatDesLieux,
    super.contratId,
    super.dateEtatDesLieux,
    super.heureVisite,
    super.observationsGenerales,
    super.nombreSalons,
    super.nombreChambres,
    super.nombreCuisines,
    super.nombreSallesBain,
    super.nombreWc,
    super.nombreBalcons,
    super.autresPieces,
    super.pieces,
    super.signatureBailleur,
    super.signatureLocataire,
    super.dateSignature,
    super.statut,
    super.createdAt,
    super.contratNumero,
    super.bienAdresse,
    super.bienVille,
  });

  factory EtatLogementModel.fromJson(Map<String, dynamic> json) {
    // Le contrat associé peut être renvoyé sous la clé 'Contrat' (include Sequelize)
    final contrat = json['Contrat'] is Map
        ? Map<String, dynamic>.from(json['Contrat'])
        : null;

    int asInt(dynamic v) =>
        v == null ? 0 : (v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0);

    return EtatLogementModel(
      id: json['id']?.toString() ?? '',
      numeroEtatDesLieux: json['numero_etat_des_lieux'],
      contratId: json['contratId']?.toString(),
      dateEtatDesLieux: json['date_etat_des_lieux'],
      heureVisite: json['heure_visite'],
      observationsGenerales: json['observations_generales'],
      nombreSalons: asInt(json['nombre_salons']),
      nombreChambres: asInt(json['nombre_chambres']),
      nombreCuisines: asInt(json['nombre_cuisines']),
      nombreSallesBain: asInt(json['nombre_salles_bain']),
      nombreWc: asInt(json['nombre_wc']),
      nombreBalcons: asInt(json['nombre_balcons']),
      autresPieces: json['autres_pieces'] is List
          ? List<String>.from(
              (json['autres_pieces'] as List).map((e) => e.toString()))
          : const [],
      pieces: json['pieces'] is List
          ? (json['pieces'] as List)
              .whereType<Map>()
              .map((e) => PieceEtatModel.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      signatureBailleur: json['signature_bailleur'],
      signatureLocataire: json['signature_locataire'],
      dateSignature: json['date_signature'],
      statut: json['statut'],
      createdAt: json['createdAt'],
      contratNumero: contrat?['numero_contrat'],
      bienAdresse: contrat?['bien_adresse'],
      bienVille: contrat?['bien_ville'],
    );
  }
}

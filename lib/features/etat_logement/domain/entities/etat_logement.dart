import 'package:equatable/equatable.dart';

/// État d'une pièce inspectée lors de l'état des lieux.
class PieceEtat extends Equatable {
  final String nom;
  final String? etatSol;
  final String? etatMurs;
  final String? etatPlafond;
  final String? etatFenetres;
  final String? etatPortes;
  final String? etatElectricite;
  final String? etatEclairage;
  final String? proprete;
  final bool humidite;
  final bool degradations;
  final String? observations;
  final List<String> photos;

  const PieceEtat({
    required this.nom,
    this.etatSol,
    this.etatMurs,
    this.etatPlafond,
    this.etatFenetres,
    this.etatPortes,
    this.etatElectricite,
    this.etatEclairage,
    this.proprete,
    this.humidite = false,
    this.degradations = false,
    this.observations,
    this.photos = const [],
  });

  /// Sérialisation vers le format attendu par le backend (snake_case).
  Map<String, dynamic> toJson() => {
        'nom': nom,
        'etat_sol': etatSol,
        'etat_murs': etatMurs,
        'etat_plafond': etatPlafond,
        'etat_fenetres': etatFenetres,
        'etat_portes': etatPortes,
        'etat_electricite': etatElectricite,
        'etat_eclairage': etatEclairage,
        'proprete': proprete,
        'humidite': humidite,
        'degradations': degradations,
        'observations': observations ?? '',
        'photos': photos,
      };

  @override
  List<Object?> get props => [
        nom,
        etatSol,
        etatMurs,
        etatPlafond,
        etatFenetres,
        etatPortes,
        etatElectricite,
        etatEclairage,
        proprete,
        humidite,
        degradations,
        observations,
        photos,
      ];
}

/// État des lieux d'un logement, rattaché à un contrat de bail.
class EtatLogement extends Equatable {
  final String id;
  final String? numeroEtatDesLieux;
  final String? contratId;
  final String? dateEtatDesLieux;
  final String? heureVisite;
  final String? observationsGenerales;
  final int nombreSalons;
  final int nombreChambres;
  final int nombreCuisines;
  final int nombreSallesBain;
  final int nombreWc;
  final int nombreBalcons;
  final List<String> autresPieces;
  final List<PieceEtat> pieces;
  final String? signatureBailleur;
  final String? signatureLocataire;
  final String? dateSignature;
  final String? statut;
  final String? createdAt;

  // Infos du contrat associé (présentes dans la liste via l'include Sequelize)
  final String? contratNumero;
  final String? bienAdresse;
  final String? bienVille;

  const EtatLogement({
    required this.id,
    this.numeroEtatDesLieux,
    this.contratId,
    this.dateEtatDesLieux,
    this.heureVisite,
    this.observationsGenerales,
    this.nombreSalons = 0,
    this.nombreChambres = 0,
    this.nombreCuisines = 0,
    this.nombreSallesBain = 0,
    this.nombreWc = 0,
    this.nombreBalcons = 0,
    this.autresPieces = const [],
    this.pieces = const [],
    this.signatureBailleur,
    this.signatureLocataire,
    this.dateSignature,
    this.statut,
    this.createdAt,
    this.contratNumero,
    this.bienAdresse,
    this.bienVille,
  });

  bool get estSigne => statut == 'signe' || statut == 'termine';

  @override
  List<Object?> get props => [id, numeroEtatDesLieux, statut];
}

import 'package:equatable/equatable.dart';

class ContratTravail extends Equatable {
  final String id;
  final String? numeroContrat;
  final String? poste;
  final List<dynamic>? missions;
  final String? lieuTravail;
  final String? typeContrat;
  final List<dynamic>? jourTravail; // [{jour, debut, fin}, ...]
  final String? heureDebut;
  final String? heureFin;
  final String? tempsPause;
  final String? dateDebut;
  final String? dateFin;
  final double? salaireMensuel;
  final String? moyenPaiement;
  final int? nbrJoursConges;
  final String? remunerationJoursFeries;
  final String? remunerationAbsencesMaladie;
  final bool? avanceSalaire;
  final dynamic avantagesSalarial;
  final String? dureePreavis;
  final dynamic assuranceMaladie;
  final dynamic clauses;
  final String? dateSignature;
  final String? lieuSignature;
  final String? signatureEmployeur;
  final String? signatureSalarie;
  final String? statut;
  final Map<String, dynamic>? salarie;
  final String? createdAt;

  /// L'employeur, quand le contrat m'a ete adresse en tant que salarie.
  final Map<String, dynamic>? employeur;

  /// 'envoye' si je suis l'employeur, 'recu' si le contrat m'est adresse.
  ///
  /// Renseigne par le backend : lui seul connait l'utilisateur courant. La
  /// requete ne regardait que le cote employeur, un contrat recu en tant que
  /// salarie n'apparaissait donc pas.
  final String? direction;

  const ContratTravail({
    required this.id,
    this.numeroContrat,
    this.poste,
    this.missions,
    this.lieuTravail,
    this.typeContrat,
    this.jourTravail,
    this.heureDebut,
    this.heureFin,
    this.tempsPause,
    this.dateDebut,
    this.dateFin,
    this.salaireMensuel,
    this.moyenPaiement,
    this.nbrJoursConges,
    this.remunerationJoursFeries,
    this.remunerationAbsencesMaladie,
    this.avanceSalaire,
    this.avantagesSalarial,
    this.dureePreavis,
    this.assuranceMaladie,
    this.clauses,
    this.dateSignature,
    this.lieuSignature,
    this.signatureEmployeur,
    this.signatureSalarie,
    this.statut,
    this.salarie,
    this.createdAt,
    this.employeur,
    this.direction,
  });

  bool get estRecu => direction == 'recu';

  /// La partie a afficher : si le contrat est recu, c'est l'employeur qui
  /// interesse l'utilisateur, pas lui-meme.
  Map<String, dynamic>? get contrepartie => estRecu ? employeur : salarie;

  @override
  List<Object?> get props => [id, numeroContrat, direction];
}

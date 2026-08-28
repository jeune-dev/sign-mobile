import 'package:equatable/equatable.dart';

class ContratBail extends Equatable {
  final String id;
  final String? numeroContrat;
  final String? bienAdresse;
  final String? bienVille;
  final String? bienType;
  final String? statut;
  final double? loyerMensuel;
  final String? devise;
  final String? dateDebutBail;
  final List<dynamic>? locataires;
  final Map<String, dynamic>? proprietaire;

  /// 'envoye' si je suis a l'origine du document, 'recu' s'il m'est adresse.
  ///
  /// Renseigne par le backend : lui seul connait l'utilisateur courant. Sans
  /// cette information, un document recu se confondait avec un document emis.
  final String? direction;


  const ContratBail({
    required this.id,
    this.numeroContrat,
    this.bienAdresse,
    this.bienVille,
    this.bienType,
    this.statut,
    this.loyerMensuel,
    this.devise,
    this.dateDebutBail,
    this.locataires,
    this.proprietaire,
    this.direction,
  });

  bool get estRecu => direction == 'recu';

  @override
  List<Object?> get props => [id, numeroContrat, direction];
}

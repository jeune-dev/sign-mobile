import 'package:equatable/equatable.dart';

class AutreContrat extends Equatable {
  final String id;
  final String? numeroContrat;
  final String type;
  final String? statut;
  final Map<String, dynamic>? generateur;
  final Map<String, dynamic>? autrePartie;
  final Map<String, dynamic>? data;
  final String? createdAt;

  /// 'envoye' si je suis a l'origine du document, 'recu' s'il m'est adresse.
  ///
  /// Renseigne par le backend : lui seul connait l'utilisateur courant. Sans
  /// cette information, un document recu se confondait avec un document emis.
  final String? direction;


  const AutreContrat({
    required this.id,
    this.numeroContrat,
    required this.type,
    this.statut,
    this.generateur,
    this.autrePartie,
    this.data,
    this.createdAt,
    this.direction,
  });

  bool get estRecu => direction == 'recu';

  /// La partie a afficher : si le contrat est recu, c'est l'emetteur
  /// qui interesse l'utilisateur, pas lui-meme.
  Map<String, dynamic>? get contrepartie => estRecu ? generateur : autrePartie;

  @override
  List<Object?> get props => [id, numeroContrat, type, direction];
}

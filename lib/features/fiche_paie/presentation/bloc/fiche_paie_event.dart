import 'package:equatable/equatable.dart';
import '../../domain/entities/fiche_paie.dart';

abstract class FichePaieEvent extends Equatable {
  const FichePaieEvent();

  @override
  List<Object?> get props => [];
}

class CreerFichePaieEvent extends FichePaieEvent {
  final FichePaie fiche;

  /// Informations de l'emetteur saisies dans le formulaire. Facultatives :
  /// le backend retombe sur le profil si elles manquent.
  final Map<String, dynamic>? emetteur;

  const CreerFichePaieEvent(this.fiche, {this.emetteur});

  @override
  List<Object?> get props => [fiche, emetteur];
}

class LoadFichesPaieEvent extends FichePaieEvent {
  final int page;
  final int limit;
  const LoadFichesPaieEvent({this.page = 1, this.limit = 10});

  @override
  List<Object?> get props => [page, limit];
}

class LoadMoreFichesPaieEvent extends FichePaieEvent {}

class TelechargerFichePaieEvent extends FichePaieEvent {
  final String ficheId;
  final String titre;
  // 'view' = ouvrir dans le lecteur PDF ; 'download' = enregistrer dans Téléchargements
  final String mode;
  const TelechargerFichePaieEvent({required this.ficheId, required this.titre, this.mode = 'view'});

  @override
  List<Object?> get props => [ficheId, titre, mode];
}

import 'package:equatable/equatable.dart';
import '../../domain/entities/fiche_paie.dart';

abstract class FichePaieEvent extends Equatable {
  const FichePaieEvent();

  @override
  List<Object?> get props => [];
}

class CreerFichePaieEvent extends FichePaieEvent {
  final FichePaie fiche;
  const CreerFichePaieEvent(this.fiche);

  @override
  List<Object?> get props => [fiche];
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
  const TelechargerFichePaieEvent({required this.ficheId, required this.titre});

  @override
  List<Object?> get props => [ficheId, titre];
}

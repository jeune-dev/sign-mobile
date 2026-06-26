import '../../domain/entities/etat_logement.dart';

abstract class EtatLogementState {}

class EtatLogementInitial extends EtatLogementState {}

class EtatLogementLoading extends EtatLogementState {}

class EtatsLogementLoaded extends EtatLogementState {
  final List<EtatLogement> etats;
  EtatsLogementLoaded(this.etats);
}

class EtatLogementDetailLoaded extends EtatLogementState {
  final EtatLogement etat;
  EtatLogementDetailLoaded(this.etat);
}

class EtatLogementSuccess extends EtatLogementState {
  final String message;
  EtatLogementSuccess({this.message = 'Opération réussie'});
}

class EtatLogementBytes extends EtatLogementState {
  final List<int> bytes;
  final String etatId;
  final String titre;
  EtatLogementBytes({required this.bytes, required this.etatId, this.titre = ''});
}

class EtatLogementError extends EtatLogementState {
  final String message;
  EtatLogementError(this.message);
}

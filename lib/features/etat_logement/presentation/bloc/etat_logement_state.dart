import '../../domain/entities/etat_logement.dart';
import 'package:sign_application/core/models/document_cree.dart';

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

  /// Etat des lieux tout juste cree. Null pour une signature.
  final DocumentCree? documentCree;

  EtatLogementSuccess({this.message = 'Opération réussie', this.documentCree});
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

import 'package:equatable/equatable.dart';
import '../../domain/entities/fiche_paie.dart';

abstract class FichePaieEvent extends Equatable {
  const FichePaieEvent();

  @override
  List<Object?> get props => [];
}

/// CREATE fiche de paie
class CreerFichePaieEvent extends FichePaieEvent {
  final FichePaie fiche;

  const CreerFichePaieEvent(this.fiche);

  @override
  List<Object?> get props => [fiche];
}
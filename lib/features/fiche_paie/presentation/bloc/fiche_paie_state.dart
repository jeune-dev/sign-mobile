import 'package:equatable/equatable.dart';
import '../../domain/entities/fiche_paie.dart';

abstract class FichePaieState extends Equatable {
  const FichePaieState();

  @override
  List<Object?> get props => [];
}

/// Initial
class FichePaieInitial extends FichePaieState {}

/// Loading
class FichePaieLoading extends FichePaieState {}

/// Success
class FichePaieSuccess extends FichePaieState {
  final FichePaie fiche;

  const FichePaieSuccess(this.fiche);

  @override
  List<Object?> get props => [fiche];
}

/// Error
class FichePaieError extends FichePaieState {
  final String message;

  const FichePaieError(this.message);

  @override
  List<Object?> get props => [message];
}
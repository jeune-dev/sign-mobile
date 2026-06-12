import 'package:equatable/equatable.dart';
import '../../domain/entities/fiche_paie.dart';

abstract class FichePaieState extends Equatable {
  const FichePaieState();

  @override
  List<Object?> get props => [];
}

class FichePaieInitial extends FichePaieState {}

class FichePaieLoading extends FichePaieState {}

class FichesPaieLoaded extends FichePaieState {
  final List<FichePaie> fiches;
  final bool hasMore;
  final bool isRefreshing;

  const FichesPaieLoaded({
    required this.fiches,
    this.hasMore = true,
    this.isRefreshing = false,
  });

  FichesPaieLoaded copyWith({
    List<FichePaie>? fiches,
    bool? hasMore,
    bool? isRefreshing,
  }) =>
      FichesPaieLoaded(
        fiches:       fiches       ?? this.fiches,
        hasMore:      hasMore      ?? this.hasMore,
        isRefreshing: isRefreshing ?? this.isRefreshing,
      );

  @override
  List<Object?> get props => [fiches, hasMore, isRefreshing];
}

class FichePaieSuccess extends FichePaieState {
  final FichePaie fiche;
  const FichePaieSuccess(this.fiche);

  @override
  List<Object?> get props => [fiche];
}

class FichePaieBytes extends FichePaieState {
  final List<int> bytes;
  final String titre;
  const FichePaieBytes({required this.bytes, required this.titre});

  @override
  List<Object?> get props => [bytes, titre];
}

class FichePaieError extends FichePaieState {
  final String message;
  const FichePaieError(this.message);

  @override
  List<Object?> get props => [message];
}

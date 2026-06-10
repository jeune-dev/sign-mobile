import 'package:sign_application/features/contrat_travail/domain/entities/contrat_travail.dart';

abstract class ContratTravailState {}

class ContratTravailInitial extends ContratTravailState {}

class ContratTravailLoading extends ContratTravailState {}

class ContratsTravailLoaded extends ContratTravailState {
  final List<ContratTravail> contrats;
  final bool hasMore;
  final bool isRefreshing;
  ContratsTravailLoaded({required this.contrats, this.hasMore = true, this.isRefreshing = false});

  ContratsTravailLoaded copyWith({List<ContratTravail>? contrats, bool? hasMore, bool? isRefreshing}) =>
      ContratsTravailLoaded(
        contrats:     contrats     ?? this.contrats,
        hasMore:      hasMore      ?? this.hasMore,
        isRefreshing: isRefreshing ?? this.isRefreshing,
      );
}

class ContratTravailDetailLoaded extends ContratTravailState {
  final ContratTravail contrat;
  ContratTravailDetailLoaded(this.contrat);
}

class ContratTravailSuccess extends ContratTravailState {
  final String message;
  ContratTravailSuccess({this.message = 'Opération réussie'});
}

class ContratTravailBytes extends ContratTravailState {
  final List<int> bytes;
  final String contratId;
  final String titre;
  ContratTravailBytes({required this.bytes, required this.contratId, this.titre = ''});
}

class ContratTravailError extends ContratTravailState {
  final String message;
  ContratTravailError(this.message);
}

class ContratTravailStatsLoaded extends ContratTravailState {
  final int total;
  final int signes;
  final int enAttente;
  ContratTravailStatsLoaded({required this.total, required this.signes, required this.enAttente});
}

class ContratTravailStatsLoading extends ContratTravailState {}

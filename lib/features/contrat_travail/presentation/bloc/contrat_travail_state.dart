import 'package:sign_application/features/contrat_travail/domain/entities/contrat_travail.dart';

abstract class ContratTravailState {}

class ContratTravailInitial extends ContratTravailState {}

class ContratTravailLoading extends ContratTravailState {}

class ContratsTravailLoaded extends ContratTravailState {
  final List<ContratTravail> contrats;
  final bool hasMore;
  ContratsTravailLoaded({required this.contrats, this.hasMore = true});
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
  ContratTravailBytes({required this.bytes, required this.contratId});
}

class ContratTravailError extends ContratTravailState {
  final String message;
  ContratTravailError(this.message);
}

import 'package:sign_application/features/contrat/domain/entities/contrat_bail.dart';

abstract class ContratState {}

class ContratInitial extends ContratState {}

class ContratLoading extends ContratState {}

class ContratsLoaded extends ContratState {
  final List<ContratBail> contrats;
  final bool hasMore;
  ContratsLoaded({required this.contrats, this.hasMore = true});
}

class ContratSuccess extends ContratState {
  final String message;
  ContratSuccess({this.message = 'Opération réussie'});
}

class ContratBytes extends ContratState {
  final List<int> bytes;
  final String contratId;
  ContratBytes({required this.bytes, required this.contratId});
}

class ContratError extends ContratState {
  final String message;
  ContratError(this.message);
}

import 'package:sign_application/features/autres_contrats/domain/entities/autre_contrat.dart';

abstract class AutresContratsState {}

class AutresContratsInitial extends AutresContratsState {}

class AutresContratsLoading extends AutresContratsState {}

class AutresContratsListLoaded extends AutresContratsState {
  final String type;
  final List<AutreContrat> contrats;
  final bool isRefreshing;
  AutresContratsListLoaded({required this.type, required this.contrats, this.isRefreshing = false});
}

class AutresContratsDetailLoaded extends AutresContratsState {
  final AutreContrat contrat;
  AutresContratsDetailLoaded(this.contrat);
}

class AutresContratsSuccess extends AutresContratsState {
  final String message;
  AutresContratsSuccess({this.message = 'Opération réussie'});
}

class AutresContratsBytes extends AutresContratsState {
  final List<int> bytes;
  final String id;
  final String titre;
  AutresContratsBytes({required this.bytes, required this.id, this.titre = ''});
}

class AutresContratsError extends AutresContratsState {
  final String message;
  AutresContratsError(this.message);
}

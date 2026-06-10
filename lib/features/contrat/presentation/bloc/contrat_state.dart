import 'package:sign_application/features/contrat/domain/entities/contrat_bail.dart';

abstract class ContratState {}

class ContratInitial extends ContratState {}

class ContratLoading extends ContratState {}

class ContratsLoaded extends ContratState {
  final List<ContratBail> contrats;
  final bool hasMore;
  final bool isRefreshing;
  ContratsLoaded({required this.contrats, this.hasMore = true, this.isRefreshing = false});

  ContratsLoaded copyWith({List<ContratBail>? contrats, bool? hasMore, bool? isRefreshing}) =>
      ContratsLoaded(
        contrats:     contrats     ?? this.contrats,
        hasMore:      hasMore      ?? this.hasMore,
        isRefreshing: isRefreshing ?? this.isRefreshing,
      );
}

class ContratSuccess extends ContratState {
  final String message;
  ContratSuccess({this.message = 'Opération réussie'});
}

class ContratBytes extends ContratState {
  final List<int> bytes;
  final String contratId;
  final String titre;
  ContratBytes({required this.bytes, required this.contratId, this.titre = ''});
}

class ContratError extends ContratState {
  final String message;
  ContratError(this.message);
}

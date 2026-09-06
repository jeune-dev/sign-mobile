import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/dossier_client.dart';
import '../../domain/usecases/get_dossier_client.dart';

/// Bloc dédié à la fiche d'un client.
///
/// Séparé de `ClientBloc` à dessein : celui-ci porte la liste des clients, et
/// ouvrir une fiche depuis la liste le ferait passer par un état de
/// chargement — au retour, la liste serait vide et devrait se recharger.
abstract class DossierClientEvent {}

class ChargerDossierClient extends DossierClientEvent {
  final String clientId;
  ChargerDossierClient(this.clientId);
}

abstract class DossierClientState {}

class DossierClientInitial extends DossierClientState {}

class DossierClientLoading extends DossierClientState {}

class DossierClientLoaded extends DossierClientState {
  final DossierClient dossier;
  DossierClientLoaded(this.dossier);
}

class DossierClientError extends DossierClientState {
  final String message;
  DossierClientError(this.message);
}

class DossierClientBloc extends Bloc<DossierClientEvent, DossierClientState> {
  final GetDossierClient getDossierClient;

  DossierClientBloc({required this.getDossierClient})
      : super(DossierClientInitial()) {
    on<ChargerDossierClient>((event, emit) async {
      emit(DossierClientLoading());
      final result = await getDossierClient(event.clientId);
      result.fold(
        (failure) => emit(DossierClientError(failure.errorMessage)),
        (dossier) => emit(DossierClientLoaded(dossier)),
      );
    });
  }
}

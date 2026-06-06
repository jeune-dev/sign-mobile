import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_clients.dart';
import '../../domain/usecases/rechercher_clients.dart';
import '../../domain/usecases/ajouter_client.dart';
import 'client_event.dart';
import 'client_state.dart';

class ClientBloc extends Bloc<ClientEvent, ClientState> {
  final GetClients getClients;
  final RechercherClients rechercherClients;
  final AjouterClient ajouterClient;

  ClientBloc({
    required this.getClients,
    required this.rechercherClients,
    required this.ajouterClient,
  }) : super(ClientInitial()) {
    on<LoadClients>(_onLoadClients);
    on<RechercherClientsEvent>(_onRechercherClients);
    on<AjouterClientEvent>(_onAjouterClient);
    on<ResetClientState>((_, emit) => emit(ClientInitial()));
  }

  Future<void> _onLoadClients(
    LoadClients event,
    Emitter<ClientState> emit,
  ) async {
    emit(ClientLoading());
    final result = await getClients();
    result.fold(
      (failure) => emit(ClientError(failure.errorMessage)),
      (clients) => emit(ClientsLoaded(clients: clients, total: clients.length)),
    );
  }

  Future<void> _onRechercherClients(
    RechercherClientsEvent event,
    Emitter<ClientState> emit,
  ) async {
    emit(ClientLoading());
    final result = await rechercherClients(event.query);
    result.fold(
      (failure) => emit(ClientError(failure.errorMessage)),
      (clients) => emit(ClientsRechercheLoaded(clients)),
    );
  }

  Future<void> _onAjouterClient(
    AjouterClientEvent event,
    Emitter<ClientState> emit,
  ) async {
    emit(ClientLoading());
    final result = await ajouterClient(
      nom: event.nom,
      prenom: event.prenom,
      email: event.email,
      motDePasse: event.motDePasse,
      telephone: event.telephone,
      adresse: event.adresse,
      carteIdentiteNationalNum: event.carteIdentiteNationalNum,
    );
    result.fold(
      (failure) => emit(ClientError(failure.errorMessage)),
      (_) => emit(ClientSuccess(message: 'Client ajouté avec succès')),
    );
  }
}

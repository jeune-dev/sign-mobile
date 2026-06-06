import 'package:sign_application/features/client/domain/entities/client.dart';

abstract class ClientState {}

class ClientInitial extends ClientState {}

class ClientLoading extends ClientState {}

class ClientsLoaded extends ClientState {
  final List<Client> clients;
  final int total;
  ClientsLoaded({required this.clients, required this.total});
}

class ClientsRechercheLoaded extends ClientState {
  final List<Client> clients;
  ClientsRechercheLoaded(this.clients);
}

class ClientSuccess extends ClientState {
  final String message;
  ClientSuccess({this.message = 'Opération réussie'});
}

class ClientError extends ClientState {
  final String message;
  ClientError(this.message);
}

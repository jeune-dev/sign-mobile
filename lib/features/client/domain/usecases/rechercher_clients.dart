import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../entities/client.dart';
import '../repositories/client_repository.dart';

class RechercherClients {
  final ClientRepository repository;
  RechercherClients(this.repository);

  Future<Either<Failure, List<Client>>> call(String query) =>
      repository.rechercherClients(query);
}

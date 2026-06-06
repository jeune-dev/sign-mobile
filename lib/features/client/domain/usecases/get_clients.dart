import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../entities/client.dart';
import '../repositories/client_repository.dart';

class GetClients {
  final ClientRepository repository;
  GetClients(this.repository);

  Future<Either<Failure, List<Client>>> call() => repository.getClients();
}

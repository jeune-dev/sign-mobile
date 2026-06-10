import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../repositories/contrat_travail_repository.dart';

class GetStatsTravail {
  final ContratTravailRepository repository;
  GetStatsTravail(this.repository);

  Future<Either<Failure, Map<String, int>>> call() => repository.getStatsTravail();
}

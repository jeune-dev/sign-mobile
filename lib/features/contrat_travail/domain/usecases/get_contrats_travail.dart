import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../entities/contrat_travail.dart';
import '../repositories/contrat_travail_repository.dart';

class GetContratsTravail {
  final ContratTravailRepository repository;
  GetContratsTravail(this.repository);

  Future<Either<Failure, List<ContratTravail>>> call({int page = 1, int limit = 10}) =>
      repository.getContratsTravail(page: page, limit: limit);
}

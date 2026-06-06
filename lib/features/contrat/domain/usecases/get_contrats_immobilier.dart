import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../entities/contrat_bail.dart';
import '../repositories/contrat_repository.dart';

class GetContratsImmobilier {
  final ContratRepository repository;
  GetContratsImmobilier(this.repository);

  Future<Either<Failure, List<ContratBail>>> call({int page = 1, int limit = 10}) =>
      repository.getContratsImmobilier(page: page, limit: limit);
}

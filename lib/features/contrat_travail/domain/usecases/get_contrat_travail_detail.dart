import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../entities/contrat_travail.dart';
import '../repositories/contrat_travail_repository.dart';

class GetContratTravailDetail {
  final ContratTravailRepository repository;
  GetContratTravailDetail(this.repository);

  Future<Either<Failure, ContratTravail>> call(String contratId) =>
      repository.getContratTravailDetail(contratId);
}

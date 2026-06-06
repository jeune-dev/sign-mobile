import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../repositories/contrat_travail_repository.dart';

class CreerContratTravail {
  final ContratTravailRepository repository;
  CreerContratTravail(this.repository);

  Future<Either<Failure, void>> call(Map<String, dynamic> data) =>
      repository.creerContratTravail(data);
}

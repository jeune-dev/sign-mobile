import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../repositories/contrat_travail_repository.dart';

class SignerContratTravail {
  final ContratTravailRepository repository;
  SignerContratTravail(this.repository);

  Future<Either<Failure, void>> call(String contratId, String signature) =>
      repository.signerContratTravail(contratId, signature);
}

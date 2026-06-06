import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../repositories/autre_contrat_repository.dart';

class SignerAutreContrat {
  final AutreContratRepository repository;
  SignerAutreContrat(this.repository);

  Future<Either<Failure, void>> call(String type, String id, String signature) =>
      repository.signerContrat(type, id, signature);
}

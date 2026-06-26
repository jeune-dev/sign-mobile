import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../repositories/etat_logement_repository.dart';

class SignerEtatLogement {
  final EtatLogementRepository repository;
  SignerEtatLogement(this.repository);

  Future<Either<Failure, void>> call(String etatId, String signature) =>
      repository.signerEtatLogement(etatId, signature);
}

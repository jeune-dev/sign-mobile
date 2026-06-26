import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../entities/etat_logement.dart';
import '../repositories/etat_logement_repository.dart';

class GetEtatsLogement {
  final EtatLogementRepository repository;
  GetEtatsLogement(this.repository);

  Future<Either<Failure, List<EtatLogement>>> call() =>
      repository.getEtatsLogement();
}

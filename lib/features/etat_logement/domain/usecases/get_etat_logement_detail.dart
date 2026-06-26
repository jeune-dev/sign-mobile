import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../entities/etat_logement.dart';
import '../repositories/etat_logement_repository.dart';

class GetEtatLogementDetail {
  final EtatLogementRepository repository;
  GetEtatLogementDetail(this.repository);

  Future<Either<Failure, EtatLogement>> call(String etatId) =>
      repository.getEtatLogementDetail(etatId);
}

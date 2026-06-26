import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../repositories/etat_logement_repository.dart';

class TelechargerEtatLogement {
  final EtatLogementRepository repository;
  TelechargerEtatLogement(this.repository);

  Future<Either<Failure, List<int>>> call(String etatId) =>
      repository.telechargerEtatLogement(etatId);
}

import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../repositories/etat_logement_repository.dart';

class CreerEtatLogement {
  final EtatLogementRepository repository;
  CreerEtatLogement(this.repository);

  Future<Either<Failure, void>> call(
    String contratId,
    Map<String, dynamic> data,
  ) =>
      repository.creerEtatLogement(contratId, data);
}

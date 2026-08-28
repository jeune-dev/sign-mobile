import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../repositories/etat_logement_repository.dart';
import 'package:sign_application/core/models/document_cree.dart';

class CreerEtatLogement {
  final EtatLogementRepository repository;
  CreerEtatLogement(this.repository);

  Future<Either<Failure, DocumentCree>> call(
    String contratId,
    Map<String, dynamic> data,
  ) =>
      repository.creerEtatLogement(contratId, data);
}

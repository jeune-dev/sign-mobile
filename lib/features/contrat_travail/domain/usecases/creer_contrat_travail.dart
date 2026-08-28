import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../repositories/contrat_travail_repository.dart';
import 'package:sign_application/core/models/document_cree.dart';

class CreerContratTravail {
  final ContratTravailRepository repository;
  CreerContratTravail(this.repository);

  Future<Either<Failure, DocumentCree>> call(Map<String, dynamic> data) =>
      repository.creerContratTravail(data);
}

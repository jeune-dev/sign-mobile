import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../repositories/contrat_repository.dart';
import 'package:sign_application/core/models/document_cree.dart';

class CreerContratBail {
  final ContratRepository repository;
  CreerContratBail(this.repository);

  Future<Either<Failure, DocumentCree>> call(Map<String, dynamic> data) =>
      repository.creerContratBail(data);
}

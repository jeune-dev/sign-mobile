import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../repositories/autre_contrat_repository.dart';
import 'package:sign_application/core/models/document_cree.dart';

class CreerAutreContrat {
  final AutreContratRepository repository;
  CreerAutreContrat(this.repository);

  Future<Either<Failure, DocumentCree>> call(String type, Map<String, dynamic> body) =>
      repository.creerContrat(type, body);
}

import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../entities/contrat_bail.dart';
import 'package:sign_application/core/models/document_cree.dart';

abstract class ContratRepository {
  Future<Either<Failure, List<ContratBail>>> getContratsImmobilier({int page = 1, int limit = 10});
  Future<Either<Failure, DocumentCree>> creerContratBail(Map<String, dynamic> data);
  Future<Either<Failure, List<int>>> telechargerContrat(String contratId);
}

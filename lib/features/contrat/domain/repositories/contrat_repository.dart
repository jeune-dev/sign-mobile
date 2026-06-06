import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../entities/contrat_bail.dart';

abstract class ContratRepository {
  Future<Either<Failure, List<ContratBail>>> getContratsImmobilier({int page = 1, int limit = 10});
  Future<Either<Failure, void>> creerContratBail(Map<String, dynamic> data);
  Future<Either<Failure, List<int>>> telechargerContrat(String contratId);
}

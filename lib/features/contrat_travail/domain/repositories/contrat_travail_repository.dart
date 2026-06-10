import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../entities/contrat_travail.dart';

abstract class ContratTravailRepository {
  Future<Either<Failure, List<ContratTravail>>> getContratsTravail({int page = 1, int limit = 10});
  Future<Either<Failure, ContratTravail>> getContratTravailDetail(String contratId);
  Future<Either<Failure, void>> creerContratTravail(Map<String, dynamic> data);
  Future<Either<Failure, void>> signerContratTravail(String contratId, String signature);
  Future<Either<Failure, List<int>>> telechargerContratTravail(String contratId);
  Future<Either<Failure, Map<String, int>>> getStatsTravail();
}

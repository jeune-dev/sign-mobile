import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../entities/autre_contrat.dart';

abstract class AutreContratRepository {
  Future<Either<Failure, List<AutreContrat>>> getContrats(String type);
  Future<Either<Failure, AutreContrat>> getContratDetail(String type, String id);
  Future<Either<Failure, void>> creerContrat(String type, Map<String, dynamic> body);
  Future<Either<Failure, void>> signerContrat(String type, String id, String signature);
  Future<Either<Failure, List<int>>> telechargerContrat(String type, String id);
}

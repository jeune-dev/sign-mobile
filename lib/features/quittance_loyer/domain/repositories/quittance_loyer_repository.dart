import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../entities/quittance_loyer.dart';

abstract class QuittanceLoyerRepository {
  Future<Either<Failure, List<QuittanceLoyer>>> getQuittances({int page = 1, int limit = 10});
  Future<Either<Failure, QuittanceLoyer>> getQuittanceDetail(String quittanceId);
  Future<Either<Failure, void>> creerQuittance(Map<String, dynamic> data);
  Future<Either<Failure, List<int>>> telechargerQuittance(String quittanceId);
}

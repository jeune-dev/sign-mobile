import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../entities/quittance_loyer.dart';
import '../repositories/quittance_loyer_repository.dart';

class GetQuittanceDetail {
  final QuittanceLoyerRepository repository;
  GetQuittanceDetail(this.repository);

  Future<Either<Failure, QuittanceLoyer>> call(String quittanceId) =>
      repository.getQuittanceDetail(quittanceId);
}

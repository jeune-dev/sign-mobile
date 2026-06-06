import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../repositories/quittance_loyer_repository.dart';

class TelechargerQuittance {
  final QuittanceLoyerRepository repository;
  TelechargerQuittance(this.repository);

  Future<Either<Failure, List<int>>> call(String quittanceId) =>
      repository.telechargerQuittance(quittanceId);
}

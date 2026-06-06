import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../entities/quittance_loyer.dart';
import '../repositories/quittance_loyer_repository.dart';

class GetQuittances {
  final QuittanceLoyerRepository repository;
  GetQuittances(this.repository);

  Future<Either<Failure, List<QuittanceLoyer>>> call({int page = 1, int limit = 10}) =>
      repository.getQuittances(page: page, limit: limit);
}

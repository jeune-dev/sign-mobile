import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../repositories/facture_repository.dart';

class GetFactures {
  final FactureRepository repository;
  GetFactures(this.repository);

  Future<Either<Failure, FacturesPageResult>> call({int page = 1, int limit = 10}) =>
      repository.getFactures(page: page, limit: limit);
}

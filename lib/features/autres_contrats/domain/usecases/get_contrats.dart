import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../entities/autre_contrat.dart';
import '../repositories/autre_contrat_repository.dart';

class GetContrats {
  final AutreContratRepository repository;
  GetContrats(this.repository);

  Future<Either<Failure, List<AutreContrat>>> call(String type) =>
      repository.getContrats(type);
}

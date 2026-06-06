import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../entities/autre_contrat.dart';
import '../repositories/autre_contrat_repository.dart';

class GetAutreContratDetail {
  final AutreContratRepository repository;
  GetAutreContratDetail(this.repository);

  Future<Either<Failure, AutreContrat>> call(String type, String id) =>
      repository.getContratDetail(type, id);
}

import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../repositories/autre_contrat_repository.dart';

class TelechargerAutreContrat {
  final AutreContratRepository repository;
  TelechargerAutreContrat(this.repository);

  Future<Either<Failure, List<int>>> call(String type, String id) =>
      repository.telechargerContrat(type, id);
}

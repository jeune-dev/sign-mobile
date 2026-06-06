import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../repositories/autre_contrat_repository.dart';

class CreerAutreContrat {
  final AutreContratRepository repository;
  CreerAutreContrat(this.repository);

  Future<Either<Failure, void>> call(String type, Map<String, dynamic> body) =>
      repository.creerContrat(type, body);
}

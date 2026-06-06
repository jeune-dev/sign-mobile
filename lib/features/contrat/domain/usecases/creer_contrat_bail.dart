import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../repositories/contrat_repository.dart';

class CreerContratBail {
  final ContratRepository repository;
  CreerContratBail(this.repository);

  Future<Either<Failure, void>> call(Map<String, dynamic> data) =>
      repository.creerContratBail(data);
}

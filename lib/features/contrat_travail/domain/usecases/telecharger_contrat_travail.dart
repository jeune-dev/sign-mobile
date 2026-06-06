import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../repositories/contrat_travail_repository.dart';

class TelechargerContratTravail {
  final ContratTravailRepository repository;
  TelechargerContratTravail(this.repository);

  Future<Either<Failure, List<int>>> call(String contratId) =>
      repository.telechargerContratTravail(contratId);
}

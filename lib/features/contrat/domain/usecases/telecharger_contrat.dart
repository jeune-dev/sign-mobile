import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../repositories/contrat_repository.dart';

class TelechargerContrat {
  final ContratRepository repository;
  TelechargerContrat(this.repository);

  Future<Either<Failure, List<int>>> call(String contratId) =>
      repository.telechargerContrat(contratId);
}

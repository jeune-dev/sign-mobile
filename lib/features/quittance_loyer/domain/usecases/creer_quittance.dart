import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../repositories/quittance_loyer_repository.dart';

class CreerQuittance {
  final QuittanceLoyerRepository repository;
  CreerQuittance(this.repository);

  Future<Either<Failure, void>> call(Map<String, dynamic> data) =>
      repository.creerQuittance(data);
}

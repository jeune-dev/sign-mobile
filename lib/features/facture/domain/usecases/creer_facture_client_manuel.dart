import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../repositories/facture_repository.dart';

class CreerFactureClientManuel {
  final FactureRepository repository;
  CreerFactureClientManuel(this.repository);

  Future<Either<Failure, void>> call(Map<String, dynamic> data) =>
      repository.creerFactureClientManuel(data);
}

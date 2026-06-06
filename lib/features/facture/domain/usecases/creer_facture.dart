import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../repositories/facture_repository.dart';

class CreerFacture {
  final FactureRepository repository;
  CreerFacture(this.repository);

  Future<Either<Failure, void>> call(Map<String, dynamic> data) =>
      repository.creerFacture(data);
}

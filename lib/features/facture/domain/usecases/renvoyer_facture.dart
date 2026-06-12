import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../repositories/facture_repository.dart';

class RenvoyerFacture {
  final FactureRepository repository;
  RenvoyerFacture(this.repository);

  Future<Either<Failure, void>> call(String documentId) {
    return repository.renvoyerFacture(documentId);
  }
}

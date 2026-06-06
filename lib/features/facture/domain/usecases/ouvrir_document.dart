import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../repositories/facture_repository.dart';

class OuvrirDocument {
  final FactureRepository repository;
  OuvrirDocument(this.repository);

  Future<Either<Failure, List<int>>> call(String documentId) =>
      repository.ouvrirDocument(documentId);
}

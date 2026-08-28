import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../repositories/facture_repository.dart';
import 'package:sign_application/core/models/document_cree.dart';

class CreerFacture {
  final FactureRepository repository;
  CreerFacture(this.repository);

  Future<Either<Failure, DocumentCree>> call(Map<String, dynamic> data) =>
      repository.creerFacture(data);
}

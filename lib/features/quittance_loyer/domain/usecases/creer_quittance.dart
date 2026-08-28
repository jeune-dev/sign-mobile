import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../repositories/quittance_loyer_repository.dart';
import 'package:sign_application/core/models/document_cree.dart';

class CreerQuittance {
  final QuittanceLoyerRepository repository;
  CreerQuittance(this.repository);

  Future<Either<Failure, DocumentCree>> call(Map<String, dynamic> data) =>
      repository.creerQuittance(data);
}

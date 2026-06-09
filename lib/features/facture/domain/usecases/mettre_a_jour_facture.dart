import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../repositories/facture_repository.dart';

class MettreAJourFacture {
  final FactureRepository repository;
  MettreAJourFacture(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required String documentId,
    double? avance,
    String? statut,
  }) {
    return repository.mettreAJourFacture(
      documentId: documentId,
      avance: avance,
      statut: statut,
    );
  }
}

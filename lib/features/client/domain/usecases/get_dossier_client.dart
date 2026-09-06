import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../entities/dossier_client.dart';
import '../repositories/client_repository.dart';

/// Ouvrir la fiche d'un client : ses factures et ses contrats.
class GetDossierClient {
  final ClientRepository repository;
  GetDossierClient(this.repository);

  Future<Either<Failure, DossierClient>> call(String clientId) {
    return repository.getDossierClient(clientId);
  }
}

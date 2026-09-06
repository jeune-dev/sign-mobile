import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../entities/client.dart';
import '../entities/dossier_client.dart';

abstract class ClientRepository {
  Future<Either<Failure, List<Client>>> getClients();
  Future<Either<Failure, List<Client>>> rechercherClients(String query);
  Future<Either<Failure, void>> ajouterClient({
    required String nom,
    required String prenom,
    required String email,
    required String motDePasse,
    String? telephone,
    String? adresse,
    String? carteIdentiteNationalNum,
  });

  /// Tout ce qui a été établi avec ce client : factures et contrats.
  Future<Either<Failure, DossierClient>> getDossierClient(String clientId);
}

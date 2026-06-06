import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../entities/client.dart';

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
}

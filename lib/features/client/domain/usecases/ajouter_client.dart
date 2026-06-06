import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../repositories/client_repository.dart';

class AjouterClient {
  final ClientRepository repository;
  AjouterClient(this.repository);

  Future<Either<Failure, void>> call({
    required String nom,
    required String prenom,
    required String email,
    required String motDePasse,
    String? telephone,
    String? adresse,
    String? carteIdentiteNationalNum,
  }) =>
      repository.ajouterClient(
        nom: nom,
        prenom: prenom,
        email: email,
        motDePasse: motDePasse,
        telephone: telephone,
        adresse: adresse,
        carteIdentiteNationalNum: carteIdentiteNationalNum,
      );
}

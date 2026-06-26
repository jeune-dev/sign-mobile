import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../entities/etat_logement.dart';

abstract class EtatLogementRepository {
  /// Liste tous les états des lieux du bailleur connecté.
  Future<Either<Failure, List<EtatLogement>>> getEtatsLogement();

  /// Détail d'un état des lieux.
  Future<Either<Failure, EtatLogement>> getEtatLogementDetail(String etatId);

  /// Crée un état des lieux pour un contrat de bail donné.
  Future<Either<Failure, void>> creerEtatLogement(
    String contratId,
    Map<String, dynamic> data,
  );

  /// Signature locataire d'un état des lieux.
  Future<Either<Failure, void>> signerEtatLogement(
    String etatId,
    String signature,
  );

  /// Télécharge le PDF d'un état des lieux.
  Future<Either<Failure, List<int>>> telechargerEtatLogement(String etatId);
}

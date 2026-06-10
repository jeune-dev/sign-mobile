import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../entities/fiche_paie.dart';

abstract class FichePaieRepository {
  Future<Either<Failure, FichePaie>> creerFichePaie(FichePaie fiche);
  Future<Either<Failure, List<FichePaie>>> getFichesPaie({int page, int limit});
  Future<Either<Failure, List<int>>> telechargerFichePaie(String ficheId);
}
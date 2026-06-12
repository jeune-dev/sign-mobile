import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../entities/fiche_paie.dart';
import '../repositories/fiche_paie_repository.dart';

class CreerFichePaie {
  final FichePaieRepository repository;
  CreerFichePaie(this.repository);

  Future<Either<Failure, FichePaie>> call(FichePaie fiche) =>
      repository.creerFichePaie(fiche);
}

class GetFichesPaie {
  final FichePaieRepository repository;
  GetFichesPaie(this.repository);

  Future<Either<Failure, List<FichePaie>>> call({int page = 1, int limit = 10}) =>
      repository.getFichesPaie(page: page, limit: limit);
}

class TelechargerFichePaie {
  final FichePaieRepository repository;
  TelechargerFichePaie(this.repository);

  Future<Either<Failure, List<int>>> call(String ficheId) =>
      repository.telechargerFichePaie(ficheId);
}

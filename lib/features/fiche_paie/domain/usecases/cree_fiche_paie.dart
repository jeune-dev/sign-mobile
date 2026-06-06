import '../entities/fiche_paie.dart';
import '../repositories/fiche_paie_repository.dart';

class CreerFichePaie {
  final FichePaieRepository repository;

  CreerFichePaie(this.repository);

  Future<FichePaie> call(FichePaie fiche) {
    return repository.creerFichePaie(fiche);
  }
}
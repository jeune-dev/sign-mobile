import '../entities/fiche_paie.dart';

abstract class FichePaieRepository {
  Future<FichePaie> creerFichePaie(FichePaie fiche);
}
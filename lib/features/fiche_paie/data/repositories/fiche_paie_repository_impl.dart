import '../../domain/entities/fiche_paie.dart';
import '../../domain/repositories/fiche_paie_repository.dart';
import '../datasources/fiche_paie_remote_datasource.dart';
import '../models/fichie_paie_model.dart';

class FichePaieRepositoryImpl implements FichePaieRepository {
  final FichePaieRemoteDataSource remoteDataSource;

  FichePaieRepositoryImpl(this.remoteDataSource);

  @override
  Future<FichePaie> creerFichePaie(FichePaie fiche) async {
    final model = FichePaieModel(
      numeroFiche: fiche.numeroFiche,
      employeurId: fiche.employeurId,
      salarieId: fiche.salarieId,

      numeroIpres: fiche.numeroIpres,
      numeroCss: fiche.numeroCss,
      poste: fiche.poste,
      dateEmbauche: fiche.dateEmbauche,

      typeContrat: fiche.typeContrat,
      mois: fiche.mois,
      annee: fiche.annee,

      salaireBrut: fiche.salaireBrut,
      modeCalcul: fiche.modeCalcul,

      nombreJoursTravailles: fiche.nombreJoursTravailles,
      nombreHeuresTravailles: fiche.nombreHeuresTravailles,

      absence: fiche.absence,
      nombreJoursAbsence: fiche.nombreJoursAbsence,
      typeAbsence: fiche.typeAbsence,
      autreTypeAbsence: fiche.autreTypeAbsence, // ✅

      aHeuresSupp: fiche.aHeuresSupp,
      nombreHeuresSupplementaires: fiche.nombreHeuresSupplementaires,

      aPrimes: fiche.aPrimes,
      primeTransport: fiche.primeTransport,
      primeLogement: fiche.primeLogement,
      primePerformance: fiche.primePerformance,
      primeExceptionnelle: fiche.primeExceptionnelle,
      autresPrimes: fiche.autresPrimes,

      avantagesNature: fiche.avantagesNature,   // ✅
      autreAvantages: fiche.autreAvantages,     // ✅
      valeurAvantages: fiche.valeurAvantages,   // ✅

      congesPris: fiche.congesPris,
      nombreJoursConges: fiche.nombreJoursConges,
      montantConges: fiche.montantConges, // ✅

      aAvanceSalaire: fiche.aAvanceSalaire,
      montantAvanceSalaire: fiche.montantAvanceSalaire,

      aAutresRetenues: fiche.aAutresRetenues,
      motifRetenue: fiche.motifRetenue,
      montantRetenue: fiche.montantRetenue,

      soumisIpres: fiche.soumisIpres,
      soumisCss: fiche.soumisCss,
      soumisIr: fiche.soumisIr,

      aAssurance: fiche.aAssurance, // ✅
      montantAssurance: fiche.montantAssurance, // ✅

      situationFamiliale: fiche.situationFamiliale,
      nombreEnfants: fiche.nombreEnfants,

      modePaiement: fiche.modePaiement,
      datePaiement: fiche.datePaiement,
    );

    final result = await remoteDataSource.creerFichePaie(model);
    return result;
  }
}
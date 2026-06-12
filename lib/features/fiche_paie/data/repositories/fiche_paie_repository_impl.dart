import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../../domain/entities/fiche_paie.dart';
import '../../domain/repositories/fiche_paie_repository.dart';
import '../datasources/fiche_paie_remote_datasource.dart';
import '../models/fichie_paie_model.dart';

class FichePaieRepositoryImpl implements FichePaieRepository {
  final FichePaieRemoteDataSource remoteDataSource;

  FichePaieRepositoryImpl(this.remoteDataSource);

  String _mapDioError(DioException e) {
    if (e.response?.data is Map && e.response?.data['message'] != null) {
      return e.response!.data['message'] as String;
    }
    return e.message ?? 'Une erreur est survenue';
  }

  @override
  Future<Either<Failure, FichePaie>> creerFichePaie(FichePaie fiche) async {
    try {
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
        autreTypeAbsence: fiche.autreTypeAbsence,
        aHeuresSupp: fiche.aHeuresSupp,
        nombreHeuresSupplementaires: fiche.nombreHeuresSupplementaires,
        aPrimes: fiche.aPrimes,
        primeTransport: fiche.primeTransport,
        primeLogement: fiche.primeLogement,
        primePerformance: fiche.primePerformance,
        primeExceptionnelle: fiche.primeExceptionnelle,
        autresPrimes: fiche.autresPrimes,
        avantagesNature: fiche.avantagesNature,
        autreAvantages: fiche.autreAvantages,
        valeurAvantages: fiche.valeurAvantages,
        congesPris: fiche.congesPris,
        nombreJoursConges: fiche.nombreJoursConges,
        montantConges: fiche.montantConges,
        aAvanceSalaire: fiche.aAvanceSalaire,
        montantAvanceSalaire: fiche.montantAvanceSalaire,
        aAutresRetenues: fiche.aAutresRetenues,
        motifRetenue: fiche.motifRetenue,
        montantRetenue: fiche.montantRetenue,
        soumisIpres: fiche.soumisIpres,
        soumisCss: fiche.soumisCss,
        soumisIr: fiche.soumisIr,
        aAssurance: fiche.aAssurance,
        montantAssurance: fiche.montantAssurance,
        situationFamiliale: fiche.situationFamiliale,
        nombreEnfants: fiche.nombreEnfants,
        modePaiement: fiche.modePaiement,
        datePaiement: fiche.datePaiement,
      );
      final result = await remoteDataSource.creerFichePaie(model);
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _mapDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FichePaie>>> getFichesPaie({
    int page  = 1,
    int limit = 10,
  }) async {
    try {
      final fiches = await remoteDataSource.getFichesPaie(page: page, limit: limit);
      return Right(fiches);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _mapDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<int>>> telechargerFichePaie(String ficheId) async {
    try {
      final bytes = await remoteDataSource.telechargerFichePaie(ficheId);
      return Right(bytes);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _mapDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }
}

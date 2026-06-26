import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../../domain/entities/etat_logement.dart';
import '../../domain/repositories/etat_logement_repository.dart';
import '../datasources/etat_logement_remote_datasource.dart';

class EtatLogementRepositoryImpl implements EtatLogementRepository {
  final EtatLogementRemoteDataSource remoteDataSource;
  EtatLogementRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<EtatLogement>>> getEtatsLogement() async {
    try {
      final etats = await remoteDataSource.getEtatsLogement();
      return Right(etats);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _handleDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, EtatLogement>> getEtatLogementDetail(
      String etatId) async {
    try {
      final etat = await remoteDataSource.getEtatLogementDetail(etatId);
      return Right(etat);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _handleDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> creerEtatLogement(
    String contratId,
    Map<String, dynamic> data,
  ) async {
    try {
      await remoteDataSource.creerEtatLogement(contratId, data);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _handleDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signerEtatLogement(
    String etatId,
    String signature,
  ) async {
    try {
      await remoteDataSource.signerEtatLogement(etatId, signature);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _handleDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<int>>> telechargerEtatLogement(
      String etatId) async {
    try {
      final bytes = await remoteDataSource.telechargerEtatLogement(etatId);
      return Right(bytes);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _handleDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  String _handleDioError(DioException e) {
    if (e.response?.data is Map && e.response?.data['message'] != null) {
      return e.response!.data['message'];
    }
    return e.message ?? 'Une erreur est survenue';
  }
}

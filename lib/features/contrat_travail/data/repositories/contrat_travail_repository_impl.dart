import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../../domain/entities/contrat_travail.dart';
import '../../domain/repositories/contrat_travail_repository.dart';
import '../datasources/contrat_travail_remote_datasource.dart';

class ContratTravailRepositoryImpl implements ContratTravailRepository {
  final ContratTravailRemoteDataSource remoteDataSource;
  ContratTravailRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<ContratTravail>>> getContratsTravail({int page = 1, int limit = 10}) async {
    try {
      final contrats = await remoteDataSource.getContratsTravail(page: page, limit: limit);
      return Right(contrats);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _handleDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ContratTravail>> getContratTravailDetail(String contratId) async {
    try {
      final contrat = await remoteDataSource.getContratTravailDetail(contratId);
      return Right(contrat);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _handleDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> creerContratTravail(Map<String, dynamic> data) async {
    try {
      await remoteDataSource.creerContratTravail(data);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _handleDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signerContratTravail(String contratId, String signature) async {
    try {
      await remoteDataSource.signerContratTravail(contratId, signature);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _handleDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<int>>> telechargerContratTravail(String contratId) async {
    try {
      final bytes = await remoteDataSource.telechargerContratTravail(contratId);
      return Right(bytes);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _handleDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>> getStatsTravail() async {
    try {
      final stats = await remoteDataSource.getStatsTravail();
      return Right(stats);
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

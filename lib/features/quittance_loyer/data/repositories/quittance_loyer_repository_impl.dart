import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../../domain/entities/quittance_loyer.dart';
import '../../domain/repositories/quittance_loyer_repository.dart';
import '../datasources/quittance_loyer_remote_datasource.dart';

class QuittanceLoyerRepositoryImpl implements QuittanceLoyerRepository {
  final QuittanceLoyerRemoteDataSource remoteDataSource;
  QuittanceLoyerRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<QuittanceLoyer>>> getQuittances({int page = 1, int limit = 10}) async {
    try {
      final quittances = await remoteDataSource.getQuittances(page: page, limit: limit);
      return Right(quittances);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _handleDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, QuittanceLoyer>> getQuittanceDetail(String quittanceId) async {
    try {
      final quittance = await remoteDataSource.getQuittanceDetail(quittanceId);
      return Right(quittance);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _handleDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> creerQuittance(Map<String, dynamic> data) async {
    try {
      await remoteDataSource.creerQuittance(data);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _handleDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<int>>> telechargerQuittance(String quittanceId) async {
    try {
      final bytes = await remoteDataSource.telechargerQuittance(quittanceId);
      return Right(bytes);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _handleDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  String _handleDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      return (data['message'] ?? data['error'] ?? data['msg'])?.toString()
          ?? e.message
          ?? 'Une erreur est survenue';
    }
    return e.message ?? 'Une erreur est survenue';
  }
}

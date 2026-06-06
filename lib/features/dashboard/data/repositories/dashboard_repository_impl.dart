import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;
  DashboardRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, DashboardStats>> getDashboardStats() async {
    try {
      final stats = await remoteDataSource.getDashboardStats();
      return Right(stats);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _handleDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<dynamic>>> getDocumentsRecents({int limit = 5}) async {
    try {
      final docs = await remoteDataSource.getDocumentsRecents(limit: limit);
      return Right(docs);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _handleDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<int>>> ouvrirDocument(String documentId) async {
    try {
      final bytes = await remoteDataSource.ouvrirDocument(documentId);
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

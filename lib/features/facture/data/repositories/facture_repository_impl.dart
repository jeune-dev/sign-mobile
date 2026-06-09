import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../../domain/repositories/facture_repository.dart';
import '../datasources/facture_remote_datasource.dart';

class FactureRepositoryImpl implements FactureRepository {
  final FactureRemoteDataSource remoteDataSource;
  FactureRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, FacturesPageResult>> getFactures({int page = 1, int limit = 10}) async {
    try {
      final result = await remoteDataSource.getFactures(page: page, limit: limit);
      return Right(FacturesPageResult(
        factures: result.factures,
        total: result.total,
        totalPages: result.totalPages,
        currentPage: result.currentPage,
        limit: result.limit,
      ));
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _handleDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> creerFacture(Map<String, dynamic> data) async {
    try {
      await remoteDataSource.creerFacture(data);
      return const Right(null);
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

  @override
  Future<Either<Failure, Map<String, dynamic>>> mettreAJourFacture({
    required String documentId,
    double? avance,
    String? statut,
  }) async {
    try {
      final data = await remoteDataSource.mettreAJourFacture(
        documentId: documentId,
        avance: avance,
        statut: statut,
      );
      return Right(data);
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

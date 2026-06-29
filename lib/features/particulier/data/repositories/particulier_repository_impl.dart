import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../../domain/entities/particulier_facture.dart';
import '../../domain/entities/particulier_contrat.dart';
import '../../domain/repositories/particulier_repository.dart';
import '../datasources/particulier_remote_datasource.dart';

class ParticulierRepositoryImpl implements ParticulierRepository {
  final ParticulierRemoteDataSource remoteDataSource;

  ParticulierRepositoryImpl({required this.remoteDataSource});

  String _mapDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      return (data['message'] ?? data['error'] ?? data['msg'])?.toString()
          ?? e.message
          ?? 'Une erreur est survenue';
    }
    return e.message ?? 'Une erreur est survenue';
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getDashboardStats() async {
    try {
      final data = await remoteDataSource.getDashboardStats();
      return Right(data);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _mapDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ParticulierFacture>>> getFactures({
    String? statut,
    int page  = 1,
    int limit = 20,
  }) async {
    try {
      final factures = await remoteDataSource.getFactures(statut: statut, page: page, limit: limit);
      return Right(factures);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _mapDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ParticulierContrat>>> getTousContrats({String? statut, String? type}) async {
    try {
      final contrats = await remoteDataSource.getTousContrats(statut: statut, type: type);
      return Right(contrats);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _mapDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ParticulierContrat>>> getContratsByType({
    required String type,
    String? statut,
    int page  = 1,
    int limit = 20,
  }) async {
    try {
      final contrats = await remoteDataSource.getContratsByType(
          type: type, statut: statut, page: page, limit: limit);
      return Right(contrats);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _mapDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ParticulierContrat>> getContratDetail({
    required String type,
    required String contratId,
  }) async {
    try {
      final contrat = await remoteDataSource.getContratDetail(type: type, contratId: contratId);
      return Right(contrat);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _mapDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signerContrat({
    required String type,
    required String contratId,
    required String signature,
  }) async {
    try {
      await remoteDataSource.signerContrat(type: type, contratId: contratId, signature: signature);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _mapDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Uint8List>> downloadContratPdf({
    required String type,
    required String contratId,
  }) async {
    try {
      final bytes = await remoteDataSource.downloadContratPdf(type: type, contratId: contratId);
      return Right(bytes);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _mapDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }
}

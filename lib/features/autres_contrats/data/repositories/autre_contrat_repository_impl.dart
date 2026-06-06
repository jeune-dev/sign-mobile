import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../../domain/entities/autre_contrat.dart';
import '../../domain/repositories/autre_contrat_repository.dart';
import '../datasources/autre_contrat_remote_datasource.dart';

class AutreContratRepositoryImpl implements AutreContratRepository {
  final AutreContratRemoteDataSource remoteDataSource;
  AutreContratRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<AutreContrat>>> getContrats(String type) async {
    try {
      final contrats = await remoteDataSource.getContrats(type);
      return Right(contrats);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _handleDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AutreContrat>> getContratDetail(String type, String id) async {
    try {
      final contrat = await remoteDataSource.getContratDetail(type, id);
      return Right(contrat);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _handleDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> creerContrat(String type, Map<String, dynamic> body) async {
    try {
      await remoteDataSource.creerContrat(type, body);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _handleDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signerContrat(String type, String id, String signature) async {
    try {
      await remoteDataSource.signerContrat(type, id, signature);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _handleDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<int>>> telechargerContrat(String type, String id) async {
    try {
      final bytes = await remoteDataSource.telechargerContrat(type, id);
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

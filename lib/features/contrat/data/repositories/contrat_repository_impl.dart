import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../../domain/entities/contrat_bail.dart';
import '../../domain/repositories/contrat_repository.dart';
import '../datasources/contrat_remote_datasource.dart';

class ContratRepositoryImpl implements ContratRepository {
  final ContratRemoteDataSource remoteDataSource;
  ContratRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<ContratBail>>> getContratsImmobilier({int page = 1, int limit = 10}) async {
    try {
      final contrats = await remoteDataSource.getContratsImmobilier(page: page, limit: limit);
      return Right(contrats);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _handleDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> creerContratBail(Map<String, dynamic> data) async {
    try {
      await remoteDataSource.creerContratBail(data);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _handleDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<int>>> telechargerContrat(String contratId) async {
    try {
      final bytes = await remoteDataSource.telechargerContrat(contratId);
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

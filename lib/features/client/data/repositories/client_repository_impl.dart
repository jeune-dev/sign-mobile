import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../../domain/entities/client.dart';
import '../../domain/repositories/client_repository.dart';
import '../datasources/client_remote_datasource.dart';

class ClientRepositoryImpl implements ClientRepository {
  final ClientRemoteDataSource remoteDataSource;
  ClientRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<Client>>> getClients() async {
    try {
      final clients = await remoteDataSource.getClients();
      return Right(clients);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _handleDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Client>>> rechercherClients(String query) async {
    try {
      final clients = await remoteDataSource.rechercherClients(query);
      return Right(clients);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _handleDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> ajouterClient({
    required String nom,
    required String prenom,
    required String email,
    required String motDePasse,
    String? telephone,
    String? adresse,
    String? carteIdentiteNationalNum,
  }) async {
    try {
      final data = {
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'mot_de_passe': motDePasse,
        'role': 'Particulier',
        if (telephone != null && telephone.isNotEmpty) 'telephone': telephone,
        if (adresse != null && adresse.isNotEmpty) 'adresse': adresse,
        if (carteIdentiteNationalNum != null && carteIdentiteNationalNum.isNotEmpty)
          'carte_identite_national_num': carteIdentiteNationalNum,
      };
      await remoteDataSource.ajouterClient(data);
      return const Right(null);
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

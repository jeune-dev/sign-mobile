import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../../domain/entities/account_user.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_remote_datasource.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AccountRemoteDataSource remoteDataSource;
  AccountRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, AccountUser>> getMe() async {
    try {
      final user = await remoteDataSource.getMe();
      return Right(user);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _handleDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AccountUser>> modifierInfoPersonnelles({
    String? nom,
    String? prenom,
    String? email,
    String? telephone,
    String? adresse,
    String? carteIdentiteNationalNum,
    String? rc,
    String? ninea,
    String? nomEntreprise,
    String? adresseEntreprise,
    String? telephoneEntreprise,
    String? emailEntreprise,
    String? photoProfilPath,
    String? logoPath,
    String? signaturePath,
  }) async {
    try {
      final fields = <String, dynamic>{
        if (nom != null) 'nom': nom,
        if (prenom != null) 'prenom': prenom,
        if (email != null) 'email': email,
        if (telephone != null) 'telephone': telephone,
        if (adresse != null) 'adresse': adresse,
        if (carteIdentiteNationalNum != null) 'carte_identite_national_num': carteIdentiteNationalNum,
        if (rc != null) 'rc': rc,
        if (ninea != null) 'ninea': ninea,
        if (nomEntreprise != null) 'nomEntreprise': nomEntreprise,
        if (adresseEntreprise != null) 'adresseEntreprise': adresseEntreprise,
        if (telephoneEntreprise != null) 'telephoneEntreprise': telephoneEntreprise,
        if (emailEntreprise != null) 'emailEntreprise': emailEntreprise,
      };

      final filePaths = <String, String>{
        if (photoProfilPath != null) 'photoProfil': photoProfilPath,
        if (logoPath != null) 'logo': logoPath,
        if (signaturePath != null) 'signature': signaturePath,
      };

      final user = await remoteDataSource.modifierInfoPersonnelles(fields, filePaths);
      return Right(user);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _handleDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await remoteDataSource.changePassword(oldPassword, newPassword);
      return const Right(null);
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

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/services/token_service.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, User>> login(
      String identifiant,
      String motDePasse,
      ) async {
    try {
      final authResponse =
          await remoteDataSource.login(identifiant, motDePasse);

      // Stocker le JWT
      await sl<TokenService>().setToken(authResponse.token);

      // Stocker l'ID et le rôle (pour la reprise de session)
      final storage = sl<FlutterSecureStorage>();
      await storage.write(key: 'user_id', value: authResponse.user.id);
      await storage.write(key: 'user_role', value: authResponse.user.role);

      return Right(authResponse.user);
    } on DioException catch (e) {
      String message = 'Une erreur est survenue';
      if (e.response?.data is Map && e.response?.data['message'] != null) {
        message = e.response!.data['message'];
      } else if (e.message != null) {
        message = e.message!;
      }
      return Left(ServerFailure(errorMessage: message));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> register({
    required String nom,
    required String prenom,
    required String email,
    required String mot_de_passe,
    required String adresse,
    required String telephone,
    required String carte_identite_national_num,
    required String role,
    XFile? photoProfil,
    XFile? logo,
    String? rc,
    String? ninea,
    XFile? signature,
    String? nomEntreprise,
    String? adresseEntreprise,
    String? telephoneEntreprise,
    String? emailEntreprise,
  }) async {
    try {
      final authResponse = await remoteDataSource.register(
        nom: nom,
        prenom: prenom,
        email: email,
        mot_de_passe: mot_de_passe,
        adresse: adresse,
        telephone: telephone,
        carte_identite_national_num: carte_identite_national_num,
        role: role,
        photoProfil: photoProfil,
        logo: logo,
        rc: rc,
        ninea: ninea,
        signature: signature,
        nomEntreprise: nomEntreprise,
        adresseEntreprise: adresseEntreprise,
        telephoneEntreprise: telephoneEntreprise,
        emailEntreprise: emailEntreprise,
      );

      await sl<TokenService>().setToken(authResponse.token);

      // Stocker le rôle pour la reprise de session
      await sl<FlutterSecureStorage>().write(
        key: 'user_role',
        value: authResponse.user.role,
      );

      return Right(authResponse.user);
    } on DioException catch (e) {
      String message = 'Une erreur est survenue';
      if (e.response?.data is Map && e.response?.data['message'] != null) {
        message = e.response!.data['message'];
      } else if (e.message != null) {
        message = e.message!;
      }
      return Left(ServerFailure(errorMessage: message));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }
}

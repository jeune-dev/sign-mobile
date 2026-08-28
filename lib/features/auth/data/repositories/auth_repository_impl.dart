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
  Future<Either<Failure, void>> forgotPassword(String email) async {
    try {
      await remoteDataSource.forgotPassword(email);
      return const Right(null);
    } on DioException catch (e) {
      final message = e.error?.toString() ?? 'Erreur lors de la demande';
      return Left(ServerFailure(errorMessage: message));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email, String otpRecu, String newPassword) async {
    try {
      await remoteDataSource.resetPassword(email, otpRecu, newPassword);
      return const Right(null);
    } on DioException catch (e) {
      final message = e.error?.toString() ?? 'Erreur lors de la réinitialisation';
      return Left(ServerFailure(errorMessage: message));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> login(
      String identifiant,
      String motDePasse,
      ) async {
    try {
      final authResponse =
          await remoteDataSource.login(identifiant, motDePasse);

      // Stocker le JWT (et le refresh token si présent)
      final tokenService = sl<TokenService>();
      await tokenService.setToken(authResponse.token);
      await tokenService.setRefreshToken(authResponse.refreshToken);

      // Stocker l'ID et le rôle (pour la reprise de session)
      final storage = sl<FlutterSecureStorage>();
      await storage.write(key: 'user_id', value: authResponse.user.id);
      await storage.write(key: 'user_role', value: authResponse.user.role);

      return Right(authResponse.user);
    } on DioException catch (e) {
      String message = 'Une erreur est survenue';
      final donnees = e.response?.data;
      if (donnees is Map && donnees['message'] != null) {
        message = donnees['message'];
      } else if (e.message != null) {
        message = e.message!;
      }
      // Compte antérieur à la refonte : le backend réclame son mot de passe.
      if (donnees is Map && donnees['motDePasseRequis'] == true) {
        return Left(MotDePasseRequisFailure(errorMessage: message));
      }
      // Adresse jamais confirmée : on renvoie vers la saisie du code.
      if (donnees is Map && donnees['verificationRequise'] == true) {
        return Left(VerificationEmailRequiseFailure(
          errorMessage: message,
          email: donnees['email']?.toString() ?? '',
        ));
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
    required String telephone,
    required String role,
    // Facultatifs depuis l'inscription rapide (§ 2) : seuls nom, prénom,
    // ville, téléphone et le type de profil sont demandés. Les anciens
    // champs restent acceptés par le backend.
    String? ville,
    String? email,
    String? mot_de_passe,
    String? adresse,
    String? carte_identite_national_num,
    String? typeDocumentIdentite,
    XFile? documentIdentite,
    XFile? photoProfil,
    XFile? logo,
    String? rc,
    String? ninea,
    XFile? signature,
    String? nomEntreprise,
    String? adresseEntreprise,
    String? telephoneEntreprise,
    String? emailEntreprise,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      final authResponse = await remoteDataSource.register(
        nom: nom,
        prenom: prenom,
        telephone: telephone,
        role: role,
        ville: ville,
        email: email,
        mot_de_passe: mot_de_passe,
        adresse: adresse,
        carte_identite_national_num: carte_identite_national_num,
        typeDocumentIdentite: typeDocumentIdentite,
        documentIdentite: documentIdentite,
        photoProfil: photoProfil,
        logo: logo,
        rc: rc,
        ninea: ninea,
        signature: signature,
        nomEntreprise: nomEntreprise,
        adresseEntreprise: adresseEntreprise,
        telephoneEntreprise: telephoneEntreprise,
        emailEntreprise: emailEntreprise,
        onSendProgress: onSendProgress,
      );

      final tokenService = sl<TokenService>();
      await tokenService.setToken(authResponse.token);
      await tokenService.setRefreshToken(authResponse.refreshToken);

      // Stocker l'id et le rôle : depuis la refonte, l'inscription ouvre
      // directement la session, sans repasser par l'écran de connexion.
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
}

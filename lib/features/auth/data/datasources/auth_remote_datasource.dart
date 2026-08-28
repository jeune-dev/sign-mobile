import 'dart:io';
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sign_application/core/config/env.dart';
import 'package:sign_application/core/services/token_service.dart';
import 'package:sign_application/injection_container.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login(String identifiant, String motDePasse);
  Future<void> forgotPassword(String email);

  /// Confirme l'adresse avec le code recu et ouvre la session.
  Future<UserModel> verifierEmail(String email, String code);

  /// Redemande un code de verification.
  Future<void> renvoyerCodeVerification(String email);
  Future<void> resetPassword(String email, String otpRecu, String newPassword);
  Future<AuthResponseModel> register({
    required String nom,
    required String prenom,
    required String telephone,
    required String role,
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
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;
  final String _loginPath;
  final String _registerPath;

  final String _forgotPasswordPath;
  final String _resetPasswordPath;

  AuthRemoteDataSourceImpl({required this.dio})
      : _loginPath = _normalisePath(Env.login),
        _registerPath = _normalisePath(Env.register),
        _forgotPasswordPath = _normalisePath(Env.accountForgotPassword),
        _resetPasswordPath = _normalisePath(Env.accountResetPassword);

  static String _normalisePath(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw StateError(
        'Les chemins AUTH_LOGIN_PATH et AUTH_REGISTER_PATH ne peuvent pas être vides.',
      );
    }
    return trimmed.startsWith('/') ? trimmed : '/$trimmed';
  }

  @override
  Future<AuthResponseModel> login(
      String identifiant,
      String motDePasse,
      ) async {
    final response = await dio.post(
      _loginPath,
      data: {
        'identifiant': identifiant,
        'mot_de_passe': motDePasse,
      },
    );

    if (response.statusCode == 200) {
      return AuthResponseModel.fromJson(response.data);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
      error: response.data['message'] ?? 'Erreur de connexion',
    );
  }

  @override
  Future<UserModel> verifierEmail(String email, String code) async {
    try {
      final reponse = await dio.post(
        _normalisePath(Env.authVerifierEmail),
        data: {'email': email, 'code': code},
      );

      // Meme forme qu'une connexion : jetons + utilisateur. On ouvre donc la
      // session ici, exactement comme le fait le depot pour le login.
      final auth = AuthResponseModel.fromJson(reponse.data);
      final tokenService = sl<TokenService>();
      await tokenService.setToken(auth.token);
      await tokenService.setRefreshToken(auth.refreshToken);

      final storage = sl<FlutterSecureStorage>();
      await storage.write(key: 'user_id', value: auth.user.id);
      await storage.write(key: 'user_role', value: auth.user.role);

      return auth.user;
    } on DioException catch (e) {
      throw Exception(_messageErreur(e, 'Vérification impossible'));
    }
  }

  @override
  Future<void> renvoyerCodeVerification(String email) async {
    try {
      await dio.post(
        _normalisePath(Env.authRenvoyerCode),
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw Exception(_messageErreur(e, 'Envoi du code impossible'));
    }
  }

  /// Extrait le message le plus parlant d'une erreur Dio.
  String _messageErreur(DioException e, String parDefaut) {
    final donnees = e.response?.data;
    if (donnees is Map) {
      final details = donnees['details'];
      if (details is List && details.isNotEmpty) return details.first.toString();
      if (donnees['message'] != null) return donnees['message'].toString();
    }
    return parDefaut;
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      await dio.post(_forgotPasswordPath, data: {'email': email});
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? e.response!.data['message'] ?? 'Erreur lors de la demande'
          : 'Erreur lors de la demande';
      throw DioException(
        requestOptions: e.requestOptions,
        response: e.response,
        type: DioExceptionType.badResponse,
        error: msg,
      );
    }
  }

  @override
  Future<void> resetPassword(String email, String otpRecu, String newPassword) async {
    try {
      await dio.post(_resetPasswordPath, data: {
        'email': email,
        'otpRecu': otpRecu,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? e.response!.data['message'] ?? 'Erreur lors de la réinitialisation'
          : 'Erreur lors de la réinitialisation';
      throw DioException(
        requestOptions: e.requestOptions,
        response: e.response,
        type: DioExceptionType.badResponse,
        error: msg,
      );
    }
  }

  @override
  Future<AuthResponseModel> register({
    required String nom,
    required String prenom,
    required String telephone,
    required String role,
    String? ville,
    String? email,
    String? mot_de_passe,
    String? adresse,
    String? carte_identite_national_num,
    String? typeDocumentIdentite,
    XFile? documentIdentite,
    String? rc,
    String? ninea,
    XFile? photoProfil,
    XFile? logo,
    XFile? signature,
    String? nomEntreprise,
    String? adresseEntreprise,
    String? telephoneEntreprise,
    String? emailEntreprise,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    // VULN-H02 : Aucun print() — données sensibles jamais loggées
    // Seuls les champs réellement renseignés sont transmis : le backend
    // refuse une chaîne vide là où il attend un e-mail ou un mot de passe.
    final formData = FormData.fromMap({
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'role': role,
      if (ville != null && ville.isNotEmpty) 'ville': ville,
      if (email != null && email.isNotEmpty) 'email': email,
      if (mot_de_passe != null && mot_de_passe.isNotEmpty) 'mot_de_passe': mot_de_passe,
      if (adresse != null && adresse.isNotEmpty) 'adresse': adresse,
      if (carte_identite_national_num != null && carte_identite_national_num.isNotEmpty)
        'carte_identite_national_num': carte_identite_national_num,
      if (typeDocumentIdentite != null) 'type_document_identite': typeDocumentIdentite,
      if (rc != null) 'rc': rc,
      if (ninea != null) 'ninea': ninea,
      if (nomEntreprise != null) 'nomEntreprise': nomEntreprise,
      if (adresseEntreprise != null) 'adresseEntreprise': adresseEntreprise,
      if (telephoneEntreprise != null) 'telephoneEntreprise': telephoneEntreprise,
      if (emailEntreprise != null) 'emailEntreprise': emailEntreprise,
    });

    if (photoProfil != null) {
      formData.files.add(MapEntry(
        'photoProfil',
        await MultipartFile.fromFile(
          File(photoProfil.path).path,
          filename: photoProfil.path.split('/').last,
        ),
      ));
    }

    if (logo != null) {
      formData.files.add(MapEntry(
        'logo',
        await MultipartFile.fromFile(
          File(logo.path).path,
          filename: logo.path.split('/').last,
        ),
      ));
    }

    if (signature != null) {
      formData.files.add(MapEntry(
        'signature',
        await MultipartFile.fromFile(
          File(signature.path).path,
          filename: signature.path.split('/').last,
        ),
      ));
    }

    if (documentIdentite != null) {
      formData.files.add(MapEntry(
        'documentIdentite',
        await MultipartFile.fromFile(
          File(documentIdentite.path).path,
          filename: documentIdentite.path.split('/').last,
        ),
      ));
    }

    try {
      final response = await dio.post(
        _registerPath,
        data: formData,
        onSendProgress: onSendProgress,
        options: Options(contentType: 'multipart/form-data'),
      );
      return AuthResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode != null &&
          e.response!.statusCode! >= 400 &&
          e.response!.statusCode! < 500) {
        final errorData = e.response?.data;
        String errorMessage = 'Données invalides';
        if (errorData is Map) {
          final details = errorData['details'];
          if (details is List && details.isNotEmpty) {
            errorMessage = details.first.toString();
          } else if (errorData.containsKey('message')) {
            errorMessage = errorData['message'].toString();
          }
        }
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          type: DioExceptionType.badResponse,
          error: errorMessage,
        );
      }
      rethrow;
    }
  }
}

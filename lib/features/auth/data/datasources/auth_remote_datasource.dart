import 'dart:io';
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sign_application/core/config/env.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login(String identifiant, String motDePasse);
  Future<void> forgotPassword(String email);
  Future<void> resetPassword(String email, String otpRecu, String newPassword);
  Future<AuthResponseModel> register({
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
    required String email,
    required String mot_de_passe,
    required String adresse,
    required String telephone,
    required String carte_identite_national_num,
    required String role,
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
    final formData = FormData.fromMap({
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'mot_de_passe': mot_de_passe,
      'adresse': adresse,
      'telephone': telephone,
      'carte_identite_national_num': carte_identite_national_num,
      'role': role,
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

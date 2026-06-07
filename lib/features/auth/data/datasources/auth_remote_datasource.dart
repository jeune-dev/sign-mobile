import 'dart:io';
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sign_application/core/config/env.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login(String identifiant, String motDePasse);
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
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;
  final String _loginPath;
  final String _registerPath;

  AuthRemoteDataSourceImpl({required this.dio})
      : _loginPath = _normalisePath(Env.login),
        _registerPath = _normalisePath(Env.register);

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
        options: Options(contentType: 'multipart/form-data'),
      );
      return AuthResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        final errorMessage = errorData is Map && errorData.containsKey('message')
            ? errorData['message']
            : 'Données invalides';
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

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

    try {
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
    } on DioException catch (e) {
      print('--- Erreur Dio ---');
      print('Type: ${e.type}');
      print('Response: ${e.response?.data}');
      print('Message: ${e.message}');
      rethrow;
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
  }) async {
    try {
      print('========== REGISTER REQUEST ==========');
      print('Endpoint : $_registerPath');

      // Créer FormData pour envoyer les données et le fichier
      final formData = FormData.fromMap({
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'mot_de_passe': mot_de_passe,
        'adresse': adresse,
        'telephone': telephone,
        'carte_identite_national_num': carte_identite_national_num,
        'role': role,
        'rc': rc,
        'ninea': ninea,
        'nomEntreprise': nomEntreprise,
        'adresseEntreprise': adresseEntreprise,
        'telephoneEntreprise': telephoneEntreprise,
        'emailEntreprise': emailEntreprise,

      });

      // Ajouter le fichier photoProfil s'il existe
      if (photoProfil != null) {
        final file = File(photoProfil.path);
        final fileName = photoProfil.path.split('/').last;

        formData.files.add(MapEntry(
          'photoProfil',
          await MultipartFile.fromFile(
            file.path,
            filename: fileName,
          ),
        ));

        print('Avec fichier photoProfil: $fileName');
      }

      // Ajouter le fichier logo s'il existe
      if (logo != null) {
        final file = File(logo.path);
        final fileName = logo.path.split('/').last;

        formData.files.add(MapEntry(
          'logo',
          await MultipartFile.fromFile(
            file.path,
            filename: fileName,
          ),
        ));

        print('Avec fichier logo: $fileName');
      }

      // Ajouter le fichier signature s'il existe
      if (signature != null) {
        final file = File(signature.path);
        final fileName = signature.path.split('/').last;

        formData.files.add(MapEntry(
          'signature',
          await MultipartFile.fromFile(
            file.path,
            filename: fileName,
          ),
        ));

        print('Avec fichier signature: $fileName');
      }

      print('Payload :');
      print({
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'mot_de_passe': '***',
        'adresse': adresse,
        'telephone': telephone,
        'carte_identite_national_num': carte_identite_national_num,
        'role': role,
        'photoProfil': photoProfil != null ? 'présent' : 'absent',
        'logo': logo != null ? 'présent' : 'absent',
        'signature': signature != null ? 'présent' : 'absent',
      });

      final response = await dio.post(
        _registerPath,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      print('========== REGISTER RESPONSE ==========');
      print('Status code : ${response.statusCode}');
      print('Response data : ${response.data}');

      return AuthResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      print('========== REGISTER ERROR (DIO) ==========');
      print('Message : ${e.message}');
      print('Type : ${e.type}');
      print('Status code : ${e.response?.statusCode}');
      print('Error data : ${e.response?.data}');
      print('Request path : ${e.requestOptions.path}');

      // Gestion spécifique des erreurs
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
    } catch (e) {
      print('========== REGISTER ERROR (UNKNOWN) ==========');
      print('Error : $e');
      rethrow;
    }
  }
}
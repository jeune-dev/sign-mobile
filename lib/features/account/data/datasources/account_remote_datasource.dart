import 'package:dio/dio.dart';
import 'package:sign_application/core/config/env.dart';
import '../models/account_user_model.dart';

abstract class AccountRemoteDataSource {
  Future<AccountUserModel> getMe();
  Future<AccountUserModel> modifierInfoPersonnelles(Map<String, dynamic> fields, Map<String, String> filePaths);
  Future<void> changePassword(String oldPassword, String newPassword);
}

class AccountRemoteDataSourceImpl implements AccountRemoteDataSource {
  final Dio dio;
  AccountRemoteDataSourceImpl({required this.dio});

  @override
  Future<AccountUserModel> getMe() async {
    final response = await dio.get(Env.accountMe);
    final json = Map<String, dynamic>.from(response.data['utilisateur']);
    return AccountUserModel.fromJson(json);
  }

  @override
  Future<AccountUserModel> modifierInfoPersonnelles(
    Map<String, dynamic> fields,
    Map<String, String> filePaths,
  ) async {
    // Construire le FormData (fichiers optionnels)
    final formFields = <String, dynamic>{};
    fields.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        formFields[key] = value;
      }
    });

    FormData? formData;
    if (filePaths.isNotEmpty) {
      final Map<String, dynamic> allFields = {...formFields};
      for (final entry in filePaths.entries) {
        allFields[entry.key] = await MultipartFile.fromFile(entry.value);
      }
      formData = FormData.fromMap(allFields);
    }

    final response = await dio.put(
      Env.accountModifierInfo,
      data: formData ?? formFields,
      options: formData != null
          ? Options(contentType: 'multipart/form-data')
          : null,
    );

    final json = Map<String, dynamic>.from(response.data['utilisateur']);
    return AccountUserModel.fromJson(json);
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {
    await dio.put(
      Env.accountChangePassword,
      data: {'oldPassword': oldPassword, 'newPassword': newPassword},
    );
  }
}

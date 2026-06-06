import 'package:dio/dio.dart';
import 'package:sign_application/core/config/env.dart';
import '../models/fichie_paie_model.dart';

abstract class FichePaieRemoteDataSource {
  Future<FichePaieModel> creerFichePaie(FichePaieModel fiche);
}

class FichePaieRemoteDataSourceImpl implements FichePaieRemoteDataSource {
  final Dio dio;

  FichePaieRemoteDataSourceImpl(this.dio);

  @override
  Future<FichePaieModel> creerFichePaie(FichePaieModel fiche) async {
    final response = await dio.post(
      Env.fichePaieCreer,
      data: fiche.toJson(),
    );

    if (response.data['success'] == false) {
      throw Exception(response.data['message']);
    }

    return FichePaieModel.fromJson(response.data['data']);
  }
}
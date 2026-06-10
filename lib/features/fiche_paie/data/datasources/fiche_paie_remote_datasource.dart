import 'package:dio/dio.dart';
import 'package:sign_application/core/config/env.dart';
import '../models/fichie_paie_model.dart';

abstract class FichePaieRemoteDataSource {
  Future<FichePaieModel> creerFichePaie(FichePaieModel fiche);
  Future<List<FichePaieModel>> getFichesPaie({int page, int limit});
  Future<List<int>> telechargerFichePaie(String ficheId);
}

class FichePaieRemoteDataSourceImpl implements FichePaieRemoteDataSource {
  final Dio dio;

  FichePaieRemoteDataSourceImpl(this.dio);

  @override
  Future<List<FichePaieModel>> getFichesPaie({int page = 1, int limit = 10}) async {
    final response = await dio.get(
      Env.fichePaieMesFiches,
      queryParameters: {'page': page, 'limit': limit},
    );
    final raw = response.data['data'];
    final List dataList = raw is List
        ? raw
        : (raw is Map && raw['rows'] is List)
            ? raw['rows'] as List
            : (raw is Map && raw['fiches'] is List)
                ? raw['fiches'] as List
                : [];
    return dataList
        .map((e) => FichePaieModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<List<int>> telechargerFichePaie(String ficheId) async {
    final response = await dio.get(
      '${Env.fichePaieDetail}/$ficheId/download',
      options: Options(
        responseType: ResponseType.bytes,
        validateStatus: (s) => s != null && s >= 200 && s < 300,
      ),
    );
    return List<int>.from(response.data);
  }

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
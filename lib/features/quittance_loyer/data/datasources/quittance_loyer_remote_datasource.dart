import 'package:dio/dio.dart';
import 'package:sign_application/core/config/env.dart';
import '../models/quittance_loyer_model.dart';

abstract class QuittanceLoyerRemoteDataSource {
  Future<List<QuittanceLoyerModel>> getQuittances({int page, int limit});
  Future<QuittanceLoyerModel> getQuittanceDetail(String quittanceId);
  Future<void> creerQuittance(Map<String, dynamic> data);
  Future<List<int>> telechargerQuittance(String quittanceId);
}

class QuittanceLoyerRemoteDataSourceImpl implements QuittanceLoyerRemoteDataSource {
  final Dio dio;
  QuittanceLoyerRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<QuittanceLoyerModel>> getQuittances({int page = 1, int limit = 10}) async {
    final response = await dio.get(
      Env.quittanceListe,
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = response.data['data'] as List? ?? [];
    return data
        .map((e) => QuittanceLoyerModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<QuittanceLoyerModel> getQuittanceDetail(String quittanceId) async {
    final response = await dio.get('${Env.quittanceDetail}/$quittanceId');
    return QuittanceLoyerModel.fromJson(
      Map<String, dynamic>.from(response.data['data']),
    );
  }

  @override
  Future<void> creerQuittance(Map<String, dynamic> data) async {
    await dio.post(Env.quittanceCreer, data: data);
  }

  @override
  Future<List<int>> telechargerQuittance(String quittanceId) async {
    final response = await dio.get(
      '${Env.quittanceTelecharger}/$quittanceId/download',
      options: Options(
        responseType: ResponseType.bytes,
        validateStatus: (status) => true,
      ),
    );
    return List<int>.from(response.data);
  }
}

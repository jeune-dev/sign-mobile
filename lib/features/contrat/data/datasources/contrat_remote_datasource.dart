import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_application/core/config/env.dart';
import '../models/contrat_bail_model.dart';

abstract class ContratRemoteDataSource {
  Future<List<ContratBailModel>> getContratsImmobilier({int page, int limit});
  Future<void> creerContratBail(Map<String, dynamic> data);
  Future<List<int>> telechargerContrat(String contratId);
} 

class ContratRemoteDataSourceImpl implements ContratRemoteDataSource {
  final Dio dio;
  ContratRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<ContratBailModel>> getContratsImmobilier({int page = 1, int limit = 10}) async {
    final response = await dio.get(
      Env.contratBailListe,
      queryParameters: {'page': page, 'limit': limit},
    );

    // REST-H01 : logs uniquement en mode debug
    if (kDebugMode) {
      debugPrint('📋 [ContratBail] response.data type: ${response.data.runtimeType}');
      debugPrint('📋 [ContratBail] keys: ${response.data is Map ? (response.data as Map).keys.toList() : "not a map"}');
      debugPrint('📋 [ContratBail] data type: ${response.data['data']?.runtimeType}');
      debugPrint('📋 [ContratBail] data length: ${response.data['data'] is List ? (response.data['data'] as List).length : "not a list"}');
      if (response.data['data'] is List && (response.data['data'] as List).isNotEmpty) {
        final first = (response.data['data'] as List).first;
        debugPrint('📋 [ContratBail] first item keys: ${(first as Map).keys.toList()}');
      }
    }

    // Gère les deux structures possibles :
    // 1. { data: [...] }
    // 2. { data: { contrats: [...], pagination: {...} } }
    List rawList;
    final raw = response.data['data'];
    if (raw is List) {
      rawList = raw;
    } else if (raw is Map && raw['contrats'] is List) {
      rawList = raw['contrats'] as List;
    } else {
      rawList = [];
    }

    return rawList
        .map((e) => ContratBailModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<void> creerContratBail(Map<String, dynamic> data) async {
    await dio.post(Env.contratBailCreer, data: data);
  }

  @override
  Future<List<int>> telechargerContrat(String contratId) async {
    // VULN-M01 : validateStatus restreint aux 2xx uniquement
    final response = await dio.get(
      '${Env.contratBailTelecharger}/$contratId',
      options: Options(
        responseType: ResponseType.bytes,
        validateStatus: (status) => status != null && status >= 200 && status < 300,
      ),
    );
    return List<int>.from(response.data);
  }
}

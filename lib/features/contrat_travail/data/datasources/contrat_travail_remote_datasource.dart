import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_application/core/config/env.dart';
import '../models/contrat_travail_model.dart';

abstract class ContratTravailRemoteDataSource {
  Future<List<ContratTravailModel>> getContratsTravail({int page, int limit});
  Future<ContratTravailModel> getContratTravailDetail(String contratId);
  Future<void> creerContratTravail(Map<String, dynamic> data);
  Future<void> signerContratTravail(String contratId, String signature);
  Future<List<int>> telechargerContratTravail(String contratId);
}

class ContratTravailRemoteDataSourceImpl implements ContratTravailRemoteDataSource {
  final Dio dio;
  ContratTravailRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<ContratTravailModel>> getContratsTravail({int page = 1, int limit = 10}) async {
    final response = await dio.get(
      Env.contratTravailListe,
      queryParameters: {'page': page, 'limit': limit},
    );
    debugPrint('🔍 [ContratTravail] response.data runtimeType: ${response.data.runtimeType}');
    debugPrint('🔍 [ContratTravail] response.data keys: ${response.data is Map ? (response.data as Map).keys.toList() : "not a map"}');
    final raw = response.data['data'];
    debugPrint('🔍 [ContratTravail] data runtimeType: ${raw.runtimeType}');
    if (raw is List) {
      debugPrint('🔍 [ContratTravail] data is List, length=${raw.length}');
      if (raw.isNotEmpty) debugPrint('🔍 [ContratTravail] first item keys: ${(raw.first as Map).keys.toList()}');
    } else if (raw is Map) {
      debugPrint('🔍 [ContratTravail] data is Map, keys=${raw.keys.toList()}');
    }

    // Gère : { data: [...] } ou { data: { rows: [...] } } ou { data: { contrats: [...] } }
    final List dataList = raw is List
        ? raw
        : (raw is Map && raw['rows'] is List)
            ? raw['rows'] as List
            : (raw is Map && raw['contrats'] is List)
                ? raw['contrats'] as List
                : [];

    debugPrint('🔍 [ContratTravail] dataList.length: ${dataList.length}');

    final result = <ContratTravailModel>[];
    for (final e in dataList) {
      try {
        result.add(ContratTravailModel.fromJson(Map<String, dynamic>.from(e as Map)));
      } catch (err) {
        debugPrint('🔍 [ContratTravail] fromJson ERROR: $err — item: $e');
      }
    }
    debugPrint('🔍 [ContratTravail] parsed ${result.length} contrats');
    return result;
  }

  @override
  Future<ContratTravailModel> getContratTravailDetail(String contratId) async {
    final response = await dio.get('${Env.contratTravailDetail}/$contratId');
    return ContratTravailModel.fromJson(
      Map<String, dynamic>.from(response.data['data']),
    );
  }

  @override
  Future<void> creerContratTravail(Map<String, dynamic> data) async {
    // Backend attend : { salarieId, signature_employeur, data: { ...reste } }
    final salarieId          = data.remove('salarieId');
    final signatureEmployeur = data.remove('signature_employeur') ?? '';
    // missions doit être dans data (spread dans le model)
    // S'assurer qu'il est présent et non null
    data['missions'] ??= [];
    final body = {
      'salarieId':           salarieId,
      'signature_employeur': signatureEmployeur,
      'data':                data,
    };
    await dio.post(Env.contratTravailCreer, data: body);
  }

  @override
  Future<void> signerContratTravail(String contratId, String signature) async {
    await dio.post(
      '${Env.contratTravailSigner}/$contratId/sign',
      data: {'signature': signature},
    );
  }

  @override
  Future<List<int>> telechargerContratTravail(String contratId) async {
    final response = await dio.get(
      '${Env.contratTravailTelecharger}/$contratId/download',
      options: Options(
        responseType: ResponseType.bytes,
        validateStatus: (status) => true,
      ),
    );
    return List<int>.from(response.data);
  }
}

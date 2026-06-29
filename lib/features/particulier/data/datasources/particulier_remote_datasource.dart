import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_application/core/config/env.dart';
import '../models/particulier_facture_model.dart';
import '../models/particulier_contrat_model.dart';

abstract class ParticulierRemoteDataSource {
  Future<Map<String, dynamic>> getDashboardStats();
  Future<List<ParticulierFactureModel>> getFactures({String? statut, int page, int limit});
  Future<List<ParticulierContratModel>> getTousContrats({String? statut, String? type});
  Future<List<ParticulierContratModel>> getContratsByType({required String type, String? statut, int page, int limit});
  Future<ParticulierContratModel> getContratDetail({required String type, required String contratId});
  Future<void> signerContrat({required String type, required String contratId, required String signature});
  Future<Uint8List> downloadContratPdf({required String type, required String contratId});
}

class ParticulierRemoteDataSourceImpl implements ParticulierRemoteDataSource {
  final Dio dio;
  ParticulierRemoteDataSourceImpl({required this.dio});

  @override
  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await dio.get(Env.particulierDashboardStats);
    return Map<String, dynamic>.from(response.data['data']);
  }

  @override
  Future<List<ParticulierFactureModel>> getFactures({
    String? statut,
    int page  = 1,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (statut != null) params['statut'] = statut;

    final response = await dio.get(Env.particulierFactures, queryParameters: params);
    final raw = response.data['data'];
    final list = (raw is Map ? raw['factures'] : raw) as List? ?? [];

    final result = <ParticulierFactureModel>[];
    for (final e in list) {
      try {
        result.add(ParticulierFactureModel.fromJson(Map<String, dynamic>.from(e as Map)));
      } catch (err, stack) {
        debugPrint('⚠️ ParticulierFacture parse error: $err');
        if (!kDebugMode) FlutterError.reportError(FlutterErrorDetails(exception: err, stack: stack));
      }
    }
    return result;
  }

  @override
  Future<List<ParticulierContratModel>> getTousContrats({String? statut, String? type}) async {
    final params = <String, dynamic>{};
    if (statut != null) params['statut'] = statut;
    if (type  != null) params['type']   = type;

    final response = await dio.get(Env.particulierContrats, queryParameters: params);
    final raw = response.data['data'];
    final list = (raw is Map ? raw['contrats'] : raw) as List? ?? [];

    return _parseContrats(list);
  }

  @override
  Future<List<ParticulierContratModel>> getContratsByType({
    required String type,
    String? statut,
    int page  = 1,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (statut != null) params['statut'] = statut;

    final response = await dio.get(
      '${Env.particulierContrats}/$type',
      queryParameters: params,
    );
    final raw  = response.data['data'];
    final list = (raw is Map ? raw['contrats'] : raw) as List? ?? [];

    return _parseContrats(list);
  }

  @override
  Future<ParticulierContratModel> getContratDetail({
    required String type,
    required String contratId,
  }) async {
    final response = await dio.get('${Env.particulierContrats}/$type/$contratId');
    final raw = response.data['data'];
    final contratJson = (raw is Map && raw['contrat'] != null) ? raw['contrat'] : raw;
    return ParticulierContratModel.fromJson(Map<String, dynamic>.from(contratJson as Map));
  }

  @override
  Future<void> signerContrat({
    required String type,
    required String contratId,
    required String signature,
  }) async {
    await dio.post(
      '${Env.particulierContrats}/$type/$contratId/signer',
      data: {'signature': signature},
    );
  }

  @override
  Future<Uint8List> downloadContratPdf({
    required String type,
    required String contratId,
  }) async {
    final response = await dio.get(
      '${Env.particulierContrats}/$type/$contratId/pdf',
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data is Uint8List) return data;
    return Uint8List.fromList(List<int>.from(data as List));
  }

  List<ParticulierContratModel> _parseContrats(List list) {
    final result = <ParticulierContratModel>[];
    for (final e in list) {
      try {
        result.add(ParticulierContratModel.fromJson(Map<String, dynamic>.from(e as Map)));
      } catch (err, stack) {
        debugPrint('⚠️ ParticulierContrat parse error: $err');
        if (!kDebugMode) FlutterError.reportError(FlutterErrorDetails(exception: err, stack: stack));
      }
    }
    return result;
  }
}

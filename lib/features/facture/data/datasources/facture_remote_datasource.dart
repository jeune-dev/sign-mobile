import 'package:dio/dio.dart';
import 'package:sign_application/core/config/env.dart';
import '../models/facture_model.dart';

/// Résultat paginé retourné par le backend
class FacturesResult {
  final List<FactureModel> factures;
  final int total;
  final int totalPages;
  final int currentPage;
  final int limit;

  const FacturesResult({
    required this.factures,
    required this.total,
    required this.totalPages,
    required this.currentPage,
    required this.limit,
  });
}

abstract class FactureRemoteDataSource {
  Future<FacturesResult> getFactures({int page, int limit});
  Future<void> creerFacture(Map<String, dynamic> data);
  Future<List<int>> ouvrirDocument(String documentId);
}

class FactureRemoteDataSourceImpl implements FactureRemoteDataSource {
  final Dio dio;
  FactureRemoteDataSourceImpl({required this.dio});

  @override
  Future<FacturesResult> getFactures({int page = 1, int limit = 10}) async {
    final response = await dio.get(
      Env.documentMesDocuments,
      queryParameters: {'page': page, 'limit': limit},
    );

    final body = response.data as Map<String, dynamic>;
    final dataList = body['data'] as List? ?? [];
    final pagination = body['pagination'] as Map<String, dynamic>? ?? {};

    final factures = dataList
        .map((e) => FactureModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return FacturesResult(
      factures: factures,
      total: pagination['total'] ?? factures.length,
      totalPages: pagination['totalPages'] ?? 1,
      currentPage: pagination['page'] ?? page,
      limit: pagination['limit'] ?? limit,
    );
  }

  @override
  Future<void> creerFacture(Map<String, dynamic> data) async {
    await dio.post(Env.documentCreer, data: data);
  }

  @override
  Future<List<int>> ouvrirDocument(String documentId) async {
    final response = await dio.get(
      '${Env.documentOuvrir}/$documentId',
      options: Options(responseType: ResponseType.bytes),
    );
    return List<int>.from(response.data);
  }
}

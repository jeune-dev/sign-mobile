import 'package:dio/dio.dart';
import 'package:sign_application/core/config/env.dart';
import '../../domain/entities/dashboard_stats.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardStats> getDashboardStats();
  Future<List<dynamic>> getDocumentsRecents({int limit});
  Future<List<int>> ouvrirDocument(String documentId);
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final Dio dio;
  DashboardRemoteDataSourceImpl({required this.dio});

  @override
  Future<DashboardStats> getDashboardStats() async {
    final response = await dio.get(Env.dashboardStats);
    final data = response.data['data'] ?? {};

    return DashboardStats(
      nombreFactures: data['nombreFactures'] ?? 0,
      nombreContratsImmobilier: data['nombreContratsImmobilier'] ?? 0,
      nombreContratsTravail: data['nombreContratsTravail'] ?? 0,
    );
  }

  @override
  Future<List<dynamic>> getDocumentsRecents({int limit = 5}) async {
    final response = await dio.get(
      Env.documentMesDocuments,
      queryParameters: {'page': 1, 'limit': limit},
    );
    return List<dynamic>.from(response.data['data'] ?? []);
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

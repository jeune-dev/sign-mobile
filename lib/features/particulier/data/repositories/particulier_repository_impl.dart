import '../../domain/entities/particulier_facture.dart';
import '../../domain/entities/particulier_contrat.dart';
import '../../domain/repositories/particulier_repository.dart';
import '../datasources/particulier_remote_datasource.dart';

class ParticulierRepositoryImpl implements ParticulierRepository {
  final ParticulierRemoteDataSource remoteDataSource;

  ParticulierRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Map<String, dynamic>> getDashboardStats() =>
      remoteDataSource.getDashboardStats();

  @override
  Future<List<ParticulierFacture>> getFactures({
    String? statut,
    int page  = 1,
    int limit = 20,
  }) =>
      remoteDataSource.getFactures(statut: statut, page: page, limit: limit);

  @override
  Future<List<ParticulierContrat>> getTousContrats({String? statut}) =>
      remoteDataSource.getTousContrats(statut: statut);

  @override
  Future<List<ParticulierContrat>> getContratsByType({
    required String type,
    String? statut,
    int page  = 1,
    int limit = 20,
  }) =>
      remoteDataSource.getContratsByType(type: type, statut: statut, page: page, limit: limit);

  @override
  Future<ParticulierContrat> getContratDetail({
    required String type,
    required String contratId,
  }) =>
      remoteDataSource.getContratDetail(type: type, contratId: contratId);

  @override
  Future<void> signerContrat({
    required String type,
    required String contratId,
    required String signature,
  }) =>
      remoteDataSource.signerContrat(type: type, contratId: contratId, signature: signature);
}

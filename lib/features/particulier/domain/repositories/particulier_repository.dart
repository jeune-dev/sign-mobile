import '../entities/particulier_facture.dart';
import '../entities/particulier_contrat.dart';

abstract class ParticulierRepository {
  Future<Map<String, dynamic>> getDashboardStats();
  Future<List<ParticulierFacture>> getFactures({String? statut, int page, int limit});
  Future<List<ParticulierContrat>> getTousContrats({String? statut});
  Future<List<ParticulierContrat>> getContratsByType({required String type, String? statut, int page, int limit});
  Future<ParticulierContrat> getContratDetail({required String type, required String contratId});
  Future<void> signerContrat({required String type, required String contratId, required String signature});
}

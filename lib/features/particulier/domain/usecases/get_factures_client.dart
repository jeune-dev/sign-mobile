import '../entities/particulier_facture.dart';
import '../repositories/particulier_repository.dart';

class GetFacturesClient {
  final ParticulierRepository repository;
  GetFacturesClient(this.repository);

  Future<List<ParticulierFacture>> call({String? statut, int page = 1, int limit = 20}) =>
      repository.getFactures(statut: statut, page: page, limit: limit);
}

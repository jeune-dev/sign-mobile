import '../entities/particulier_contrat.dart';
import '../repositories/particulier_repository.dart';

class GetContratsClient {
  final ParticulierRepository repository;
  GetContratsClient(this.repository);

  Future<List<ParticulierContrat>> call({String? statut}) =>
      repository.getTousContrats(statut: statut);
}

class GetContratsByTypeClient {
  final ParticulierRepository repository;
  GetContratsByTypeClient(this.repository);

  Future<List<ParticulierContrat>> call({required String type, String? statut, int page = 1, int limit = 20}) =>
      repository.getContratsByType(type: type, statut: statut, page: page, limit: limit);
}

class GetContratDetailClient {
  final ParticulierRepository repository;
  GetContratDetailClient(this.repository);

  Future<ParticulierContrat> call({required String type, required String contratId}) =>
      repository.getContratDetail(type: type, contratId: contratId);
}

class SignerContratClient {
  final ParticulierRepository repository;
  SignerContratClient(this.repository);

  Future<void> call({required String type, required String contratId, required String signature}) =>
      repository.signerContrat(type: type, contratId: contratId, signature: signature);
}

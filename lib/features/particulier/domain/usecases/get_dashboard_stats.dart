import '../repositories/particulier_repository.dart';

class GetDashboardStats {
  final ParticulierRepository repository;
  GetDashboardStats(this.repository);

  Future<Map<String, dynamic>> call() => repository.getDashboardStats();
}

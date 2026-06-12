import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../repositories/particulier_repository.dart';

class GetDashboardStats {
  final ParticulierRepository repository;
  GetDashboardStats(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call() =>
      repository.getDashboardStats();
}

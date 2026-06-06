import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../entities/dashboard_stats.dart';

abstract class DashboardRepository {
  Future<Either<Failure, DashboardStats>> getDashboardStats();
  Future<Either<Failure, List<dynamic>>> getDocumentsRecents({int limit = 5});
  Future<Either<Failure, List<int>>> ouvrirDocument(String documentId);
}

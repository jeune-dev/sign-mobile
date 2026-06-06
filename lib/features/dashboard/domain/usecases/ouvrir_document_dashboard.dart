import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../repositories/dashboard_repository.dart';

class OuvrirDocumentDashboard {
  final DashboardRepository repository;
  OuvrirDocumentDashboard(this.repository);

  Future<Either<Failure, List<int>>> call(String documentId) =>
      repository.ouvrirDocument(documentId);
}

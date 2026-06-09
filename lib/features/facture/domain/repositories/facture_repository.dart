import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../entities/facture.dart';

class FacturesPageResult {
  final List<Facture> factures;
  final int total;
  final int totalPages;
  final int currentPage;
  final int limit;

  const FacturesPageResult({
    required this.factures,
    required this.total,
    required this.totalPages,
    required this.currentPage,
    required this.limit,
  });
}

abstract class FactureRepository {
  Future<Either<Failure, FacturesPageResult>> getFactures({int page = 1, int limit = 10});
  Future<Either<Failure, void>> creerFacture(Map<String, dynamic> data);
  Future<Either<Failure, List<int>>> ouvrirDocument(String documentId);
  Future<Either<Failure, Map<String, dynamic>>> mettreAJourFacture({
    required String documentId,
    double? avance,
    String? statut,
  });
}

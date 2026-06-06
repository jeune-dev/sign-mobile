import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../repositories/dashboard_repository.dart';

class GetDocumentsRecents {
  final DashboardRepository repository;
  GetDocumentsRecents(this.repository);

  Future<Either<Failure, List<dynamic>>> call({int limit = 5}) =>
      repository.getDocumentsRecents(limit: limit);
}

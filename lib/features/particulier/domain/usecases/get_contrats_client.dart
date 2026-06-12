import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../entities/particulier_contrat.dart';
import '../repositories/particulier_repository.dart';

class GetContratsClient {
  final ParticulierRepository repository;
  GetContratsClient(this.repository);

  Future<Either<Failure, List<ParticulierContrat>>> call({String? statut}) =>
      repository.getTousContrats(statut: statut);
}

class GetContratsByTypeClient {
  final ParticulierRepository repository;
  GetContratsByTypeClient(this.repository);

  Future<Either<Failure, List<ParticulierContrat>>> call({
    required String type,
    String? statut,
    int page  = 1,
    int limit = 20,
  }) =>
      repository.getContratsByType(type: type, statut: statut, page: page, limit: limit);
}

class GetContratDetailClient {
  final ParticulierRepository repository;
  GetContratDetailClient(this.repository);

  Future<Either<Failure, ParticulierContrat>> call({
    required String type,
    required String contratId,
  }) =>
      repository.getContratDetail(type: type, contratId: contratId);
}

class SignerContratClient {
  final ParticulierRepository repository;
  SignerContratClient(this.repository);

  Future<Either<Failure, void>> call({
    required String type,
    required String contratId,
    required String signature,
  }) =>
      repository.signerContrat(type: type, contratId: contratId, signature: signature);
}

class DownloadContratPdfClient {
  final ParticulierRepository repository;
  DownloadContratPdfClient(this.repository);

  Future<Either<Failure, Uint8List>> call({
    required String type,
    required String contratId,
  }) =>
      repository.downloadContratPdf(type: type, contratId: contratId);
}

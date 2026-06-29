import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../entities/particulier_facture.dart';
import '../entities/particulier_contrat.dart';

abstract class ParticulierRepository {
  Future<Either<Failure, Map<String, dynamic>>> getDashboardStats();
  Future<Either<Failure, List<ParticulierFacture>>> getFactures({String? statut, int page, int limit});
  Future<Either<Failure, List<ParticulierContrat>>> getTousContrats({String? statut, String? type});
  Future<Either<Failure, List<ParticulierContrat>>> getContratsByType({required String type, String? statut, int page, int limit});
  Future<Either<Failure, ParticulierContrat>> getContratDetail({required String type, required String contratId});
  Future<Either<Failure, void>> signerContrat({required String type, required String contratId, required String signature});
  Future<Either<Failure, Uint8List>> downloadContratPdf({required String type, required String contratId});
}

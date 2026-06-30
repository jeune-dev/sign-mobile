import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../entities/account_user.dart';

abstract class AccountRepository {
  Future<Either<Failure, AccountUser>> getMe();

  Future<Either<Failure, AccountUser>> modifierInfoPersonnelles({
    String? nom,
    String? prenom,
    String? email,
    String? telephone,
    String? adresse,
    String? carteIdentiteNationalNum,
    String? rc,
    String? ninea,
    String? nomEntreprise,
    String? adresseEntreprise,
    String? telephoneEntreprise,
    String? emailEntreprise,
    String? photoProfilPath,
    String? logoPath,
    String? signaturePath,
  });

  Future<Either<Failure, void>> changePassword({
    required String oldPassword,
    required String newPassword,
  });

  Future<Either<Failure, void>> deleteAccount();
}

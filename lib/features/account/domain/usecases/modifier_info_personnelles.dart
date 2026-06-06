import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../entities/account_user.dart';
import '../repositories/account_repository.dart';

class ModifierInfoPersonnelles {
  final AccountRepository repository;
  ModifierInfoPersonnelles(this.repository);

  Future<Either<Failure, AccountUser>> call({
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
  }) =>
      repository.modifierInfoPersonnelles(
        nom: nom,
        prenom: prenom,
        email: email,
        telephone: telephone,
        adresse: adresse,
        carteIdentiteNationalNum: carteIdentiteNationalNum,
        rc: rc,
        ninea: ninea,
        nomEntreprise: nomEntreprise,
        adresseEntreprise: adresseEntreprise,
        telephoneEntreprise: telephoneEntreprise,
        emailEntreprise: emailEntreprise,
        photoProfilPath: photoProfilPath,
        logoPath: logoPath,
        signaturePath: signaturePath,
      );
}

import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/errors/failure.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUser {
  final AuthRepository repository;
  RegisterUser(this.repository);

  Future<Either<Failure, User>> call({
    required String nom,
    required String prenom,
    required String telephone,
    required String role,
    // Facultatifs depuis l'inscription rapide (§ 2) : seuls nom, prénom,
    // ville, téléphone et le type de profil sont demandés. Les anciens
    // champs restent acceptés par le backend.
    String? ville,
    String? email,
    String? mot_de_passe,
    String? adresse,
    String? carte_identite_national_num,
    String? typeDocumentIdentite,
    XFile? documentIdentite,
    XFile? photoProfil,
    XFile? logo,
    String? rc,
    String? ninea,
    XFile? signature,

    // Champs entreprise ajoutés
    String? nomEntreprise,
    String? adresseEntreprise,
    String? telephoneEntreprise,
    String? emailEntreprise,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    return await repository.register(
      nom: nom,
      prenom: prenom,
      telephone: telephone,
      role: role,
      ville: ville,
      email: email,
      mot_de_passe: mot_de_passe,
      adresse: adresse,
      carte_identite_national_num: carte_identite_national_num,
      typeDocumentIdentite: typeDocumentIdentite,
      documentIdentite: documentIdentite,
      photoProfil: photoProfil,
      logo: logo,
      rc: rc,
      ninea: ninea,
      signature: signature,
      nomEntreprise: nomEntreprise,
      adresseEntreprise: adresseEntreprise,
      telephoneEntreprise: telephoneEntreprise,
      emailEntreprise: emailEntreprise,
      onSendProgress: onSendProgress,
    );
  }
}
import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/errors/failure.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, void>> forgotPassword(String email);
  Future<Either<Failure, void>> resetPassword(String email, String otpRecu, String newPassword);

  Future<Either<Failure, User>> login(
      String identifiant,
      String motDePasse,
      );

  Future<Either<Failure, User>> register({
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
  });
}
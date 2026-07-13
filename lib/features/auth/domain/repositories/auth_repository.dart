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
    required String email,
    required String mot_de_passe,
    required String adresse,
    required String telephone,
    required String carte_identite_national_num,
    required String role,
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
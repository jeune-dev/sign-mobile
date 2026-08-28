import 'package:equatable/equatable.dart';

/// Entité utilisateur — ne contient JAMAIS le mot de passe (VULN-C03)
class User extends Equatable {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String adresse;
  final String telephone;
  final String carte_identite_national_num;
  final String role;

  // ── Champs du nouveau parcours ─────────────────────────────────────────
  /// Ville de résidence, demandée dès l'inscription rapide (§ 2).
  final String? ville;
  /// Type de la pièce dont [carte_identite_national_num] est le numéro :
  /// 'carte_identite' ou 'passeport'.
  final String? typeDocumentIdentite;
  /// NIN / numéro personnel — demandé seulement quand un document l'exige.
  final String? nin;
  /// L'utilisateur a suivi le parcours « compte complet » (§ 11) : ses
  /// informations sont alors préremplies partout (§ 16).
  final bool profilComplet;
  /// Propriété du numéro confirmée. Vaut true dès l'inscription tant que
  /// l'OTP n'est pas branché.
  final bool telephoneVerifie;
  /// Propriété de l'adresse e-mail confirmée.
  final bool emailVerifie;
  final String? photoProfil;
  final String? logo;
  final String? rc;
  final String? ninea;
  final String? signature;
  final String? token;

  // Champs entreprise
  final String? nomEntreprise;
  final String? adresseEntreprise;
  final String? telephoneEntreprise;
  final String? emailEntreprise;

  const User({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.adresse,
    required this.telephone,
    required this.carte_identite_national_num,
    required this.role,
    this.ville,
    this.typeDocumentIdentite,
    this.nin,
    this.profilComplet = false,
    this.telephoneVerifie = false,
    this.emailVerifie = false,
    this.photoProfil,
    this.logo,
    this.rc,
    this.ninea,
    this.signature,
    this.nomEntreprise,
    this.adresseEntreprise,
    this.telephoneEntreprise,
    this.emailEntreprise,
    this.token,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'prenom': prenom,
    'email': email,
    'adresse': adresse,
    'telephone': telephone,
    'carte_identite_national_num': carte_identite_national_num,
    'role': role,
    'ville': ville,
    'type_document_identite': typeDocumentIdentite,
    'nin': nin,
    'profil_complet': profilComplet,
    'telephone_verifie': telephoneVerifie,
    'email_verifie': emailVerifie,
    'photoProfil': photoProfil,
    'logo': logo,
    'rc': rc,
    'ninea': ninea,
    // VULN-C03 : signature non exposée dans les logs
    'signature': signature != null ? '[PRÉSENT]' : null,
    'nomEntreprise': nomEntreprise,
    'adresseEntreprise': adresseEntreprise,
    'telephoneEntreprise': telephoneEntreprise,
    'emailEntreprise': emailEntreprise,
  };

  @override
  List<Object?> get props => [
    id,
    nom,
    prenom,
    email,
    adresse,
    telephone,
    carte_identite_national_num,
    role,
    ville,
    typeDocumentIdentite,
    nin,
    profilComplet,
    telephoneVerifie,
    emailVerifie,
    photoProfil,
    logo,
    rc,
    ninea,
    nomEntreprise,
    adresseEntreprise,
    telephoneEntreprise,
    emailEntreprise,
    token,
  ];
}

import 'package:equatable/equatable.dart';

class AccountUser extends Equatable {
  final String id;
  final String? nom;
  final String? prenom;
  final String? email;
  final String? telephone;
  final String? adresse;
  final String? role;
  final String? photoProfil;
  final String? logo;
  final String? signature;
  final String? carteIdentiteNationalNum;
  /// Ville de résidence, demandée dès l'inscription rapide (§ 2).
  final String? ville;
  /// NIN / numéro personnel, réclamé seulement quand un document l'exige.
  final String? nin;
  /// L'utilisateur a suivi le parcours « compte complet » (§ 11).
  final bool profilComplet;
  final String? rc;
  final String? ninea;
  final String? nomEntreprise;
  final String? adresseEntreprise;
  final String? telephoneEntreprise;
  final String? emailEntreprise;
  final String? statut;
  /// Vrai une fois l'identite controlee par un administrateur. C'est ce
  /// drapeau — et non `statut` — qui leve la limite de documents : les deux
  /// sont independants, un compte verifie peut ensuite etre desactive.
  final bool compteVerifie;

  const AccountUser({
    required this.id,
    this.nom,
    this.prenom,
    this.email,
    this.telephone,
    this.adresse,
    this.role,
    this.photoProfil,
    this.logo,
    this.signature,
    this.carteIdentiteNationalNum,
    this.ville,
    this.nin,
    this.profilComplet = false,
    this.rc,
    this.ninea,
    this.nomEntreprise,
    this.adresseEntreprise,
    this.telephoneEntreprise,
    this.emailEntreprise,
    this.statut,
    this.compteVerifie = false,
  });

  String get fullName {
    final p = prenom?.trim() ?? '';
    final n = nom?.trim() ?? '';
    if (p.isNotEmpty && n.isNotEmpty) return '$p $n';
    if (p.isNotEmpty) return p;
    if (n.isNotEmpty) return n;
    return 'Utilisateur';
  }

  @override
  List<Object?> get props => [id, nom, prenom, email, role];
}

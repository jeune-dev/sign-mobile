import 'package:equatable/equatable.dart';

class FactureItem extends Equatable {
  final String designation;
  final int quantite;
  final double prixUnitaire;

  const FactureItem({
    required this.designation,
    required this.quantite,
    required this.prixUnitaire,
  });

  @override
  List<Object?> get props => [designation, quantite, prixUnitaire];
}

/// Un règlement encaissé sur une facture.
///
/// Chaque versement a donné lieu à une facture distincte, envoyée aux deux
/// parties — `reference` porte son numéro.
class Versement extends Equatable {
  final double montant;
  final String? date;
  final String? reference;

  const Versement({required this.montant, this.date, this.reference});

  factory Versement.fromJson(Map<String, dynamic> json) => Versement(
        montant: (json['montant'] ?? 0).toDouble(),
        date: json['date']?.toString(),
        reference: json['reference']?.toString(),
      );

  @override
  List<Object?> get props => [montant, date, reference];
}

/// Résumé d'un dossier de facture.
///
/// Une facture réglée en une fois n'est pas un dossier (`estDossier` faux) et
/// s'affiche telle quelle. Dès le deuxième règlement, les factures successives
/// se rangent ensemble : c'est ce que l'écran présente comme un dossier que
/// l'on ouvre.
class DossierFacture extends Equatable {
  final bool estDossier;
  final int nombreFactures;
  final double montantRegle;
  final double resteAPayer;
  final double totalTtc;
  final String? statut;
  final String? derniereFactureId;
  final String? numeroDerniereFacture;

  const DossierFacture({
    this.estDossier = false,
    this.nombreFactures = 1,
    this.montantRegle = 0,
    this.resteAPayer = 0,
    this.totalTtc = 0,
    this.statut,
    this.derniereFactureId,
    this.numeroDerniereFacture,
  });

  factory DossierFacture.fromJson(Map<String, dynamic> json) => DossierFacture(
        estDossier: json['est_dossier'] == true,
        nombreFactures: (json['nombre_factures'] ?? 1) as int,
        montantRegle: (json['montant_regle'] ?? 0).toDouble(),
        resteAPayer: (json['reste_a_payer'] ?? 0).toDouble(),
        totalTtc: (json['total_ttc'] ?? 0).toDouble(),
        statut: json['statut']?.toString(),
        derniereFactureId: json['derniere_facture_id']?.toString(),
        numeroDerniereFacture: json['numero_derniere_facture']?.toString(),
      );

  @override
  List<Object?> get props => [estDossier, nombreFactures, montantRegle, resteAPayer];
}

class Facture extends Equatable {
  final String id;
  final String? numeroFacture;
  final String? dateExecution;
  final String? lieuExecution;
  final double montant;
  final double avance;
  final String? moyenPaiement;
  final int? tva;
  final String? delaisExecution;
  final List<dynamic>? items;
  final Map<String, dynamic>? client;
  final String? statut; // 'en_attente' | 'partiel' | 'payee'
  /// Horodatage automatique serveur — jamais choisi depuis le mobile.
  final String? dateGeneration;

  /// 'envoye' si je suis l'émetteur, 'recu' si la facture m'est adressée.
  ///
  /// Renseigné par le backend : lui seul connaît l'utilisateur courant. Une
  /// facture reçue n'apparaissait pas du tout dans l'application, la requête
  /// ne regardant que les documents émis.
  final String? direction;

  /// L'émetteur, quand la facture m'a été adressée.
  final Map<String, dynamic>? professionnel;

  /// Le règlement d'une facture n'appartient qu'à celui qui l'a émise : le
  /// destinataire ne peut ni changer son statut, ni y enregistrer un
  /// versement, ni la renvoyer. Le backend le dit, et refuse de toute façon
  /// la requête — l'application s'en sert seulement pour ne pas proposer une
  /// action vouée à un refus.
  final bool peutModifier;

  /// Les règlements déjà encaissés, du plus ancien au plus récent.
  final List<Versement> historiqueVersements;

  /// Résumé du dossier : combien de factures, combien reste-t-il à payer.
  final DossierFacture dossier;

  /// Les factures émises après celle-ci pour le même règlement, telles que le
  /// backend les renvoie. Sert à ouvrir chaque pièce du dossier.
  final List<Map<String, dynamic>> versements;

  const Facture({
    required this.id,
    this.numeroFacture,
    this.dateExecution,
    this.lieuExecution,
    required this.montant,
    required this.avance,
    this.moyenPaiement,
    this.tva,
    this.delaisExecution,
    this.items,
    this.client,
    this.statut,
    this.direction,
    this.professionnel,
    this.dateGeneration,
    this.peutModifier = false,
    this.historiqueVersements = const [],
    this.dossier = const DossierFacture(),
    this.versements = const [],
  });

  bool get estRecue => direction == 'recu';

  /// La partie à afficher dans la liste : si la facture est reçue, c'est
  /// l'émetteur qui intéresse l'utilisateur, pas lui-même.
  Map<String, dynamic>? get contrepartie => estRecue ? professionnel : client;

  /// Ce qu'il reste à encaisser, tel que le serveur l'a calculé — jamais
  /// recalculé ici : la TVA et les versements successifs y entrent, et deux
  /// formules finiraient par diverger.
  double get resteAPayer => dossier.resteAPayer;

  double get montantRegle => dossier.montantRegle;

  bool get estSoldee => statut == 'payee' && resteAPayer <= 0;

  @override
  List<Object?> get props => [id, numeroFacture, statut, direction, dossier];
}

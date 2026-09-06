import 'package:equatable/equatable.dart';
import 'package:sign_application/features/facture/domain/entities/facture.dart';

/// Un document contractuel établi avec un client.
///
/// Volontairement pauvre : la fiche client n'affiche qu'un numéro, un état et
/// une date. Le détail se lit dans l'écran du type concerné, qui sait tout ce
/// qu'un bail ou une fiche de paie comporte.
class ContratResume extends Equatable {
  final String id;
  final String type;
  final String typeLabel;
  final String? numero;
  final String? statut;
  final String? date;

  const ContratResume({
    required this.id,
    required this.type,
    required this.typeLabel,
    this.numero,
    this.statut,
    this.date,
  });

  factory ContratResume.fromJson(Map<String, dynamic> json) => ContratResume(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        typeLabel: json['typeLabel']?.toString() ?? 'Document',
        numero: json['numero']?.toString(),
        statut: json['statut']?.toString(),
        date: json['date']?.toString(),
      );

  bool get estSigne => statut == 'signe';

  @override
  List<Object?> get props => [id, type, numero, statut];
}

/// Les contrats d'un même type, réunis.
///
/// Les baux avec les baux, les contrats de travail avec les contrats de
/// travail : c'est le classement demandé pour retrouver une pièce sans
/// parcourir toute la liste.
class GroupeContrats extends Equatable {
  final String type;
  final String typeLabel;
  final List<ContratResume> documents;

  const GroupeContrats({
    required this.type,
    required this.typeLabel,
    required this.documents,
  });

  factory GroupeContrats.fromJson(Map<String, dynamic> json) => GroupeContrats(
        type: json['type']?.toString() ?? '',
        typeLabel: json['typeLabel']?.toString() ?? 'Documents',
        documents: (json['documents'] as List? ?? [])
            .map((e) => ContratResume.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );

  @override
  List<Object?> get props => [type, documents];
}

/// Ce qui a été établi avec un client, en un coup d'oeil.
class ResumeDossierClient extends Equatable {
  final int nbFactures;
  final int nbContrats;
  final double montantFacture;
  final double montantRegle;
  final double resteAPayer;

  const ResumeDossierClient({
    this.nbFactures = 0,
    this.nbContrats = 0,
    this.montantFacture = 0,
    this.montantRegle = 0,
    this.resteAPayer = 0,
  });

  factory ResumeDossierClient.fromJson(Map<String, dynamic> json) =>
      ResumeDossierClient(
        nbFactures: (json['nb_factures'] ?? 0) as int,
        nbContrats: (json['nb_contrats'] ?? 0) as int,
        montantFacture: (json['montant_facture'] ?? 0).toDouble(),
        montantRegle: (json['montant_regle'] ?? 0).toDouble(),
        resteAPayer: (json['reste_a_payer'] ?? 0).toDouble(),
      );

  @override
  List<Object?> get props => [nbFactures, nbContrats, montantFacture, resteAPayer];
}

/// La fiche d'un client : ses factures et ses contrats.
///
/// Les factures arrivent déjà groupées par dossier — une facture réglée en
/// plusieurs fois n'y compte que pour une entrée. Les contrats arrivent
/// groupés par type.
class DossierClient extends Equatable {
  final ResumeDossierClient resume;
  final List<Facture> factures;
  final List<GroupeContrats> contrats;

  const DossierClient({
    required this.resume,
    required this.factures,
    required this.contrats,
  });

  @override
  List<Object?> get props => [resume, factures, contrats];
}

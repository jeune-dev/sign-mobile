import 'package:equatable/equatable.dart';

class ParticulierContrat extends Equatable {
  final String id;
  final String type;
  final String typeLabel;
  final String numeroContrat;
  final String statut;
  final bool peutSigner;
  final String createdAt;
  final String? generateurNom;
  final String? generateurEntreprise;
  final String? generateurEmail;
  final Map<String, dynamic> rawData;

  const ParticulierContrat({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.numeroContrat,
    required this.statut,
    required this.peutSigner,
    required this.createdAt,
    this.generateurNom,
    this.generateurEntreprise,
    this.generateurEmail,
    required this.rawData,
  });

  bool get estSigne => statut == 'signe' || statut == 'Actif';

  @override
  List<Object?> get props => [id, type];
}

import 'package:sign_application/features/facture/data/models/facture_model.dart';
import '../../domain/entities/dossier_client.dart';

/// Traduction de la réponse `/professionnel/client/:id/dossier`.
///
/// Les factures réutilisent `FactureModel` : la fiche client et la liste des
/// factures affichent les mêmes objets, avec le même dossier de versements —
/// deux modèles parallèles finiraient par diverger.
class DossierClientModel extends DossierClient {
  const DossierClientModel({
    required super.resume,
    required super.factures,
    required super.contrats,
  });

  factory DossierClientModel.fromJson(Map<String, dynamic> json) {
    return DossierClientModel(
      resume: ResumeDossierClient.fromJson(
        Map<String, dynamic>.from(json['resume'] ?? {}),
      ),
      factures: (json['factures'] as List? ?? [])
          .map((e) => FactureModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      contrats: (json['contrats'] as List? ?? [])
          .map((e) => GroupeContrats.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

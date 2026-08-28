/// type_document_signs.dart — Clés de documents partagées avec le backend.
///
/// Ces valeurs doivent correspondre exactement aux clés de
/// `exigencesDocument.referentiel.js` côté serveur : c'est sur elles que
/// SIGNS décide quelles informations réclamer avant la création d'un document
/// (§ 4 du cahier des charges).
///
/// Un type inconnu du backend n'est pas une erreur : le serveur applique
/// alors des exigences minimales, et le parcours continue normalement.
library;

class TypeDocumentSigns {
  TypeDocumentSigns._();

  static const String facture = 'facture';
  static const String contratBail = 'contrat-bail';
  static const String contratTravail = 'contrat-travail';
  static const String quittanceLoyer = 'quittance-loyer';
  static const String etatLogement = 'etat-logement';
  static const String fichePaie = 'fiche-paie';

  /// Traduit l'identifiant utilisé dans les écrans de contrats
  /// (`bail`, `travail`, ou directement la valeur d'API des autres contrats)
  /// vers la clé attendue par le backend.
  static String depuisIdContrat(String id) {
    switch (id) {
      case 'bail':
        return contratBail;
      case 'travail':
        return contratTravail;
      default:
        // Les « autres contrats » utilisent déjà la valeur d'API du backend
        // (contrat-prestation, procuration, reconnaissance-dette…).
        return id;
    }
  }
}

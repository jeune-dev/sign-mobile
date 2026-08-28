/// document_cree.dart — Ce que renvoie une création de document.
///
/// Les API de création répondent déjà `{ success, message, data: <document> }`,
/// mais l'application jetait cette réponse : les blocs n'émettaient qu'un
/// message. Impossible, dans ces conditions, d'afficher le document juste
/// après l'avoir généré — il fallait retourner à la liste et le retrouver.
///
/// Ce petit objet fait remonter le strict nécessaire pour ouvrir l'écran de
/// confirmation (§ 9) : de quoi retélécharger le PDF, et de quoi le nommer.
class DocumentCree {
  /// Identifiant du document créé, utilisé pour télécharger son PDF.
  /// `null` si l'API n'a rien renvoyé d'exploitable — l'écran de confirmation
  /// est alors ignoré, sans que la création soit remise en cause.
  final String? id;

  /// Numéro ou référence lisible (« F-2026-001 »), affiché à l'utilisateur.
  final String? reference;

  const DocumentCree({this.id, this.reference});

  bool get exploitable => id != null && id!.isNotEmpty;

  /// Construit l'objet à partir du corps de réponse d'une API de création,
  /// quelle que soit la fonctionnalité : le document se trouve sous `data`,
  /// et sa référence porte un nom différent selon le type de document.
  factory DocumentCree.depuisReponse(dynamic corps) {
    if (corps is! Map) return const DocumentCree();

    final donnees = corps['data'] is Map
        ? Map<String, dynamic>.from(corps['data'] as Map)
        : Map<String, dynamic>.from(corps);

    String? premierNonVide(List<String> cles) {
      for (final cle in cles) {
        final valeur = donnees[cle];
        if (valeur != null && valeur.toString().trim().isNotEmpty) {
          return valeur.toString();
        }
      }
      return null;
    }

    return DocumentCree(
      id: premierNonVide(['id', 'contratId', 'documentId', 'factureId']),
      reference: premierNonVide([
        'numero_contrat',
        'numero_facture',
        'numero_quittance',
        'numero',
        'reference',
      ]),
    );
  }
}

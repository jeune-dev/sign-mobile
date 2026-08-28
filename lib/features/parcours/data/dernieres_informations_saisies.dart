/// dernieres_informations_saisies.dart — Ce que l'utilisateur vient de saisir.
///
/// Rien de ce que l'utilisateur saisit pour un document n'est enregistré sur
/// son compte tant qu'il ne l'a pas autorisé. Ces valeurs doivent pourtant
/// vivre le temps de la création : la feuille des informations manquantes
/// s'ouvre avant le formulaire, et la proposition d'enregistrement s'affiche
/// après que l'écran s'est refermé.
///
/// Ce dépôt est ce tampon, et rien d'autre :
///   - en mémoire uniquement, jamais écrit sur le disque ;
///   - vidé à l'ouverture de chaque document, pour que les mêmes informations
///     soient redemandées à chaque fois tant que l'enregistrement n'est pas
///     autorisé ;
///   - vidé également dès qu'il a servi à alimenter le profil.
///
/// Ce n'est pas un cache de profil — la source de vérité reste le backend.
library;

class DernieresInformationsSaisies {
  final Map<String, dynamic> _valeurs = {};

  /// Ajoute une saisie au tampon du document en cours.
  ///
  /// Fusion et non remplacement : la feuille des informations manquantes et
  /// le formulaire alimentent tour à tour le même document, chacun avec ses
  /// propres champs. Un remplacement perdrait ceux de l'autre.
  void memoriser(Map<String, dynamic> valeurs) {
    valeurs.forEach((cle, valeur) {
      final texte = valeur?.toString().trim() ?? '';
      if (texte.isNotEmpty) _valeurs[cle] = valeur;
    });
  }

  /// Saisie du document en cours, ou null si rien n'a été fourni.
  Map<String, dynamic>? get valeurs =>
      _valeurs.isEmpty ? null : Map<String, dynamic>.from(_valeurs);

  bool get disponible => _valeurs.isNotEmpty;

  /// À appeler à l'ouverture d'un document, et une fois les informations
  /// enregistrées dans le profil.
  void vider() => _valeurs.clear();
}

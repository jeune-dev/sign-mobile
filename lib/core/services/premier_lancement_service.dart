import 'package:shared_preferences/shared_preferences.dart';

/// premier_lancement_service.dart — Mémorise ce que l'utilisateur a déjà vu.
///
/// Deux drapeaux, tous deux locaux à l'appareil :
///
///   * `bienvenue_vue`      — la page de bienvenue (§ 1) ne s'affiche qu'à la
///                            toute première ouverture de l'application ;
///   * `proposition_compte` — la proposition de créer un compte complet
///                            (§ 10) ne doit pas revenir harceler quelqu'un
///                            qui l'a déjà refusée.
///
/// SharedPreferences plutôt que le stockage sécurisé : ce ne sont pas des
/// secrets, et une lecture de SharedPreferences est synchrone côté natif,
/// donc sans latence perceptible au démarrage.
class PremierLancementService {
  static const _cleBienvenueVue = 'signs_bienvenue_vue';
  static const _cleCompteRefuse = 'signs_proposition_compte_refusee';

  /// La page de bienvenue doit-elle être affichée ?
  Future<bool> doitAfficherBienvenue() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_cleBienvenueVue) ?? false);
  }

  /// À appeler quand l'utilisateur appuie sur « Commencer ».
  Future<void> marquerBienvenueVue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cleBienvenueVue, true);
  }

  /// L'utilisateur a-t-il déjà décliné la création du compte complet ?
  Future<bool> propositionCompteRefusee() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_cleCompteRefuse) ?? false;
  }

  /// « Plus tard » sur la proposition de compte complet — on n'y revient plus.
  Future<void> marquerPropositionCompteRefusee() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cleCompteRefuse, true);
  }

  /// Remet le drapeau à zéro : appelé à la déconnexion, pour qu'un autre
  /// utilisateur du même téléphone reçoive bien la proposition.
  Future<void> reinitialiserPropositionCompte() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cleCompteRefuse);
  }
}

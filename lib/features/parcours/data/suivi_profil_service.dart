import 'package:flutter/foundation.dart';

import '../domain/etat_profil.dart';
import 'datasources/parcours_remote_datasource.dart';

/// suivi_profil_service.dart — L'état d'avancement du profil, en un seul point.
///
/// La pastille rouge du bouton de réglage, les compteurs des deux écrans de
/// complétion et les raccourcis du profil lisent tous cette instance : sans
/// elle, chaque écran interrogeait le serveur pour son compte et affichait un
/// chiffre différent de son voisin.
///
/// C'est un [ChangeNotifier] : un écran qui dépose une pièce ou enregistre une
/// information appelle [rafraichir], et la pastille s'éteint d'elle-même
/// partout où elle était allumée.
class SuiviProfilService extends ChangeNotifier {
  final ParcoursRemoteDataSource source;

  SuiviProfilService({required this.source});

  EtatProfil? _etat;
  bool _chargement = false;

  /// `null` tant que rien n'a été chargé : aucun écran ne doit annoncer
  /// « 0 champ restant » alors qu'il n'en sait encore rien.
  EtatProfil? get etat => _etat;

  bool get chargement => _chargement;

  /// Recharge le profil et les justificatifs, puis recalcule l'état.
  ///
  /// Échec silencieux : sans réseau, on garde le dernier état connu plutôt que
  /// d'éteindre une pastille qui a peut-être encore lieu d'être.
  Future<void> rafraichir() async {
    if (_chargement) return;
    _chargement = true;
    try {
      final profil = await source.prereemplissage();
      final justificatifs = await source.listerJustificatifs();
      _etat = EtatProfil.analyser(
        profil: profil,
        justificatifs: justificatifs.justificatifs,
      );
      notifyListeners();
    } catch (_) {
      // Rien à faire : l'état précédent reste affiché.
    } finally {
      _chargement = false;
    }
  }

  /// Applique un état déjà calculé.
  ///
  /// Un écran qui vient de charger le profil ET les justificatifs pour son
  /// propre affichage n'a aucune raison de refaire les deux appels : il pousse
  /// son résultat ici, et la pastille suit.
  void appliquer(EtatProfil nouvelEtat) {
    _etat = nouvelEtat;
    notifyListeners();
  }

  /// Déconnexion : l'état du compte précédent ne doit pas se retrouver sur
  /// celui qui se connecte ensuite depuis le même téléphone.
  void vider() {
    _etat = null;
    notifyListeners();
  }
}

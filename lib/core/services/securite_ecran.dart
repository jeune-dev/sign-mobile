import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Empêche la capture des écrans qui affichent une pièce d'identité.
///
/// ── Ce que cela protège ───────────────────────────────────────────────────
/// Le drapeau natif `FLAG_SECURE` bloque trois choses à la fois : la capture
/// d'écran, l'enregistrement vidéo, et la vignette que le système conserve
/// dans le gestionnaire de tâches.
///
/// C'est la vignette qui compte le plus. Android photographie l'écran à chaque
/// changement d'application, et cette image survit à la fermeture de l'app :
/// une CNI affichée reste consultable dans le carrousel des tâches récentes,
/// et lisible par quiconque prend le téléphone en main.
///
/// ── Pourquoi pas partout ──────────────────────────────────────────────────
/// La protection n'est PAS posée globalement. Un utilisateur doit pouvoir
/// capturer sa propre facture ou son contrat pour l'envoyer à un tiers ;
/// verrouiller toute l'application le priverait d'un usage légitime pour un
/// gain de sécurité nul — ces documents lui appartiennent et il les a déjà.
/// Seuls les écrans qui manipulent une pièce d'identité l'activent.
///
/// ── Limite connue ─────────────────────────────────────────────────────────
/// iOS n'expose aucun équivalent : le système ne permet pas d'interdire la
/// capture à une application. Les appels sont donc sans effet sur iPhone, et
/// silencieux plutôt qu'en erreur — un écran ne doit jamais planter parce que
/// la plateforme ne sait pas se protéger.
class SecuriteEcran {
  const SecuriteEcran._();

  static const MethodChannel _canal = MethodChannel('signs/securite_ecran');

  static Future<void> _appeler(String methode) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _canal.invokeMethod<void>(methode);
    } on PlatformException catch (e) {
      // Une protection d'écran qui échoue ne doit pas empêcher de consulter
      // ses justificatifs : on la journalise sans interrompre le parcours.
      debugPrint('[SecuriteEcran] $methode indisponible : ${e.message}');
    } on MissingPluginException {
      // Canal absent (build partiel, test) — sans conséquence fonctionnelle.
    }
  }

  /// À appeler dans `initState` d'un écran affichant une pièce d'identité.
  static Future<void> activer() => _appeler('activer');

  /// À appeler dans `dispose` du même écran. Impérativement symétrique :
  /// oublier la levée verrouillerait la capture pour tout le reste de la
  /// session, y compris sur les écrans où elle est légitime.
  static Future<void> desactiver() => _appeler('desactiver');
}

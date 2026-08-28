import 'package:flutter/material.dart';

import 'package:sign_application/core/theme/app_color.dart';
import 'package:sign_application/core/widgets/toastNotif.dart';
import 'package:toastification/toastification.dart';
import 'package:sign_application/injection_container.dart';

import '../data/datasources/parcours_remote_datasource.dart';
import '../data/models/exigences_document.dart';
import 'widgets/informations_manquantes_sheet.dart';
import 'widgets/proposition_compte_complet_dialog.dart';
import 'package:sign_application/core/theme/app_typo.dart';
import 'widgets/quota_atteint_dialog.dart';
import 'package:sign_application/core/routes/app_router.dart';
import '../data/dernieres_informations_saisies.dart';

/// parcours_document.dart — Point d'entrée unique de la création d'un document.
///
/// Enchaîne, dans l'ordre du cahier des charges :
///
///   § 4  — demander à SIGNS ce qu'il manque pour ce document, et le réclamer
///          à l'utilisateur avant d'ouvrir le formulaire ;
///   § 7  — ouvrir le formulaire de création ;
///   § 10 — au retour, si un document a bien été créé, proposer la création
///          du compte complet.
///
/// Les pages de création n'ont donc rien à savoir de ce parcours : il suffit
/// de remplacer leur `Navigator.push(...)` par `ParcoursDocument.ouvrir(...)`.
class ParcoursDocument {
  ParcoursDocument._();

  /// Ouvre un formulaire de création en respectant tout le parcours.
  ///
  /// [typeDocument] doit correspondre à une clé du référentiel backend
  /// (`facture`, `contrat-bail`, `contrat-prestation`…).
  /// [page] construit l'écran de création.
  /// [profilComplet] évite de reproposer le compte complet à quelqu'un qui
  /// l'a déjà créé.
  static Future<void> ouvrir(
    BuildContext context, {
    required String typeDocument,
    required WidgetBuilder page,
    bool profilComplet = false,
  }) async {
    // Chaque document repart d'un tampon vide : tant que l'utilisateur n'a
    // pas autorisé l'enregistrement de ses informations, elles lui sont
    // redemandées à chaque création plutôt que d'être conservées.
    sl<DernieresInformationsSaisies>().vider();

    // Un seul appel : la réponse porte à la fois le quota et les
    // informations manquantes.
    final exigences = await _chargerExigences(typeDocument);

    // Le quota passe avant tout le reste : inutile de réclamer des
    // informations pour un document que l'utilisateur ne pourra pas créer.
    if (exigences != null && !exigences.quota.autorise) {
      if (!context.mounted) return;
      await QuotaAtteintDialog.afficher(context, exigences.quota);
      return;
    }

    if (!context.mounted) return;
    final peutContinuer = await _reclamerInformationsManquantes(context, exigences);
    if (!peutContinuer || !context.mounted) return;

    // § 9 / § 15 : les identifiants déjà enregistrés sont contrôlés AVANT
    // d'ouvrir le formulaire. Signaler un numéro incohérent maintenant vaut
    // mieux que de le faire après vingt champs remplis.
    final generationAutorisee = await autoriserGeneration(context, typeDocument);
    if (!generationAutorisee || !context.mounted) return;

    // Les pages de création renvoient `true` quand un document a été généré.
    final documentCree = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: page),
    );

    if (documentCree != true || !context.mounted) return;

    // Compteur relu apres la creation : c est la seule valeur juste. Le quota
    // charge plus haut ignore le document qui vient d etre produit, et un
    // autre appareil a pu en creer entre-temps.
    final quotaApres = (await _chargerExigences(typeDocument))?.quota;
    final restants = quotaApres != null && quotaApres.limite
        ? quotaApres.restants
        : (exigences != null && exigences.quota.limite
            ? (exigences.quota.restants - 1).clamp(0, exigences.quota.plafond)
            : null);

    if (!context.mounted) return;

    // L utilisateur doit savoir ou il en est apres CHAQUE document : la
    // suspension du compte au-dela de la limite ne doit jamais le surprendre.
    if (restants != null) {
      await _annoncerDocumentsRestants(context, restants, quotaApres);
      if (!context.mounted) return;
    }

    await PropositionCompteCompletDialog.afficherSiNecessaire(
      context,
      profilDejaComplet: profilComplet,
      documentsRestants: restants,
    );
  }

  /// Annonce ce qu il reste apres une creation.
  ///
  /// Zero restant : la fenetre complete, celle-la meme qui accueillera la
  /// prochaine tentative — mieux vaut l apprendre maintenant qu au moment de
  /// commencer un document qu on ne pourra pas finir. Sinon un simple rappel.
  static Future<void> _annoncerDocumentsRestants(
    BuildContext context,
    int restants,
    QuotaDocument? quota,
  ) async {
    if (restants <= 0) {
      if (quota != null) await QuotaAtteintDialog.afficher(context, quota);
      return;
    }

    showToast(
      context,
      restants == 1 ? 'Dernier document' : 'Document créé',
      restants == 1
          ? "Il vous reste 1 document avant la vérification de votre compte."
          : "Il vous reste $restants documents avant la vérification de votre compte.",
      restants == 1 ? ToastificationType.warning : ToastificationType.info,
    );
  }

  /// Interroge le backend. Renvoie null si l'appel échoue — on n'empêche
  /// alors pas l'utilisateur de travailler : le serveur tranchera à la
  /// création (403 QUOTA_ATTEINT le cas échéant).
  static Future<ExigencesDocument?> _chargerExigences(String typeDocument) async {
    try {
      return await sl<ParcoursRemoteDataSource>().exigences(typeDocument);
    } catch (_) {
      return null;
    }
  }

  /// § 4 : interroge le backend et, si besoin, ouvre la feuille de saisie.
  ///
  /// Renvoie `false` uniquement quand l'utilisateur a renoncé alors qu'une
  /// information indispensable manquait.
  static Future<bool> _reclamerInformationsManquantes(
    BuildContext context,
    ExigencesDocument? exigences,
  ) async {
    // Backend injoignable ou type inconnu : on n'empêche pas l'utilisateur de
    // travailler — le contrôle avant génération refera le point.
    if (exigences == null) return true;
    if (exigences.riensADemander) return true;
    if (!context.mounted) return true;

    final saisie = await InformationsManquantesSheet.afficher(context, exigences);
    if (saisie == null) return false;

    // La saisie n'est pas enregistrée : elle est retenue le temps du document
    // et alimentera la proposition d'enregistrement, après la génération.
    sl<DernieresInformationsSaisies>().memoriser(saisie);
    return true;
  }

  /// § 9 et § 15 : contrôle final juste avant de générer le document.
  ///
  /// Renvoie `true` si la génération peut avoir lieu. Un identifiant au
  /// niveau « format valide » ne bloque pas : il est signalé, puis
  /// l'utilisateur décide.
  static Future<bool> autoriserGeneration(
    BuildContext context,
    String typeDocument,
  ) async {
    VerificationGeneration verification;
    try {
      verification = await sl<ParcoursRemoteDataSource>().verifierAvantGeneration(
        typeDocument,
        valeursFournies: sl<DernieresInformationsSaisies>().valeurs,
      );
    } catch (_) {
      // Le backend revalidera de toute façon à la création : on laisse passer
      // plutôt que de bloquer sur une erreur réseau.
      return true;
    }

    if (!context.mounted) return true;

    // 🔴 Génération bloquée : une information indispensable est absente ou
    // manifestement incohérente.
    if (!verification.autorise) {
      await _afficherBlocages(context, verification, typeDocument);
      return false;
    }

    // 🟠 Format valide mais non vérifiable : on informe et on laisse le choix.
    if (verification.avertissements.isNotEmpty) {
      final continuer = await _confirmerMalgreAvertissements(context, verification);
      if (continuer) return true;

      // « Vérifier mes informations » ne renvoyait nulle part : l'utilisateur
      // était simplement ramené en arrière, sans moyen d'agir. On l'amène là
      // où le signalement se résout réellement.
      if (!context.mounted) return false;
      await _corrigerInformations(context, verification, typeDocument);
      return false;
    }

    return true;
  }

  /// Champs dont un avertissement se lève en déposant une photo de la pièce :
  /// SIGNS sait que le format est bon, mais ne peut pas confirmer l'existence
  /// du numéro — seul un justificatif permet à l'admin de trancher.
  static const _champsPiece = {
    'carte_identite_national_num',
    'type_document_identite',
    'nin',
    'rc',
    'ninea',
  };

  /// Amène l'utilisateur à l'endroit qui résout ses signalements.
  ///
  /// Un numéro de pièce « format valide, non vérifiable » se règle par le
  /// dépôt d'une photo ; un champ simplement absent se règle en le saisissant.
  static Future<void> _corrigerInformations(
    BuildContext context,
    VerificationGeneration verification,
    String typeDocument,
  ) async {
    final concernePiece = verification.avertissements
        .any((s) => _champsPiece.contains(s.champ));

    if (concernePiece) {
      await Navigator.of(context).pushNamed(AppRouter.justificatifsRoute);
      return;
    }

    final exigences = await _chargerExigences(typeDocument);
    if (!context.mounted) return;
    await _reclamerInformationsManquantes(context, exigences);
  }

  static Future<void> _afficherBlocages(
    BuildContext context,
    VerificationGeneration verification,
    String typeDocument,
  ) async {
    final corriger = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogueSignalements(
        titre: 'Génération impossible',
        introduction:
            'Certaines informations doivent être corrigées avant de générer ce document.',
        signalements: verification.blocages,
        couleur: AppColor.kDanger,
        icone: Icons.error_outline_rounded,
        libelleAction: 'Corriger maintenant',
      ),
    );

    if (corriger != true) return;

    final exigences = await _chargerExigences(typeDocument);
    if (!context.mounted) return;
    await _reclamerInformationsManquantes(context, exigences);
  }

  static Future<bool> _confirmerMalgreAvertissements(
    BuildContext context,
    VerificationGeneration verification,
  ) async {
    final continuer = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogueSignalements(
        titre: 'Vérification non disponible',
        introduction:
            'Le format de ces informations est correct, mais SIGNS ne peut pas '
            'confirmer leur existence auprès d’une source officielle.',
        signalements: verification.avertissements,
        couleur: AppColor.kAlerte,
        icone: Icons.info_outline_rounded,
        libelleAction: 'Générer quand même',
        libelleAnnulation: 'Vérifier mes informations',
      ),
    );
    return continuer == true;
  }
}

/// Boîte de dialogue commune aux blocages (🔴) et aux avertissements (🟠).
class _DialogueSignalements extends StatelessWidget {
  final String titre;
  final String introduction;
  final List<SignalementGeneration> signalements;
  final Color couleur;
  final IconData icone;
  final String libelleAction;
  final String libelleAnnulation;

  const _DialogueSignalements({
    required this.titre,
    required this.introduction,
    required this.signalements,
    required this.couleur,
    required this.icone,
    required this.libelleAction,
    this.libelleAnnulation = 'Annuler',
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, color: couleur, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    titre,
                    style: AppTypo.jakarta(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColor.kGrayscaleDark100,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              introduction,
              style: AppTypo.jakarta(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: AppColor.kGrayscale40,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.35,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: signalements
                      .map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: couleur,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    s.message,
                                    style: AppTypo.jakarta(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppColor.kGrayscaleDark100,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // `OverflowBar` plutôt qu'un `Row` : les libellés sont propres à
            // chaque appel — « Vérifier mes informations » et « Générer quand
            // même » côte à côte débordaient sur un écran de 360 dp. Ils sont
            // alors empilés au lieu d'être tronqués, l'action principale
            // restant en dernier dans les deux dispositions.
            OverflowBar(
              alignment: MainAxisAlignment.end,
              overflowAlignment: OverflowBarAlignment.end,
              spacing: 4,
              overflowSpacing: 2,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    libelleAnnulation,
                    textAlign: TextAlign.center,
                    style: AppTypo.jakarta(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColor.kGrayscale40,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    libelleAction,
                    textAlign: TextAlign.center,
                    style: AppTypo.jakarta(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColor.kPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

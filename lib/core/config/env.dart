import 'package:flutter_dotenv/flutter_dotenv.dart';

/// REST-C01 : Variables d'environnement lues depuis --dart-define (production)
/// avec fallback sur flutter_dotenv (développement local).
///
/// En production :
///   flutter build apk --dart-define=API_BASE_URL=https://sign-backend-ha5a.onrender.com/sign ...
///
/// En développement :
///   Les valeurs sont lues depuis le fichier .env (non bundlé dans l'APK).
class Env {
  // ─── Résolution d'une variable ──────────────────────────────────────────────
  // Priorité : 1) --dart-define   2) .env local   3) valeur par défaut
  static String _get(String key, {required String fallback}) {
    // 1. Valeur injectée à la compilation via --dart-define
    // fromEnvironment est évalué à compile-time par clé littérale,
    // donc on utilise un switch statique pour chaque clé connue.
    final fromDefine = _fromDefine(key);
    if (fromDefine.isNotEmpty) return fromDefine;

    // 2. Fallback sur .env chargé en mémoire (dev uniquement)
    // Guard : dotenv.load() peut ne pas avoir été appelé (prod sans --dart-define)
    try {
      final fromDotenv = dotenv.maybeGet(key)?.trim();
      if (fromDotenv != null && fromDotenv.isNotEmpty) return fromDotenv;
    } catch (_) {
      // dotenv non initialisé — on tombe sur le fallback codé en dur ci-dessous
    }

    // 3. Valeur par défaut codée en dur
    return fallback;
  }

  /// Résolution à la compilation via --dart-define (retourne '' si non définie)
  static String _fromDefine(String key) {
    switch (key) {
      case 'API_BASE_URL':
        return const String.fromEnvironment('API_BASE_URL');
      case 'AUTH_LOGIN_PATH':
        return const String.fromEnvironment('AUTH_LOGIN_PATH');
      case 'AUTH_REGISTER_PATH':
        return const String.fromEnvironment('AUTH_REGISTER_PATH');
      case 'ACCOUNT_ME_PATH':
        return const String.fromEnvironment('ACCOUNT_ME_PATH');
      case 'ACCOUNT_MODIFIER_INFO_PATH':
        return const String.fromEnvironment('ACCOUNT_MODIFIER_INFO_PATH');
      case 'ACCOUNT_CHANGE_PASSWORD_PATH':
        return const String.fromEnvironment('ACCOUNT_CHANGE_PASSWORD_PATH');
      case 'CLIENT_LISTE_PATH':
        return const String.fromEnvironment('CLIENT_LISTE_PATH');
      case 'CLIENT_AJOUT_PATH':
        return const String.fromEnvironment('CLIENT_AJOUT_PATH');
      case 'CLIENT_RECHERCHE_PATH':
        return const String.fromEnvironment('CLIENT_RECHERCHE_PATH');
      case 'DOCUMENT_MES_DOCUMENTS_PATH':
        return const String.fromEnvironment('DOCUMENT_MES_DOCUMENTS_PATH');
      case 'DOCUMENT_CREER_PATH':
        return const String.fromEnvironment('DOCUMENT_CREER_PATH');
      case 'DOCUMENT_OUVRIR_PATH':
        return const String.fromEnvironment('DOCUMENT_OUVRIR_PATH');
      case 'DOCUMENT_TELECHARGER_PATH':
        return const String.fromEnvironment('DOCUMENT_TELECHARGER_PATH');
      case 'CONTRAT_BAIL_LISTE_PATH':
        return const String.fromEnvironment('CONTRAT_BAIL_LISTE_PATH');
      case 'CONTRAT_BAIL_CREER_PATH':
        return const String.fromEnvironment('CONTRAT_BAIL_CREER_PATH');
      case 'CONTRAT_BAIL_TELECHARGER_PATH':
        return const String.fromEnvironment('CONTRAT_BAIL_TELECHARGER_PATH');
      case 'CONTRAT_BAIL_SIGNER_PATH':
        return const String.fromEnvironment('CONTRAT_BAIL_SIGNER_PATH');
      case 'DASHBOARD_STATS_PATH':
        return const String.fromEnvironment('DASHBOARD_STATS_PATH');
      case 'CONTRAT_TRAVAIL_CREER_PATH':
        return const String.fromEnvironment('CONTRAT_TRAVAIL_CREER_PATH');
      case 'CONTRAT_TRAVAIL_LISTE_PATH':
        return const String.fromEnvironment('CONTRAT_TRAVAIL_LISTE_PATH');
      case 'CONTRAT_TRAVAIL_DETAIL_PATH':
        return const String.fromEnvironment('CONTRAT_TRAVAIL_DETAIL_PATH');
      case 'CONTRAT_TRAVAIL_TELECHARGER_PATH':
        return const String.fromEnvironment('CONTRAT_TRAVAIL_TELECHARGER_PATH');
      case 'CONTRAT_TRAVAIL_SIGNER_PATH':
        return const String.fromEnvironment('CONTRAT_TRAVAIL_SIGNER_PATH');
      case 'QUITTANCE_CREER_PATH':
        return const String.fromEnvironment('QUITTANCE_CREER_PATH');
      case 'QUITTANCE_LISTE_PATH':
        return const String.fromEnvironment('QUITTANCE_LISTE_PATH');
      case 'QUITTANCE_DETAIL_PATH':
        return const String.fromEnvironment('QUITTANCE_DETAIL_PATH');
      case 'QUITTANCE_TELECHARGER_PATH':
        return const String.fromEnvironment('QUITTANCE_TELECHARGER_PATH');
      case 'FICHE_PAIE_CREER_PATH':
        return const String.fromEnvironment('FICHE_PAIE_CREER_PATH');
      case 'FICHE_PAIE_MES_FICHES_PATH':
        return const String.fromEnvironment('FICHE_PAIE_MES_FICHES_PATH');
      case 'FICHE_PAIE_DETAIL_PATH':
        return const String.fromEnvironment('FICHE_PAIE_DETAIL_PATH');
      case 'PARTICULIER_DASHBOARD_STATS_PATH':
        return const String.fromEnvironment('PARTICULIER_DASHBOARD_STATS_PATH');
      case 'PARTICULIER_FACTURES_PATH':
        return const String.fromEnvironment('PARTICULIER_FACTURES_PATH');
      case 'PARTICULIER_CONTRATS_PATH':
        return const String.fromEnvironment('PARTICULIER_CONTRATS_PATH');
      default:
        return '';
    }
  }

  // ─── Base ────────────────────────────────────────────────────────────────────
  static String get baseUrl => _get('API_BASE_URL',
      fallback: 'https://sign-backend-ha5a.onrender.com/sign');

  // ─── Auth ────────────────────────────────────────────────────────────────────
  static String get login =>
      _get('AUTH_LOGIN_PATH', fallback: '/auth/login');
  static String get register =>
      _get('AUTH_REGISTER_PATH', fallback: '/auth/register');

  // ─── Account ─────────────────────────────────────────────────────────────────
  static String get accountMe =>
      _get('ACCOUNT_ME_PATH', fallback: '/account/me');
  static String get accountModifierInfo =>
      _get('ACCOUNT_MODIFIER_INFO_PATH', fallback: '/account/modifier-info-personnelles');
  static String get accountChangePassword =>
      _get('ACCOUNT_CHANGE_PASSWORD_PATH', fallback: '/account/change-password');

  // ─── Client ──────────────────────────────────────────────────────────────────
  static String get clientListe =>
      _get('CLIENT_LISTE_PATH', fallback: '/professionnel/client/liste-clients');
  static String get clientAjout =>
      _get('CLIENT_AJOUT_PATH', fallback: '/professionnel/client/ajout-client');
  static String get clientRecherche =>
      _get('CLIENT_RECHERCHE_PATH', fallback: '/professionnel/client/recherche-client');

  // ─── Facture / Document ───────────────────────────────────────────────────────
  static String get documentMesDocuments =>
      _get('DOCUMENT_MES_DOCUMENTS_PATH', fallback: '/professionnel/document/mes-documents');
  static String get documentCreer =>
      _get('DOCUMENT_CREER_PATH', fallback: '/professionnel/document/creer-document');
  static String get documentOuvrir =>
      _get('DOCUMENT_OUVRIR_PATH', fallback: '/professionnel/document/ouvrir-document');
  static String get documentTelecharger =>
      _get('DOCUMENT_TELECHARGER_PATH', fallback: '/professionnel/document/telecharger-document');

  // ─── Contrat Bail ─────────────────────────────────────────────────────────────
  static String get contratBailListe =>
      _get('CONTRAT_BAIL_LISTE_PATH', fallback: '/professionnel/contratBail/mes-contrat-immobilier');
  static String get contratBailCreer =>
      _get('CONTRAT_BAIL_CREER_PATH', fallback: '/professionnel/contratBail/creation-contrat-immobilier');
  static String get contratBailTelecharger =>
      _get('CONTRAT_BAIL_TELECHARGER_PATH', fallback: '/professionnel/contratBail/telecharger-contrat-immobilier');
  static String get contratBailSigner =>
      _get('CONTRAT_BAIL_SIGNER_PATH', fallback: '/professionnel/contratBail');

  // ─── Dashboard ────────────────────────────────────────────────────────────────
  static String get dashboardStats =>
      _get('DASHBOARD_STATS_PATH', fallback: '/professionnel/dashboard/stats');

  // ─── Contrat Travail ──────────────────────────────────────────────────────────
  static String get contratTravailCreer =>
      _get('CONTRAT_TRAVAIL_CREER_PATH', fallback: '/professionnel/contratTravail/creation-contrat-travail');
  static String get contratTravailListe =>
      _get('CONTRAT_TRAVAIL_LISTE_PATH', fallback: '/professionnel/contratTravail');
  static String get contratTravailDetail =>
      _get('CONTRAT_TRAVAIL_DETAIL_PATH', fallback: '/professionnel/contratTravail');
  static String get contratTravailTelecharger =>
      _get('CONTRAT_TRAVAIL_TELECHARGER_PATH', fallback: '/professionnel/contratTravail');
  static String get contratTravailSigner =>
      _get('CONTRAT_TRAVAIL_SIGNER_PATH', fallback: '/professionnel/contratTravail');

  // ─── Quittance de loyer ───────────────────────────────────────────────────────
  static String get quittanceCreer =>
      _get('QUITTANCE_CREER_PATH', fallback: '/professionnel/creation-quittance-loyer');
  static String get quittanceListe =>
      _get('QUITTANCE_LISTE_PATH', fallback: '/professionnel');
  static String get quittanceDetail =>
      _get('QUITTANCE_DETAIL_PATH', fallback: '/professionnel');
  static String get quittanceTelecharger =>
      _get('QUITTANCE_TELECHARGER_PATH', fallback: '/professionnel');

  // ─── Fiche de paie ────────────────────────────────────────────────────────────
  static String get fichePaieCreer =>
      _get('FICHE_PAIE_CREER_PATH', fallback: '/professionnel/cree-fiches-paie');
  static String get fichePaieMesFiches =>
      _get('FICHE_PAIE_MES_FICHES_PATH', fallback: '/professionnel/mes-fiches-paie');
  static String get fichePaieDetail =>
      _get('FICHE_PAIE_DETAIL_PATH', fallback: '/professionnel/fiche-paie');

  // ─── Particulier ─────────────────────────────────────────────────────────────
  static String get particulierDashboardStats =>
      _get('PARTICULIER_DASHBOARD_STATS_PATH', fallback: '/particulier/dashboard/stats');
  static String get particulierFactures =>
      _get('PARTICULIER_FACTURES_PATH', fallback: '/particulier/factures');
  static String get particulierContrats =>
      _get('PARTICULIER_CONTRATS_PATH', fallback: '/particulier/contrats');

  // ─── Autres Contrats ──────────────────────────────────────────────────────────
  static const String typeCaution             = 'contrat-caution';
  static const String typeConfidentialite     = 'contrat-confidentialite';
  static const String typeLocation            = 'contrat-location';
  static const String typePartenariat         = 'contrat-partenariat';
  static const String typePrestation          = 'contrat-prestation';
  static const String typeProcuration         = 'procuration';
  static const String typeReconnaissanceDette = 'reconnaissance-dette';

  // ─── Stats endpoints ──────────────────────────────────────────────────────────
  static String get contratBailStats    => '/professionnel/contratBail/stats';
  static String get contratTravailStats => '/professionnel/contratTravail/stats';
  static String autresContratsStats(String type) => '${autresContratsBase(type)}/stats';

  static String autresContratsBase(String type) {
    const map = {
      'contrat-caution':          'contrat-caution',
      'contrat-confidentialite':  'contrat-confidentialite',
      'contrat-location':         'contrat-location',
      'contrat-partenariat':      'contrat-partenariat',
      'contrat-prestation':       'contrat-prestation',
      'procuration':              'procuration',
      'reconnaissance-dette':     'reconnaissance-dette',
    };
    return '/professionnel/${map[type] ?? type}';
  }
}

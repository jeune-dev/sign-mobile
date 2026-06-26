import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Résolution des variables d'environnement.
/// Priorité : 1) --dart-define (production)  2) .env local (dev)  3) valeur par défaut
///
/// En production :
///   flutter build apk --dart-define=API_BASE_URL=https://sign-backend-ha5a.onrender.com/sign ...
class Env {
  static String _get(String key, {required String fallback}) {
    final fromDefine = _fromDefine(key);
    if (fromDefine.isNotEmpty) return fromDefine;

    try {
      final fromDotenv = dotenv.maybeGet(key)?.trim();
      if (fromDotenv != null && fromDotenv.isNotEmpty) return fromDotenv;
    } catch (_) {}

    return fallback;
  }

  static String _fromDefine(String key) {
    switch (key) {
      case 'API_BASE_URL':
        return const String.fromEnvironment('API_BASE_URL');
      case 'AUTH_LOGIN_PATH':
        return const String.fromEnvironment('AUTH_LOGIN_PATH');
      case 'AUTH_REGISTER_PATH':
        return const String.fromEnvironment('AUTH_REGISTER_PATH');
      case 'AUTH_REFRESH_PATH':
        return const String.fromEnvironment('AUTH_REFRESH_PATH');
      case 'AUTH_LOGOUT_PATH':
        return const String.fromEnvironment('AUTH_LOGOUT_PATH');
      case 'ACCOUNT_ME_PATH':
        return const String.fromEnvironment('ACCOUNT_ME_PATH');
      case 'ACCOUNT_MODIFIER_INFO_PATH':
        return const String.fromEnvironment('ACCOUNT_MODIFIER_INFO_PATH');
      case 'ACCOUNT_CHANGE_PASSWORD_PATH':
        return const String.fromEnvironment('ACCOUNT_CHANGE_PASSWORD_PATH');
      case 'ACCOUNT_FORGOT_PASSWORD_PATH':
        return const String.fromEnvironment('ACCOUNT_FORGOT_PASSWORD_PATH');
      case 'ACCOUNT_RESET_PASSWORD_PATH':
        return const String.fromEnvironment('ACCOUNT_RESET_PASSWORD_PATH');
      case 'ACCOUNT_DEVICE_TOKEN_PATH':
        return const String.fromEnvironment('ACCOUNT_DEVICE_TOKEN_PATH');
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
      case 'ETAT_LOGEMENT_BASE_PATH':
        return const String.fromEnvironment('ETAT_LOGEMENT_BASE_PATH');
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
  static String get baseUrl {
    final v = _get('API_BASE_URL', fallback: '');
    assert(v.isNotEmpty, 'API_BASE_URL manquant — relance avec --dart-define=API_BASE_URL=...');
    return v;
  }

  // ─── Auth ────────────────────────────────────────────────────────────────────
  static String get login =>
      _get('AUTH_LOGIN_PATH', fallback: '/v1/auth/login');
  static String get register =>
      _get('AUTH_REGISTER_PATH', fallback: '/v1/auth/register');
  static String get authRefresh =>
      _get('AUTH_REFRESH_PATH', fallback: '/v1/auth/refresh');
  static String get authLogout =>
      _get('AUTH_LOGOUT_PATH', fallback: '/v1/auth/logout');

  // ─── Account ─────────────────────────────────────────────────────────────────
  static String get accountMe =>
      _get('ACCOUNT_ME_PATH', fallback: '/v1/account/me');
  static String get accountModifierInfo =>
      _get('ACCOUNT_MODIFIER_INFO_PATH', fallback: '/v1/account/modifier-info-personnelles');
  static String get accountChangePassword =>
      _get('ACCOUNT_CHANGE_PASSWORD_PATH', fallback: '/v1/account/change-password');
  static String get accountForgotPassword =>
      _get('ACCOUNT_FORGOT_PASSWORD_PATH', fallback: '/v1/account/forgot-password');
  static String get accountResetPassword =>
      _get('ACCOUNT_RESET_PASSWORD_PATH', fallback: '/v1/account/reset-password');
  static String get accountDeviceToken =>
      _get('ACCOUNT_DEVICE_TOKEN_PATH', fallback: '/v1/account/device-token');

  // ─── Client ──────────────────────────────────────────────────────────────────
  static String get clientListe =>
      _get('CLIENT_LISTE_PATH', fallback: '/v1/professionnel/client/liste-clients');
  static String get clientAjout =>
      _get('CLIENT_AJOUT_PATH', fallback: '/v1/professionnel/client/ajout-client');
  static String get clientRecherche =>
      _get('CLIENT_RECHERCHE_PATH', fallback: '/v1/professionnel/client/recherche-client');

  // ─── Facture / Document ───────────────────────────────────────────────────────
  static String get documentMesDocuments =>
      _get('DOCUMENT_MES_DOCUMENTS_PATH', fallback: '/v1/professionnel/document/mes-documents');
  static String get documentCreer =>
      _get('DOCUMENT_CREER_PATH', fallback: '/v1/professionnel/document/creer-document');
  static String get documentOuvrir =>
      _get('DOCUMENT_OUVRIR_PATH', fallback: '/v1/professionnel/document/ouvrir-document');
  static String get documentTelecharger =>
      _get('DOCUMENT_TELECHARGER_PATH', fallback: '/v1/professionnel/document/telecharger-document');
  static String documentMettreAJour(String id) => '/v1/professionnel/document/$id/mettre-a-jour';
  static String documentRenvoyerFacture(String id) => '/v1/professionnel/document/$id/renvoyer-facture';

  // ─── Contrat Bail ─────────────────────────────────────────────────────────────
  static String get contratBailListe =>
      _get('CONTRAT_BAIL_LISTE_PATH', fallback: '/v1/professionnel/contratBail/mes-contrat-immobilier');
  static String get contratBailCreer =>
      _get('CONTRAT_BAIL_CREER_PATH', fallback: '/v1/professionnel/contratBail/creation-contrat-immobilier');
  static String get contratBailTelecharger =>
      _get('CONTRAT_BAIL_TELECHARGER_PATH', fallback: '/v1/professionnel/contratBail/telecharger-contrat-immobilier');
  static String get contratBailSigner =>
      _get('CONTRAT_BAIL_SIGNER_PATH', fallback: '/v1/professionnel/contratBail');

  // ─── Dashboard ────────────────────────────────────────────────────────────────
  static String get dashboardStats =>
      _get('DASHBOARD_STATS_PATH', fallback: '/v1/professionnel/dashboard/stats');

  // ─── Contrat Travail ──────────────────────────────────────────────────────────
  static String get contratTravailCreer =>
      _get('CONTRAT_TRAVAIL_CREER_PATH', fallback: '/v1/professionnel/contratTravail/creation-contrat-travail');
  static String get contratTravailListe =>
      _get('CONTRAT_TRAVAIL_LISTE_PATH', fallback: '/v1/professionnel/contratTravail');
  static String get contratTravailDetail =>
      _get('CONTRAT_TRAVAIL_DETAIL_PATH', fallback: '/v1/professionnel/contratTravail');
  static String get contratTravailTelecharger =>
      _get('CONTRAT_TRAVAIL_TELECHARGER_PATH', fallback: '/v1/professionnel/contratTravail');
  static String get contratTravailSigner =>
      _get('CONTRAT_TRAVAIL_SIGNER_PATH', fallback: '/v1/professionnel/contratTravail');

  // ─── Quittance de loyer ───────────────────────────────────────────────────────
  static String get quittanceCreer =>
      _get('QUITTANCE_CREER_PATH', fallback: '/v1/professionnel/creation-quittance-loyer');
  static String get quittanceListe =>
      _get('QUITTANCE_LISTE_PATH', fallback: '/v1/professionnel');
  static String get quittanceDetail =>
      _get('QUITTANCE_DETAIL_PATH', fallback: '/v1/professionnel');
  static String get quittanceTelecharger =>
      _get('QUITTANCE_TELECHARGER_PATH', fallback: '/v1/professionnel');

  // ─── Fiche de paie ────────────────────────────────────────────────────────────
  static String get fichePaieCreer =>
      _get('FICHE_PAIE_CREER_PATH', fallback: '/v1/professionnel/cree-fiches-paie');
  static String get fichePaieMesFiches =>
      _get('FICHE_PAIE_MES_FICHES_PATH', fallback: '/v1/professionnel/mes-fiches-paie');
  static String get fichePaieDetail =>
      _get('FICHE_PAIE_DETAIL_PATH', fallback: '/v1/professionnel/fiche-paie');

  // ─── État des lieux ───────────────────────────────────────────────────────────
  static String get etatLogementBase =>
      _get('ETAT_LOGEMENT_BASE_PATH', fallback: '/v1/professionnel/etat-logement');

  // ─── Particulier ─────────────────────────────────────────────────────────────
  static String get particulierDashboardStats =>
      _get('PARTICULIER_DASHBOARD_STATS_PATH', fallback: '/v1/particulier/dashboard/stats');
  static String get particulierFactures =>
      _get('PARTICULIER_FACTURES_PATH', fallback: '/v1/particulier/factures');
  static String get particulierContrats =>
      _get('PARTICULIER_CONTRATS_PATH', fallback: '/v1/particulier/contrats');

  // ─── Stats endpoints ──────────────────────────────────────────────────────────
  static String get contratBailStats    => '/v1/professionnel/contratBail/stats';
  static String get contratTravailStats => '/v1/professionnel/contratTravail/stats';
  static String autresContratsStats(String type) => '${autresContratsBase(type)}/stats';

  static String autresContratsBase(String type) => '/v1/professionnel/$type';
}

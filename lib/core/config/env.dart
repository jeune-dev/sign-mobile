import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  // Base
  static String get baseUrl => dotenv.get('API_BASE_URL');

  // Auth
  static String get login => dotenv.get('AUTH_LOGIN_PATH', fallback: '/auth/login');
  static String get register => dotenv.get('AUTH_REGISTER_PATH', fallback: '/auth/register');

  // Account
  static String get accountMe => dotenv.get('ACCOUNT_ME_PATH', fallback: '/account/me');
  static String get accountModifierInfo => dotenv.get('ACCOUNT_MODIFIER_INFO_PATH', fallback: '/account/modifier-info-personnelles');
  static String get accountChangePassword => dotenv.get('ACCOUNT_CHANGE_PASSWORD_PATH', fallback: '/account/change-password');

  // Client
  static String get clientListe => dotenv.get('CLIENT_LISTE_PATH', fallback: '/professionnel/client/liste-clients');
  static String get clientAjout => dotenv.get('CLIENT_AJOUT_PATH', fallback: '/professionnel/client/ajout-client');
  static String get clientRecherche => dotenv.get('CLIENT_RECHERCHE_PATH', fallback: '/professionnel/client/recherche-client');

  // Facture / Document
  static String get documentMesDocuments => dotenv.get('DOCUMENT_MES_DOCUMENTS_PATH', fallback: '/professionnel/document/mes-documents');
  static String get documentCreer => dotenv.get('DOCUMENT_CREER_PATH', fallback: '/professionnel/document/creer-document');
  static String get documentOuvrir => dotenv.get('DOCUMENT_OUVRIR_PATH', fallback: '/professionnel/document/ouvrir-document');
  static String get documentTelecharger => dotenv.get('DOCUMENT_TELECHARGER_PATH', fallback: '/professionnel/document/telecharger-document');

  // Contrat Bail
  static String get contratBailListe => dotenv.get('CONTRAT_BAIL_LISTE_PATH', fallback: '/professionnel/contratBail/mes-contrat-immobilier');
  static String get contratBailCreer => dotenv.get('CONTRAT_BAIL_CREER_PATH', fallback: '/professionnel/contratBail/creation-contrat-immobilier');
  static String get contratBailTelecharger => dotenv.get('CONTRAT_BAIL_TELECHARGER_PATH', fallback: '/professionnel/contratBail/telecharger-contrat-immobilier');
  // POST /:id/signer → locataire signe le contrat
  static String get contratBailSigner => dotenv.get('CONTRAT_BAIL_SIGNER_PATH', fallback: '/professionnel/contratBail');

  // Dashboard — un seul endpoint retourne les 3 stats
  static String get dashboardStats => dotenv.get('DASHBOARD_STATS_PATH', fallback: '/professionnel/dashboard/stats');

  // Contrat Travail
  static String get contratTravailCreer => dotenv.get('CONTRAT_TRAVAIL_CREER_PATH', fallback: '/professionnel/contratTravail/creation-contrat-travail');
  static String get contratTravailListe => dotenv.get('CONTRAT_TRAVAIL_LISTE_PATH', fallback: '/professionnel/contratTravail');
  static String get contratTravailDetail => dotenv.get('CONTRAT_TRAVAIL_DETAIL_PATH', fallback: '/professionnel/contratTravail');
  static String get contratTravailTelecharger => dotenv.get('CONTRAT_TRAVAIL_TELECHARGER_PATH', fallback: '/professionnel/contratTravail');
  static String get contratTravailSigner => dotenv.get('CONTRAT_TRAVAIL_SIGNER_PATH', fallback: '/professionnel/contratTravail');

  // Quittance de loyer
  static String get quittanceCreer => dotenv.get('QUITTANCE_CREER_PATH', fallback: '/professionnel/creation-quittance-loyer');
  static String get quittanceListe => dotenv.get('QUITTANCE_LISTE_PATH', fallback: '/professionnel');
  static String get quittanceDetail => dotenv.get('QUITTANCE_DETAIL_PATH', fallback: '/professionnel');
  static String get quittanceTelecharger => dotenv.get('QUITTANCE_TELECHARGER_PATH', fallback: '/professionnel');

  // Fiche de paie
  static String get fichePaieCreer => dotenv.get('FICHE_PAIE_CREER_PATH', fallback: '/professionnel/cree-fiches-paie');
  static String get fichePaieMesFiches => dotenv.get('FICHE_PAIE_MES_FICHES_PATH', fallback: '/professionnel/mes-fiches-paie');
  static String get fichePaieDetail => dotenv.get('FICHE_PAIE_DETAIL_PATH', fallback: '/professionnel/fiche-paie');

  // Autres Contrats — type constants (segments de chemin exacts du backend)
  static const String typeCaution           = 'contrat-caution';
  static const String typeConfidentialite   = 'contrat-confidentialite';
  static const String typeLocation          = 'contrat-location';
  static const String typePartenariat       = 'contrat-partenariat';
  static const String typePrestation        = 'contrat-prestation';
  static const String typeProcuration       = 'procuration';
  static const String typeReconnaissanceDette = 'reconnaissance-dette';

  // Stats endpoints — GET /{base}/stats
  static String get contratBailStats     => '/professionnel/contratBail/stats';
  static String get contratTravailStats  => '/professionnel/contratTravail/stats';
  static String autresContratsStats(String type) => '${autresContratsBase(type)}/stats';

  // Getter générique — utilise le type constant ci-dessus
  static String autresContratsBase(String type) {
    // Mapping sécurisé vers les chemins backend corrects
    const map = {
      'contrat-caution':        'contrat-caution',
      'contrat-confidentialite':'contrat-confidentialite',
      'contrat-location':       'contrat-location',
      'contrat-partenariat':    'contrat-partenariat',
      'contrat-prestation':     'contrat-prestation',
      'procuration':            'procuration',
      'reconnaissance-dette':   'reconnaissance-dette',
    };
    return '/professionnel/${map[type] ?? type}';
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/env.dart';
import 'core/services/token_service.dart';

// Account
import 'features/account/data/datasources/account_remote_datasource.dart';
import 'features/account/data/repositories/account_repository_impl.dart';
import 'features/account/domain/repositories/account_repository.dart';
import 'features/account/domain/usecases/get_me.dart';
import 'features/account/domain/usecases/modifier_info_personnelles.dart';
import 'features/account/domain/usecases/change_password.dart';
import 'features/account/presentation/bloc/account_bloc.dart';

// Auth
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login_user.dart';
import 'features/auth/domain/usecases/register_user.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

// Fiche de paie
import 'features/fiche_paie/data/datasources/fiche_paie_remote_datasource.dart';
import 'features/fiche_paie/data/repositories/fiche_paie_repository_impl.dart';
import 'features/fiche_paie/domain/repositories/fiche_paie_repository.dart';
import 'features/fiche_paie/domain/usecases/cree_fiche_paie.dart';
// GetFichesPaie and TelechargerFichePaie are defined in cree_fiche_paie.dart
import 'features/fiche_paie/presentation/bloc/fiche_paie_bloc.dart';

// Client
import 'features/client/data/datasources/client_remote_datasource.dart';
import 'features/client/data/repositories/client_repository_impl.dart';
import 'features/client/domain/repositories/client_repository.dart';
import 'features/client/domain/usecases/get_clients.dart';
import 'features/client/domain/usecases/rechercher_clients.dart';
import 'features/client/domain/usecases/ajouter_client.dart';
import 'features/client/presentation/bloc/client_bloc.dart';

// Facture
import 'features/facture/data/datasources/facture_remote_datasource.dart';
import 'features/facture/data/repositories/facture_repository_impl.dart';
import 'features/facture/domain/repositories/facture_repository.dart';
import 'features/facture/domain/usecases/get_factures.dart';
import 'features/facture/domain/usecases/creer_facture.dart';
import 'features/facture/domain/usecases/ouvrir_document.dart';
import 'features/facture/domain/usecases/mettre_a_jour_facture.dart';
import 'features/facture/presentation/bloc/facture_bloc.dart';

// Contrat
import 'features/contrat/data/datasources/contrat_remote_datasource.dart';
import 'features/contrat/data/repositories/contrat_repository_impl.dart';
import 'features/contrat/domain/repositories/contrat_repository.dart';
import 'features/contrat/domain/usecases/get_contrats_immobilier.dart';
import 'features/contrat/domain/usecases/creer_contrat_bail.dart';
import 'features/contrat/domain/usecases/telecharger_contrat.dart';
import 'features/contrat/presentation/bloc/contrat_bloc.dart';

// Contrat Travail
import 'features/contrat_travail/data/datasources/contrat_travail_remote_datasource.dart';
import 'features/contrat_travail/data/repositories/contrat_travail_repository_impl.dart';
import 'features/contrat_travail/domain/repositories/contrat_travail_repository.dart';
import 'features/contrat_travail/domain/usecases/get_contrats_travail.dart';
import 'features/contrat_travail/domain/usecases/get_contrat_travail_detail.dart';
import 'features/contrat_travail/domain/usecases/creer_contrat_travail.dart';
import 'features/contrat_travail/domain/usecases/signer_contrat_travail.dart';
import 'features/contrat_travail/domain/usecases/telecharger_contrat_travail.dart';
import 'features/contrat_travail/domain/usecases/get_stats_travail.dart';
import 'features/contrat_travail/presentation/bloc/contrat_travail_bloc.dart';

// Quittance Loyer
import 'features/quittance_loyer/data/datasources/quittance_loyer_remote_datasource.dart';
import 'features/quittance_loyer/data/repositories/quittance_loyer_repository_impl.dart';
import 'features/quittance_loyer/domain/repositories/quittance_loyer_repository.dart';
import 'features/quittance_loyer/domain/usecases/get_quittances.dart';
import 'features/quittance_loyer/domain/usecases/get_quittance_detail.dart';
import 'features/quittance_loyer/domain/usecases/creer_quittance.dart';
import 'features/quittance_loyer/domain/usecases/telecharger_quittance.dart';
import 'features/quittance_loyer/presentation/bloc/quittance_loyer_bloc.dart';

// Autres Contrats
import 'features/autres_contrats/data/datasources/autre_contrat_remote_datasource.dart';
import 'features/autres_contrats/data/repositories/autre_contrat_repository_impl.dart';
import 'features/autres_contrats/domain/repositories/autre_contrat_repository.dart';
import 'features/autres_contrats/domain/usecases/get_contrats.dart';
import 'features/autres_contrats/domain/usecases/get_autre_contrat_detail.dart';
import 'features/autres_contrats/domain/usecases/creer_autre_contrat.dart';
import 'features/autres_contrats/domain/usecases/signer_autre_contrat.dart';
import 'features/autres_contrats/domain/usecases/telecharger_autre_contrat.dart';
import 'features/autres_contrats/presentation/bloc/autres_contrats_bloc.dart';

// Dashboard (Professionnel)
import 'features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'features/dashboard/domain/repositories/dashboard_repository.dart';
import 'features/dashboard/domain/usecases/get_dashboard_stats.dart';
import 'features/dashboard/domain/usecases/get_documents_recents.dart';
import 'features/dashboard/domain/usecases/ouvrir_document_dashboard.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';

// Particulier
import 'features/particulier/data/datasources/particulier_remote_datasource.dart';
import 'features/particulier/data/repositories/particulier_repository_impl.dart';
import 'features/particulier/domain/repositories/particulier_repository.dart';
import 'features/particulier/domain/usecases/get_dashboard_stats.dart'
    as particulier_dashboard;
import 'features/particulier/domain/usecases/get_factures_client.dart';
import 'features/particulier/domain/usecases/get_contrats_client.dart';
import 'features/particulier/presentation/bloc/particulier_bloc.dart';

// ─── Helpers Dio ─────────────────────────────────────────────────────────────

final sl = GetIt.instance;

/// Tente de rafraîchir le JWT via le refresh token stocké.
/// Implémente la rotation : le refresh token est consommé et un nouveau est émis.
/// Retourne true si le nouveau token a été sauvegardé, false sinon.
Future<bool> _tryRefresh(Dio dio) async {
  try {
    final refreshToken = await sl<TokenService>().getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    final response = await dio.post(
      Env.authRefresh,
      data: {'refreshToken': refreshToken},
      options: Options(
        // Empêche l'intercepteur de relancer _tryRefresh (boucle infinie)
        extra: {'skipAuthInterceptor': true},
      ),
    );

    final newToken   = response.data['token']        as String?;
    final newRefresh = response.data['refreshToken'] as String?;

    if (newToken == null || newToken.isEmpty) return false;

    await sl<TokenService>().setToken(newToken);
    if (newRefresh != null && newRefresh.isNotEmpty) {
      await sl<TokenService>().setRefreshToken(newRefresh);
    }
    return true;
  } catch (_) {
    return false;
  }
}

/// Révoque le refresh token côté backend (déconnexion propre).
/// Appelé lors du logout — l'erreur réseau est ignorée car le token local
/// sera de toute façon supprimé par [TokenService.clearToken].
Future<void> revokeRefreshToken(Dio dio) async {
  try {
    final refreshToken = await sl<TokenService>().getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return;

    await dio.post(
      Env.authLogout,
      data: {'refreshToken': refreshToken},
      options: Options(extra: {'skipAuthInterceptor': true}),
    );
  } catch (_) {
    // Ignorer — la révocation côté serveur est best-effort
  }
}

// ─── Initialisation ──────────────────────────────────────────────────────────

Future<void> init() async {
  //================================================
  // SERVICES EXTERNES
  //================================================

  // REST-C01 : En production, les variables sont injectées via --dart-define.
  // Le fichier .env n'est PAS bundlé dans l'APK.

  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  sl.registerLazySingleton(() => const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      ));

  //================================================
  // CORE SERVICES
  //================================================

  sl.registerLazySingleton(() => TokenService(secureStorage: sl()));

  //================================================
  // DIO HTTP CLIENT
  //================================================

  sl.registerLazySingleton(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: Env.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        contentType: 'application/json',
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (kDebugMode) {
          debugPrint('🌐 [REQUEST] ${options.method} ${options.path}');
        }

        final path = options.path.split('?')[0].trim();
        final isPublicEndpoint =
            path.endsWith('/auth/login') ||
            path.endsWith('/auth/register') ||
            path.endsWith(Env.authRefresh) ||
            path.endsWith(Env.authLogout) ||
            options.extra['skipAuthInterceptor'] == true;

        if (!isPublicEndpoint) {
          // VULN-M05 : Utilise getValidToken() qui vérifie l'expiration côté client
          final token = await sl<TokenService>().getValidToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }

        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          debugPrint('✅ [RESPONSE] ${response.statusCode} ${response.requestOptions.path}');
        }
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        if (kDebugMode) {
          debugPrint('❌ [ERROR] ${e.type} ${e.requestOptions.path} — Status: ${e.response?.statusCode}');
        }

        // VULN-C04 : 401 → tenter le refresh avant de déconnecter
        if (e.response?.statusCode == 401) {
          // Ne pas boucler sur les endpoints publics (login/refresh eux-mêmes)
          final isPublic = e.requestOptions.extra['skipAuthInterceptor'] == true;
          if (!isPublic) {
            final refreshed = await _tryRefresh(dio);
            if (refreshed) {
              final token = await sl<TokenService>().getToken();
              e.requestOptions.headers['Authorization'] = 'Bearer $token';
              try {
                final retryResponse = await dio.fetch(e.requestOptions);
                return handler.resolve(retryResponse);
              } catch (_) {
                // Retry échoué — déconnecter
              }
            }
          }
          await sl<TokenService>().clearToken();
        }

        // OPT-05 : Retry automatique sur erreurs réseau transitoires (max 2 tentatives)
        final isNetworkError = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError;

        final retryCount = e.requestOptions.extra['retryCount'] as int? ?? 0;

        if (isNetworkError && retryCount < 2) {
          if (kDebugMode) {
            debugPrint('🔄 [RETRY] Tentative ${retryCount + 1}/2 pour ${e.requestOptions.path}');
          }
          e.requestOptions.extra['retryCount'] = retryCount + 1;
          await Future.delayed(Duration(seconds: retryCount + 1));
          try {
            final response = await dio.fetch(e.requestOptions);
            return handler.resolve(response);
          } catch (_) {
            // Retry réseau échoué — erreur originale propagée
          }
        }

        return handler.next(e);
      },
    ));

    return dio;
  });

  //================================================
  // FEATURE — ACCOUNT
  //================================================

  sl.registerLazySingleton<AccountRemoteDataSource>(
      () => AccountRemoteDataSourceImpl(dio: sl()));
  sl.registerLazySingleton<AccountRepository>(
      () => AccountRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetMe(sl()));
  sl.registerLazySingleton(() => ModifierInfoPersonnelles(sl()));
  sl.registerLazySingleton(() => ChangePassword(sl()));
  sl.registerFactory(() => AccountBloc(
        getMe: sl(),
        modifierInfoPersonnelles: sl(),
        changePassword: sl(),
      ));

  //================================================
  // FEATURE — AUTH
  //================================================

  sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(dio: sl()));
  sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(remoteDataSource: sl()));
  sl.registerLazySingleton(() => LoginUser(sl()));
  sl.registerLazySingleton(() => RegisterUser(sl()));
  sl.registerFactory(() => AuthBloc(loginUser: sl(), registerUser: sl()));

  //================================================
  // FEATURE — FICHE DE PAIE
  //================================================

  sl.registerLazySingleton<FichePaieRemoteDataSource>(
      () => FichePaieRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<FichePaieRepository>(
      () => FichePaieRepositoryImpl(sl()));
  sl.registerLazySingleton(() => CreerFichePaie(sl()));
  sl.registerLazySingleton(() => GetFichesPaie(sl()));
  sl.registerLazySingleton(() => TelechargerFichePaie(sl()));
  sl.registerFactory(() => FichePaieBloc(
        creerFichePaie:       sl(),
        getFichesPaie:        sl(),
        telechargerFichePaie: sl(),
      ));

  //================================================
  // FEATURE — CLIENT
  //================================================

  sl.registerLazySingleton<ClientRemoteDataSource>(
      () => ClientRemoteDataSourceImpl(dio: sl()));
  sl.registerLazySingleton<ClientRepository>(
      () => ClientRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetClients(sl()));
  sl.registerLazySingleton(() => RechercherClients(sl()));
  sl.registerLazySingleton(() => AjouterClient(sl()));
  sl.registerFactory(() => ClientBloc(
        getClients: sl(),
        rechercherClients: sl(),
        ajouterClient: sl(),
      ));

  //================================================
  // FEATURE — FACTURE
  //================================================

  sl.registerLazySingleton<FactureRemoteDataSource>(
      () => FactureRemoteDataSourceImpl(dio: sl()));
  sl.registerLazySingleton<FactureRepository>(
      () => FactureRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetFactures(sl()));
  sl.registerLazySingleton(() => CreerFacture(sl()));
  sl.registerLazySingleton(() => OuvrirDocument(sl()));
  sl.registerLazySingleton(() => MettreAJourFacture(sl()));
  sl.registerFactory(() => FactureBloc(
        getFactures: sl(),
        creerFacture: sl(),
        ouvrirDocument: sl(),
        mettreAJourFacture: sl(),
      ));

  //================================================
  // FEATURE — CONTRAT
  //================================================

  sl.registerLazySingleton<ContratRemoteDataSource>(
      () => ContratRemoteDataSourceImpl(dio: sl()));
  sl.registerLazySingleton<ContratRepository>(
      () => ContratRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetContratsImmobilier(sl()));
  sl.registerLazySingleton(() => CreerContratBail(sl()));
  sl.registerLazySingleton(() => TelechargerContrat(sl()));
  sl.registerFactory(() => ContratBloc(
        getContratsImmobilier: sl(),
        creerContratBail: sl(),
        telechargerContrat: sl(),
      ));

  //================================================
  // FEATURE — CONTRAT TRAVAIL
  //================================================

  sl.registerLazySingleton<ContratTravailRemoteDataSource>(
      () => ContratTravailRemoteDataSourceImpl(dio: sl()));
  sl.registerLazySingleton<ContratTravailRepository>(
      () => ContratTravailRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetContratsTravail(sl()));
  sl.registerLazySingleton(() => GetContratTravailDetail(sl()));
  sl.registerLazySingleton(() => CreerContratTravail(sl()));
  sl.registerLazySingleton(() => SignerContratTravail(sl()));
  sl.registerLazySingleton(() => TelechargerContratTravail(sl()));
  sl.registerLazySingleton(() => GetStatsTravail(sl()));
  sl.registerFactory(() => ContratTravailBloc(
        getContratsTravail:       sl(),
        getContratTravailDetail:  sl(),
        creerContratTravail:      sl(),
        signerContratTravail:     sl(),
        telechargerContratTravail: sl(),
        getStatsTravail:          sl(),
      ));

  //================================================
  // FEATURE — QUITTANCE LOYER
  //================================================

  sl.registerLazySingleton<QuittanceLoyerRemoteDataSource>(
      () => QuittanceLoyerRemoteDataSourceImpl(dio: sl()));
  sl.registerLazySingleton<QuittanceLoyerRepository>(
      () => QuittanceLoyerRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetQuittances(sl()));
  sl.registerLazySingleton(() => GetQuittanceDetail(sl()));
  sl.registerLazySingleton(() => CreerQuittance(sl()));
  sl.registerLazySingleton(() => TelechargerQuittance(sl()));
  sl.registerFactory(() => QuittanceLoyerBloc(
        getQuittances: sl(),
        getQuittanceDetail: sl(),
        creerQuittance: sl(),
        telechargerQuittance: sl(),
      ));

  //================================================
  // FEATURE — AUTRES CONTRATS
  //================================================

  sl.registerLazySingleton<AutreContratRemoteDataSource>(
      () => AutreContratRemoteDataSourceImpl(dio: sl()));
  sl.registerLazySingleton<AutreContratRepository>(
      () => AutreContratRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetContrats(sl()));
  sl.registerLazySingleton(() => GetAutreContratDetail(sl()));
  sl.registerLazySingleton(() => CreerAutreContrat(sl()));
  sl.registerLazySingleton(() => SignerAutreContrat(sl()));
  sl.registerLazySingleton(() => TelechargerAutreContrat(sl()));
  sl.registerFactory(() => AutresContratsBloc(
        getContrats: sl(),
        getDetail: sl(),
        creerContrat: sl(),
        signerContrat: sl(),
        telechargerContrat: sl(),
      ));

  //================================================
  // FEATURE — DASHBOARD
  //================================================

  sl.registerLazySingleton<DashboardRemoteDataSource>(
      () => DashboardRemoteDataSourceImpl(dio: sl()));
  sl.registerLazySingleton<DashboardRepository>(
      () => DashboardRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetDashboardStats(sl()));
  sl.registerLazySingleton(() => GetDocumentsRecents(sl()));
  sl.registerLazySingleton(() => OuvrirDocumentDashboard(sl()));
  sl.registerFactory(() => DashboardBloc(
        getDashboardStats: sl(),
        getDocumentsRecents: sl(),
        ouvrirDocument: sl(),
      ));

  //================================================
  // FEATURE — PARTICULIER (CLIENT)
  //================================================

  sl.registerLazySingleton<ParticulierRemoteDataSource>(
      () => ParticulierRemoteDataSourceImpl(dio: sl()));
  sl.registerLazySingleton<ParticulierRepository>(
      () => ParticulierRepositoryImpl(remoteDataSource: sl()));
  sl.registerLazySingleton(
      () => particulier_dashboard.GetDashboardStats(sl()));
  sl.registerLazySingleton(() => GetFacturesClient(sl()));
  sl.registerLazySingleton(() => GetContratsClient(sl()));
  sl.registerLazySingleton(() => GetContratsByTypeClient(sl()));
  sl.registerLazySingleton(() => GetContratDetailClient(sl()));
  sl.registerLazySingleton(() => SignerContratClient(sl()));
  sl.registerFactory(() => ParticulierBloc(
        getDashboardStats:      sl<particulier_dashboard.GetDashboardStats>(),
        getFacturesClient:      sl(),
        getContratsClient:      sl(),
        getContratsByTypeClient: sl(),
        getContratDetailClient: sl(),
        signerContratClient:    sl(),
      ));
}

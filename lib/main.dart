import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:sign_application/core/routes/app_router.dart';
import 'package:sign_application/core/theme/app_theme.dart';
import 'package:sign_application/features/account/presentation/bloc/account_bloc.dart';
import 'package:sign_application/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sign_application/features/auth/presentation/pages/onboarding_page.dart';
import 'package:sign_application/core/services/auth_event_bus.dart';
import 'package:sign_application/features/auth/presentation/bloc/auth_event.dart';
import 'package:sign_application/features/client/presentation/bloc/client_bloc.dart';
import 'package:sign_application/features/contrat/presentation/bloc/contrat_bloc.dart';
import 'package:sign_application/features/contrat_travail/presentation/bloc/contrat_travail_bloc.dart';
import 'package:sign_application/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:sign_application/features/facture/presentation/bloc/facture_bloc.dart';
import 'package:sign_application/features/fiche_paie/presentation/bloc/fiche_paie_bloc.dart';
import 'package:sign_application/features/quittance_loyer/presentation/bloc/quittance_loyer_bloc.dart';
import 'package:sign_application/features/etat_logement/presentation/bloc/etat_logement_bloc.dart';
import 'package:sign_application/features/autres_contrats/presentation/bloc/autres_contrats_bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sign_application/core/services/fcm_service.dart';
import 'package:sign_application/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enregistrer le handler background FCM avant Firebase.initializeApp()
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // IMP-06 : Désactive le téléchargement runtime des polices Google Fonts.
  // Les fichiers .ttf doivent être bundlés dans assets/fonts/ (voir pubspec.yaml).
  // Si les fichiers .ttf sont absents, Flutter tombera sur la police système par défaut.
  GoogleFonts.config.allowRuntimeFetching = false;

  // IMP-02 : Firebase Crashlytics — monitoring des crashes en production.
  // Android  : google-services.json dans android/app/
  // iOS      : GoogleService-Info.plist dans ios/Runner/ (via Xcode → Add Files to Runner)
  // AS-03    : Guard iOS — sans GoogleService-Info.plist, Firebase crashe au démarrage iOS.
  try {
    await Firebase.initializeApp();
    if (!kDebugMode) {
      // Crashlytics actif uniquement en production (pas pendant les tests)
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  } catch (e) {
    // Firebase non configuré sur cette plateforme (iOS sans GoogleService-Info.plist)
    // L'app continue de fonctionner sans Crashlytics
    debugPrint('⚠️ Firebase non initialisé : $e');
  }

  // Requis par media_store_plus — initialiser une seule fois avant tout
  if (Platform.isAndroid) {
    await MediaStore.ensureInitialized();
    MediaStore.appFolder = 'Sign';
  }

  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Écouter le bus d'événements : logout forcé depuis l'intercepteur Dio (401 définitif)
    AuthEventBus.instance.onLogout.listen((_) {
      // Émettre LogoutRequested sur l'AuthBloc global
      if (mounted) {
        di.sl<AuthBloc>().add(LogoutRequested());
        // Rediriger vers login et vider la pile de navigation
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRouter.loginRoute,
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AuthBloc>()),
        BlocProvider(create: (_) => di.sl<AccountBloc>()),
        BlocProvider(create: (_) => di.sl<DashboardBloc>()),
        BlocProvider(create: (_) => di.sl<ClientBloc>()),
        BlocProvider(create: (_) => di.sl<FactureBloc>()),
        BlocProvider(create: (_) => di.sl<ContratBloc>()),
        BlocProvider(create: (_) => di.sl<ContratTravailBloc>()),
        BlocProvider(create: (_) => di.sl<QuittanceLoyerBloc>()),
        BlocProvider(create: (_) => di.sl<EtatLogementBloc>()),
        BlocProvider(create: (_) => di.sl<FichePaieBloc>()),
        BlocProvider(create: (_) => di.sl<AutresContratsBloc>()),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Sign',
        theme: AppTheme.light(),
        locale: const Locale('fr', 'FR'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('fr', 'FR'),
          Locale('en', 'US'),
        ],
        // Clamp textScaler : empêche le texte d'exploser sur les téléphones
        // dont l'utilisateur a mis "Taille du texte = Grande/Très grande"
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(
              textScaler: mq.textScaler.clamp(maxScaleFactor: 1.2),
            ),
            child: child!,
          );
        },
        home: const OnboardingPage1(),
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}

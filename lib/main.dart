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
import 'package:sign_application/features/auth/presentation/pages/splash_page.dart';
import 'package:sign_application/features/client/presentation/bloc/client_bloc.dart';
import 'package:sign_application/features/contrat/presentation/bloc/contrat_bloc.dart';
import 'package:sign_application/features/contrat_travail/presentation/bloc/contrat_travail_bloc.dart';
import 'package:sign_application/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:sign_application/features/facture/presentation/bloc/facture_bloc.dart';
import 'package:sign_application/features/fiche_paie/presentation/bloc/fiche_paie_bloc.dart';
import 'package:sign_application/features/quittance_loyer/presentation/bloc/quittance_loyer_bloc.dart';
import 'package:sign_application/features/autres_contrats/presentation/bloc/autres_contrats_bloc.dart';
import 'package:sign_application/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // IMP-06 : Désactive le téléchargement runtime des polices Google Fonts.
  // Les fichiers .ttf doivent être bundlés dans assets/fonts/ (voir pubspec.yaml).
  // Si les fichiers .ttf sont absents, Flutter tombera sur la police système par défaut.
  GoogleFonts.config.allowRuntimeFetching = false;

  // IMP-02 : Firebase Crashlytics — monitoring des crashes en production.
  // PRÉREQUIS : Ajouter google-services.json dans android/app/ depuis la console Firebase.
  // https://console.firebase.google.com → Nouveau projet → Ajouter app Android
  // applicationId: com.signapp.sign_application
  await Firebase.initializeApp();
  if (!kDebugMode) {
    // Crashlytics actif uniquement en production (pas pendant les tests)
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // Requis par media_store_plus — initialiser une seule fois avant tout
  if (Platform.isAndroid) {
    await MediaStore.ensureInitialized();
    MediaStore.appFolder = 'Sign';
  }

  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        BlocProvider(create: (_) => di.sl<FichePaieBloc>()),
        BlocProvider(create: (_) => di.sl<AutresContratsBloc>()),
      ],
      child: MaterialApp(
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
        home: const SplashPage(),
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}

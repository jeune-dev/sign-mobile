import 'package:flutter/material.dart';
import 'package:sign_application/features/auth/presentation/pages/login_page.dart';
import 'package:sign_application/features/auth/presentation/pages/register_page.dart';
import 'package:sign_application/features/home/presentation/pages/client/clientpage.dart';
import 'package:sign_application/features/home/presentation/pages/professionnel/professionnelpage.dart';
import 'package:sign_application/features/auth/presentation/widgets/ContiditionUtilisation.dart';
import 'package:sign_application/features/auth/presentation/widgets/PolitiqueConfidentialite.dart';
import 'package:sign_application/features/auth/domain/entities/user.dart';
import 'package:sign_application/features/fiche_paie/presentation/page/creation_fiche_paie.dart';
import 'package:sign_application/features/auth/presentation/pages/onboarding_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_application/injection_container.dart'; // sl
import 'package:sign_application/features/fiche_paie/presentation/bloc/fiche_paie_bloc.dart';

class AppRouter {
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String homeRoute = '/home';
  static const String clientRoute = '/client';
  static const String professionnelRoute = '/professionnel';

  static const String politiqueConfRoute = '/politique-confidentialite';
  static const String contiditionUtilisationRoute = '/condition-utilisation';

  static const String onboardingRoute = '/onboarding';
  static const String fichePaieRoute = '/fiche-paie';


  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case loginRoute:
        return MaterialPageRoute(builder: (_) => LoginPage());

      case registerRoute:
        return MaterialPageRoute(builder: (_) => const RegisterPage());

      case clientRoute:
        final user = settings.arguments as User?;
        return MaterialPageRoute(
          builder: (_) => ClientPage(user: user),
        );

      case professionnelRoute:
        final user = settings.arguments as User?;
        return MaterialPageRoute(
            builder: (_) => ProfessionnelPage(user: user)
        );

      case politiqueConfRoute:
        return MaterialPageRoute(builder: (_) => PolitiqueConfidentialite());

      case contiditionUtilisationRoute:
        return MaterialPageRoute(builder: (_) => const ConditionUtilisation());

      case onboardingRoute:
        return MaterialPageRoute(builder: (_) => const OnboardingPage1());

      case fichePaieRoute:
        final user = settings.arguments as User?;

        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<FichePaieBloc>(), // 🔥 IMPORTANT
            child: FichePaieFormPage(user: user),
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
        );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:sign_application/core/services/token_service.dart';
import 'package:sign_application/features/auth/presentation/pages/login_page.dart';
import 'package:sign_application/features/auth/presentation/pages/register_page.dart';
import 'package:sign_application/features/home/presentation/pages/client/clientpage.dart';
import 'package:sign_application/features/home/presentation/pages/professionnel/professionnelpage.dart';
import 'package:sign_application/features/auth/presentation/widgets/ContiditionUtilisation.dart';
import 'package:sign_application/features/auth/presentation/widgets/PolitiqueConfidentialite.dart';
import 'package:sign_application/features/auth/domain/entities/user.dart';
import 'package:sign_application/features/fiche_paie/presentation/page/creation_fiche_paie.dart';
import 'package:sign_application/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:sign_application/features/auth/presentation/pages/reset_password_page.dart';
import 'package:sign_application/features/auth/presentation/pages/onboarding_page.dart';
import 'package:sign_application/injection_container.dart';

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
  static const String forgotPasswordRoute = '/forgot-password';
  static const String resetPasswordRoute = '/reset-password';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case loginRoute:
        return MaterialPageRoute(builder: (_) => LoginPage());

      case registerRoute:
        return MaterialPageRoute(builder: (_) => const RegisterPage());

      case clientRoute:
        final user = settings.arguments as User?;
        return MaterialPageRoute(
          builder: (_) => _AuthGuard(
            child: ClientPage(user: user),
          ),
        );

      case professionnelRoute:
        final user = settings.arguments as User?;
        return MaterialPageRoute(
          builder: (_) => _AuthGuard(
            child: ProfessionnelPage(user: user),
          ),
        );

      case fichePaieRoute:
        final user = settings.arguments as User?;
        return MaterialPageRoute(
          builder: (_) => _AuthGuard(
            child: FichePaieFormPage(user: user),
          ),
        );

      case politiqueConfRoute:
        return MaterialPageRoute(builder: (_) => PolitiqueConfidentialite());

      case contiditionUtilisationRoute:
        return MaterialPageRoute(builder: (_) => const ConditionUtilisation());

      case onboardingRoute:
        return MaterialPageRoute(builder: (_) => const OnboardingPage1());

      case forgotPasswordRoute:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());

      case resetPasswordRoute:
        final email = settings.arguments as String? ?? '';
        return MaterialPageRoute(
            builder: (_) => ResetPasswordPage(email: email));

      default:
        return MaterialPageRoute(builder: (_) => const LoginPage());
    }
  }
}

/// Vérifie le token avant d'afficher une page protégée.
/// Si le token est absent ou expiré, redirige vers /onboarding.
class _AuthGuard extends StatelessWidget {
  final Widget child;
  const _AuthGuard({required this.child});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: sl<TokenService>().isAuthenticated,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == true) {
          return child;
        }
        // Token manquant ou expiré — rediriger hors du widget tree courant
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.onboardingRoute,
            (route) => false,
          );
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

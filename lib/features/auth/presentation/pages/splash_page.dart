import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../injection_container.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/services/token_service.dart';

/// VULN-M06 : Logique d'auth corrigée — reprend la session si token valide,
///            redirige vers login si expiré ou absent.
/// VULN-H01 : Suppression du log du JWT en clair.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    try {
      final tokenService = sl<TokenService>();
      final storage = sl<FlutterSecureStorage>();

      // VULN-M05 : Vérifie validité ET expiration du token
      final isAuth = await tokenService.isAuthenticated;

      if (!mounted) return;

      if (isAuth) {
        // Token valide : on récupère le rôle pour rediriger vers la bonne page
        final role = await storage.read(key: 'user_role');
        if (!mounted) return;

        if (role == 'Particulier' || role == 'client') {
          Navigator.of(context).pushReplacementNamed(AppRouter.clientRoute);
        } else {
          Navigator.of(context).pushReplacementNamed(AppRouter.professionnelRoute);
        }
      } else {
        // Pas de token ou expiré → onboarding/login
        Navigator.of(context).pushReplacementNamed(AppRouter.onboardingRoute);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRouter.onboardingRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

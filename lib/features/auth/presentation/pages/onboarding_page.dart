import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sign_application/core/config/user_role.dart';
import 'package:sign_application/core/routes/app_router.dart';
import 'package:sign_application/core/services/token_service.dart';
import 'package:sign_application/core/theme/app_color.dart';
import 'package:sign_application/injection_container.dart';

// Première page d'onboarding (logo 1)
class OnboardingPage1 extends StatefulWidget {
  // Route vers laquelle rediriger à la fin de l'animation.
  // Par défaut login ; quand un appelant fournit une valeur, elle prime.
  // Comme c'est la page d'accueil de l'app, la destination réelle
  // (accueil client/pro si déjà connecté, sinon login) est résolue ici
  // pendant que l'animation joue — plus besoin d'un écran intermédiaire.
  final String nextRoute;

  const OnboardingPage1({super.key, this.nextRoute = AppRouter.loginRoute});

  @override
  State<OnboardingPage1> createState() => _OnboardingPage1State();
}

class _OnboardingPage1State extends State<OnboardingPage1>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Destination finale calculée selon l'authentification.
  late String _nextRoute = widget.nextRoute;

  @override
  void initState() {
    super.initState();

    // Résout la destination (auth) en tâche de fond pendant l'animation.
    _resolveDestination();

    // Animation de pulsation continue pour l'image
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Timer pour passer à la page suivante
    _timer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
            OnboardingPage2(nextRoute: _nextRoute),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  // VULN-M05/M06 : reprend la session si token valide, sinon login.
  Future<void> _resolveDestination() async {
    try {
      final tokenService = sl<TokenService>();
      final storage = sl<FlutterSecureStorage>();
      if (await tokenService.isAuthenticated) {
        final role = await storage.read(key: 'user_role');
        _nextRoute = UserRoleX.fromString(role).isClient
            ? AppRouter.clientRoute
            : AppRouter.professionnelRoute;
      } else {
        _nextRoute = AppRouter.loginRoute;
      }
    } catch (_) {
      _nextRoute = AppRouter.loginRoute;
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Éléments décoratifs en arrière-plan
          ..._buildBackgroundCircles(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Image avec animation de pulsation
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Hero(
                        tag: 'onboarding-logo-1',
                        child: Image.asset(
                          'assets/images/onboarding1.jpeg',
                          width: 200, // Ajustez selon vos besoins
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Cercles décoratifs flottants
  List<Widget> _buildBackgroundCircles() {
    return [
      Positioned(
        top: -50,
        right: -50,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColor.kPrimary.withOpacity(0.03),
          ),
        ),
      ),
      Positioned(
        bottom: -80,
        left: -40,
        child: Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColor.kPrimary.withOpacity(0.02),
          ),
        ),
      ),
    ];
  }
}

// Deuxième page d'onboarding (logo 2)
class OnboardingPage2 extends StatefulWidget {
  // Route finale après l'animation (login ou accueil client/pro).
  final String nextRoute;

  const OnboardingPage2({super.key, this.nextRoute = AppRouter.loginRoute});

  @override
  State<OnboardingPage2> createState() => _OnboardingPage2State();
}

class _OnboardingPage2State extends State<OnboardingPage2>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _timer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        // Redirige vers la destination finale calculée au démarrage :
        // accueil client/pro si déjà connecté, sinon login.
        Navigator.of(context).pushReplacementNamed(widget.nextRoute);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Même type de cercles décoratifs (légèrement différents)
          ..._buildBackgroundCircles(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Hero(
                        tag: 'onboarding-logo-2',
                        child: Image.asset(
                          'assets/images/onboarding2.jpeg',
                          width: 200,
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBackgroundCircles() {
    return [
      Positioned(
        top: -30,
        left: -30,
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColor.kPrimary.withOpacity(0.02),
          ),
        ),
      ),
      Positioned(
        bottom: -60,
        right: -20,
        child: Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColor.kPrimary.withOpacity(0.03),
          ),
        ),
      ),
    ];
  }
}
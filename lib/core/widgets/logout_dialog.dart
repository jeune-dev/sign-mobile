import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_application/core/routes/app_router.dart';
import 'package:sign_application/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sign_application/features/auth/presentation/bloc/auth_event.dart';

/// Modal de déconnexion partagé — à appeler via [LogoutDialog.show].
///
/// Dispatche [LogoutRequested] (qui révoque le refresh token côté backend)
/// puis redirige vers la page de connexion en effaçant la pile de navigation.
class LogoutDialog extends StatelessWidget {
  const LogoutDialog._();

  /// Affiche le modal depuis n'importe quelle page.
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => BlocProvider.value(
        value: context.read<AuthBloc>(),
        child: const LogoutDialog._(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: _LogoutCard(
        onCancel: () => Navigator.of(context).pop(),
        onConfirm: () {
          Navigator.of(context).pop();
          context.read<AuthBloc>().add(LogoutRequested());
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.loginRoute,
            (route) => false,
          );
        },
      ),
    );
  }
}

class _LogoutCard extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _LogoutCard({required this.onCancel, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Zone icône ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 36, bottom: 4),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFEE4444)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEE4444).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Titre ─────────────────────────────────────────────────────
          const Text(
            'Déconnexion',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 10),

          // ── Sous-titre ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              'Êtes-vous sûr de vouloir vous déconnecter de votre compte ?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // ── Ligne de séparation ───────────────────────────────────────
          Divider(color: Colors.grey[100], height: 1),

          // ── Boutons ───────────────────────────────────────────────────
          IntrinsicHeight(
            child: Row(
              children: [
                // Annuler
                Expanded(
                  child: _DialogButton(
                    label: 'Annuler',
                    textColor: Colors.grey[600]!,
                    onTap: onCancel,
                    roundLeft: true,
                  ),
                ),
                VerticalDivider(color: Colors.grey[100], width: 1),
                // Confirmer
                Expanded(
                  child: _DialogButton(
                    label: 'Se déconnecter',
                    textColor: const Color(0xFFEE4444),
                    fontWeight: FontWeight.w700,
                    onTap: onConfirm,
                    roundRight: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final Color textColor;
  final FontWeight fontWeight;
  final VoidCallback onTap;
  final bool roundLeft;
  final bool roundRight;

  const _DialogButton({
    required this.label,
    required this.textColor,
    required this.onTap,
    this.fontWeight = FontWeight.w600,
    this.roundLeft = false,
    this.roundRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.only(
          bottomLeft: roundLeft ? const Radius.circular(28) : Radius.zero,
          bottomRight: roundRight ? const Radius.circular(28) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: fontWeight,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

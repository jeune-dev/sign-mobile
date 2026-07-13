import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/app_update_launcher.dart';
import '../services/app_version_config.dart';
import '../theme/app_color.dart';

/// Écran plein écran bloquant — mise à jour obligatoire. Aucune sortie
/// possible : pas de bouton retour (PopScope canPop:false), pas de bouton
/// fermer, un seul CTA vers le Store.
class ForceUpdateScreen extends StatefulWidget {
  final AppVersionConfig config;
  const ForceUpdateScreen({super.key, required this.config});

  @override
  State<ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends State<ForceUpdateScreen> {
  bool _launching = false;

  Future<void> _handleUpdate() async {
    if (_launching) return;
    setState(() => _launching = true);
    await AppUpdateLauncher.openImmediateUpdate(widget.config.storeUrl);
    if (mounted) setState(() => _launching = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0E0E10) : Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColor.kPrimary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    size: 56,
                    color: AppColor.kPrimary,
                  ),
                ),
                const SizedBox(height: 36),
                Text(
                  'Mise à jour requise',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColor.kGrayscaleDark100,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Une nouvelle version est nécessaire pour continuer à utiliser l\'application.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    height: 1.55,
                    color: AppColor.kGrayscale40,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cette mise à jour améliore la sécurité, la stabilité et les performances.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    height: 1.5,
                    color: AppColor.kGrayscale40,
                  ),
                ),
                const SizedBox(height: 44),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _launching ? null : _handleUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _launching
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            widget.config.updateButton,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 15.5,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/app_version_config.dart';
import '../theme/app_color.dart';

/// Popup premium de mise à jour facultative — pas un AlertDialog standard,
/// design custom avec illustration, coins très arrondis et ombre douce.
class UpdateDialog extends StatelessWidget {
  final AppVersionConfig config;
  final VoidCallback onUpdate;
  final VoidCallback onLater;

  const UpdateDialog({
    super.key,
    required this.config,
    required this.onUpdate,
    required this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColor.kPrimary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.rocket_launch_rounded,
                size: 36,
                color: AppColor.kPrimary,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              config.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColor.kGrayscaleDark100,
              ),
            ),
            if (config.subtitle.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                config.subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColor.kGrayscale40,
                ),
              ),
            ],
            if (config.message.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                config.message,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  height: 1.55,
                  color: AppColor.kGrayscale40,
                ),
              ),
            ],
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  config.updateButton,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: onLater,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                config.laterButton,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColor.kGrayscale40,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

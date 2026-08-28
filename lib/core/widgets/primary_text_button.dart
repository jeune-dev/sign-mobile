


import 'package:sign_application/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:sign_application/core/theme/app_typo.dart';
class PrimaryTextButton extends StatelessWidget {
  const PrimaryTextButton({
    super.key,
    required this.onPressed,
    required this.titre,
    this.style,
  });

  final Function() onPressed;
  final String titre;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero, // Retire le padding par défaut
        // tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Réduit la zone de clic
        foregroundColor: AppColor.kPrimary, // Couleur d'ondulation au clic
      ),
      child: Text(
        titre,
        style: style ??
            AppTypo.jakarta(
              color: AppColor.kPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
      ),
    );
  }
}

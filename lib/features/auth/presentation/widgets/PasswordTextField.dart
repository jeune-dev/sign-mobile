import 'package:sign_application/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PasswordTextField extends StatefulWidget {
  final String hintText;
  final double width, height;
  final TextEditingController controller;
  final BorderRadiusGeometry borderRadius;
  // Ajout du validateur
  final FormFieldValidator<String>? validator;

  const PasswordTextField(
      {super.key,
      required this.hintText,
      required this.height,
      required this.controller,
      required this.width,
      required this.borderRadius,
      this.validator});

  @override
  _PasswordTextFieldState createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true; // Par défaut, le mot de passe est masqué

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      constraints: BoxConstraints(minHeight: widget.height),
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: TextFormField(
        obscureText: _obscureText,
        controller: widget.controller,
        style: GoogleFonts.plusJakartaSans(
          color: AppColor.kGrayscaleDark100,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        // Passage du validateur au TextFormField
        validator: widget.validator,
        decoration: InputDecoration(
          border: InputBorder.none, // La bordure est gérée par le Container
          filled: true,
          fillColor: Colors.transparent, // Le Container gère déjà la couleur
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColor.kGrayscaleDark100,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
            tooltip: _obscureText ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
          ),
          hintText: widget.hintText,
          hintStyle: GoogleFonts.plusJakartaSans(
            color: AppColor.kGrayscale40,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

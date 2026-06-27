import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';
import '../../../../core/widgets/toastNotif.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey              = GlobalKey<FormState>();
  final _otpController        = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmController    = TextEditingController();
  bool _submitted       = false;
  bool _obscureNew      = true;
  bool _obscureConfirm  = true;

  @override
  void dispose() {
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(ResetPasswordRequested(
      email:       widget.email,
      otpRecu:     _otpController.text.trim(),
      newPassword: _newPasswordController.text,
    ));
  }

  InputDecoration _dec(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 15, color: const Color(0xFF9CA3AF)),
      prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8F8FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF111827), width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
  );

  Widget _eyeBtn(bool obscure, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Icon(
      obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
      color: const Color(0xFF9CA3AF), size: 20,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is ResetPasswordSuccess) {
          showToast(context, 'Succès', 'Mot de passe réinitialisé avec succès.', ToastificationType.success);
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        } else if (state is AuthFailure) {
          showToast(context, 'Erreur', state.message, ToastificationType.error);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Retour',
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              autovalidateMode: _submitted
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // ── Icône ──────────────────────────────────────────────────
                  Center(
                    child: Container(
                      width: 88, height: 88,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.verified_user_rounded, size: 44, color: Color(0xFF16A34A)),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Titre ──────────────────────────────────────────────────
                  Text(
                    'Nouveau mot de passe',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26, fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827), letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Saisissez le code reçu par email à ${widget.email} et choisissez un nouveau mot de passe.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, color: const Color(0xFF6B7280), height: 1.5),
                  ),
                  const SizedBox(height: 36),

                  // ── Code OTP ───────────────────────────────────────────────
                  _label('Code reçu par email'),
                  TextFormField(
                    controller: _otpController,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.next,
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 2, color: const Color(0xFF111827)),
                    decoration: _dec('Ex: AB12CD34', Icons.vpn_key_outlined),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Veuillez entrer le code reçu par email' : null,
                  ),
                  const SizedBox(height: 20),

                  // ── Nouveau mot de passe ────────────────────────────────────
                  _label('Nouveau mot de passe'),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _obscureNew,
                    textInputAction: TextInputAction.next,
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, color: const Color(0xFF111827)),
                    decoration: _dec('Minimum 8 caractères', Icons.lock_outline_rounded,
                      suffix: _eyeBtn(_obscureNew, () => setState(() => _obscureNew = !_obscureNew))),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Veuillez entrer un nouveau mot de passe';
                      if (v.length < 8) return 'Le mot de passe doit contenir au moins 8 caractères';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── Confirmer ──────────────────────────────────────────────
                  _label('Confirmer le mot de passe'),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, color: const Color(0xFF111827)),
                    decoration: _dec('Répétez le nouveau mot de passe', Icons.lock_outline_rounded,
                      suffix: _eyeBtn(_obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm))),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Veuillez confirmer le mot de passe';
                      if (v != _newPasswordController.text) return 'Les mots de passe ne correspondent pas';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // ── Bouton ─────────────────────────────────────────────────
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                            disabledBackgroundColor: Colors.black38,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: isLoading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Réinitialiser le mot de passe', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700)),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.check_circle_outline_rounded, size: 18),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

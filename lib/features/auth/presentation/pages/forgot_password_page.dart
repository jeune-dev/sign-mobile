import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';
import '../../../../core/widgets/toastNotif.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey         = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      ForgotPasswordRequested(email: _emailController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is ForgotPasswordSuccess) {
          showToast(context, 'Code envoyé', 'Un code a été envoyé à votre adresse email.', ToastificationType.success);
          Navigator.of(context).pushNamed('/reset-password', arguments: _emailController.text.trim());
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

                  // ── Icône centrale ─────────────────────────────────────────
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.lock_reset_rounded, size: 44, color: Color(0xFF111827)),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Titre ──────────────────────────────────────────────────
                  Text(
                    'Mot de passe oublié ?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26, fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827), letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Entrez votre adresse email et nous vous enverrons un code de réinitialisation.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15, color: const Color(0xFF6B7280), height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // ── Champ email ────────────────────────────────────────────
                  Text(
                    'Adresse email',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, color: const Color(0xFF111827)),
                    decoration: InputDecoration(
                      hintText: 'exemple@email.com',
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 15, color: const Color(0xFF9CA3AF)),
                      prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF6B7280), size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8F8FA),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF111827), width: 1.5)),
                      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
                      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Veuillez entrer votre email';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) return 'Format d\'email invalide';
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
                                    Text('Envoyer le code', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700)),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.send_rounded, size: 18),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Retour à la connexion',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

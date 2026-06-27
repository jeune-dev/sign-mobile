import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';
import 'package:sign_application/core/widgets/toastNotif.dart';
import 'package:sign_application/features/client/presentation/bloc/client_bloc.dart';
import 'package:sign_application/features/client/presentation/bloc/client_event.dart';
import 'package:sign_application/features/client/presentation/bloc/client_state.dart';

class AjouterClientPage extends StatefulWidget {
  const AjouterClientPage({super.key});

  @override
  State<AjouterClientPage> createState() => _AjouterClientPageState();
}

class _AjouterClientPageState extends State<AjouterClientPage> {
  final _formKey              = GlobalKey<FormState>();
  final _nomController        = TextEditingController();
  final _prenomController     = TextEditingController();
  final _emailController      = TextEditingController();
  final _passwordController   = TextEditingController();
  final _confirmPwdController = TextEditingController();
  final _adresseController    = TextEditingController();
  final _telephoneController  = TextEditingController();
  final _cinController        = TextEditingController();

  bool _obscurePwd     = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPwdController.dispose();
    _adresseController.dispose();
    _telephoneController.dispose();
    _cinController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ClientBloc>().add(AjouterClientEvent(
      nom:                    _nomController.text.trim(),
      prenom:                 _prenomController.text.trim(),
      email:                  _emailController.text.trim(),
      motDePasse:             _passwordController.text,
      telephone:              _telephoneController.text.trim(),
      adresse:                _adresseController.text.trim(),
      carteIdentiteNationalNum: _cinController.text.trim(),
    ));
  }

  // ── Décoration commune des champs ──────────────────────────────────────────
  InputDecoration _dec(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFF6B7280)),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8F8FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.black87, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  Widget _label(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          if (required) ...[
            const SizedBox(width: 3),
            const Text('*', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        children: [
          Container(width: 3, height: 16, decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ClientBloc, ClientState>(
      listener: (ctx, state) {
        if (state is ClientSuccess) {
          showToast(context, 'Succès', state.message, ToastificationType.success);
          Navigator.pop(context);
        }
        if (state is ClientError) {
          showToast(context, 'Erreur', state.message, ToastificationType.error);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Nouveau client',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: BlocBuilder<ClientBloc, ClientState>(
          builder: (ctx, state) {
            final isLoading = state is ClientLoading;
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                children: [
                  // ── Identité ────────────────────────────────────────────
                  _card(children: [
                    _section('Identité'),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Prénom', required: true),
                              TextFormField(
                                controller: _prenomController,
                                textCapitalization: TextCapitalization.words,
                                decoration: _dec('Prénom', Icons.person_outline_rounded),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Nom', required: true),
                              TextFormField(
                                controller: _nomController,
                                textCapitalization: TextCapitalization.words,
                                decoration: _dec('Nom', Icons.badge_outlined),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _label('Numéro CIN'),
                    TextFormField(
                      controller: _cinController,
                      decoration: _dec("Carte d'identité nationale", Icons.credit_card_outlined),
                    ),
                  ]),

                  const SizedBox(height: 12),

                  // ── Contact ──────────────────────────────────────────────
                  _card(children: [
                    _section('Contact'),
                    _label('Email', required: true),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _dec('exemple@email.com', Icons.email_outlined),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email requis';
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Email invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _label('Téléphone'),
                    TextFormField(
                      controller: _telephoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _dec('+221 XX XXX XX XX', Icons.phone_outlined),
                    ),
                    const SizedBox(height: 16),
                    _label('Adresse'),
                    TextFormField(
                      controller: _adresseController,
                      maxLines: 2,
                      decoration: _dec('Adresse complète', Icons.location_on_outlined),
                    ),
                  ]),

                  const SizedBox(height: 12),

                  // ── Mot de passe ──────────────────────────────────────────
                  _card(children: [
                    _section('Accès'),
                    _label('Mot de passe', required: true),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePwd,
                      decoration: _dec(
                        'Minimum 6 caractères',
                        Icons.lock_outline_rounded,
                        suffix: _eyeBtn(_obscurePwd, () => setState(() => _obscurePwd = !_obscurePwd)),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Mot de passe requis';
                        if (v.length < 6) return 'Minimum 6 caractères';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _label('Confirmer le mot de passe', required: true),
                    TextFormField(
                      controller: _confirmPwdController,
                      obscureText: _obscureConfirm,
                      decoration: _dec(
                        'Répétez le mot de passe',
                        Icons.lock_outline_rounded,
                        suffix: _eyeBtn(_obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Confirmation requise';
                        if (v != _passwordController.text) return 'Les mots de passe ne correspondent pas';
                        return null;
                      },
                    ),
                  ]),

                  const SizedBox(height: 8),

                  // ── Note informative ──────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFF16A34A), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Un email de bienvenue sera envoyé au client avec ses identifiants de connexion.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF15803D)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Bouton submit ─────────────────────────────────────────
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.black38,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Créer le compte client',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.person_add_alt_1_rounded, size: 18),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _eyeBtn(bool obscure, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: const Color(0xFF9CA3AF),
        size: 20,
      ),
    );
  }
}

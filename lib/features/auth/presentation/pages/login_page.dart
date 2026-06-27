import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter/gestures.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import 'package:sign_application/core/config/user_role.dart';
import 'package:sign_application/core/routes/app_router.dart';
import 'package:sign_application/core/widgets/toastNotif.dart';
import '../../../../core/theme/app_color.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _phoneNumber;
  bool _isEmail = true;
  bool _obscurePassword = true;

  // SEC-05 : Throttle anti-brute-force — max 1 tentative toutes les 3 secondes
  int _loginAttempts = 0;
  DateTime? _lastLoginAttempt;
  bool _isThrottled = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    // SEC-05 : Throttle anti-brute-force
    final now = DateTime.now();
    if (_lastLoginAttempt != null &&
        now.difference(_lastLoginAttempt!) < const Duration(seconds: 3)) {
      // Tentative trop rapide — ignorer silencieusement
      return;
    }

    // Après 5 tentatives échouées, bloquer 30 secondes
    if (_isThrottled) {
      showToast(
        context,
        'Trop de tentatives',
        'Veuillez patienter 30 secondes avant de réessayer.',
        ToastificationType.warning,
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      _lastLoginAttempt = now;
      _loginAttempts++;

      // Blocage temporaire après 5 tentatives consécutives
      if (_loginAttempts >= 5) {
        setState(() => _isThrottled = true);
        Future.delayed(const Duration(seconds: 30), () {
          if (mounted) {
            setState(() {
              _isThrottled = false;
              _loginAttempts = 0;
            });
          }
        });
      }

      String identifiant;
      if (_isEmail) {
        identifiant = _emailController.text.trim();
      } else {
        identifiant = _phoneNumber ?? '';
      }
      context.read<AuthBloc>().add(
        LoginRequested(
          identifiant: identifiant,
          mot_de_passe: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) => previous is AuthLoading,
      listener: (context, state) {
        if (state is AuthSuccess) {
          // SEC-05 : Réinitialiser le compteur de tentatives après succès
          _loginAttempts = 0;
          _isThrottled = false;
          final userRole = UserRoleX.fromString(state.user.role);
          String route = AppRouter.homeRoute;

          if (userRole.isClient) {
            route = AppRouter.clientRoute;
          } else if (userRole.isPro) {
            route = AppRouter.professionnelRoute;
          }

          Navigator.of(context).pushNamedAndRemoveUntil(
            route,
                (route) => false,
            arguments: state.user,
          );

          showToast(
            context,
            'Connexion réussie',
            'Vous êtes maintenant connecté.',
            ToastificationType.success,
          );
        } else if (state is AuthFailure) {
          showToast(
            context,
            'Échec de la connexion',
            state.message,
            ToastificationType.error,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildLoginCard(isLoading),
                    const SizedBox(height: 28),
                    _buildTermsAndPrivacy(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────── HEADER ───────────────────────
  Widget _buildHeader() {
    return LayoutBuilder(builder: (context, constraints) {
      final screenW = MediaQuery.sizeOf(context).width;
      // Réduction progressive pour petits écrans (< 360px)
      final titleSize = screenW < 360 ? 24.0 : (screenW < 400 ? 28.0 : 32.0);
      return _buildHeaderContent(titleSize);
    });
  }

  Widget _buildHeaderContent(double titleSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Hero(
            tag: 'app-logo',
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logosign.jpeg',
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Se ',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                  color: AppColor.kGrayscaleDark100,
                  height: 1.2,
                ),
              ),
              TextSpan(
                text: 'Connecter',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                  color: AppColor.kPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Connectez-vous pour générer vos factures et signer des contrats en toute sécurité',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppColor.kGrayscale40,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ─────────────────────── CARD ───────────────────────
  Widget _buildLoginCard(bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColor.kPrimary.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSelector(),
          const SizedBox(height: 20),
          _buildIdentifierField(),
          const SizedBox(height: 20),
          _buildPasswordField(),
          const SizedBox(height: 16),
          _buildForgotRow(),
          const SizedBox(height: 28),
          _buildLoginButton(isLoading),
          const SizedBox(height: 20),
          _buildRegisterLink(),
        ],
      ),
    );
  }

  // ─────────────────────── SELECTOR ───────────────────────
  Widget _buildSelector() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _selectorTab(
            label: 'Email',
            selected: _isEmail,
            onTap: () {
              setState(() {
                _isEmail = true;
                _phoneNumber = null;
              });
            },
          ),
          _selectorTab(
            label: 'Téléphone',
            selected: !_isEmail,
            onTap: () {
              setState(() {
                _isEmail = false;
                _emailController.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _selectorTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: selected ? AppColor.kPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
              BoxShadow(
                color: AppColor.kPrimary.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColor.kGrayscale40,
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────── IDENTIFIER ───────────────────────
  Widget _buildIdentifierField() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _isEmail
          ? _buildEmailField(key: const ValueKey('email'))
          : _buildPhoneField(key: const ValueKey('phone')),
    );
  }

  Widget _buildEmailField({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Email'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColor.kGrayscaleDark100,
          ),
          decoration: InputDecoration(
            hintText: 'exemple@email.com',
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              color: AppColor.kGrayscale40,
            ),
            prefixIcon: Icon(
              Icons.email_outlined,
              color: AppColor.kPrimary,
              size: 20,
            ),
            filled: true,
            fillColor: const Color(0xFFF8F8FA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColor.kPrimary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Ce champ est requis';
            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
              return 'Email invalide';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPhoneField({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Téléphone'),
        const SizedBox(height: 8),
        IntlPhoneField(
          initialCountryCode: 'SN',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColor.kGrayscaleDark100,
          ),
          dropdownTextStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColor.kGrayscaleDark100,
          ),
          decoration: InputDecoration(
            hintText: 'Votre numéro',
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              color: AppColor.kGrayscale40,
            ),
            filled: true,
            fillColor: const Color(0xFFF8F8FA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColor.kPrimary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            counterText: '',
          ),
          onChanged: (phone) {
            setState(() {
              _phoneNumber = phone.completeNumber;
            });
          },
          validator: (phone) {
            if (phone == null || phone.number.isEmpty) {
              return 'Ce champ est requis';
            }
            if (!phone.isValidNumber()) {
              return 'Numéro invalide pour le pays sélectionné';
            }
            return null;
          },
        ),
      ],
    );
  }

  // ─────────────────────── PASSWORD ───────────────────────
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Mot de passe'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColor.kGrayscaleDark100,
          ),
          decoration: InputDecoration(
            hintText: 'Votre mot de passe',
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              color: AppColor.kGrayscale40,
            ),
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              color: AppColor.kPrimary,
              size: 20,
            ),
            suffixIcon: GestureDetector(
              onTap: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              child: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColor.kGrayscale40,
                size: 20,
              ),
            ),
            filled: true,
            fillColor: const Color(0xFFF8F8FA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColor.kPrimary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Ce champ est requis';
            return null;
          },
        ),
      ],
    );
  }

  // ─────────────────────── HELPERS ───────────────────────
  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColor.kGrayscaleDark100,
        letterSpacing: 0.1,
      ),
    );
  }

  Widget _buildForgotRow() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pushNamed('/forgot-password'),
        child: Text(
          'Mot de passe oublié ?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColor.kPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : _onLoginPressed,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  AppColor.kPrimary,
                  AppColor.kPrimary.withValues(alpha: 0.82),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: isLoading
                  ? []
                  : [
                BoxShadow(
                  color: AppColor.kPrimary.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
                  : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Se connecter',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Nouveau chez nous ? ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColor.kGrayscale40,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed('/register'),
            child: Text(
              'Créer un compte',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColor.kPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsAndPrivacy() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'En vous connectant, vous acceptez nos '),
              TextSpan(
                text: 'Conditions d\'utilisation',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: AppColor.kPrimary,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => Navigator.of(context)
                      .pushNamed(AppRouter.contiditionUtilisationRoute),
              ),
              const TextSpan(text: ' et notre '),
              TextSpan(
                text: 'Politique de confidentialité',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: AppColor.kPrimary,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => Navigator.of(context)
                      .pushNamed(AppRouter.politiqueConfRoute),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColor.kGrayscale40,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}
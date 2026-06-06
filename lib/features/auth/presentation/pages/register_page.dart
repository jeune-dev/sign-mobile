import 'package:sign_application/core/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:flutter/gestures.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/toastNotif.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _phoneNumber;
  String? _entreprisePhoneNumber;
  final _phoneController = TextEditingController();
  final _entreprisePhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cinController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rcController = TextEditingController();
  final _nineaController = TextEditingController();
  final _nomEntrepriseController = TextEditingController();
  final _adresseEntrepriseController = TextEditingController();
  final _emailEntrepriseController = TextEditingController();

  String? _selectedRole;
  File? _profileImage;
  File? _logoImage;
  File? _signatureImage;
  bool _obscurePassword = true;

  // ── Critères mot de passe ──
  bool _hasUpperCase = false;
  bool _hasLowerCase = false;
  bool _hasDigit = false;
  bool _hasSpecialChar = false;
  bool _hasMinLength = false;
  bool _passwordFocused = false;

  int _currentStep = 0;
  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  final List<String> _roles = ['Particulier', 'Independant', 'Professionnel'];

  // ── Validation mot de passe en temps réel ──
  void _checkPasswordStrength(String value) {
    setState(() {
      _hasUpperCase = value.contains(RegExp(r'[A-Z]'));
      _hasLowerCase = value.contains(RegExp(r'[a-z]'));
      _hasDigit = value.contains(RegExp(r'[0-9]'));
      _hasSpecialChar =
          value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\\/~`]'));
      _hasMinLength = value.length >= 8;
    });
  }

  bool get _isPasswordValid =>
      _hasUpperCase && _hasLowerCase && _hasDigit && _hasSpecialChar && _hasMinLength;

  Future<void> _pickImage({required bool isProfile}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isProfile) {
          _profileImage = File(pickedFile.path);
        } else {
          _logoImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _openSignaturePad() async {
    final controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Signez ici',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: 200,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8FA),
            borderRadius: BorderRadius.circular(14),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Signature(
              controller: controller,
              width: MediaQuery.of(context).size.width * 0.8,
              height: 200,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => controller.clear(),
            child: Text(
              'Effacer',
              style: GoogleFonts.plusJakartaSans(color: AppColor.kGrayscale40),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.isEmpty) {
                Navigator.pop(context);
                return;
              }
              final Uint8List? data = await controller.toPngBytes();
              if (data != null) {
                final tempDir = await getTemporaryDirectory();
                final file = File(
                  '${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png',
                );
                await file.writeAsBytes(data);
                setState(() => _signatureImage = file);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.kPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Valider',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _goToNextStep() {
    if (_formKeys[_currentStep].currentState!.validate()) {
      if (_currentStep < 1) {
        setState(() => _currentStep += 1);
      } else {
        _submitRegistration();
      }
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  void _submitRegistration() {
    if (_formKeys[1].currentState!.validate()) {
      context.read<AuthBloc>().add(
        RegisterRequested(
          nom: _lastNameController.text.trim(),
          prenom: _firstNameController.text.trim(),
          email: _emailController.text.trim(),
          mot_de_passe: _passwordController.text,
          adresse: _addressController.text.trim(),
          telephone: _phoneNumber ?? '',
          carte_identite_national_num: _cinController.text.trim(),
          role: _selectedRole ?? 'Particulier',
          photoProfil: _profileImage != null ? XFile(_profileImage!.path) : null,
          logo: _logoImage != null ? XFile(_logoImage!.path) : null,
          rc: _rcController.text.trim().isNotEmpty ? _rcController.text.trim() : null,
          ninea: _nineaController.text.trim().isNotEmpty
              ? _nineaController.text.trim()
              : null,
          signature: _signatureImage != null ? XFile(_signatureImage!.path) : null,
          nomEntreprise: _nomEntrepriseController.text.trim().isNotEmpty
              ? _nomEntrepriseController.text.trim()
              : null,
          adresseEntreprise: _adresseEntrepriseController.text.trim().isNotEmpty
              ? _adresseEntrepriseController.text.trim()
              : null,
          telephoneEntreprise: _entreprisePhoneNumber,
          emailEntreprise: _emailEntrepriseController.text.trim().isNotEmpty
              ? _emailEntrepriseController.text.trim()
              : null,
        ),
      );
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cinController.dispose();
    _passwordController.dispose();
    _rcController.dispose();
    _nineaController.dispose();
    _nomEntrepriseController.dispose();
    _adresseEntrepriseController.dispose();
    _emailEntrepriseController.dispose();
    _phoneController.dispose();
    _entreprisePhoneController.dispose();
    super.dispose();
  }

  // ─────────────────────── BUILD ───────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (previous, current) => previous != current,
        listener: (context, state) {
          if (state is AuthSuccess) {
            FocusScope.of(context).unfocus();
            showToast(
              context,
              'Inscription réussie',
              'Vous pouvez maintenant vous connecter !',
              ToastificationType.success,
            );
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRouter.loginRoute,
                  (route) => false,
            );
            context.read<AuthBloc>().add(ResetAuthState());
          } else if (state is AuthFailure) {
            showToast(
              context,
              'Échec de l\'inscription',
              state.message,
              ToastificationType.error,
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Bouton retour ──
                  GestureDetector(
                    onTap: () {
                      if (_currentStep > 0) {
                        _goToPreviousStep();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildStepIndicator(),
                  const SizedBox(height: 24),
                  _buildRegisterForm(isLoading),
                  const SizedBox(height: 24),
                  _buildStepNavigation(isLoading),
                  const SizedBox(height: 28),
                  _buildTermsAndPrivacy(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────── HEADER ───────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Hero(
            tag: 'app-logo',
            child: Image.asset(
              'assets/images/logosignapk.jpeg',
              width: 130,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _currentStep == 0 ? 'Commençons !' : 'Informations complémentaires',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColor.kGrayscaleDark100,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _currentStep == 0
              ? 'Remplissez vos informations personnelles'
              : 'Complétez votre profil pour commencer à signer',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColor.kGrayscale40,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ─────────────────────── STEP INDICATOR ───────────────────────
  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepCircle(1, 'Informations', _currentStep >= 0),
        Expanded(
          child: Container(
            height: 2,
            color: _currentStep >= 1 ? AppColor.kPrimary : AppColor.kLine,
          ),
        ),
        _buildStepCircle(2, 'Profil', _currentStep >= 1),
      ],
    );
  }

  Widget _buildStepCircle(int stepNumber, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppColor.kPrimary : AppColor.kLine,
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
              BoxShadow(
                color: AppColor.kPrimary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
                : null,
          ),
          child: Center(
            child: Text(
              '$stepNumber',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isActive ? AppColor.kPrimary : AppColor.kGrayscale40,
          ),
        ),
      ],
    );
  }

  // ─────────────────────── FORM CARD ───────────────────────
  Widget _buildRegisterForm(bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColor.kPrimary.withOpacity(0.08),
            blurRadius: 40,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKeys[_currentStep],
        child: _currentStep == 0 ? _buildStep1Form() : _buildStep2Form(),
      ),
    );
  }

  // ─────────────────────── STEP 1 ───────────────────────
  Widget _buildStep1Form() {
    return Column(
      children: [
        // CORRECTION 2 : Prénom — lettres uniquement
        _buildInputField(
          label: 'Prénom',
          hint: 'Ex: Jane',
          controller: _firstNameController,
          icon: Icons.person_outline,
          isRequired: true,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Ce champ est obligatoire';
            if (!RegExp(r"^[a-zA-ZÀ-ÿ\s\-']+$").hasMatch(v)) {
              return 'Le prénom ne doit contenir que des lettres';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // CORRECTION 2 : Nom — lettres uniquement
        _buildInputField(
          label: 'Nom',
          hint: 'Ex: Doe',
          controller: _lastNameController,
          icon: Icons.person_outline,
          isRequired: true,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Ce champ est obligatoire';
            if (!RegExp(r"^[a-zA-ZÀ-ÿ\s\-']+$").hasMatch(v)) {
              return 'Le nom ne doit contenir que des lettres';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // CORRECTION 1 : Téléphone obligatoire
        _buildPhoneInput(
          label: 'Téléphone',
          isRequired: true,
          controller: _phoneController,
          onChanged: (phone) => setState(() => _phoneNumber = phone.completeNumber),
        ),
        const SizedBox(height: 16),
        _buildInputField(
          label: 'Adresse e-mail',
          hint: 'exemple@gmail.com',
          controller: _emailController,
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          isRequired: true,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Ce champ est obligatoire';
            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
              return 'Email invalide';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // CORRECTION 3 : Mot de passe avec critères visuels
        _buildPasswordInput(),
      ],
    );
  }

  // ─────────────────────── STEP 2 ───────────────────────
  Widget _buildStep2Form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(
          label: 'Adresse complète',
          hint: 'Ex: Dakar, Sacré Coeur 3',
          controller: _addressController,
          icon: Icons.location_on_outlined,
          isRequired: true,
          validator: (v) => (v == null || v.isEmpty) ? 'Ce champ est obligatoire' : null,
        ),
        const SizedBox(height: 16),
        // CORRECTION 4 : CIN — chiffres uniquement
        _buildCinInputField(),
        const SizedBox(height: 16),
        _buildRoleDropdown(),
        const SizedBox(height: 20),
        _buildProfilePhotoSection(),

        if (_selectedRole == 'Professionnel') ...[
          const SizedBox(height: 20),
          Container(height: 1, color: AppColor.kLine),
          const SizedBox(height: 20),
          _buildSectionTitle("Informations de l'entreprise"),
          const SizedBox(height: 16),
          _buildInputField(
            label: "Nom de l'entreprise",
            hint: 'Ex: Mon Entreprise SARL',
            controller: _nomEntrepriseController,
            icon: Icons.apartment_outlined,
            isRequired: true,
            validator: (v) =>
            (v == null || v.isEmpty) ? 'Ce champ est obligatoire' : null,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: "Adresse de l'entreprise",
            hint: 'Ex: Dakar, Sénégal',
            controller: _adresseEntrepriseController,
            icon: Icons.location_on_outlined,
            isRequired: true,
            validator: (v) =>
            (v == null || v.isEmpty) ? 'Ce champ est obligatoire' : null,
          ),
          const SizedBox(height: 16),
          _buildPhoneInput(
            label: "Téléphone de l'entreprise",
            isRequired: true,
            controller: _entreprisePhoneController,
            onChanged: (phone) =>
                setState(() => _entreprisePhoneNumber = phone.completeNumber),
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: "Email de l'entreprise",
            hint: 'Ex: contact@monentreprise.sn',
            controller: _emailEntrepriseController,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            isRequired: true,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Ce champ est obligatoire';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Email invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: 'Registre de Commerce (RC)',
            hint: 'Ex: RC 2023 B 12345',
            controller: _rcController,
            icon: Icons.business_center_outlined,
            isRequired: true,
            validator: (v) =>
            (v == null || v.isEmpty) ? 'Ce champ est obligatoire' : null,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: 'NINEA',
            hint: 'Ex: 123456789',
            controller: _nineaController,
            icon: Icons.numbers_outlined,
            isRequired: true,
            validator: (v) =>
            (v == null || v.isEmpty) ? 'Ce champ est obligatoire' : null,
          ),
          const SizedBox(height: 16),
          _buildLogoSection(),
          const SizedBox(height: 16),
          _buildSignatureSection(),
        ],
      ],
    );
  }

  // ─────────────────────── COMPOSANTS INPUTS ───────────────────────

  Widget _fieldLabel(String label, {bool isRequired = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: AppColor.kGrayscaleDark100,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isRequired)
          Text(
            ' *',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.red,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColor.kGrayscaleDark100,
      ),
    );
  }

  InputDecoration _baseDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: AppColor.kGrayscale40,
      ),
      prefixIcon: Icon(icon, color: AppColor.kPrimary, size: 20),
      filled: true,
      fillColor: const Color(0xFFF8F8FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      errorStyle: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        color: Colors.redAccent,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label, isRequired: isRequired),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColor.kGrayscaleDark100,
          ),
          decoration: _baseDecoration(hint: hint, icon: icon),
          validator: validator,
        ),
      ],
    );
  }

  // ─────────────────────── CIN INPUT — chiffres uniquement (CORRECTION 4) ──
  Widget _buildCinInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel("Numéro de carte d'identité", isRequired: true),
        const SizedBox(height: 8),
        TextFormField(
          controller: _cinController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColor.kGrayscaleDark100,
          ),
          decoration: _baseDecoration(hint: 'Ex: 12345678', icon: Icons.badge_outlined),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Ce champ est obligatoire';
            if (!RegExp(r'^\d+$').hasMatch(v)) {
              return 'Seuls les chiffres sont autorisés';
            }
            return null;
          },
        ),
      ],
    );
  }

  // ─────────────────────── PHONE INPUT (CORRECTION 1) ──────────────────────
  Widget _buildPhoneInput({
    required String label,
    required void Function(PhoneNumber) onChanged,
    required TextEditingController controller,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label, isRequired: isRequired),
        const SizedBox(height: 8),
        IntlPhoneField(
          controller: controller,
          initialCountryCode: 'SN',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColor.kGrayscaleDark100,
          ),
          dropdownTextStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColor.kGrayscaleDark100,
          ),
          decoration: InputDecoration(
            hintText: 'Votre numéro',
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColor.kGrayscale40,
            ),
            filled: true,
            fillColor: const Color(0xFFF8F8FA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
            errorStyle: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: Colors.redAccent,
              fontWeight: FontWeight.w500,
            ),
          ),
          onChanged: onChanged,
          validator: (phone) {
            if (phone == null || phone.number.isEmpty) {
              return 'Ce champ est obligatoire';
            }
            if (!phone.isValidNumber()) {
              return 'Numéro de téléphone invalide';
            }
            return null;
          },
        ),
      ],
    );
  }

  // ─────────────────────── PASSWORD INPUT (CORRECTION 3) ───────────────────
  Widget _buildPasswordInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Mot de passe', isRequired: true),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (focused) => setState(() => _passwordFocused = focused),
          child: TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            onChanged: _checkPasswordStrength,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColor.kGrayscaleDark100,
            ),
            decoration: InputDecoration(
              hintText: 'Créez un mot de passe sécurisé',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColor.kGrayscale40,
              ),
              prefixIcon:
              Icon(Icons.lock_outline_rounded, color: AppColor.kPrimary, size: 20),
              suffixIcon: GestureDetector(
                onTap: () => setState(() => _obscurePassword = !_obscurePassword),
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
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              errorStyle: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: Colors.redAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Ce champ est obligatoire';
              if (!_isPasswordValid) {
                return 'Le mot de passe ne respecte pas tous les critères';
              }
              return null;
            },
          ),
        ),
        // Critères visibles dès la saisie ou le focus
        if (_passwordController.text.isNotEmpty || _passwordFocused) ...[
          const SizedBox(height: 10),
          _buildPasswordCriteria(),
        ],
      ],
    );
  }

  Widget _buildPasswordCriteria() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Critères du mot de passe :',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColor.kGrayscaleDark100,
            ),
          ),
          const SizedBox(height: 6),
          _buildCriteriaRow('Au moins 8 caractères', _hasMinLength),
          _buildCriteriaRow('Une lettre majuscule (A–Z)', _hasUpperCase),
          _buildCriteriaRow('Une lettre minuscule (a–z)', _hasLowerCase),
          _buildCriteriaRow('Un chiffre (0–9)', _hasDigit),
          _buildCriteriaRow('Un caractère spécial (!@#\$%...)', _hasSpecialChar),
        ],
      ),
    );
  }

  Widget _buildCriteriaRow(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 14,
            color: isMet ? const Color(0xFF22C55E) : Colors.redAccent,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isMet ? const Color(0xFF22C55E) : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── ROLE DROPDOWN ───────────────────────
  Widget _buildRoleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Rôle', isRequired: true),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedRole,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColor.kPrimary),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColor.kGrayscaleDark100,
          ),
          decoration: InputDecoration(
            hintText: 'Sélectionnez votre rôle',
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColor.kGrayscale40,
            ),
            prefixIcon: Icon(Icons.work_outline, color: AppColor.kPrimary, size: 20),
            filled: true,
            fillColor: const Color(0xFFF8F8FA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            errorStyle: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: Colors.redAccent,
              fontWeight: FontWeight.w500,
            ),
          ),
          items: _roles.map((role) {
            return DropdownMenuItem<String>(
              value: role,
              child: Text(
                role,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: AppColor.kGrayscaleDark100,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedRole = value),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez sélectionner un rôle';
            }
            return null;
          },
        ),
      ],
    );
  }

  // ─────────────────────── PHOTO / LOGO / SIGNATURE ────────────────────────

  Widget _buildProfilePhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Photo de profil'),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _pickImage(isProfile: true),
          child: Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFFF8F8FA),
              border: _profileImage != null
                  ? Border.all(color: AppColor.kPrimary, width: 2)
                  : null,
            ),
            child: _profileImage != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_profileImage!, fit: BoxFit.cover),
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_outlined,
                    size: 30, color: AppColor.kPrimary),
                const SizedBox(height: 8),
                Text(
                  'Ajouter une photo',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColor.kPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Optionnel — cliquez pour sélectionner',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColor.kGrayscale40,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel("Logo de l'entreprise"),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _pickImage(isProfile: false),
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFFF8F8FA),
              border: _logoImage != null
                  ? Border.all(color: AppColor.kPrimary, width: 2)
                  : null,
            ),
            child: _logoImage != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_logoImage!, fit: BoxFit.contain),
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined,
                    size: 28, color: AppColor.kPrimary),
                const SizedBox(height: 6),
                Text(
                  'Ajouter un logo',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColor.kPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Optionnel',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColor.kGrayscale40,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignatureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Signature'),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _openSignaturePad,
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFFF8F8FA),
              border: _signatureImage != null
                  ? Border.all(color: AppColor.kPrimary, width: 2)
                  : null,
            ),
            child: _signatureImage != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_signatureImage!, fit: BoxFit.contain),
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.draw_outlined, size: 28, color: AppColor.kPrimary),
                const SizedBox(height: 6),
                Text(
                  'Signez ici',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColor.kPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Optionnel — touchez pour signer',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColor.kGrayscale40,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────── NAVIGATION BUTTONS ──────────────────────────────
  Widget _buildStepNavigation(bool isLoading) {
    return Row(
      children: [
        if (_currentStep > 0) ...[
          Expanded(
            child: SizedBox(
              height: 54,
              child: OutlinedButton.icon(
                onPressed: _goToPreviousStep,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: Text(
                  'Retour',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColor.kPrimary,
                  side: BorderSide(color: AppColor.kPrimary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: SizedBox(
            height: 54,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isLoading ? null : _goToNextStep,
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: [
                        AppColor.kPrimary,
                        AppColor.kPrimary.withOpacity(0.82),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: isLoading
                        ? []
                        : [
                      BoxShadow(
                        color: AppColor.kPrimary.withOpacity(0.35),
                        blurRadius: 16,
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
                          _currentStep == 0 ? 'Suivant' : "S'inscrire",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentStep == 0
                              ? Icons.arrow_forward_rounded
                              : Icons.check_circle_outline_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────── TERMS ───────────────────────────────────────────
  Widget _buildTermsAndPrivacy() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'En vous inscrivant, vous acceptez nos '),
              TextSpan(
                text: "Conditions d'utilisation",
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
                  ..onTap = () =>
                      Navigator.of(context).pushNamed(AppRouter.politiqueConfRoute),
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
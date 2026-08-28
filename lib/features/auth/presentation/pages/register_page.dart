// ─────────────────────────────────────────────────────────────────────────────
// ⚠️ ÉCRAN REMPLACÉ — ne plus router vers cette page.
//
// L'inscription passe désormais par `inscription_rapide_page.dart` : nom,
// prénom, ville et numéro de téléphone suffisent, et aucune pièce d'identité
// n'est demandée à ce stade (refonte du parcours, § 2 du cahier des charges).
//
// Ce fichier est conservé le temps que la refonte soit validée en production
// — il documente l'ancien formulaire complet (photo de profil, logo,
// signature, document d'identité) et permet un retour arrière immédiat en
// remettant `registerRoute` dessus dans app_router.dart.
// À supprimer une fois le nouveau parcours confirmé.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:sign_application/core/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';
import 'dart:io';
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
import 'package:sign_application/core/theme/app_typo.dart';

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

  // ── Document d'identité (carte / permis / passeport) ──
  String _selectedDocumentType = 'carte_identite';
  File? _documentIdentiteImage;
  bool _obscurePassword = true;

  // ── Critères mot de passe ──
  bool _hasUpperCase = false;
  bool _hasLowerCase = false;
  bool _hasDigit = false;
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
      _hasMinLength = value.length >= 8;
    });
  }

  // Alignée sur la politique backend (validations/common.js) : majuscule +
  // minuscule + chiffre + 8 caractères minimum. Le caractère spécial n'est
  // PAS exigé par le backend — l'imposer ici bloquerait des mots de passe
  // pourtant valides côté serveur.
  bool get _isPasswordValid =>
      _hasUpperCase && _hasLowerCase && _hasDigit && _hasMinLength;

  // image_picker copie l'image choisie dans le dossier cache de l'app et
  // renvoie ce chemin volatil : Android peut le purger avant l'envoi du
  // formulaire, ce qui provoque un PathNotFoundException au moment du
  // MultipartFile.fromFile. On recopie donc immédiatement chaque image dans
  // le répertoire documents (persistant) et on garde cette copie stable.
  Future<File> _persistPickedImage(String cachePath) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final ext = cachePath.contains('.') ? cachePath.split('.').last : 'jpg';
    final target = File(
      '${docsDir.path}/reg_${DateTime.now().microsecondsSinceEpoch}.$ext',
    );
    return File(cachePath).copy(target.path);
  }

  Future<void> _pickImage({required bool isProfile}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final persisted = await _persistPickedImage(pickedFile.path);
      if (!mounted) return;
      setState(() {
        if (isProfile) {
          _profileImage = persisted;
        } else {
          _logoImage = persisted;
        }
      });
    }
  }

  Future<void> _pickDocumentIdentiteImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pickedFile != null) {
      final persisted = await _persistPickedImage(pickedFile.path);
      if (!mounted) return;
      setState(() => _documentIdentiteImage = persisted);
    }
  }

  Future<void> _openSignaturePad() async {
    // BUG-03 : SignatureController doit être disposé dans tous les cas
    final controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );

    try {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Signez ici',
          style: AppTypo.jakarta(fontWeight: FontWeight.w700),
        ),
        content: Container(
          width: MediaQuery.of(dialogContext).size.width * 0.8,
          height: 200,
          decoration: BoxDecoration(
            color: AppColor.kChamp,
            borderRadius: BorderRadius.circular(14),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Signature(
              controller: controller,
              width: MediaQuery.of(dialogContext).size.width * 0.8,
              height: 200,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => controller.clear(),
            child: Text(
              'Effacer',
              style: AppTypo.jakarta(color: AppColor.kGrayscale40),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.isEmpty) {
                Navigator.pop(dialogContext);
                return;
              }
              final Uint8List? data = await controller.toPngBytes();
              // SEC-01 : Vérifier mounted après chaque await
              if (!dialogContext.mounted) return;
              if (data != null) {
                // Répertoire documents (persistant) plutôt que le cache, pour
                // éviter que le fichier soit purgé avant l'envoi du formulaire.
                final docsDir = await getApplicationDocumentsDirectory();
                if (!dialogContext.mounted) return;
                final file = File(
                  '${docsDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png',
                );
                await file.writeAsBytes(data);
                if (mounted) setState(() => _signatureImage = file);
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext);
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
              style: AppTypo.jakarta(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    } finally {
      controller.dispose();
    }
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
      // Le sélecteur d'image n'est pas un TextFormField : la validation
      // "obligatoire" est vérifiée manuellement ici avant l'envoi.
      if (_documentIdentiteImage == null) {
        showToast(
          context,
          'Photo requise',
          "Merci d'ajouter une photo de votre document d'identité pour continuer.",
          ToastificationType.error,
        );
        return;
      }
      context.read<AuthBloc>().add(
        RegisterRequested(
          nom: _lastNameController.text.trim(),
          prenom: _firstNameController.text.trim(),
          email: _emailController.text.trim(),
          mot_de_passe: _passwordController.text,
          adresse: _addressController.text.trim(),
          telephone: _phoneNumber ?? '',
          carte_identite_national_num: _cinController.text.trim(),
          typeDocumentIdentite: _selectedDocumentType,
          documentIdentite: _documentIdentiteImage != null
              ? XFile(_documentIdentiteImage!.path)
              : null,
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
          final isLoading = state is AuthLoading || state is AuthUploadProgress;
          final uploadProgress = state is AuthUploadProgress ? state.progress : null;
          return SafeArea(
            child: Stack(
              fit: StackFit.expand,
              children: [
                SingleChildScrollView(
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
                            color: Colors.black.withValues(alpha: 0.08),
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
                if (uploadProgress != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LinearProgressIndicator(
                          value: uploadProgress,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                          minHeight: 3,
                        ),
                        if (uploadProgress < 1.0)
                          Container(
                            color: Colors.white.withValues(alpha: 0.85),
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 14, height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Envoi en cours… ${(uploadProgress * 100).toInt()}%',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
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
            // Même traitement que la page de connexion : pastille blanche
            // circulaire qui fond le fond du logo et masque le liseré visible.
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
        LayoutBuilder(
          builder: (context, _) {
            final sw = MediaQuery.sizeOf(context).width;
            final fs = sw < 360 ? 22.0 : (sw < 400 ? 25.0 : 28.0);
            return Text(
              _currentStep == 0 ? 'Commençons !' : 'Informations complémentaires',
              style: AppTypo.jakarta(
                fontSize: fs,
                fontWeight: FontWeight.w800,
                color: AppColor.kGrayscaleDark100,
                height: 1.2,
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          _currentStep == 0
              ? 'Remplissez vos informations personnelles'
              : 'Complétez votre profil pour commencer à signer',
          style: AppTypo.jakarta(
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
                color: AppColor.kPrimary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
                : null,
          ),
          child: Center(
            child: Text(
              '$stepNumber',
              style: AppTypo.jakarta(
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
          style: AppTypo.jakarta(
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

  // ─────────────────────── HELPERS RÔLE ───────────────────────
  bool get _isProType => _selectedRole == 'Professionnel' || _selectedRole == 'Independant';
  bool get _isEntreprise => _selectedRole == 'Professionnel';

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
        _buildDocumentTypeSelector(),
        const SizedBox(height: 16),
        _buildCinInputField(),
        const SizedBox(height: 16),
        _buildDocumentIdentitePhotoSection(),
        const SizedBox(height: 16),
        _buildRoleDropdown(),
        const SizedBox(height: 20),
        _buildProfilePhotoSection(),

        // ── Bloc commun Professionnel ET Indépendant ─────────────────
        if (_isProType) ...[
          const SizedBox(height: 20),
          Container(height: 1, color: AppColor.kLine),
          const SizedBox(height: 20),

          // Badge type de compte
          _buildAccountTypeBanner(),
          const SizedBox(height: 16),

          _buildSectionTitle(
            _isEntreprise
                ? "Informations de l'entreprise"
                : "Informations professionnelles",
          ),
          const SizedBox(height: 16),

          _buildInputField(
            label: _isEntreprise ? "Nom de l'entreprise" : "Nom commercial / Activité",
            hint: _isEntreprise ? 'Ex: Mon Entreprise SARL' : 'Ex: Consulting Digital',
            controller: _nomEntrepriseController,
            icon: _isEntreprise ? Icons.apartment_outlined : Icons.work_outline,
            isRequired: false,
            validator: null,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: "Adresse professionnelle",
            hint: 'Ex: Dakar, Sénégal',
            controller: _adresseEntrepriseController,
            icon: Icons.location_on_outlined,
            isRequired: false,
            validator: null,
          ),
          const SizedBox(height: 16),
          _buildPhoneInput(
            label: "Téléphone professionnel",
            isRequired: false,
            controller: _entreprisePhoneController,
            onChanged: (phone) =>
                setState(() => _entreprisePhoneNumber = phone.completeNumber),
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: "Email professionnel",
            hint: 'Ex: contact@monactivite.sn',
            controller: _emailEntrepriseController,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            isRequired: false,
            validator: (value) {
              if (value == null || value.isEmpty) return null; // optionnel
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Email invalide';
              }
              return null;
            },
          ),

          // ── RC et NINEA : UNIQUEMENT pour Professionnel (entreprise) ──
          if (_isEntreprise) ...[
            const SizedBox(height: 16),
            _buildInputField(
              label: 'Registre de Commerce (RC)',
              hint: 'Ex: RC 2023 B 12345',
              controller: _rcController,
              icon: Icons.business_center_outlined,
              isRequired: true,
              validator: (v) =>
              (v == null || v.isEmpty) ? 'RC obligatoire pour une entreprise' : null,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              label: 'NINEA',
              hint: 'Ex: 123456789',
              controller: _nineaController,
              icon: Icons.numbers_outlined,
              isRequired: true,
              validator: (v) =>
              (v == null || v.isEmpty) ? 'NINEA obligatoire pour une entreprise' : null,
            ),
          ],

          const SizedBox(height: 16),
          _buildLogoSection(),
          const SizedBox(height: 16),
          _buildSignatureSection(),
        ],
      ],
    );
  }

  /// Bannière informative qui explique la différence entre les types de compte
  Widget _buildAccountTypeBanner() {
    final isEnt = _isEntreprise;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isEnt
            ? const Color(0xFFE8F0FE)
            : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEnt
              ? const Color(0xFF4285F4).withValues(alpha: 0.3)
              : const Color(0xFFFF9800).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isEnt ? Icons.business : Icons.person_pin_outlined,
            color: isEnt ? const Color(0xFF4285F4) : const Color(0xFFFF9800),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEnt ? 'Compte Professionnel' : 'Compte Indépendant',
                  style: AppTypo.jakarta(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isEnt
                        ? const Color(0xFF1A56DB)
                        : const Color(0xFFE65100),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isEnt
                      ? 'RC et NINEA requis — pour les entreprises enregistrées'
                      : 'Sans RC ni NINEA — pour les freelances et travailleurs indépendants',
                  style: AppTypo.jakarta(
                    fontSize: 11,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
            style: AppTypo.jakarta(
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
            style: AppTypo.jakarta(
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
      style: AppTypo.jakarta(
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
      hintStyle: AppTypo.jakarta(
        fontSize: 14,
        color: AppColor.kGrayscale40,
      ),
      prefixIcon: Icon(icon, color: AppColor.kPrimary, size: 20),
      filled: true,
      fillColor: AppColor.kChamp,
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
      errorStyle: AppTypo.jakarta(
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
          style: AppTypo.jakarta(
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

  // ─────────────────────── TYPE DE DOCUMENT D'IDENTITÉ ──────────────────────
  static const List<Map<String, dynamic>> _documentTypeOptions = [
    {'value': 'carte_identite', 'label': "Carte d'identité", 'icon': Icons.badge_outlined},
    {'value': 'permis', 'label': 'Permis de conduire', 'icon': Icons.directions_car_outlined},
    {'value': 'passeport', 'label': 'Passeport', 'icon': Icons.flight_takeoff_outlined},
  ];

  Widget _buildDocumentTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Type de document', isRequired: true),
        const SizedBox(height: 10),
        Row(
          children: _documentTypeOptions.map((opt) {
            final isSelected = _selectedDocumentType == opt['value'];
            final isLast = opt == _documentTypeOptions.last;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : 8),
                child: GestureDetector(
                  onTap: () => setState(() {
                    _selectedDocumentType = opt['value'] as String;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColor.kPrimary : AppColor.kChamp,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColor.kPrimary : AppColor.kLine,
                        width: 1.4,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColor.kPrimary.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            opt['icon'] as IconData,
                            key: ValueKey('${opt['value']}_$isSelected'),
                            size: 22,
                            color: isSelected ? Colors.white : AppColor.kGrayscale40,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          opt['label'] as String,
                          textAlign: TextAlign.center,
                          style: AppTypo.jakarta(
                            fontSize: 10.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColor.kGrayscaleDark100,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String get _documentNumberLabel {
    switch (_selectedDocumentType) {
      case 'permis':
        return 'Numéro de permis de conduire';
      case 'passeport':
        return 'Numéro de passeport';
      default:
        return "Numéro de carte d'identité";
    }
  }

  String get _documentNumberHint {
    switch (_selectedDocumentType) {
      case 'permis':
        return 'Ex: SN-2024-00123';
      case 'passeport':
        return 'Ex: 12AB34567';
      default:
        return 'Ex: 12345678';
    }
  }

  // ─────────────────────── NUMÉRO DE DOCUMENT — validation adaptée au type ──
  Widget _buildCinInputField() {
    final isNumericOnly = _selectedDocumentType == 'carte_identite';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(_documentNumberLabel, isRequired: true),
        const SizedBox(height: 8),
        TextFormField(
          controller: _cinController,
          keyboardType: isNumericOnly ? TextInputType.number : TextInputType.text,
          inputFormatters: isNumericOnly
              ? [FilteringTextInputFormatter.digitsOnly]
              : [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
          style: AppTypo.jakarta(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColor.kGrayscaleDark100,
          ),
          decoration: _baseDecoration(hint: _documentNumberHint, icon: Icons.badge_outlined),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Ce champ est obligatoire';
            if (isNumericOnly && !RegExp(r'^\d+$').hasMatch(v)) {
              return 'Seuls les chiffres sont autorisés';
            }
            if (!isNumericOnly && !RegExp(r'^[A-Za-z0-9\-]+$').hasMatch(v)) {
              return 'Format invalide';
            }
            return null;
          },
        ),
      ],
    );
  }

  // ─────────────────────── PHOTO DU DOCUMENT D'IDENTITÉ ─────────────────────
  Widget _buildDocumentIdentitePhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Photo du document', isRequired: true),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _pickDocumentIdentiteImage,
          child: Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColor.kChamp,
              border: Border.all(
                color: _documentIdentiteImage != null ? AppColor.kPrimary : AppColor.kLine,
                width: _documentIdentiteImage != null ? 2 : 1,
              ),
            ),
            child: _documentIdentiteImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_documentIdentiteImage!, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined, size: 30, color: AppColor.kPrimary),
                      const SizedBox(height: 8),
                      Text(
                        'Ajouter une photo du document',
                        style: AppTypo.jakarta(
                          color: AppColor.kPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Obligatoire — cliquez pour sélectionner',
                        style: AppTypo.jakarta(
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
          style: AppTypo.jakarta(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColor.kGrayscaleDark100,
          ),
          dropdownTextStyle: AppTypo.jakarta(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColor.kGrayscaleDark100,
          ),
          decoration: InputDecoration(
            hintText: 'Votre numéro',
            hintStyle: AppTypo.jakarta(
              fontSize: 14,
              color: AppColor.kGrayscale40,
            ),
            filled: true,
            fillColor: AppColor.kChamp,
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
            errorStyle: AppTypo.jakarta(
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
            // isValidNumber() lance parfois une exception (NumberTooShortException)
            // au lieu de retourner false — on la traite comme un numéro invalide.
            try {
              if (!phone.isValidNumber()) {
                return 'Numéro de téléphone invalide';
              }
            } catch (_) {
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
            style: AppTypo.jakarta(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColor.kGrayscaleDark100,
            ),
            decoration: InputDecoration(
              hintText: 'Créez un mot de passe sécurisé',
              hintStyle: AppTypo.jakarta(
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
              fillColor: AppColor.kChamp,
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
              errorStyle: AppTypo.jakarta(
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
        color: AppColor.kChamp,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Critères du mot de passe :',
            style: AppTypo.jakarta(
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
            style: AppTypo.jakarta(
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
        _fieldLabel('Choisissez votre profil', isRequired: true),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedRole,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColor.kPrimary),
          style: AppTypo.jakarta(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColor.kGrayscaleDark100,
          ),
          decoration: InputDecoration(
            hintText: 'Sélectionnez votre rôle',
            hintStyle: AppTypo.jakarta(
              fontSize: 14,
              color: AppColor.kGrayscale40,
            ),
            prefixIcon: Icon(Icons.work_outline, color: AppColor.kPrimary, size: 20),
            filled: true,
            fillColor: AppColor.kChamp,
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
            errorStyle: AppTypo.jakarta(
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
                style: AppTypo.jakarta(
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
              color: AppColor.kChamp,
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
                  style: AppTypo.jakarta(
                    color: AppColor.kPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Optionnel — cliquez pour sélectionner',
                  style: AppTypo.jakarta(
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
              color: AppColor.kChamp,
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
                  style: AppTypo.jakarta(
                    color: AppColor.kPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Optionnel',
                  textAlign: TextAlign.center,
                  style: AppTypo.jakarta(
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
              color: AppColor.kChamp,
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
                  style: AppTypo.jakarta(
                    color: AppColor.kPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Optionnel — touchez pour signer',
                  textAlign: TextAlign.center,
                  style: AppTypo.jakarta(
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
                  style: AppTypo.jakarta(
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
                          style: AppTypo.jakarta(
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
                style: AppTypo.jakarta(
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
                style: AppTypo.jakarta(
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
          style: AppTypo.jakarta(
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
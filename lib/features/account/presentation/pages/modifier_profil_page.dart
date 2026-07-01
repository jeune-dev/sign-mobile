import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_application/core/config/user_role.dart';
import 'package:sign_application/features/account/domain/entities/account_user.dart';
import 'package:sign_application/features/account/presentation/bloc/account_bloc.dart';
import 'package:sign_application/features/account/presentation/bloc/account_event.dart';
import 'package:sign_application/features/account/presentation/bloc/account_state.dart';

/// Écran d'édition des informations saisies à l'inscription.
/// Réutilise l'AccountBloc global (fourni dans main.dart) : à la sauvegarde,
/// on émet [ModifierInfoPersonnellesEvent] et la page profil se met à jour
/// automatiquement via l'état [AccountSuccess].
class ModifierProfilPage extends StatefulWidget {
  final AccountUser user;
  const ModifierProfilPage({super.key, required this.user});

  @override
  State<ModifierProfilPage> createState() => _ModifierProfilPageState();
}

class _ModifierProfilPageState extends State<ModifierProfilPage> {
  final _formKey = GlobalKey<FormState>();

  // Informations personnelles
  late final TextEditingController _prenom;
  late final TextEditingController _nom;
  late final TextEditingController _email;
  late final TextEditingController _telephone;
  late final TextEditingController _adresse;
  late final TextEditingController _cin;

  // Informations professionnelles / entreprise
  late final TextEditingController _nomEntreprise;
  late final TextEditingController _adresseEntreprise;
  late final TextEditingController _telephoneEntreprise;
  late final TextEditingController _emailEntreprise;
  late final TextEditingController _ninea;
  late final TextEditingController _rc;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _prenom = TextEditingController(text: u.prenom ?? '');
    _nom = TextEditingController(text: u.nom ?? '');
    _email = TextEditingController(text: u.email ?? '');
    _telephone = TextEditingController(text: u.telephone ?? '');
    _adresse = TextEditingController(text: u.adresse ?? '');
    _cin = TextEditingController(text: u.carteIdentiteNationalNum ?? '');
    _nomEntreprise = TextEditingController(text: u.nomEntreprise ?? '');
    _adresseEntreprise = TextEditingController(text: u.adresseEntreprise ?? '');
    _telephoneEntreprise = TextEditingController(text: u.telephoneEntreprise ?? '');
    _emailEntreprise = TextEditingController(text: u.emailEntreprise ?? '');
    _ninea = TextEditingController(text: u.ninea ?? '');
    _rc = TextEditingController(text: u.rc ?? '');
  }

  @override
  void dispose() {
    _prenom.dispose();
    _nom.dispose();
    _email.dispose();
    _telephone.dispose();
    _adresse.dispose();
    _cin.dispose();
    _nomEntreprise.dispose();
    _adresseEntreprise.dispose();
    _telephoneEntreprise.dispose();
    _emailEntreprise.dispose();
    _ninea.dispose();
    _rc.dispose();
    super.dispose();
  }

  // On n'envoie que les valeurs non vides : le backend ignore les champs absents,
  // ce qui évite de déclencher les validations de format sur un champ laissé vide.
  String? _val(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final role = UserRoleX.fromString(widget.user.role);
    final isPro = role.isPro;
    final isEntreprise = role.isEntreprise;

    context.read<AccountBloc>().add(
          ModifierInfoPersonnellesEvent(
            prenom: _val(_prenom),
            nom: _val(_nom),
            email: _val(_email),
            telephone: _val(_telephone),
            adresse: _val(_adresse),
            carteIdentiteNationalNum: _val(_cin),
            // Champs pro uniquement si le rôle le justifie
            nomEntreprise: isPro ? _val(_nomEntreprise) : null,
            adresseEntreprise: isPro ? _val(_adresseEntreprise) : null,
            telephoneEntreprise: isPro ? _val(_telephoneEntreprise) : null,
            emailEntreprise: isPro ? _val(_emailEntreprise) : null,
            ninea: isEntreprise ? _val(_ninea) : null,
            rc: isEntreprise ? _val(_rc) : null,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final role = UserRoleX.fromString(widget.user.role);
    final isPro = role.isPro;
    final isEntreprise = role.isEntreprise;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Modifier mes informations',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: BlocConsumer<AccountBloc, AccountState>(
        listener: (context, state) {
          if (state is AccountSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green[700],
              ),
            );
            Navigator.of(context).pop();
          }
          if (state is AccountError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red[700],
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AccountLoading;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              children: [
                // ── Informations personnelles ──────────────────────────────
                _card(
                  title: 'Informations personnelles',
                  icon: Icons.person_outline,
                  children: [
                    _field(controller: _prenom, label: 'Prénom', icon: Icons.badge_outlined),
                    _field(controller: _nom, label: 'Nom', icon: Icons.badge_outlined),
                    _field(
                      controller: _email,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    _field(
                      controller: _telephone,
                      label: 'Téléphone',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    _field(controller: _adresse, label: 'Adresse', icon: Icons.location_on_outlined),
                    _field(
                      controller: _cin,
                      label: 'N° CIN',
                      icon: Icons.credit_card_outlined,
                      keyboardType: TextInputType.number,
                      isLast: true,
                    ),
                  ],
                ),

                if (isPro) ...[
                  const SizedBox(height: 20),
                  _card(
                    title: isEntreprise
                        ? 'Informations entreprise'
                        : 'Informations professionnelles',
                    icon: isEntreprise ? Icons.business_outlined : Icons.work_outline,
                    children: [
                      _field(
                          controller: _nomEntreprise,
                          label: 'Raison sociale',
                          icon: Icons.store_outlined),
                      _field(
                          controller: _adresseEntreprise,
                          label: 'Adresse pro',
                          icon: Icons.location_city_outlined),
                      _field(
                        controller: _telephoneEntreprise,
                        label: 'Tél. professionnel',
                        icon: Icons.phone_in_talk_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      _field(
                        controller: _emailEntreprise,
                        label: 'Email professionnel',
                        icon: Icons.alternate_email,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                        isLast: !isEntreprise,
                      ),
                      if (isEntreprise) ...[
                        _field(controller: _ninea, label: 'NINEA', icon: Icons.tag_outlined),
                        _field(
                            controller: _rc,
                            label: 'RC',
                            icon: Icons.numbers_outlined,
                            isLast: true),
                      ],
                    ],
                  ),
                ],

                const SizedBox(height: 28),

                // ── Bouton Enregistrer ──────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.black38,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.4),
                          )
                        : const Text(
                            'Enregistrer les modifications',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String? _validateEmail(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null; // champ optionnel
    final ok = RegExp(r'^[\w.\-+]+@[\w\-]+\.[\w\-.]+$').hasMatch(t);
    return ok ? null : 'Email invalide';
  }

  // ── Carte de section ────────────────────────────────────────────────────
  Widget _card({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey[100], height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  // ── Champ de saisie ─────────────────────────────────────────────────────
  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
        inputFormatters: keyboardType == TextInputType.number
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
          prefixIcon: Icon(icon, size: 20, color: Colors.grey[500]),
          filled: true,
          fillColor: const Color(0xFFF8F8F8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black87, width: 1.4),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red[400]!),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red[400]!, width: 1.4),
          ),
        ),
      ),
    );
  }
}

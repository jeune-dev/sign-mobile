import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_application/features/client/domain/entities/client.dart';
import '../bloc/autres_contrats_bloc.dart';
import '../bloc/autres_contrats_event.dart';
import '../bloc/autres_contrats_state.dart';
import '../widgets/client_search_field.dart';

class CreationContratConfidentialitePage extends StatefulWidget {
  const CreationContratConfidentialitePage({super.key});

  @override
  State<CreationContratConfidentialitePage> createState() => _State();
}

class _State extends State<CreationContratConfidentialitePage> {
  final _formKey = GlobalKey<FormState>();
  final _typeInfoCtrl = TextEditingController();
  final _dureeCtrl = TextEditingController();
  final _sanctionsCtrl = TextEditingController();
  final _documentsCtrl = TextEditingController();
  final _personnesCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  String _niveauConf = 'moyen';
  Client? _selectedClient;

  static const _badgeColor = Color(0xFF2563EB);

  @override
  void dispose() {
    _typeInfoCtrl.dispose();
    _dureeCtrl.dispose();
    _sanctionsCtrl.dispose();
    _documentsCtrl.dispose();
    _personnesCtrl.dispose();
    _villeCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un client'), backgroundColor: Colors.red),
      );
      return;
    }
    context.read<AutresContratsBloc>().add(CreerContrat('contrat-confidentialite', {
      'autrePartieId': _selectedClient!.id,
      'data': {
        'type_informations': _typeInfoCtrl.text.trim(),
        'niveau_confidentialite': _niveauConf,
        'duree_confidentialite': _dureeCtrl.text.trim(),
        'sanctions_violation': _sanctionsCtrl.text.trim(),
        if (_documentsCtrl.text.trim().isNotEmpty) 'documents_concernes': _documentsCtrl.text.trim(),
        if (_personnesCtrl.text.trim().isNotEmpty) 'personnes_autorisees': _personnesCtrl.text.trim(),
        if (_villeCtrl.text.trim().isNotEmpty) 'ville_signature': _villeCtrl.text.trim(),
      },
      'signature_generateur': '',
    }));
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: BlocListener<AutresContratsBloc, AutresContratsState>(
        listener: (context, state) {
          if (state is AutresContratsSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
            Navigator.pop(context);
          }
          if (state is AutresContratsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: Column(
          children: [
            // Custom Header
            Container(
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Contrat de confidentialité',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _badgeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('NDA', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  children: [
                    ClientSearchField(
                      label: 'Autre partie',
                      onClientSelected: (c) => setState(() => _selectedClient = c),
                    ),
                    const SizedBox(height: 16),
                    // Section: Confidentialité
                    _buildSection(
                      icon: Icons.lock_outline,
                      iconColor: _badgeColor,
                      title: 'Confidentialité',
                      children: [
                        _field(_typeInfoCtrl, "Type d'informations", icon: Icons.info_outline, required: true),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _niveauConf,
                          decoration: _dec('Niveau de confidentialité', icon: Icons.security_outlined),
                          items: const [
                            DropdownMenuItem(value: 'faible', child: Text('Faible')),
                            DropdownMenuItem(value: 'moyen', child: Text('Moyen')),
                            DropdownMenuItem(value: 'élevé', child: Text('Élevé')),
                          ],
                          onChanged: (v) => setState(() => _niveauConf = v!),
                        ),
                        const SizedBox(height: 12),
                        _field(_dureeCtrl, 'Durée de confidentialité', icon: Icons.timer_outlined, required: true),
                        const SizedBox(height: 12),
                        _field(_sanctionsCtrl, 'Sanctions en cas de violation', icon: Icons.gavel_outlined, required: true, maxLines: 3),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Section: Détails
                    _buildSection(
                      icon: Icons.article_outlined,
                      iconColor: _badgeColor,
                      title: 'Détails',
                      children: [
                        _field(_documentsCtrl, 'Documents concernés (optionnel)', icon: Icons.folder_outlined, required: false),
                        const SizedBox(height: 12),
                        _field(_personnesCtrl, 'Personnes autorisées (optionnel)', icon: Icons.group_outlined, required: false),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Section: Signature
                    _buildSection(
                      icon: Icons.location_on_outlined,
                      iconColor: _badgeColor,
                      title: 'Signature',
                      children: [
                        _field(_villeCtrl, 'Ville de signature (optionnel)', icon: Icons.place_outlined, required: false),
                      ],
                    ),
                    const SizedBox(height: 24),
                    BlocBuilder<AutresContratsBloc, AutresContratsState>(
                      builder: (context, state) {
                        final isLoading = state is AutresContratsLoading;
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: isLoading ? null : _submit,
                            child: isLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Créer le contrat', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required IconData icon, required Color iconColor, required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {required bool required, int maxLines = 1, IconData? icon}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: _dec(label, icon: icon),
      validator: required ? (v) => (v == null || v.isEmpty) ? 'Ce champ est requis' : null : null,
    );
  }

  InputDecoration _dec(String label, {IconData? icon}) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.grey[50],
    prefixIcon: icon != null ? Icon(icon, color: _badgeColor, size: 20) : null,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _badgeColor)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_application/features/client/domain/entities/client.dart';
import '../bloc/autres_contrats_bloc.dart';
import '../bloc/autres_contrats_event.dart';
import '../bloc/autres_contrats_state.dart';
import '../widgets/client_search_field.dart';

class CreationProcurationPage extends StatefulWidget {
  const CreationProcurationPage({super.key});

  @override
  State<CreationProcurationPage> createState() => _State();
}

class _State extends State<CreationProcurationPage> {
  final _formKey = GlobalKey<FormState>();
  final _objetCtrl = TextEditingController();
  final _pouvoirsCtrl = TextEditingController();
  final _dureeCtrl = TextEditingController();
  final _limitesCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  String _typeProcuration = 'générale';
  Client? _selectedClient;

  static const _badgeColor = Color(0xFF4F46E5);

  @override
  void dispose() {
    _objetCtrl.dispose();
    _pouvoirsCtrl.dispose();
    _dureeCtrl.dispose();
    _limitesCtrl.dispose();
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
    context.read<AutresContratsBloc>().add(CreerContrat('procuration', {
      'autrePartieId': _selectedClient!.id,
      'data': {
        'objet_procuration': _objetCtrl.text.trim(),
        'pouvoirs_accordes': _pouvoirsCtrl.text.trim(),
        'duree': _dureeCtrl.text.trim(),
        'type_procuration': _typeProcuration,
        if (_typeProcuration == 'limitée' && _limitesCtrl.text.trim().isNotEmpty) 'limites_precises': _limitesCtrl.text.trim(),
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
                      'Procuration',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _badgeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Procuration', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
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
                      label: 'Mandataire',
                      onClientSelected: (c) => setState(() => _selectedClient = c),
                    ),
                    const SizedBox(height: 16),
                    // Section: Procuration
                    _buildSection(
                      icon: Icons.description_outlined,
                      iconColor: _badgeColor,
                      title: 'Procuration',
                      children: [
                        _field(_objetCtrl, 'Objet de la procuration', icon: Icons.assignment_outlined, required: true, maxLines: 2),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _typeProcuration,
                          decoration: _dec('Type de procuration', icon: Icons.category_outlined),
                          items: const [
                            DropdownMenuItem(value: 'générale', child: Text('Générale')),
                            DropdownMenuItem(value: 'limitée', child: Text('Limitée')),
                          ],
                          onChanged: (v) => setState(() => _typeProcuration = v!),
                        ),
                        const SizedBox(height: 12),
                        _field(_pouvoirsCtrl, 'Pouvoirs accordés', icon: Icons.admin_panel_settings_outlined, required: true, maxLines: 3),
                        const SizedBox(height: 12),
                        _field(_dureeCtrl, 'Durée', icon: Icons.timer_outlined, required: true),
                      ],
                    ),
                    if (_typeProcuration == 'limitée') ...[
                      const SizedBox(height: 16),
                      // Section: Limites
                      _buildSection(
                        icon: Icons.lock_outline,
                        iconColor: _badgeColor,
                        title: 'Limites',
                        children: [
                          _field(_limitesCtrl, 'Limites précises', icon: Icons.block_outlined, required: false, maxLines: 2),
                        ],
                      ),
                    ],
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
                                : const Text('Créer la procuration', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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

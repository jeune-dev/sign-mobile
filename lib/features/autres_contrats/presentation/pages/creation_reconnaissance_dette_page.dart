import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sign_application/features/client/domain/entities/client.dart';
import '../bloc/autres_contrats_bloc.dart';
import '../bloc/autres_contrats_event.dart';
import '../bloc/autres_contrats_state.dart';
import '../widgets/client_search_field.dart';

class CreationReconnaissanceDettePage extends StatefulWidget {
  const CreationReconnaissanceDettePage({super.key});

  @override
  State<CreationReconnaissanceDettePage> createState() => _State();
}

class _State extends State<CreationReconnaissanceDettePage> {
  final _formKey = GlobalKey<FormState>();
  final _montantCtrl = TextEditingController();
  final _motifCtrl = TextEditingController();
  final _nbEchCtrl = TextEditingController();
  final _montantEchCtrl = TextEditingController();
  final _freqCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  String _devise = 'FCFA';
  bool _echelonne = false;
  DateTime? _dateLimite;
  Client? _selectedClient;

  static const _badgeColor = Color(0xFF2563EB);

  @override
  void dispose() {
    _montantCtrl.dispose();
    _motifCtrl.dispose();
    _nbEchCtrl.dispose();
    _montantEchCtrl.dispose();
    _freqCtrl.dispose();
    _villeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final dt = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      locale: const Locale('fr', 'FR'),
    );
    if (dt != null) setState(() => _dateLimite = dt);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un client'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_dateLimite == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner la date limite'), backgroundColor: Colors.red),
      );
      return;
    }
    context.read<AutresContratsBloc>().add(CreerContrat('reconnaissance-dette', {
      'autrePartieId': _selectedClient!.id,
      'data': {
        'montant': double.tryParse(_montantCtrl.text) ?? 0,
        'devise': _devise,
        'motif_dette': _motifCtrl.text.trim(),
        'date_limite_remboursement': _dateLimite!.toIso8601String().substring(0, 10),
        'remboursement_echelonne': _echelonne,
        if (_echelonne && _nbEchCtrl.text.isNotEmpty) 'nombre_echeances': int.tryParse(_nbEchCtrl.text),
        if (_echelonne && _montantEchCtrl.text.isNotEmpty) 'montant_par_echeance': double.tryParse(_montantEchCtrl.text),
        if (_echelonne && _freqCtrl.text.isNotEmpty) 'frequence_paiements': _freqCtrl.text.trim(),
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
                      'Reconnaissance de dette',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _badgeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Dette', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
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
                      label: 'Débiteur',
                      onClientSelected: (c) => setState(() => _selectedClient = c),
                    ),
                    const SizedBox(height: 16),
                    // Section: Dette
                    _buildSection(
                      icon: Icons.payments_outlined,
                      iconColor: _badgeColor,
                      title: 'Dette',
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _montantCtrl,
                                keyboardType: TextInputType.number,
                                decoration: _dec('Montant', icon: Icons.monetization_on_outlined),
                                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 110,
                              child: DropdownButtonFormField<String>(
                                value: _devise,
                                decoration: _dec('Devise'),
                                items: const [
                                  DropdownMenuItem(value: 'FCFA', child: Text('FCFA')),
                                  DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                                  DropdownMenuItem(value: 'USD', child: Text('USD')),
                                ],
                                onChanged: (v) => setState(() => _devise = v!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _field(_motifCtrl, 'Motif de la dette', icon: Icons.notes_outlined, required: true, maxLines: 2),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Section: Remboursement
                    _buildSection(
                      icon: Icons.calendar_month_outlined,
                      iconColor: _badgeColor,
                      title: 'Remboursement',
                      children: [
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              border: Border.all(color: Colors.grey[200]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, size: 20, color: _badgeColor),
                                const SizedBox(width: 10),
                                Text(
                                  _dateLimite != null
                                      ? 'Date limite : ${DateFormat('dd/MM/yyyy').format(_dateLimite!)}'
                                      : 'Date limite de remboursement *',
                                  style: TextStyle(
                                    color: _dateLimite != null ? Colors.black87 : Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: SwitchListTile(
                            title: const Text('Remboursement échelonné', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            value: _echelonne,
                            activeColor: _badgeColor,
                            onChanged: (v) => setState(() => _echelonne = v),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                        if (_echelonne) ...[
                          const SizedBox(height: 12),
                          _field(_nbEchCtrl, "Nombre d'échéances", icon: Icons.format_list_numbered_outlined, required: false, keyboardType: TextInputType.number),
                          const SizedBox(height: 12),
                          _field(_montantEchCtrl, 'Montant par échéance', icon: Icons.monetization_on_outlined, required: false, keyboardType: TextInputType.number),
                          const SizedBox(height: 12),
                          _field(_freqCtrl, 'Fréquence des paiements', icon: Icons.repeat_outlined, required: false),
                        ],
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
                                : const Text('Créer la reconnaissance', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _field(TextEditingController ctrl, String label, {required bool required, int maxLines = 1, TextInputType keyboardType = TextInputType.text, IconData? icon}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
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

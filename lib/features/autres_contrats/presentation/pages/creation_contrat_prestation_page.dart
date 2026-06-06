import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sign_application/features/client/domain/entities/client.dart';
import '../bloc/autres_contrats_bloc.dart';
import '../bloc/autres_contrats_event.dart';
import '../bloc/autres_contrats_state.dart';
import '../widgets/client_search_field.dart';

class CreationContratPrestationPage extends StatefulWidget {
  const CreationContratPrestationPage({super.key});

  @override
  State<CreationContratPrestationPage> createState() => _State();
}

class _State extends State<CreationContratPrestationPage> {
  final _formKey = GlobalKey<FormState>();
  final _titreCtrl = TextEditingController();
  final _objetCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _dureeCtrl = TextEditingController();
  final _montantCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  DateTime? _dateContrat;
  DateTime? _dateDebut;
  DateTime? _dateFin;
  String _modePaiement = 'Virement bancaire';
  Client? _selectedClient;

  static const _badgeColor = Color(0xFF2563EB);

  @override
  void dispose() {
    _titreCtrl.dispose();
    _objetCtrl.dispose();
    _typeCtrl.dispose();
    _descCtrl.dispose();
    _dureeCtrl.dispose();
    _montantCtrl.dispose();
    _villeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required void Function(DateTime) onPicked}) async {
    final dt = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('fr', 'FR'),
    );
    if (dt != null) onPicked(dt);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un client'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_dateDebut == null || _dateFin == null || _dateContrat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner toutes les dates'), backgroundColor: Colors.red),
      );
      return;
    }
    context.read<AutresContratsBloc>().add(CreerContrat('contrat-prestation', {
      'autrePartieId': _selectedClient!.id,
      'data': {
        'titre_contrat': _titreCtrl.text.trim(),
        'date_contrat': _dateContrat!.toIso8601String().substring(0, 10),
        'ville_signature': _villeCtrl.text.trim(),
        'objet_prestation': _objetCtrl.text.trim(),
        'type_prestation': _typeCtrl.text.trim(),
        'description_mission': _descCtrl.text.trim(),
        'duree_mission': _dureeCtrl.text.trim(),
        'date_debut': _dateDebut!.toIso8601String().substring(0, 10),
        'date_fin': _dateFin!.toIso8601String().substring(0, 10),
        'montant_total': double.tryParse(_montantCtrl.text) ?? 0,
        'mode_paiement': _modePaiement,
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
                      'Contrat de prestation',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _badgeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Prestation', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
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
                    // Client search
                    ClientSearchField(
                      label: 'Autre partie',
                      onClientSelected: (c) => setState(() => _selectedClient = c),
                    ),
                    const SizedBox(height: 16),
                    // Section: Informations générales
                    _buildSection(
                      icon: Icons.handshake_outlined,
                      iconColor: _badgeColor,
                      title: 'Informations générales',
                      children: [
                        _field(_titreCtrl, 'Titre du contrat', icon: Icons.title, required: true),
                        const SizedBox(height: 12),
                        _field(_objetCtrl, 'Objet de la prestation', icon: Icons.description_outlined, required: true),
                        const SizedBox(height: 12),
                        _field(_typeCtrl, 'Type de prestation', icon: Icons.category_outlined, required: true),
                        const SizedBox(height: 12),
                        _field(_descCtrl, 'Description de la mission', icon: Icons.notes_outlined, required: true, maxLines: 3),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Section: Dates & Durée
                    _buildSection(
                      icon: Icons.calendar_month_outlined,
                      iconColor: _badgeColor,
                      title: 'Dates & Durée',
                      children: [
                        _datePicker('Date du contrat', _dateContrat, (dt) => setState(() => _dateContrat = dt)),
                        const SizedBox(height: 12),
                        _datePicker('Date de début', _dateDebut, (dt) => setState(() => _dateDebut = dt)),
                        const SizedBox(height: 12),
                        _datePicker('Date de fin', _dateFin, (dt) => setState(() => _dateFin = dt)),
                        const SizedBox(height: 12),
                        _field(_dureeCtrl, 'Durée de la mission', icon: Icons.timer_outlined, required: true),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Section: Financier
                    _buildSection(
                      icon: Icons.payments_outlined,
                      iconColor: _badgeColor,
                      title: 'Financier',
                      children: [
                        _field(_montantCtrl, 'Montant total', icon: Icons.monetization_on_outlined, required: true, keyboardType: TextInputType.number),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _modePaiement,
                          decoration: _dec('Mode de paiement', icon: Icons.credit_card_outlined),
                          items: const [
                            DropdownMenuItem(value: 'Espèces', child: Text('Espèces')),
                            DropdownMenuItem(value: 'Virement bancaire', child: Text('Virement bancaire')),
                            DropdownMenuItem(value: 'Mobile Money', child: Text('Mobile Money')),
                            DropdownMenuItem(value: 'Chèque', child: Text('Chèque')),
                          ],
                          onChanged: (v) => setState(() => _modePaiement = v!),
                        ),
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
                    // Submit Button
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

  Widget _datePicker(String label, DateTime? value, void Function(DateTime) onPicked) {
    final formatted = value != null ? DateFormat('dd/MM/yyyy').format(value) : null;
    return GestureDetector(
      onTap: () => _pickDate(onPicked: onPicked),
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
              formatted ?? label,
              style: TextStyle(color: value != null ? Colors.black87 : Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
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

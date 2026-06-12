import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_application/features/client/domain/entities/client.dart';
import 'package:sign_application/features/client/presentation/bloc/client_bloc.dart';
import 'package:sign_application/features/client/presentation/bloc/client_event.dart';
import 'package:sign_application/features/client/presentation/bloc/client_state.dart';
import '../bloc/quittance_loyer_bloc.dart';
import '../bloc/quittance_loyer_event.dart';
import '../bloc/quittance_loyer_state.dart';
import 'package:toastification/toastification.dart';
import 'package:sign_application/core/widgets/toastNotif.dart';

class CreationQuittancePage extends StatefulWidget {
  const CreationQuittancePage({super.key});

  @override
  State<CreationQuittancePage> createState() => _CreationQuittancePageState();
}

class _CreationQuittancePageState extends State<CreationQuittancePage> {
  final _formKey = GlobalKey<FormState>();
  final _adresseCtrl = TextEditingController();
  final _montantLoyerCtrl = TextEditingController();
  final _montantChargesCtrl = TextEditingController();
  final _montantPayeCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  final _anneeCtrl = TextEditingController();
  final _clientSearchCtrl = TextEditingController();

  String _typeBien = 'appartement';
  String _mois = 'Janvier';
  String _modePaiement = 'Virement bancaire';
  bool _paiementComplet = true;
  DateTime? _datePaiement;
  Client? _selectedClient;

  final List<String> _moisList = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];

  double get _montantTotal {
    final loyer = double.tryParse(_montantLoyerCtrl.text) ?? 0;
    final charges = double.tryParse(_montantChargesCtrl.text) ?? 0;
    return loyer + charges;
  }

  @override
  void dispose() {
    _adresseCtrl.dispose(); _montantLoyerCtrl.dispose(); _montantChargesCtrl.dispose();
    _montantPayeCtrl.dispose(); _obsCtrl.dispose(); _villeCtrl.dispose();
    _anneeCtrl.dispose(); _clientSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final dt = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (dt != null) setState(() => _datePaiement = dt);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClient == null) {
      showToast(context, 'Champ requis', 'Veuillez sélectionner un locataire', ToastificationType.error);
      return;
    }
    if (_datePaiement == null) {
      showToast(context, 'Champ requis', 'Veuillez sélectionner la date de paiement', ToastificationType.error);
      return;
    }

    context.read<QuittanceLoyerBloc>().add(CreerQuittanceEvent({
      'locataireId': _selectedClient!.id,
      'adresse_logement': _adresseCtrl.text.trim(),
      'type_bien': _typeBien,
      'mois': _mois,
      'annee': int.tryParse(_anneeCtrl.text) ?? DateTime.now().year,
      'montant_loyer': double.tryParse(_montantLoyerCtrl.text) ?? 0,
      'montant_charges': double.tryParse(_montantChargesCtrl.text) ?? 0,
      'montant_total': _montantTotal,
      'date_paiement': _datePaiement!.toIso8601String().substring(0, 10),
      'mode_paiement': _modePaiement,
      'est_total': _paiementComplet,
      if (!_paiementComplet && _montantPayeCtrl.text.isNotEmpty)
        'montant_paye': double.tryParse(_montantPayeCtrl.text),
      if (_obsCtrl.text.trim().isNotEmpty) 'observations': _obsCtrl.text.trim(),
      if (_villeCtrl.text.trim().isNotEmpty) 'ville_emission': _villeCtrl.text.trim(),
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Nouvelle quittance', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: BlocListener<QuittanceLoyerBloc, QuittanceLoyerState>(
        listener: (context, state) {
          if (state is QuittanceLoyerSuccess) {
            showToast(context, 'Quittance créée', 'La quittance de loyer a été créée avec succès.', ToastificationType.success);
            Navigator.pop(context);
          }
          if (state is QuittanceLoyerError) {
            showToast(context, 'Erreur', state.message, ToastificationType.error);
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Locataire', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              if (_selectedClient != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${_selectedClient!.prenom} ${_selectedClient!.nom}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _selectedClient = null),
                        child: const Icon(Icons.close, color: Colors.white70, size: 18),
                      ),
                    ],
                  ),
                )
              else ...[
                TextField(
                  controller: _clientSearchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un locataire...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.black),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  onChanged: (v) {
                    if (v.length >= 2) context.read<ClientBloc>().add(RechercherClientsEvent(v));
                  },
                ),
                BlocBuilder<ClientBloc, ClientState>(
                  builder: (context, state) {
                    if (state is ClientsRechercheLoaded && state.clients.isNotEmpty) {
                      return Container(
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                        child: Column(
                          children: state.clients.take(5).map((client) => ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.black,
                              child: Text(
                                client.prenom.isNotEmpty ? client.prenom[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                            title: Text('${client.prenom} ${client.nom}', style: const TextStyle(fontSize: 13)),
                            onTap: () {
                              setState(() => _selectedClient = client);
                              _clientSearchCtrl.clear();
                            },
                          )).toList(),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
              const SizedBox(height: 20),
              _field(_adresseCtrl, 'Adresse du logement *'),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _typeBien,
                decoration: _dec('Type de bien *'),
                items: const [
                  DropdownMenuItem(value: 'appartement', child: Text('Appartement')),
                  DropdownMenuItem(value: 'maison', child: Text('Maison')),
                  DropdownMenuItem(value: 'studio', child: Text('Studio')),
                  DropdownMenuItem(value: 'villa', child: Text('Villa')),
                  DropdownMenuItem(value: 'bureau', child: Text('Bureau')),
                  DropdownMenuItem(value: 'autre', child: Text('Autre')),
                ],
                onChanged: (v) => setState(() => _typeBien = v!),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _mois,
                      decoration: _dec('Mois *'),
                      items: _moisList.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (v) => setState(() => _mois = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_anneeCtrl, 'Année *', keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 14),
              _field(_montantLoyerCtrl, 'Montant du loyer *', keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
              const SizedBox(height: 14),
              _field(_montantChargesCtrl, 'Montant des charges', required: false, keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Montant total', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('${_montantTotal.toStringAsFixed(0)} FCFA', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        _datePaiement != null
                            ? 'Date de paiement : ${_datePaiement!.toIso8601String().substring(0, 10)}'
                            : 'Date de paiement *',
                        style: TextStyle(color: _datePaiement != null ? Colors.black : Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _modePaiement,
                decoration: _dec('Mode de paiement *'),
                items: const [
                  DropdownMenuItem(value: 'Espèces', child: Text('Espèces')),
                  DropdownMenuItem(value: 'Virement bancaire', child: Text('Virement bancaire')),
                  DropdownMenuItem(value: 'Mobile Money', child: Text('Mobile Money')),
                  DropdownMenuItem(value: 'Chèque', child: Text('Chèque')),
                  DropdownMenuItem(value: 'ALL', child: Text('Tout mode de paiement')),
                  DropdownMenuItem(value: 'Autre', child: Text('Autre')),
                ],
                onChanged: (v) => setState(() => _modePaiement = v!),
              ),
              const SizedBox(height: 14),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Paiement complet', style: TextStyle(fontWeight: FontWeight.w600)),
                value: _paiementComplet,
                activeColor: Colors.black,
                onChanged: (v) => setState(() => _paiementComplet = v),
              ),
              if (!_paiementComplet) ...[
                const SizedBox(height: 8),
                _field(_montantPayeCtrl, 'Montant payé', required: false, keyboardType: TextInputType.number),
              ],
              const SizedBox(height: 14),
              _field(_obsCtrl, 'Observations', required: false, maxLines: 2),
              const SizedBox(height: 14),
              _field(_villeCtrl, 'Ville d\'émission', required: false),
              const SizedBox(height: 32),
              BlocBuilder<QuittanceLoyerBloc, QuittanceLoyerState>(
                builder: (context, state) {
                  final isLoading = state is QuittanceLoyerLoading;
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Créer la quittance', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {
    bool required = true, int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: _dec(label),
      onChanged: onChanged,
      validator: required ? (v) => (v == null || v.isEmpty) ? 'Ce champ est requis' : null : null,
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  );
}

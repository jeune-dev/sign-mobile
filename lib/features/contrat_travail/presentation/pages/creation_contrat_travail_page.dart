import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_application/features/client/domain/entities/client.dart';
import 'package:sign_application/features/client/presentation/bloc/client_bloc.dart';
import 'package:sign_application/features/client/presentation/bloc/client_event.dart';
import 'package:sign_application/features/client/presentation/bloc/client_state.dart';
import '../bloc/contrat_travail_bloc.dart';
import '../bloc/contrat_travail_event.dart';
import '../bloc/contrat_travail_state.dart';

class CreationContratTravailPage extends StatefulWidget {
  const CreationContratTravailPage({super.key});

  @override
  State<CreationContratTravailPage> createState() => _CreationContratTravailPageState();
}

class _CreationContratTravailPageState extends State<CreationContratTravailPage> {
  final _formKey = GlobalKey<FormState>();
  final _posteCtrl = TextEditingController();
  final _lieuCtrl = TextEditingController();
  final _jourTravailCtrl = TextEditingController();
  final _salaireCtrl = TextEditingController();
  final _nbrCongesCtrl = TextEditingController();
  final _clientSearchCtrl = TextEditingController();

  String _typeContrat = 'CDI';
  String _moyenPaiement = 'Virement bancaire';
  bool _avanceSalaire = false;
  DateTime? _dateDebut;
  DateTime? _dateFin;
  TimeOfDay? _heureDebut;
  TimeOfDay? _heureFin;
  Client? _selectedClient;

  // Format TimeOfDay → "HH:MM:SS" pour PostgreSQL TIME
  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _pickTime({
    required void Function(TimeOfDay) onPicked,
    TimeOfDay? initial,
  }) async {
    final t = await showTimePicker(
      context: context,
      initialTime: initial ?? const TimeOfDay(hour: 8, minute: 0),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (t != null) onPicked(t);
  }

  @override
  void dispose() {
    _posteCtrl.dispose(); _lieuCtrl.dispose(); _jourTravailCtrl.dispose();
    _salaireCtrl.dispose(); _nbrCongesCtrl.dispose(); _clientSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required void Function(DateTime) onPicked, DateTime? initial}) async {
    final dt = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (dt != null) onPicked(dt);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un salarié'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_dateDebut == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner la date de début'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_heureDebut == null || _heureFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner les heures de début et de fin'), backgroundColor: Colors.red),
      );
      return;
    }

    context.read<ContratTravailBloc>().add(CreerContratTravailEvent({
      'salarieId': _selectedClient!.id,
      'poste': _posteCtrl.text.trim(),
      'type_contrat': _typeContrat,
      'lieu_travail': _lieuCtrl.text.trim(),
      'jour_travail': _jourTravailCtrl.text.trim(),
      'heure_debut': _formatTime(_heureDebut!),  // ex: "08:00:00"
      'heure_fin':   _formatTime(_heureFin!),    // ex: "17:30:00"
      'date_debut': _dateDebut!.toIso8601String().substring(0, 10),
      if (_dateFin != null) 'date_fin': _dateFin!.toIso8601String().substring(0, 10),
      'salaire_mensuel': double.tryParse(_salaireCtrl.text) ?? 0,
      'moyen_paiement': _moyenPaiement,
      'nbr_jours_conges': int.tryParse(_nbrCongesCtrl.text.trim()) ?? 0,
      'avance_salaire': _avanceSalaire,
      'missions': [], // Tableau vide pour l'instant (requis par backend)
      'signature_employeur': '', // String vide (requis par backend)
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Nouveau contrat de travail', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: BlocListener<ContratTravailBloc, ContratTravailState>(
        listener: (context, state) {
          if (state is ContratTravailSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
            Navigator.pop(context);
          }
          if (state is ContratTravailError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Salarié', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
                    hintText: 'Rechercher un salarié...',
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
              const Text('Informations du poste', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              _field(_posteCtrl, 'Poste *'),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _typeContrat,
                decoration: _dec('Type de contrat *'),
                items: const [
                  DropdownMenuItem(value: 'CDI', child: Text('CDI')),
                  DropdownMenuItem(value: 'CDD', child: Text('CDD')),
                  DropdownMenuItem(value: 'Stage', child: Text('Stage')),
                  DropdownMenuItem(value: 'Freelance', child: Text('Freelance')),
                ],
                onChanged: (v) => setState(() => _typeContrat = v!),
              ),
              const SizedBox(height: 14),
              _field(_lieuCtrl, 'Lieu de travail *'),
              const SizedBox(height: 14),
              _field(_jourTravailCtrl, 'Jours de travail *'),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _timePicker(
                    label: 'Heure début *',
                    value: _heureDebut,
                    onPicked: (t) => setState(() => _heureDebut = t),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _timePicker(
                    label: 'Heure fin *',
                    value: _heureFin,
                    onPicked: (t) => setState(() => _heureFin = t),
                  )),
                ],
              ),
              const SizedBox(height: 14),
              _datePicker('Date de début *', _dateDebut, (dt) => setState(() => _dateDebut = dt)),
              const SizedBox(height: 14),
              _datePicker('Date de fin (optionnel)', _dateFin, (dt) => setState(() => _dateFin = dt), required: false),
              const SizedBox(height: 14),
              _field(_salaireCtrl, 'Salaire mensuel *', keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _moyenPaiement,
                decoration: _dec('Moyen de paiement *'),
                items: const [
                  DropdownMenuItem(value: 'Espèces', child: Text('Espèces')),
                  DropdownMenuItem(value: 'Virement bancaire', child: Text('Virement bancaire')),
                  DropdownMenuItem(value: 'Mobile Money', child: Text('Mobile Money')),
                  DropdownMenuItem(value: 'Chèque', child: Text('Chèque')),
                ],
                onChanged: (v) => setState(() => _moyenPaiement = v!),
              ),
              const SizedBox(height: 14),
              _field(_nbrCongesCtrl, 'Nombre de jours de congés', required: false, keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Avance sur salaire possible', style: TextStyle(fontWeight: FontWeight.w600)),
                value: _avanceSalaire,
                activeColor: Colors.black,
                onChanged: (v) => setState(() => _avanceSalaire = v),
              ),
              const SizedBox(height: 32),
              BlocBuilder<ContratTravailBloc, ContratTravailState>(
                builder: (context, state) {
                  final isLoading = state is ContratTravailLoading;
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
                          : const Text('Créer le contrat', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _timePicker({
    required String label,
    required TimeOfDay? value,
    required void Function(TimeOfDay) onPicked,
  }) {
    return GestureDetector(
      onTap: () => _pickTime(onPicked: onPicked, initial: value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time_rounded, size: 18,
                color: value != null ? const Color(0xFF00C896) : Colors.grey),
            const SizedBox(width: 8),
            Text(
              value != null
                  ? '${value.hour.toString().padLeft(2, '0')}h${value.minute.toString().padLeft(2, '0')}'
                  : label,
              style: TextStyle(
                  color: value != null ? Colors.black87 : Colors.grey.shade500,
                  fontWeight: value != null ? FontWeight.w600 : FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }

  Widget _datePicker(String label, DateTime? value, void Function(DateTime) onPicked, {bool required = true}) {
    return GestureDetector(
      onTap: () => _pickDate(onPicked: onPicked, initial: value),
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
              value != null ? value.toIso8601String().substring(0, 10) : label,
              style: TextStyle(color: value != null ? Colors.black : Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {
    bool required = true, int maxLines = 1, TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: _dec(label),
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

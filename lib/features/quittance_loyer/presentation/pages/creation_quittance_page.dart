import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
  final _formKey             = GlobalKey<FormState>();
  final _adresseCtrl         = TextEditingController();
  final _montantLoyerCtrl    = TextEditingController();
  final _montantChargesCtrl  = TextEditingController();
  final _montantPayeCtrl     = TextEditingController();
  final _obsCtrl             = TextEditingController();
  final _villeCtrl           = TextEditingController();
  final _anneeCtrl           = TextEditingController();
  final _clientSearchCtrl    = TextEditingController();

  String   _typeBien      = 'appartement';
  String   _mois          = 'Janvier';
  String   _modePaiement  = 'Virement bancaire';
  bool     _paiementComplet = true;
  DateTime? _datePaiement;
  Client?   _selectedClient;

  static final _dateFmtDisplay = DateFormat('dd/MM/yyyy');
  static final _montantFmt     = NumberFormat('#,###', 'fr_FR');

  static const _moisList = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
  ];

  double get _montantTotal {
    final loyer   = double.tryParse(_montantLoyerCtrl.text)   ?? 0;
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
      initialDate: _datePaiement ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.black87, onPrimary: Colors.white),
        ),
        child: child!,
      ),
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
      'locataireId':       _selectedClient!.id,
      'adresse_logement':  _adresseCtrl.text.trim(),
      'type_bien':         _typeBien,
      'mois':              _mois,
      'annee':             int.tryParse(_anneeCtrl.text) ?? DateTime.now().year,
      'montant_loyer':     double.tryParse(_montantLoyerCtrl.text)   ?? 0,
      'montant_charges':   double.tryParse(_montantChargesCtrl.text) ?? 0,
      'montant_total':     _montantTotal,
      'date_paiement':     _datePaiement!.toIso8601String().substring(0, 10),
      'mode_paiement':     _modePaiement,
      'est_total':         _paiementComplet,
      if (!_paiementComplet && _montantPayeCtrl.text.isNotEmpty)
        'montant_paye': double.tryParse(_montantPayeCtrl.text),
      if (_obsCtrl.text.trim().isNotEmpty) 'observations': _obsCtrl.text.trim(),
      if (_villeCtrl.text.trim().isNotEmpty) 'ville_emission': _villeCtrl.text.trim(),
    }));
  }

  // ── Décorations ─────────────────────────────────────────────────────────────
  InputDecoration _dec(String hint, {IconData? icon, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
      prefixIcon: icon != null ? Icon(icon, size: 18, color: const Color(0xFF6B7280)) : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8F8FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black87, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
    );
  }

  Widget _label(String text, {bool req = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(children: [
      Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
      if (req) const Text(' *', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
    ]),
  );

  Widget _sectionTitle(String title, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
      const SizedBox(width: 10),
      Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
    ]),
  );

  Widget _card({required List<Widget> children}) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nouvelle quittance',
          style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
        ),
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
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            children: [

              // ── Locataire ──────────────────────────────────────────────────
              _card(children: [
                _sectionTitle('Locataire', Icons.person_outline_rounded),
                if (_selectedClient != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1a1a1a),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                        child: Center(
                          child: Text(
                            _selectedClient!.prenom.isNotEmpty ? _selectedClient!.prenom[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            '${_selectedClient!.prenom} ${_selectedClient!.nom}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          if (_selectedClient!.email != null)
                            Text(_selectedClient!.email!, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12)),
                        ]),
                      ),
                      GestureDetector(
                        onTap: () => setState(() { _selectedClient = null; _clientSearchCtrl.clear(); }),
                        child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.close_rounded, color: Colors.white70, size: 16),
                        ),
                      ),
                    ]),
                  )
                else ...[
                  TextField(
                    controller: _clientSearchCtrl,
                    decoration: _dec('Rechercher un locataire…', icon: Icons.search_rounded),
                    onChanged: (v) {
                      if (v.length >= 2) context.read<ClientBloc>().add(RechercherClientsEvent(v));
                    },
                  ),
                  BlocBuilder<ClientBloc, ClientState>(
                    builder: (context, state) {
                      if (state is ClientsRechercheLoaded && state.clients.isNotEmpty && _clientSearchCtrl.text.isNotEmpty) {
                        return Container(
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 3))],
                          ),
                          child: Column(
                            children: state.clients.take(5).map((client) => InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () { setState(() => _selectedClient = client); _clientSearchCtrl.clear(); },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Row(children: [
                                  Container(
                                    width: 32, height: 32,
                                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(9)),
                                    child: Center(child: Text(
                                      client.prenom.isNotEmpty ? client.prenom[0].toUpperCase() : '?',
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                                    )),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('${client.prenom} ${client.nom}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                    if (client.email != null)
                                      Text(client.email!, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                                  ])),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF9CA3AF)),
                                ]),
                              ),
                            )).toList(),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ]),

              // ── Logement ────────────────────────────────────────────────────
              _card(children: [
                _sectionTitle('Logement', Icons.home_outlined),
                _label('Adresse du logement', req: true),
                TextFormField(
                  controller: _adresseCtrl,
                  decoration: _dec('Ex: 12 Rue Carnot, Dakar', icon: Icons.location_on_outlined),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Adresse requise' : null,
                ),
                const SizedBox(height: 14),
                _label('Type de bien', req: true),
                DropdownButtonFormField<String>(
                  value: _typeBien,
                  decoration: _dec('Type de bien', icon: Icons.apartment_outlined),
                  borderRadius: BorderRadius.circular(12),
                  items: const [
                    DropdownMenuItem(value: 'appartement', child: Text('Appartement')),
                    DropdownMenuItem(value: 'maison',      child: Text('Maison')),
                    DropdownMenuItem(value: 'studio',      child: Text('Studio')),
                    DropdownMenuItem(value: 'villa',       child: Text('Villa')),
                    DropdownMenuItem(value: 'bureau',      child: Text('Bureau')),
                    DropdownMenuItem(value: 'autre',       child: Text('Autre')),
                  ],
                  onChanged: (v) => setState(() => _typeBien = v!),
                ),
              ]),

              // ── Période ────────────────────────────────────────────────────
              _card(children: [
                _sectionTitle('Période', Icons.calendar_month_outlined),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label('Mois', req: true),
                    DropdownButtonFormField<String>(
                      value: _mois,
                      decoration: _dec('Mois'),
                      borderRadius: BorderRadius.circular(12),
                      items: _moisList.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (v) => setState(() => _mois = v!),
                    ),
                  ])),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label('Année', req: true),
                    TextFormField(
                      controller: _anneeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _dec('${DateTime.now().year}', icon: Icons.calendar_today_outlined),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                  ])),
                ]),
              ]),

              // ── Montants ────────────────────────────────────────────────────
              _card(children: [
                _sectionTitle('Montants', Icons.payments_outlined),
                _label('Loyer mensuel', req: true),
                TextFormField(
                  controller: _montantLoyerCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _dec('0', icon: Icons.monetization_on_outlined),
                  onChanged: (_) => setState(() {}),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Montant requis' : null,
                ),
                const SizedBox(height: 14),
                _label('Charges (optionnel)'),
                TextFormField(
                  controller: _montantChargesCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _dec('0', icon: Icons.receipt_outlined),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                // Carte total
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 18),
                        const SizedBox(width: 8),
                        Text('Montant total', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF15803D))),
                      ]),
                      Text(
                        '${_montantFmt.format(_montantTotal).replaceAll(',', ' ')} FCFA',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF15803D)),
                      ),
                    ],
                  ),
                ),
              ]),

              // ── Paiement ────────────────────────────────────────────────────
              _card(children: [
                _sectionTitle('Paiement', Icons.account_balance_wallet_outlined),
                // Date
                _label('Date de paiement', req: true),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _datePaiement != null ? const Color(0xFF111827) : const Color(0xFFE5E7EB), width: _datePaiement != null ? 1.5 : 1),
                    ),
                    child: Row(children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: _datePaiement != null ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _datePaiement != null ? _dateFmtDisplay.format(_datePaiement!) : 'Sélectionner une date',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _datePaiement != null ? FontWeight.w600 : FontWeight.w400,
                          color: _datePaiement != null ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF6B7280)),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
                _label('Mode de paiement', req: true),
                DropdownButtonFormField<String>(
                  value: _modePaiement,
                  decoration: _dec('Mode de paiement', icon: Icons.payment_outlined),
                  borderRadius: BorderRadius.circular(12),
                  items: const [
                    DropdownMenuItem(value: 'Espèces',           child: Text('Espèces')),
                    DropdownMenuItem(value: 'Virement bancaire', child: Text('Virement bancaire')),
                    DropdownMenuItem(value: 'Mobile Money',      child: Text('Mobile Money')),
                    DropdownMenuItem(value: 'Chèque',            child: Text('Chèque')),
                    DropdownMenuItem(value: 'ALL',               child: Text('Tout mode de paiement')),
                    DropdownMenuItem(value: 'Autre',             child: Text('Autre')),
                  ],
                  onChanged: (v) => setState(() => _modePaiement = v!),
                ),
                const SizedBox(height: 14),
                // Switch paiement complet
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Paiement complet', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(
                      _paiementComplet ? 'La totalité du loyer a été réglée' : 'Paiement partiel',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                    value: _paiementComplet,
                    activeColor: Colors.black87,
                    onChanged: (v) => setState(() => _paiementComplet = v),
                  ),
                ),
                if (!_paiementComplet) ...[
                  const SizedBox(height: 14),
                  _label('Montant payé'),
                  TextFormField(
                    controller: _montantPayeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _dec('Montant partiel reçu', icon: Icons.price_check_outlined),
                  ),
                ],
              ]),

              // ── Informations complémentaires ────────────────────────────────
              _card(children: [
                _sectionTitle('Informations complémentaires', Icons.edit_note_outlined),
                _label('Observations'),
                TextFormField(
                  controller: _obsCtrl,
                  maxLines: 3,
                  decoration: _dec('Remarques, commentaires…', icon: Icons.notes_rounded),
                ),
                const SizedBox(height: 14),
                _label("Ville d'émission"),
                TextFormField(
                  controller: _villeCtrl,
                  decoration: _dec('Ex: Dakar', icon: Icons.location_city_outlined),
                ),
              ]),

              // ── Bouton ──────────────────────────────────────────────────────
              BlocBuilder<QuittanceLoyerBloc, QuittanceLoyerState>(
                builder: (context, state) {
                  final isLoading = state is QuittanceLoyerLoading;
                  return SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.black38,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text('Générer la quittance', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700)),
                              const SizedBox(width: 8),
                              const Icon(Icons.receipt_long_rounded, size: 18),
                            ]),
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
}

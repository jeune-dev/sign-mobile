import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
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

  String   _typeBien      = 'Appartement';
  String   _mois          = 'Janvier';
  String   _modePaiement  = 'Virement bancaire';
  bool     _paiementComplet = true;
  bool     _taxeOrdureMenagere = false;
  DateTime? _datePaiement;
  Client?   _selectedClient;
  File?     _signatureImage;

  static final _dateFmtDisplay = DateFormat('dd/MM/yyyy');
  static final _montantFmt     = NumberFormat('#,###', 'fr_FR');

  static const _moisList = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
  ];

  static const _tauxTaxeOrdureMenagere = 0.036;

  double get _montantTaxeOrdure {
    if (!_taxeOrdureMenagere) return 0;
    final loyer = double.tryParse(_montantLoyerCtrl.text) ?? 0;
    return loyer * _tauxTaxeOrdureMenagere;
  }

  double get _montantTotal {
    final loyer   = double.tryParse(_montantLoyerCtrl.text)   ?? 0;
    final charges = double.tryParse(_montantChargesCtrl.text) ?? 0;
    return loyer + charges + _montantTaxeOrdure;
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

  Future<void> _openSignaturePad() async {
    final controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
    final double padWidth =
        (MediaQuery.of(context).size.width - 96).clamp(240.0, 420.0);
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Votre signature', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: padWidth,
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8FA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Signature(controller: controller, width: padWidth, height: 180),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Dessinez votre signature ci-dessus', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            ],
          ),
          actions: [
            TextButton(onPressed: () => controller.clear(), child: const Text('Effacer', style: TextStyle(color: Color(0xFF6B7280)))),
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler', style: TextStyle(color: Color(0xFF6B7280)))),
            ElevatedButton(
              onPressed: () async {
                if (controller.isEmpty) return;
                final data = await controller.toPngBytes();
                if (!dialogContext.mounted) return;
                if (data != null) {
                  final tempDir = await getTemporaryDirectory();
                  final file = File('${tempDir.path}/sig_quittance_${DateTime.now().millisecondsSinceEpoch}.png');
                  await file.writeAsBytes(data);
                  if (mounted) setState(() => _signatureImage = file);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Valider'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClient == null) {
      showToast(context, 'Champ requis', 'Veuillez sélectionner un locataire', ToastificationType.error);
      return;
    }
    if (_datePaiement == null) {
      showToast(context, 'Champ requis', 'Veuillez sélectionner la date de paiement', ToastificationType.error);
      return;
    }
    if (_signatureImage == null) {
      showToast(context, 'Signature requise', 'Veuillez apposer votre signature', ToastificationType.error);
      return;
    }

    final sigBase64 = 'data:image/png;base64,${base64Encode(await _signatureImage!.readAsBytes())}';
    if (!mounted) return;

    // Le backend attend { locataireId, signature_bailleur, data: {...} } (cf. creerQuittanceSchema)
    context.read<QuittanceLoyerBloc>().add(CreerQuittanceEvent({
      'locataireId': _selectedClient!.id,
      'signature_bailleur': sigBase64,
      'data': {
        'adresse_logement':  _adresseCtrl.text.trim(),
        'type_bien':         _typeBien,
        'mois':              _mois,
        'annee':             int.tryParse(_anneeCtrl.text) ?? DateTime.now().year,
        'montant_loyer':     double.tryParse(_montantLoyerCtrl.text)   ?? 0,
        'montant_charges':   double.tryParse(_montantChargesCtrl.text) ?? 0,
        'taxe_ordure_menagere': _taxeOrdureMenagere,
        'montant_taxe_ordure': _montantTaxeOrdure,
        'montant_total':     _montantTotal,
        'date_paiement':     _datePaiement!.toIso8601String().substring(0, 10),
        'mode_paiement':     _modePaiement,
        'paiement_complet':  _paiementComplet,
        if (!_paiementComplet && _montantPayeCtrl.text.isNotEmpty)
          'montant_paye': double.tryParse(_montantPayeCtrl.text),
        if (_obsCtrl.text.trim().isNotEmpty) 'observations': _obsCtrl.text.trim(),
        'ville_emission': _villeCtrl.text.trim(),
      },
    }));
  }

  // â”€â”€ Décorations â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
      if (req) const Text(' *', style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 13)),
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

  /// Sélecteur Oui/Non — deux boutons pill bien visibles pour un choix
  /// binaire explicite (ex: activer une taxe optionnelle).
  Widget _ouiNonToggle(String label, bool value, void Function(bool) onChanged) {
    Widget pill(bool v, String text) {
      final bool active = value == v;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: active ? const Color(0xFF1A1A1A) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : const Color(0xFF6B7280),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF111827))),
        ),
        const SizedBox(width: 12),
        Container(
          width: 130,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(children: [pill(true, 'Oui'), pill(false, 'Non')]),
        ),
      ],
    );
  }

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

              // â”€â”€ Locataire â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

              // â”€â”€ Logement â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                  isExpanded: true,
                  initialValue: _typeBien,
                  decoration: _dec('Type de bien', icon: Icons.apartment_outlined),
                  borderRadius: BorderRadius.circular(12),
                  items: const [
                    DropdownMenuItem(value: 'Appartement',     child: Text('Appartement')),
                    DropdownMenuItem(value: 'Maison',          child: Text('Maison')),
                    DropdownMenuItem(value: 'Studio',          child: Text('Studio')),
                    DropdownMenuItem(value: 'Chambre',         child: Text('Chambre')),
                    DropdownMenuItem(value: 'Local commercial', child: Text('Local commercial')),
                    DropdownMenuItem(value: 'Autre',           child: Text('Autre')),
                  ],
                  onChanged: (v) => setState(() => _typeBien = v!),
                ),
              ]),

              // â”€â”€ Période â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _card(children: [
                _sectionTitle('Période', Icons.calendar_month_outlined),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label('Mois', req: true),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _mois,
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

              // â”€â”€ Montants â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                _ouiNonToggle(
                  'Taxe Ordure Ménagère (3,6%)',
                  _taxeOrdureMenagere,
                  (v) => setState(() => _taxeOrdureMenagere = v),
                ),
                const SizedBox(height: 14),
                if (_taxeOrdureMenagere)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Taxe d'ordure ménagère (3,6%)",
                            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF6B7280))),
                        Text(
                          '${_montantFmt.format(_montantTaxeOrdure).replaceAll(',', ' ')} FCFA',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 12.5, color: const Color(0xFF111827)),
                        ),
                      ],
                    ),
                  ),
                // Carte total
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF1A1A1A), size: 18),
                        const SizedBox(width: 8),
                        Text('Montant total', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF111827))),
                      ]),
                      Text(
                        '${_montantFmt.format(_montantTotal).replaceAll(',', ' ')} FCFA',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF111827)),
                      ),
                    ],
                  ),
                ),
              ]),

              // â”€â”€ Paiement â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                  isExpanded: true,
                  initialValue: _modePaiement,
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
                  // Material transparent pour que le splash ne soit pas masqué par le fond du Container
                  child: Material(
                    color: Colors.transparent,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Paiement complet', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(
                        _paiementComplet ? 'La totalité du loyer a été réglée' : 'Paiement partiel',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                      value: _paiementComplet,
                      activeThumbColor: Colors.black87,
                      onChanged: (v) => setState(() => _paiementComplet = v),
                    ),
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

              // â”€â”€ Informations complémentaires â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _card(children: [
                _sectionTitle('Informations complémentaires', Icons.edit_note_outlined),
                _label('Observations'),
                TextFormField(
                  controller: _obsCtrl,
                  maxLines: 3,
                  decoration: _dec('Remarques, commentaires…', icon: Icons.notes_rounded),
                ),
                const SizedBox(height: 14),
                _label("Ville d'émission", req: true),
                TextFormField(
                  controller: _villeCtrl,
                  decoration: _dec('Ex: Dakar', icon: Icons.location_city_outlined),
                  validator: (v) => (v == null || v.trim().isEmpty) ? "Ville d'émission requise" : null,
                ),
              ]),

              // â”€â”€ Signature du bailleur â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _card(children: [
                _sectionTitle('Signature du bailleur', Icons.draw_outlined),
                _label('Votre signature', req: true),
                GestureDetector(
                  onTap: _openSignaturePad,
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _signatureImage != null ? Colors.black : const Color(0xFFE5E7EB),
                        width: _signatureImage != null ? 1.5 : 1,
                      ),
                    ),
                    child: _signatureImage != null
                        ? Padding(
                            padding: const EdgeInsets.all(8),
                            child: Image.file(_signatureImage!, fit: BoxFit.contain),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.gesture_rounded, color: Color(0xFF9CA3AF), size: 28),
                              SizedBox(height: 6),
                              Text('Touchez pour signer', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                            ],
                          ),
                  ),
                ),
                if (_signatureImage != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _openSignaturePad,
                      icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF6B7280)),
                      label: const Text('Recommencer', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                    ),
                  ),
                ],
              ]),

              // â”€â”€ Bouton â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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


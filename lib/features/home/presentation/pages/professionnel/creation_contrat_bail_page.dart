import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sign_application/core/constants/api_constants.dart';
import 'package:sign_application/features/auth/domain/entities/user.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import './client_avatar.dart';
import './dio_handler.dart';

class CreationContratPage extends StatefulWidget {
  final User? user;
  const CreationContratPage({super.key, this.user});

  @override
  State<CreationContratPage> createState() => _CreationContratPageState();
}

class _CreationContratPageState extends State<CreationContratPage> {
  final _formKey    = GlobalKey<FormState>();
  final _scrollCtrl = ScrollController();
  bool  _submitting = false;

  // ── Couleurs & style ─────────────────────────────────────
  static const _black   = Color(0xFF09090B);
  static const _white   = Color(0xFFFFFFFF);
  static const _gray50  = Color(0xFFFAFAFA);
  static const _gray100 = Color(0xFFF4F4F5);
  static const _gray200 = Color(0xFFE4E4E7);
  static const _gray400 = Color(0xFFA1A1AA);
  static const _gray600 = Color(0xFF52525B);

  // ─── Dio (même instance que ContratsPage) ────────────────
  late final Dio _dio;

  // ─── Recherche locataires ────────────────────────────────
  final TextEditingController _rechercheController = TextEditingController();
  List<dynamic> _clientsTrouves       = [];
  bool          _isRechercheLoading   = false;
  String        _rechercheErreur      = '';
  List<dynamic> _locatairesSelectionnes = [];

  // ─── Controllers — BIEN ─────────────────────────────────
  final _bienAdresseCtrl     = TextEditingController();
  final _bienVilleCtrl       = TextEditingController();
  final _bienCodePostalCtrl  = TextEditingController();
  final _bienPaysCtrl        = TextEditingController(text: 'Sénégal');
  final _bienSuperficieCtrl  = TextEditingController();
  final _bienNbPiecesCtrl    = TextEditingController();
  final _bienEtageCtrl       = TextEditingController();
  final _bienDescriptionCtrl = TextEditingController();

  String _bienType  = 'Appartement';
  String _bienUsage = 'Habitation';
  bool   _meuble    = false;
  bool   _parking   = false;
  bool   _cave      = false;
  bool   _balcon    = false;

  static const _typesBien  = ['Appartement', 'Maison', 'Studio', 'Villa', 'Bureau', 'Commerce', 'Entrepôt', 'Autre'];
  static const _usagesBien = ['Habitation', 'Habitation principale', 'Usage mixte', 'Commercial', 'Professionnel'];

  // ─── Controllers — BAIL ─────────────────────────────────
  final _bailDateDebutCtrl    = TextEditingController();
  final _bailDureeCtrl        = TextEditingController();
  final _bailDateFinCtrl      = TextEditingController();
  final _bailDureePreavisCtrl = TextEditingController();
  bool _renouvelable = true;

  // ─── Controllers — PAIEMENT ─────────────────────────────
  final _loyerCtrl          = TextEditingController();
  final _montantChargesCtrl = TextEditingController();
  final _jourPaiementCtrl   = TextEditingController(text: '5');
  final List<Map<String, TextEditingController>> _autresCharges = [];

  String _devise          = 'FCFA';
  String _periodicite     = 'Mensuel';
  String _moyen           = 'Virement bancaire';
  bool   _chargesIncluses = false;

  static const _devises      = ['FCFA', 'EUR', 'USD', 'GBP'];
  static const _periodicites = ['Mensuel', 'Trimestriel', 'Semestriel', 'Annuel'];
  static const _moyens       = ['Virement bancaire', 'Espèces', 'Mobile Money', 'Chèque', 'Autre'];

  // ─── Controllers — DÉPÔT ────────────────────────────────
  final _depotMontantCtrl = TextEditingController();
  final _depotDateCtrl    = TextEditingController();
  final _depotModeCtrl    = TextEditingController();
  bool _depotPrevu = true;

  // ─── Controllers — CLAUSES ──────────────────────────────
  bool   _sousLocation = false;
  bool   _animaux      = false;
  bool   _travaux      = false;
  final _clausesCtrl   = TextEditingController();

  // ─── Controllers — SIGNATURE ────────────────────────────
  final _sigVilleCtrl       = TextEditingController();
  final _sigDateCtrl        = TextEditingController();
  final _sigNomBailleurCtrl  = TextEditingController();
  final _sigNomLocataireCtrl = TextEditingController();

  // ────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    // ✅ Même pattern que ContratsPage : Dio avec token auto
    try {
      _dio = GetIt.instance<Dio>();
    } catch (e) {
      _dio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _rechercheController.dispose();
    _bienAdresseCtrl.dispose(); _bienVilleCtrl.dispose();
    _bienCodePostalCtrl.dispose(); _bienPaysCtrl.dispose();
    _bienSuperficieCtrl.dispose(); _bienNbPiecesCtrl.dispose();
    _bienEtageCtrl.dispose(); _bienDescriptionCtrl.dispose();
    _bailDateDebutCtrl.dispose(); _bailDureeCtrl.dispose();
    _bailDateFinCtrl.dispose(); _bailDureePreavisCtrl.dispose();
    _loyerCtrl.dispose(); _montantChargesCtrl.dispose();
    _jourPaiementCtrl.dispose();
    for (final ac in _autresCharges) {
      ac['label']!.dispose(); ac['montant']!.dispose();
    }
    _depotMontantCtrl.dispose(); _depotDateCtrl.dispose(); _depotModeCtrl.dispose();
    _clausesCtrl.dispose();
    _sigVilleCtrl.dispose(); _sigDateCtrl.dispose();
    _sigNomBailleurCtrl.dispose(); _sigNomLocataireCtrl.dispose();
    super.dispose();
  }

  // ── Date picker ──────────────────────────────────────────
  Future<void> _pickDate(TextEditingController ctrl) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: _black),
          dialogBackgroundColor: _white,
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ctrl.text =
      '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  // ── Recherche clients ────────────────────────────────────
  Future<void> _rechercherClients(String query) async {
    if (query.isEmpty) {
      setState(() { _clientsTrouves = []; _rechercheErreur = ''; });
      return;
    }
    setState(() { _isRechercheLoading = true; _rechercheErreur = ''; });
    try {
      await handleDioRequest(context, () async {
        final response = await _dio.get(
          '/professionnel/client/recherche-client',
          queryParameters: {
            'nom': query, 'prenom': query, 'email': query,
            'carte_identite_national_num': query, 'telephone': query,
          },
          options: Options(headers: {'Content-Type': 'application/json'}),
        );
        if (response.statusCode == 200) {
          setState(() {
            _clientsTrouves = response.data['utilisateurs'] ?? [];
            _isRechercheLoading = false;
          });
        } else {
          throw Exception('Erreur serveur: ${response.statusCode}');
        }
      });
    } catch (e) {
      setState(() {
        _rechercheErreur = 'Erreur: $e';
        _isRechercheLoading = false;
        _clientsTrouves = [];
      });
    }
  }

  void _ajouterLocataire(dynamic client) {
    if (!_locatairesSelectionnes.any((l) => l['id'] == client['id'])) {
      setState(() => _locatairesSelectionnes.add(client));
    }
    _rechercheController.clear();
    setState(() => _clientsTrouves = []);
  }

  void _retirerLocataire(dynamic client) {
    setState(() => _locatairesSelectionnes.removeWhere((l) => l['id'] == client['id']));
  }

  // ── Soumission ✅ via Dio (token géré automatiquement) ───
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_locatairesSelectionnes.isEmpty) {
      _showError('Veuillez sélectionner au moins un locataire');
      return;
    }

    setState(() => _submitting = true);
    try {
      final locIds = _locatairesSelectionnes.map((l) => l['id'].toString()).toList();

      final body = {
        'locatairesIds': locIds,
        'bien': {
          'adresse':         _bienAdresseCtrl.text.trim(),
          'ville':           _bienVilleCtrl.text.trim(),
          'code_postal':     _bienCodePostalCtrl.text.trim(),
          'pays':            _bienPaysCtrl.text.trim(),
          'type':            _bienType,
          'superficie':      double.tryParse(_bienSuperficieCtrl.text) ?? 0,
          'nombre_pieces':   int.tryParse(_bienNbPiecesCtrl.text) ?? 0,
          'etage':           int.tryParse(_bienEtageCtrl.text) ?? 0,
          'meuble':          _meuble,
          'parking':         _parking,
          'cave':            _cave,
          'balcon_terrasse': _balcon,
          'usage':           _bienUsage,
          'description':     _bienDescriptionCtrl.text.trim(),
        },
        'bail': {
          'date_debut':    _bailDateDebutCtrl.text,
          'duree':         _bailDureeCtrl.text.trim(),
          'date_fin':      _bailDateFinCtrl.text,
          'renouvelable':  _renouvelable,
          'duree_preavis': _bailDureePreavisCtrl.text.trim(),
        },
        'paiement': {
          'montant_loyer':    double.tryParse(_loyerCtrl.text) ?? 0,
          'devise':           _devise,
          'charges_incluses': _chargesIncluses,
          'montant_charges':  double.tryParse(_montantChargesCtrl.text) ?? 0,
          'autres_charges':   _autresCharges.map((ac) => {
            'label':   ac['label']!.text.trim(),
            'montant': double.tryParse(ac['montant']!.text) ?? 0,
          }).toList(),
          'jour_paiement': int.tryParse(_jourPaiementCtrl.text) ?? 5,
          'periodicite':   _periodicite,
          'moyen':         _moyen,
        },
        'depot_garantie': {
          'prevu':          _depotPrevu,
          'montant':        double.tryParse(_depotMontantCtrl.text) ?? 0,
          'date_versement': _depotDateCtrl.text,
          'mode_paiement':  _depotModeCtrl.text.trim(),
        },
        'clauses': {
          'sous_location':  _sousLocation,
          'animaux':        _animaux,
          'travaux':        _travaux,
          'personnalisees': _clausesCtrl.text.trim(),
        },
        'signature': {
          'ville':         _sigVilleCtrl.text.trim(),
          'date':          _sigDateCtrl.text,
          'nom_bailleur':  _sigNomBailleurCtrl.text.trim(),
          'nom_locataire': _sigNomLocataireCtrl.text.trim(),
        },
      };

      // ✅ Dio gère le token automatiquement via l'intercepteur GetIt
      await handleDioRequest(context, () async {
        final response = await _dio.post(
          '/professionnel/contratBail/creation-contrat-immobilier',
          data: body,
          options: Options(headers: {'Content-Type': 'application/json'}),
        );

        if (!mounted) return;

        if (response.statusCode == 200 || response.statusCode == 201) {
          _showSuccess();
        } else {
          final decoded = response.data;
          _showError(decoded['message'] ?? decoded['error'] ?? 'Erreur ${response.statusCode}');
        }
      });
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: Colors.black, size: 48),
            SizedBox(height: 12),
            Text('Contrat créé !', textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Text(
          'Le contrat a été créé avec succès.\nUn email a été envoyé aux parties.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF71717A)),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              minimumSize: const Size(160, 44),
            ),
            child: const Text('Retour à la liste'),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _gray50,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                children: [
                  _buildSectionLocataires(),
                  _buildSectionBien(),
                  _buildSectionBail(),
                  _buildSectionPaiement(),
                  _buildSectionDepot(),
                  _buildSectionClauses(),
                  _buildSectionSignature(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ── Top bar ──────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      color: _black,
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nouveau contrat',
                    style: TextStyle(color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                Text('Contrat de bail immobilier',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom bar ───────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: _white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _black,
            foregroundColor: _white,
            disabledBackgroundColor: _gray200,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: _submitting
              ? const SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          )
              : const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.send_rounded, size: 18),
              SizedBox(width: 8),
              Text('Créer le contrat',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGETS HELPERS
  // ═══════════════════════════════════════════════════════════

  Widget _section(String emoji, String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: const BoxDecoration(
              color: _black,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16), topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Text(title.toUpperCase(),
                    style: const TextStyle(color: _white, fontWeight: FontWeight.w800,
                        fontSize: 12, letterSpacing: 0.8)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {
    String? hint,
    TextInputType type = TextInputType.text,
    int maxLines = 1,
    bool required = false,
    bool readOnly = false,
    VoidCallback? onTap,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label, required: required),
          const SizedBox(height: 6),
          TextFormField(
            controller: ctrl,
            keyboardType: type,
            maxLines: maxLines,
            readOnly: readOnly,
            onTap: onTap,
            inputFormatters: inputFormatters,
            validator: required
                ? (v) => (v == null || v.trim().isEmpty) ? 'Ce champ est requis' : null
                : null,
            style: const TextStyle(fontSize: 14, color: _black),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: _gray400, fontSize: 13),
              filled: true,
              fillColor: _gray50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _gray200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _gray200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _black, width: 1.5)),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              suffixIcon: (readOnly && onTap != null)
                  ? const Icon(Icons.calendar_today_outlined, size: 16, color: _gray400)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown<T>(String label, T value, List<T> items, void Function(T?) onChanged, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label, required: required),
          const SizedBox(height: 6),
          DropdownButtonFormField<T>(
            value: value,
            isExpanded: true, // ✅ corrige overflow dans _row2
            onChanged: onChanged,
            style: const TextStyle(fontSize: 14, color: _black),
            decoration: InputDecoration(
              filled: true,
              fillColor: _gray50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _gray200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _gray200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _black, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e.toString()))).toList(),
          ),
        ],
      ),
    );
  }

  Widget _toggle(String label, bool value, void Function(bool) onChanged, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: value ? _black.withOpacity(0.05) : _gray50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: value ? _black.withOpacity(0.3) : _gray200),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
                      color: value ? _black : _gray600)),
                  if (subtitle != null)
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: _gray400)),
                ],
              ),
              const Spacer(),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44, height: 24,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: value ? _black : _gray200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(width: 20, height: 20,
                      decoration: const BoxDecoration(color: _white, shape: BoxShape.circle)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _gray600),
        children: required
            ? [const TextSpan(text: ' *', style: TextStyle(color: Colors.red))]
            : [],
      ),
    );
  }

  Widget _row2(Widget a, Widget b) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: 12),
        Expanded(child: b),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SECTIONS
  // ═══════════════════════════════════════════════════════════

  Widget _buildSectionLocataires() {
    return _section('👤', 'Locataires', [
      if (_locatairesSelectionnes.isNotEmpty) ...[
        const Text('Locataires sélectionnés :',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _gray600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _locatairesSelectionnes.map((client) {
            return Chip(
              avatar: buildClientAvatar(client, radius: 16),
              label: Text('${client['prenom']} ${client['nom']}'),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => _retirerLocataire(client),
              backgroundColor: _gray100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 12),
      ],
      const Text('Rechercher un locataire',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _gray600)),
      const SizedBox(height: 6),
      TextField(
        controller: _rechercheController,
        decoration: InputDecoration(
          hintText: 'Nom, prénom, email, téléphone...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _isRechercheLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : null,
          filled: true, fillColor: _gray50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _gray200)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _gray200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _black, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        onChanged: (value) => Future.delayed(const Duration(milliseconds: 500), () {
          if (value == _rechercheController.text) _rechercherClients(value);
        }),
      ),
      if (_rechercheErreur.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(_rechercheErreur, style: const TextStyle(color: Colors.red, fontSize: 12)),
        ),
      if (_clientsTrouves.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(border: Border.all(color: _gray200), borderRadius: BorderRadius.circular(10)),
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _clientsTrouves.length,
            itemBuilder: (context, index) {
              final client = _clientsTrouves[index];
              final dejaSelectionne = _locatairesSelectionnes.any((l) => l['id'] == client['id']);
              return ListTile(
                leading: buildClientAvatar(client, radius: 20),
                title: Text('${client['prenom']} ${client['nom']}'),
                subtitle: Text(client['email'] ?? ''),
                trailing: dejaSelectionne
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.add_circle_outline, color: Colors.black54),
                onTap: () { if (!dejaSelectionne) _ajouterLocataire(client); },
              );
            },
          ),
        ),
      if (_locatairesSelectionnes.isEmpty && _clientsTrouves.isEmpty && _rechercheController.text.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _gray100, borderRadius: BorderRadius.circular(10)),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: _gray400),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Commencez à taper pour rechercher des locataires. Vous pouvez en sélectionner plusieurs.',
                    style: TextStyle(fontSize: 11.5, color: _gray600, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
    ]);
  }

  Widget _buildSectionBien() {
    return _section('🏠', 'Bien loué', [
      _field('Adresse', _bienAdresseCtrl, hint: 'Avenue des Baobabs', required: true),
      _row2(
        _field('Ville', _bienVilleCtrl, hint: 'Dakar'),
        _field('Code postal', _bienCodePostalCtrl, hint: '12000', type: TextInputType.number),
      ),
      _row2(
        _field('Pays', _bienPaysCtrl, hint: 'Sénégal'),
        _dropdown('Type de bien', _bienType, _typesBien, (v) => setState(() => _bienType = v!), required: true),
      ),
      _row2(
        _field('Superficie (m²)', _bienSuperficieCtrl, hint: '120', type: TextInputType.number),
        _field('Nb. de pièces', _bienNbPiecesCtrl, hint: '4', type: TextInputType.number),
      ),
      _row2(
        _field('Étage', _bienEtageCtrl, hint: '2', type: TextInputType.number),
        _dropdown('Usage', _bienUsage, _usagesBien, (v) => setState(() => _bienUsage = v!)),
      ),
      _label('Équipements'),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _toggle('Meublé',  _meuble,  (v) => setState(() => _meuble = v))),
        const SizedBox(width: 8),
        Expanded(child: _toggle('Parking', _parking, (v) => setState(() => _parking = v))),
      ]),
      const SizedBox(height: 4),
      Row(children: [
        Expanded(child: _toggle('Cave',   _cave,   (v) => setState(() => _cave = v))),
        const SizedBox(width: 8),
        Expanded(child: _toggle('Balcon', _balcon, (v) => setState(() => _balcon = v))),
      ]),
      const SizedBox(height: 12),
      _field('Description', _bienDescriptionCtrl, hint: 'Appartement lumineux avec vue sur mer…', maxLines: 3),
    ]);
  }

  Widget _buildSectionBail() {
    return _section('📋', 'Bail', [
      _row2(
        _field('Date de début', _bailDateDebutCtrl, hint: 'AAAA-MM-JJ',
            readOnly: true, onTap: () => _pickDate(_bailDateDebutCtrl), required: true),
        _field('Date de fin', _bailDateFinCtrl, hint: 'AAAA-MM-JJ',
            readOnly: true, onTap: () => _pickDate(_bailDateFinCtrl)),
      ),
      _row2(
        _field('Durée', _bailDureeCtrl, hint: '12 mois'),
        _field('Préavis', _bailDureePreavisCtrl, hint: '3 mois'),
      ),
      _toggle('Renouvellement automatique', _renouvelable,
              (v) => setState(() => _renouvelable = v),
          subtitle: 'Le bail se reconduit automatiquement'),
    ]);
  }

  Widget _buildSectionPaiement() {
    return _section('💰', 'Paiement', [
      _row2(
        _field('Loyer mensuel', _loyerCtrl, hint: '500 000', type: TextInputType.number, required: true),
        _dropdown('Devise', _devise, _devises, (v) => setState(() => _devise = v!)),
      ),
      _toggle('Charges incluses dans le loyer', _chargesIncluses,
              (v) => setState(() => _chargesIncluses = v)),
      const SizedBox(height: 4),
      _field('Montant des charges', _montantChargesCtrl, hint: '50 000', type: TextInputType.number),
      _row2(
        _field("Jour d'exigibilité", _jourPaiementCtrl, hint: '5', type: TextInputType.number),
        _dropdown('Périodicité', _periodicite, _periodicites, (v) => setState(() => _periodicite = v!)),
      ),
      _dropdown('Mode de paiement', _moyen, _moyens, (v) => setState(() => _moyen = v!)),
      const SizedBox(height: 4),
      Row(
        children: [
          const Text('Autres charges', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _gray600)),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _autresCharges.add({
              'label':   TextEditingController(),
              'montant': TextEditingController(),
            })),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _black, borderRadius: BorderRadius.circular(8)),
              child: const Text('+ Ajouter', style: TextStyle(color: _white, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ..._autresCharges.asMap().entries.map((entry) {
        final i  = entry.key;
        final ac = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: TextFormField(
                controller: ac['label'],
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Libellé (ex: Eau)',
                  hintStyle: const TextStyle(color: _gray400, fontSize: 12),
                  filled: true, fillColor: _gray50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _gray200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _gray200)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              )),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: TextFormField(
                controller: ac['montant'],
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Montant',
                  hintStyle: const TextStyle(color: _gray400, fontSize: 12),
                  filled: true, fillColor: _gray50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _gray200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _gray200)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              )),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => setState(() {
                  ac['label']!.dispose(); ac['montant']!.dispose();
                  _autresCharges.removeAt(i);
                }),
                child: const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Icon(Icons.close, size: 18, color: _gray400),
                ),
              ),
            ],
          ),
        );
      }),
    ]);
  }

  Widget _buildSectionDepot() {
    return _section('🔒', 'Dépôt de garantie', [
      _toggle('Dépôt de garantie prévu', _depotPrevu, (v) => setState(() => _depotPrevu = v)),
      if (_depotPrevu) ...[
        const SizedBox(height: 8),
        _field('Montant du dépôt', _depotMontantCtrl, hint: '500 000', type: TextInputType.number),
        _row2(
          _field('Date de versement', _depotDateCtrl, hint: 'AAAA-MM-JJ',
              readOnly: true, onTap: () => _pickDate(_depotDateCtrl)),
          _field('Mode de paiement', _depotModeCtrl, hint: 'Espèces'),
        ),
      ],
    ]);
  }

  Widget _buildSectionClauses() {
    return _section('📜', 'Clauses', [
      _toggle('Sous-location autorisée', _sousLocation, (v) => setState(() => _sousLocation = v),
          subtitle: 'Le locataire peut sous-louer le bien'),
      const SizedBox(height: 4),
      _toggle('Animaux autorisés', _animaux, (v) => setState(() => _animaux = v),
          subtitle: 'Les animaux de compagnie sont acceptés'),
      const SizedBox(height: 4),
      _toggle('Travaux sans autorisation', _travaux, (v) => setState(() => _travaux = v),
          subtitle: 'Travaux autorisés sans accord préalable'),
      const SizedBox(height: 12),
      _field('Clauses particulières', _clausesCtrl,
          hint: 'Saisissez ici vos clauses spécifiques…', maxLines: 4),
    ]);
  }

  Widget _buildSectionSignature() {
    return _section('✍️', 'Signatures', [
      _row2(
        _field('Ville', _sigVilleCtrl, hint: 'Dakar'),
        _field('Date', _sigDateCtrl, hint: 'AAAA-MM-JJ',
            readOnly: true, onTap: () => _pickDate(_sigDateCtrl)),
      ),
      _field('Nom du bailleur', _sigNomBailleurCtrl, hint: 'Mamadou Diop'),
      _field('Nom(s) du/des locataire(s)', _sigNomLocataireCtrl,
          hint: 'Fatou Sarr, Ousmane Fall', maxLines: 2),
    ]);
  }
}
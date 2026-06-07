import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sign_application/features/auth/domain/entities/user.dart';
import 'package:sign_application/features/client/presentation/bloc/client_bloc.dart';
import 'package:sign_application/features/client/presentation/bloc/client_event.dart';
import 'package:sign_application/features/client/presentation/bloc/client_state.dart';
import 'package:sign_application/features/contrat/presentation/bloc/contrat_bloc.dart';
import 'package:sign_application/features/contrat/presentation/bloc/contrat_event.dart';
import 'package:sign_application/features/contrat/presentation/bloc/contrat_state.dart';
import 'package:sign_application/features/client/presentation/widgets/client_avatar.dart';

class CreationContratPage extends StatefulWidget {
  final User? user;
  const CreationContratPage({super.key, this.user});

  @override
  State<CreationContratPage> createState() => _CreationContratPageState();
}

class _CreationContratPageState extends State<CreationContratPage>
    with TickerProviderStateMixin {
  final _formKey    = GlobalKey<FormState>();
  final _scrollCtrl = ScrollController();
  bool  _submitting = false;
  late AnimationController _shimmerCtrl;

  // ── Palette ─────────────────────────────────────────────────
  static const _black   = Color(0xFF09090B);
  static const _white   = Color(0xFFFFFFFF);
  static const _gray50  = Color(0xFFFAFAFA);
  static const _gray100 = Color(0xFFF4F4F5);
  static const _gray200 = Color(0xFFE4E4E7);
  static const _gray400 = Color(0xFFA1A1AA);
  static const _gray600 = Color(0xFF52525B);

  // ─── Locataires ────────────────────────────────────────────
  final _rechercheCtrl              = TextEditingController();
  List<dynamic> _clientsTrouves        = [];
  bool          _isRechercheLoading    = false;
  String        _rechercheErreur       = '';
  List<dynamic> _locatairesSelectionnes = [];

  // ─── Bien ──────────────────────────────────────────────────
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
  bool _meuble = false, _parking = false, _cave = false, _balcon = false;

  static const _typesBien = [
    'Appartement', 'Maison', 'Studio', 'Chambre', 'Villa',
    'Local commercial', 'Bureau', 'Entrepôt', 'Terrain', 'Autre'
  ];
  static const _usagesBien = ['Habitation', 'Professionnel', 'Usage mixte'];

  // ─── Bail — stocke DateTime en interne ─────────────────────
  DateTime? _dateDebutValue;
  DateTime? _dateFinValue;
  final _bailDureeCtrl        = TextEditingController();
  final _bailDureePreavisCtrl = TextEditingController();
  bool  _renouvelable = true;
  String? _dateError; // erreur si début > fin

  // ─── Paiement ───────────────────────────────────────────────
  final _loyerCtrl          = TextEditingController();
  final _montantChargesCtrl = TextEditingController();
  final _jourPaiementCtrl   = TextEditingController(text: '5');
  final List<Map<String, TextEditingController>> _autresCharges = [];

  String _devise          = 'FCFA';
  String _periodicite     = 'Mensuel';
  String _moyen           = 'Virement bancaire';
  bool   _chargesIncluses = false;

  static const _devises      = ['FCFA', 'EUR', 'USD', 'GBP'];
  static const _periodicites = ['Mensuel', 'Trimestriel', 'Semestriel', 'Annuel', 'Autre'];

  // ← Enum exact du backend
  static const _moyens = [
    'Espèces',
    'Virement bancaire',
    'Mobile Money',
    'Chèque',
    'Autre',
  ];

  // ─── Dépôt de garantie ──────────────────────────────────────
  DateTime? _depotDateValue;
  final _depotMontantCtrl = TextEditingController();
  String _depotMode       = 'Virement bancaire';
  bool _depotPrevu = true;

  // ─── Clauses ────────────────────────────────────────────────
  bool _sousLocation = false, _animaux = false, _travaux = false;
  final _clausesCtrl = TextEditingController();

  // ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _shimmerCtrl.dispose();
    _rechercheCtrl.dispose();
    _bienAdresseCtrl.dispose();
    _bienVilleCtrl.dispose();
    _bienCodePostalCtrl.dispose();
    _bienPaysCtrl.dispose();
    _bienSuperficieCtrl.dispose();
    _bienNbPiecesCtrl.dispose();
    _bienEtageCtrl.dispose();
    _bienDescriptionCtrl.dispose();
    _bailDureeCtrl.dispose();
    _bailDureePreavisCtrl.dispose();
    _loyerCtrl.dispose();
    _montantChargesCtrl.dispose();
    _jourPaiementCtrl.dispose();
    for (final ac in _autresCharges) {
      ac['label']!.dispose();
      ac['montant']!.dispose();
    }
    _depotMontantCtrl.dispose();
    _clausesCtrl.dispose();
    super.dispose();
  }

  // ── Formater date en français ─────────────────────────────
  String _formatDateFr(DateTime? dt) {
    if (dt == null) return '';
    try {
      return DateFormat('dd MMMM yyyy', 'fr_FR').format(dt);
    } catch (_) {
      return DateFormat('dd/MM/yyyy').format(dt);
    }
  }

  // ── ISO pour l'API ────────────────────────────────────────
  String _toIso(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  // ── Date picker en FRANÇAIS ───────────────────────────────
  Future<DateTime?> _showDatePickerFr({
    DateTime? initial,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    return showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(2040),
      locale: const Locale('fr', 'FR'),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: _black,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: _black),
          ),
        ),
        child: child!,
      ),
    );
  }

  // ── Auto-calculer la durée du bail ────────────────────────
  void _calculerDuree() {
    if (_dateDebutValue == null || _dateFinValue == null) return;
    final months = (_dateFinValue!.year - _dateDebutValue!.year) * 12 +
        (_dateFinValue!.month - _dateDebutValue!.month);
    if (months > 0) {
      _bailDureeCtrl.text = months == 1 ? '1 mois' : '$months mois';
    } else {
      final days = _dateFinValue!.difference(_dateDebutValue!).inDays;
      _bailDureeCtrl.text = '$days jours';
    }
  }

  // ── Valider cohérence début / fin ─────────────────────────
  void _validateDates() {
    if (_dateDebutValue == null || _dateFinValue == null) return;
    if (_dateDebutValue!.isAfter(_dateFinValue!)) {
      setState(() {
        _dateError = 'La date de début doit être antérieure à la date de fin';
        _bailDureeCtrl.clear();
      });
    } else {
      setState(() => _dateError = null);
      _calculerDuree();
    }
  }

  // ── Clients ───────────────────────────────────────────────
  void _rechercherClients(String query) {
    if (query.isEmpty) {
      setState(() { _clientsTrouves = []; _rechercheErreur = ''; });
      return;
    }
    setState(() { _isRechercheLoading = true; _rechercheErreur = ''; });
    context.read<ClientBloc>().add(RechercherClientsEvent(query));
  }

  void _ajouterLocataire(dynamic c) {
    if (!_locatairesSelectionnes.any((l) => l['id'] == c['id'])) {
      setState(() => _locatairesSelectionnes.add(c));
    }
    _rechercheCtrl.clear();
    setState(() => _clientsTrouves = []);
  }

  void _retirerLocataire(dynamic c) =>
      setState(() => _locatairesSelectionnes.removeWhere((l) => l['id'] == c['id']));

  // ── Soumission ────────────────────────────────────────────
  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_locatairesSelectionnes.isEmpty) {
      _showError('Sélectionnez au moins un locataire');
      return;
    }
    if (_dateError != null) {
      _showError(_dateError!);
      return;
    }
    if (_dateDebutValue == null) {
      _showError('La date de début est requise');
      return;
    }
    setState(() => _submitting = true);

    context.read<ContratBloc>().add(CreerContratBailEvent({
      'locatairesIds':
          _locatairesSelectionnes.map((l) => l['id'].toString()).toList(),
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
        'date_debut':    _toIso(_dateDebutValue),
        'duree':         _bailDureeCtrl.text.trim(),
        'date_fin':      _toIso(_dateFinValue),
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
        'date_versement': _toIso(_depotDateValue),
        'mode_paiement':  _depotMode,
      },
      'clauses': {
        'sous_location':  _sousLocation ? 'Oui' : 'Non',
        'animaux':        _animaux ? 'Oui' : 'Non',
        'travaux':        _travaux ? 'Oui' : 'Non',
        'personnalisees': _clausesCtrl.text.trim(),
      },
    }));
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SuccessDialog(
        onRetour: () {
          Navigator.pop(context);       // ferme le dialog
          Navigator.pop(context, true); // revient à la liste des contrats
        },
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: Colors.red[400],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(12),
    ));
  }

  // ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ContratBloc, ContratState>(
          listener: (context, state) {
            if (state is ContratSuccess) {
              setState(() => _submitting = false);
              _showSuccess();
            }
            if (state is ContratError) {
              setState(() => _submitting = false);
              _showError(state.message);
            }
          },
        ),
        BlocListener<ClientBloc, ClientState>(
          listener: (context, state) {
            if (state is ClientsRechercheLoaded) {
              setState(() {
                _clientsTrouves = state.clients.map((c) => {
                  'id': c.id, 'nom': c.nom, 'prenom': c.prenom,
                  'email': c.email, 'telephone': c.telephone,
                }).toList();
                _isRechercheLoading = false;
              });
            }
            if (state is ClientError) {
              setState(() {
                _rechercheErreur = state.message;
                _isRechercheLoading = false;
                _clientsTrouves = [];
              });
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        body: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
                  children: [
                    _buildSectionLocataires(),
                    _buildSectionBien(),
                    _buildSectionBail(),
                    _buildSectionPaiement(),
                    _buildSectionDepot(),
                    _buildSectionClauses(),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TOP BAR — redesign complet
  // ═══════════════════════════════════════════════════════════
  Widget _buildTopBar() {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        color: _black,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Bouton retour
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.15)),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Contrat de bail',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            height: 1.1)),
                    const SizedBox(height: 2),
                    Text('Remplissez toutes les sections',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12)),
                  ],
                ),
              ),
              // Badge type
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6C63FF).withOpacity(0.8),
                      const Color(0xFF6C63FF).withOpacity(0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.home_work_rounded,
                        color: Colors.white, size: 14),
                    SizedBox(width: 5),
                    Text('Immobilier',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bottom bar ─────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: _white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4))
        ],
      ),
      child: SizedBox(
        width: double.infinity, height: 54,
        child: ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _black,
            foregroundColor: _white,
            disabledBackgroundColor: _gray200,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: _submitting
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('Créer le contrat de bail',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ],
                ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════

  Widget _section(IconData icon, Color iconColor, String title,
      List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: _black,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 12),
                Text(title,
                    style: const TextStyle(
                        color: _white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.3)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children),
          ),
        ],
      ),
    );
  }

  // ── Champ texte ────────────────────────────────────────────
  Widget _field(String label, TextEditingController ctrl, {
    String? hint,
    TextInputType type = TextInputType.text,
    int maxLines = 1,
    bool required = false,
    bool readOnly = false,
    bool disabled = false, // grisé pour durée auto
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
            readOnly: readOnly || disabled,
            onTap: onTap,
            inputFormatters: inputFormatters,
            validator: required
                ? (v) => (v == null || v.trim().isEmpty)
                    ? 'Ce champ est requis'
                    : null
                : null,
            style: TextStyle(
                fontSize: 14,
                color: disabled ? _gray400 : _black),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: _gray400, fontSize: 13),
              filled: true,
              fillColor: disabled ? _gray100 : _gray50,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _gray200)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _gray200)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _black, width: 1.5)),
              errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red)),
              disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _gray100)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              suffixIcon: disabled
                  ? const Icon(Icons.lock_outline_rounded,
                      size: 14, color: _gray400)
                  : (readOnly && onTap != null)
                      ? const Icon(Icons.calendar_today_outlined,
                          size: 16, color: _gray400)
                      : null,
            ),
          ),
        ],
      ),
    );
  }

  // ── Date picker field (affiche la date en français) ────────
  Widget _dateField(
    String label, {
    required DateTime? value,
    required void Function(DateTime) onPicked,
    bool required = false,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    final display = value != null ? _formatDateFr(value) : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label, required: required),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () async {
              final picked = await _showDatePickerFr(
                initial: value,
                firstDate: firstDate,
                lastDate: lastDate,
              );
              if (picked != null) onPicked(picked);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: _gray50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _gray200),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 16,
                      color: value != null ? _black : _gray400),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      display.isNotEmpty ? display : 'Sélectionner une date',
                      style: TextStyle(
                          fontSize: 14,
                          color: value != null ? _black : _gray400,
                          fontWeight: value != null
                              ? FontWeight.w600
                              : FontWeight.normal),
                    ),
                  ),
                  if (value != null)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          onPicked(value);
                        });
                      },
                      child: const Icon(Icons.check_circle_rounded,
                          size: 16, color: Colors.green),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Dropdown ───────────────────────────────────────────────
  Widget _dropdown<T>(String label, T value, List<T> items,
      void Function(T?) onChanged, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label, required: required),
          const SizedBox(height: 6),
          DropdownButtonFormField<T>(
            value: value,
            isExpanded: true,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 14, color: _black),
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: _gray400),
            decoration: InputDecoration(
              filled: true,
              fillColor: _gray50,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _gray200)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _gray200)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _black, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 13),
            ),
            items: items
                .map((e) => DropdownMenuItem(
                    value: e, child: Text(e.toString())))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Toggle switch ──────────────────────────────────────────
  Widget _toggle(String label, bool value, void Function(bool) onChanged,
      {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: value ? _black.withOpacity(0.04) : _gray50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: value ? _black.withOpacity(0.25) : _gray200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: value ? _black : _gray600)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 11, color: _gray400)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
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
                  alignment: value
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                      width: 20, height: 20,
                      decoration: const BoxDecoration(
                          color: _white, shape: BoxShape.circle)),
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
        style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: _gray600),
        children: required
            ? [const TextSpan(
                text: ' *', style: TextStyle(color: Colors.red))]
            : [],
      ),
    );
  }

  Widget _row2(Widget a, Widget b) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: a),
          const SizedBox(width: 12),
          Expanded(child: b),
        ],
      );

  // ═══════════════════════════════════════════════════════════
  // SECTIONS
  // ═══════════════════════════════════════════════════════════

  // ── 1. Locataires ─────────────────────────────────────────
  Widget _buildSectionLocataires() {
    return _section(
      Icons.person_search_rounded,
      const Color(0xFF6C63FF),
      'Sélection du locataire',
      [
        if (_locatairesSelectionnes.isNotEmpty) ...[
          const Text('Locataires sélectionnés',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _gray600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _locatairesSelectionnes
                .map((c) => Chip(
                      avatar: buildClientAvatar(c, radius: 14),
                      label: Text('${c['prenom']} ${c['nom']}',
                          style: const TextStyle(fontSize: 12)),
                      deleteIcon: const Icon(
                          Icons.close_rounded, size: 14),
                      onDeleted: () => _retirerLocataire(c),
                      backgroundColor: _gray100,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 14),
          const Divider(color: _gray100),
          const SizedBox(height: 12),
        ],
        // ── Champ recherche ──
        TextField(
          controller: _rechercheCtrl,
          decoration: InputDecoration(
            hintText: 'Rechercher par nom, email ou téléphone…',
            hintStyle: const TextStyle(color: _gray400, fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded,
                size: 20, color: _gray400),
            filled: true,
            fillColor: _gray50,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _gray200)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _gray200)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _black, width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
          onChanged: (v) => Future.delayed(
              const Duration(milliseconds: 450),
              () { if (v == _rechercheCtrl.text) _rechercherClients(v); }),
        ),

        // ── Loading animé ──
        if (_isRechercheLoading) ...[
          const SizedBox(height: 12),
          _buildSearchLoading(),
        ],

        if (_rechercheErreur.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[400], size: 16),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_rechercheErreur,
                        style: TextStyle(
                            color: Colors.red[700], fontSize: 12))),
              ],
            ),
          ),
        ],

        if (_clientsTrouves.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
                border: Border.all(color: _gray200),
                borderRadius: BorderRadius.circular(14)),
            constraints: const BoxConstraints(maxHeight: 220),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: _gray100),
                itemCount: _clientsTrouves.length,
                itemBuilder: (context, i) {
                  final c = _clientsTrouves[i];
                  final already = _locatairesSelectionnes
                      .any((l) => l['id'] == c['id']);
                  return ListTile(
                    dense: true,
                    leading: buildClientAvatar(c, radius: 18),
                    title: Text('${c['prenom']} ${c['nom']}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text(c['email'] ?? '',
                        style: const TextStyle(
                            fontSize: 11, color: _gray400)),
                    trailing: already
                        ? const Icon(Icons.check_circle_rounded,
                            color: Colors.green, size: 20)
                        : const Icon(Icons.add_circle_outline_rounded,
                            color: _black, size: 20),
                    onTap: () {
                      if (!already) _ajouterLocataire(c);
                    },
                  );
                },
              ),
            ),
          ),
        ],

        if (_locatairesSelectionnes.isEmpty &&
            _clientsTrouves.isEmpty &&
            !_isRechercheLoading &&
            _rechercheCtrl.text.isEmpty)
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF6C63FF).withOpacity(0.2))),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: Color(0xFF6C63FF)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tapez le nom ou l\'email d\'un locataire pour le rechercher.\nVous pouvez en sélectionner plusieurs.',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF3730A3),
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Loading shimmer pour la recherche ─────────────────────
  Widget _buildSearchLoading() {
    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (context, _) {
        final shimmerPos = _shimmerCtrl.value;
        return Column(
          children: List.generate(2, (i) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment(-1 + shimmerPos * 2, 0),
                end: Alignment(1 + shimmerPos * 2, 0),
                colors: const [
                  Color(0xFFF4F4F5),
                  Color(0xFFE9E9EC),
                  Color(0xFFF4F4F5),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE4E4E7),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          height: 12, width: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE4E4E7),
                            borderRadius: BorderRadius.circular(6),
                          )),
                      const SizedBox(height: 6),
                      Container(
                          height: 10, width: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE4E4E7),
                            borderRadius: BorderRadius.circular(6),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          )),
        );
      },
    );
  }

  // ── 2. Bien immobilier ─────────────────────────────────────
  Widget _buildSectionBien() {
    return _section(
      Icons.home_outlined,
      const Color(0xFF00C896),
      'Bien immobilier',
      [
        _field('Adresse', _bienAdresseCtrl,
            hint: 'Avenue des Baobabs, N°12', required: true),
        _row2(
          _field('Ville', _bienVilleCtrl, hint: 'Dakar'),
          _field('Code postal', _bienCodePostalCtrl,
              hint: '12000', type: TextInputType.number),
        ),
        _row2(
          _field('Pays', _bienPaysCtrl, hint: 'Sénégal'),
          _dropdown('Type de bien', _bienType, _typesBien,
              (v) => setState(() => _bienType = v!), required: true),
        ),
        _row2(
          _field('Superficie (m²)', _bienSuperficieCtrl,
              hint: '80', type: TextInputType.number),
          _field('Nb. de pièces', _bienNbPiecesCtrl,
              hint: '4', type: TextInputType.number),
        ),
        _row2(
          _field('Étage', _bienEtageCtrl,
              hint: '2', type: TextInputType.number),
          _dropdown('Usage', _bienUsage, _usagesBien,
              (v) => setState(() => _bienUsage = v!)),
        ),
        const SizedBox(height: 4),
        _label('Équipements inclus'),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _toggle('Meublé', _meuble,
              (v) => setState(() => _meuble = v))),
          const SizedBox(width: 8),
          Expanded(child: _toggle('Parking', _parking,
              (v) => setState(() => _parking = v))),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(child: _toggle('Cave', _cave,
              (v) => setState(() => _cave = v))),
          const SizedBox(width: 8),
          Expanded(child: _toggle('Balcon', _balcon,
              (v) => setState(() => _balcon = v))),
        ]),
        const SizedBox(height: 12),
        _field('Description', _bienDescriptionCtrl,
            hint: 'Appartement lumineux, vue sur jardin…', maxLines: 3),
      ],
    );
  }

  // ── 3. Conditions du bail ──────────────────────────────────
  Widget _buildSectionBail() {
    return _section(
      Icons.calendar_month_outlined,
      const Color(0xFFFFB347),
      'Conditions du bail',
      [
        // Date début
        _dateField(
          'Date de début *',
          value: _dateDebutValue,
          required: true,
          onPicked: (dt) {
            setState(() => _dateDebutValue = dt);
            _validateDates();
          },
        ),

        // Date fin
        _dateField(
          'Date de fin',
          value: _dateFinValue,
          firstDate: _dateDebutValue,
          onPicked: (dt) {
            setState(() => _dateFinValue = dt);
            _validateDates();
          },
        ),

        // ── Erreur si début > fin ─────────────────────────
        if (_dateError != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.red[600], size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_dateError!,
                      style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),

        // Durée (auto-calculée, grisée)
        _field('Durée calculée automatiquement', _bailDureeCtrl,
            hint: 'Calculée à partir des dates',
            disabled: true),

        _field('Durée de préavis', _bailDureePreavisCtrl,
            hint: '3 mois'),

        _toggle('Renouvellement automatique', _renouvelable,
            (v) => setState(() => _renouvelable = v),
            subtitle:
                'Le bail se reconduit tacitement à l\'expiration'),
      ],
    );
  }

  // ── 4. Paiement ────────────────────────────────────────────
  Widget _buildSectionPaiement() {
    return _section(
      Icons.payments_outlined,
      const Color(0xFF4ECDC4),
      'Conditions de paiement',
      [
        _row2(
          _field('Loyer mensuel', _loyerCtrl,
              hint: '500 000',
              type: TextInputType.number,
              required: true),
          _dropdown('Devise', _devise, _devises,
              (v) => setState(() => _devise = v!)),
        ),
        _toggle('Charges incluses dans le loyer', _chargesIncluses,
            (v) => setState(() => _chargesIncluses = v)),
        const SizedBox(height: 4),
        if (!_chargesIncluses)
          _field('Montant des charges', _montantChargesCtrl,
              hint: '50 000', type: TextInputType.number),
        _row2(
          _field("Jour d'échéance", _jourPaiementCtrl,
              hint: '5', type: TextInputType.number),
          _dropdown('Périodicité', _periodicite, _periodicites,
              (v) => setState(() => _periodicite = v!)),
        ),
        // Mode de paiement — enum exact du backend
        _dropdown('Mode de paiement', _moyen, _moyens,
            (v) => setState(() => _moyen = v!), required: true),
        const SizedBox(height: 8),
        // Autres charges
        Row(
          children: [
            const Text('Autres charges',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _gray600)),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _autresCharges.add({
                    'label':   TextEditingController(),
                    'montant': TextEditingController(),
                  })),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: _black,
                    borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Ajouter',
                        style: TextStyle(
                            color: _white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._autresCharges.asMap().entries.map((entry) {
          final i = entry.key; final ac = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: ac['label'],
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Ex: Eau',
                      hintStyle: const TextStyle(
                          color: _gray400, fontSize: 12),
                      filled: true, fillColor: _gray50,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _gray200)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _gray200)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: ac['montant'],
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Montant',
                      hintStyle: const TextStyle(
                          color: _gray400, fontSize: 12),
                      filled: true, fillColor: _gray50,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _gray200)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _gray200)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => setState(() {
                    ac['label']!.dispose();
                    ac['montant']!.dispose();
                    _autresCharges.removeAt(i);
                  }),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Icon(Icons.remove_circle_outline_rounded,
                        size: 20, color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── 5. Dépôt de garantie ───────────────────────────────────
  Widget _buildSectionDepot() {
    return _section(
      Icons.shield_outlined,
      const Color(0xFF45B7D1),
      'Dépôt de garantie',
      [
        _toggle('Dépôt de garantie prévu', _depotPrevu,
            (v) => setState(() => _depotPrevu = v),
            subtitle: 'Le locataire verse un dépôt à l\'entrée dans les lieux'),
        if (_depotPrevu) ...[
          const SizedBox(height: 10),
          _field('Montant du dépôt (FCFA)', _depotMontantCtrl,
              hint: '500 000', type: TextInputType.number),
          _row2(
            _dateField('Date de versement',
                value: _depotDateValue,
                onPicked: (dt) =>
                    setState(() => _depotDateValue = dt)),
            _dropdown('Mode de paiement', _depotMode, _moyens,
                (v) => setState(() => _depotMode = v!)),
          ),
        ],
      ],
    );
  }

  // ── 6. Clauses ─────────────────────────────────────────────
  Widget _buildSectionClauses() {
    return _section(
      Icons.rule_folder_outlined,
      const Color(0xFFFF6B6B),
      'Clauses du contrat',
      [
        _toggle('Sous-location autorisée', _sousLocation,
            (v) => setState(() => _sousLocation = v),
            subtitle:
                'Le locataire peut sous-louer tout ou partie du bien'),
        const SizedBox(height: 4),
        _toggle('Animaux de compagnie acceptés', _animaux,
            (v) => setState(() => _animaux = v),
            subtitle: 'Les animaux domestiques sont autorisés'),
        const SizedBox(height: 4),
        _toggle('Travaux sans accord préalable', _travaux,
            (v) => setState(() => _travaux = v),
            subtitle:
                'Le locataire peut effectuer des travaux mineurs sans demande'),
        const SizedBox(height: 14),
        _field('Clauses particulières', _clausesCtrl,
            hint: 'Ajoutez ici toute clause spécifique à ce contrat…',
            maxLines: 5),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog succès avec countdown 5s
// ─────────────────────────────────────────────────────────────────────────────
class _SuccessDialog extends StatefulWidget {
  final VoidCallback onRetour;
  const _SuccessDialog({required this.onRetour});

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog> {
  int _secondsLeft = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        if (mounted) widget.onRetour();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.all(28),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icône check
          Container(
            width: 72, height: 72,
            decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9), shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded,
                color: Colors.green, size: 40),
          ),
          const SizedBox(height: 20),
          const Text('Contrat créé !',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF09090B))),
          const SizedBox(height: 10),
          const Text(
            'Le contrat de bail a été créé avec succès.\nUn email a été envoyé aux parties concernées.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Color(0xFF52525B), fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 20),
          // Countdown
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_outlined, size: 14, color: Color(0xFFA1A1AA)),
              const SizedBox(width: 6),
              Text(
                'Redirection dans $_secondsLeft s…',
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFA1A1AA),
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onRetour,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF09090B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 15),
                elevation: 0,
              ),
              child: const Text('Retour à la liste',
                  style:
                      TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

// 📁 lib/features/fiche_paie/presentation/page/creation_fiche_paie.dart

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:sign_application/features/auth/domain/entities/user.dart';
import 'package:sign_application/features/fiche_paie/presentation/bloc/fiche_paie_bloc.dart';
import 'package:sign_application/features/fiche_paie/presentation/bloc/fiche_paie_event.dart';
import 'package:sign_application/features/fiche_paie/presentation/bloc/fiche_paie_state.dart';
import 'package:sign_application/features/fiche_paie/domain/entities/fiche_paie.dart';
import 'package:toastification/toastification.dart';
import 'package:sign_application/core/widgets/toastNotif.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Palette
// ─────────────────────────────────────────────────────────────────────────────
class _P {
  static const bg          = Color(0xFFF6F5F3);
  static const surface     = Color(0xFFFFFFFF);
  static const ink         = Color(0xFF1A1A18);
  static const inkLight    = Color(0xFF6B6B66);
  static const inkFaint    = Color(0xFFB0AFA8);
  static const accent      = Color(0xFF2563EB);
  static const accentSoft  = Color(0xFFEEF3FF);
  static const success     = Color(0xFF16A34A);
  static const successSoft = Color(0xFFECFDF5);
  static const danger      = Color(0xFFDC2626);
  static const divider     = Color(0xFFE8E7E3);
  static const toggleOff   = Color(0xFFE2E1DC);
  static const gold        = Color(0xFFD97706);
  static const amberBg     = Color(0xFFFEF3C7);
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget principal
// ─────────────────────────────────────────────────────────────────────────────
class FichePaieFormPage extends StatefulWidget {
  final User? user;
  const FichePaieFormPage({super.key, this.user});
  @override
  State<FichePaieFormPage> createState() => _FichePaieFormPageState();
}

class _FichePaieFormPageState extends State<FichePaieFormPage>
    with SingleTickerProviderStateMixin {

  final _formKey = GlobalKey<FormState>();
  late final Dio _dio;

  // ── Recherche employé
  final _searchCtrl  = TextEditingController();
  final _searchFocus = FocusNode();
  List<dynamic> _results   = [];
  bool          _searching = false;
  Timer?        _debounce;
  dynamic       _selected;

  // ── Identification salarié
  final _ipresCtrl    = TextEditingController();
  final _cssNumCtrl   = TextEditingController();
  final _posteCtrl    = TextEditingController();
  DateTime? _dateEmbauche;

  // ── Rémunération
  final _brutCtrl = TextEditingController();
  String _contrat = 'CDI';
  String _mois    = _moisList.first;
  int    _annee   = DateTime.now().year;
  String _calcul  = 'Mensuel';

  // ── Temps de travail
  final _joursTravCtrl  = TextEditingController();
  final _heuresTravCtrl = TextEditingController();

  // ── Absence
  bool   _absence     = false;
  final _joursAbsCtrl = TextEditingController();
  String _typeAbsence = 'Maladie';
  final _autreAbsCtrl = TextEditingController();

  // ── Heures supp
  bool   _hSupp    = false;
  final _hSuppCtrl = TextEditingController();

  // ── Primes
  bool   _primes         = false;
  final _pTransportCtrl  = TextEditingController();
  final _pLogCtrl        = TextEditingController();
  final _pPerfCtrl       = TextEditingController();
  final _pExcCtrl        = TextEditingController();
  final _pAutresCtrl     = TextEditingController();

  // ── Avantages en nature
  bool   _avantages      = false;
  String _typeAvantage   = 'Logement';
  final _autreAvantCtrl  = TextEditingController();
  final _valeurAvantCtrl = TextEditingController();

  // ── Congés
  bool   _conges           = false;
  final _joursCongesCtrl   = TextEditingController();
  final _montantCongesCtrl = TextEditingController();

  // ── Avances & retenues
  bool   _avance     = false;
  final _avanceCtrl  = TextEditingController();
  bool   _retenues   = false;
  final _retenueCtrl = TextEditingController();
  final _motifCtrl   = TextEditingController();

  // ── Cotisations
  bool   _soumisIpres   = true;
  bool   _soumisCss     = true;
  bool   _aAssurance    = false;
  final _assuranceCtrl  = TextEditingController();

  // ── Impôts
  bool   _soumisIr   = true;
  String _situation  = 'Célibataire';
  final _enfantsCtrl = TextEditingController();

  // ── Paiement
  String    _paiement    = 'Espèces';
  final    _numCtrl      = TextEditingController();
  DateTime? _datePaiement;

  // ── Animation
  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;

  static const _moisList = [
    'Janvier','Février','Mars','Avril','Mai','Juin',
    'Juillet','Août','Septembre','Octobre','Novembre','Décembre',
  ];

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    // REST-M02 : utilise uniquement le Dio sécurisé de injection_container
    _dio = GetIt.instance<Dio>();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _fadeCtrl.dispose();
    _searchFocus.dispose();
    for (final c in [
      _searchCtrl, _ipresCtrl, _cssNumCtrl, _posteCtrl,
      _brutCtrl, _joursTravCtrl, _heuresTravCtrl,
      _joursAbsCtrl, _autreAbsCtrl, _hSuppCtrl,
      _pTransportCtrl, _pLogCtrl, _pPerfCtrl, _pExcCtrl, _pAutresCtrl,
      _autreAvantCtrl, _valeurAvantCtrl,
      _joursCongesCtrl, _montantCongesCtrl,
      _avanceCtrl, _retenueCtrl, _motifCtrl,
      _assuranceCtrl, _enfantsCtrl, _numCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  // ── Recherche ─────────────────────────────────────────────────────────────
  void _onSearchChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() { _results = []; _searching = false; });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 450), () => _doSearch(q.trim()));
  }

  Future<void> _doSearch(String q) async {
    try {
      final res = await _dio.get(
        '/professionnel/client/recherche-client',
        queryParameters: {'nom': q, 'prenom': q, 'email': q, 'telephone': q},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() {
          _results = List<dynamic>.from(
            res.data['utilisateurs'] ?? res.data['employes'] ?? res.data['clients'] ?? [],
          );
          _searching = false;
        });
      } else {
        setState(() { _results = []; _searching = false; });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() { _results = []; _searching = false; });
    }
  }

  void _selectEmployee(dynamic emp) {
    HapticFeedback.selectionClick();
    setState(() {
      _selected = emp;
      _results  = [];
      _searchCtrl.clear();
      _searchFocus.unfocus();
    });
  }

  // ── Soumission ────────────────────────────────────────────────────────────
  void _submit() {
    if (_selected == null) { _showErr('Veuillez sélectionner un employé.'); return; }
    if (!_formKey.currentState!.validate()) return;

    final fiche = FichePaie(
      numeroFiche:   _numCtrl.text.trim(),
      employeurId:   widget.user?.id ?? '',
      salarieId:     _selected!['id'].toString(),
      typeContrat:   _contrat,
      mois:          _mois,
      annee:         _annee,
      salaireBrut:   double.tryParse(_brutCtrl.text) ?? 0,
      modeCalcul:    _calcul,
      nombreJoursTravailles:  int.tryParse(_joursTravCtrl.text),
      nombreHeuresTravailles: double.tryParse(_heuresTravCtrl.text),
      absence:            _absence,
      nombreJoursAbsence: _absence ? int.tryParse(_joursAbsCtrl.text) : null,
      typeAbsence:        _absence ? _typeAbsence : null,
      autreTypeAbsence:   (_absence && _typeAbsence == 'Autre') ? _autreAbsCtrl.text.trim() : null,
      aHeuresSupp:                 _hSupp,
      nombreHeuresSupplementaires: _hSupp ? (double.tryParse(_hSuppCtrl.text) ?? 0) : 0,
      aPrimes:            _primes,
      primeTransport:     _primes ? (double.tryParse(_pTransportCtrl.text) ?? 0) : 0,
      primeLogement:      _primes ? (double.tryParse(_pLogCtrl.text) ?? 0) : 0,
      primePerformance:   _primes ? (double.tryParse(_pPerfCtrl.text) ?? 0) : 0,
      primeExceptionnelle:_primes ? (double.tryParse(_pExcCtrl.text) ?? 0) : 0,
      autresPrimes:       _primes ? (double.tryParse(_pAutresCtrl.text) ?? 0) : 0,
      avantagesNature:    _avantages ? _typeAvantage : 'Aucun',
      autreAvantages:     (_avantages && _typeAvantage == 'Autres') ? _autreAvantCtrl.text.trim() : null,
      valeurAvantages:    _avantages ? (double.tryParse(_valeurAvantCtrl.text) ?? 0) : 0,
      congesPris:         _conges,
      nombreJoursConges:  _conges ? (int.tryParse(_joursCongesCtrl.text) ?? 0) : 0,
      montantConges:      _conges ? (double.tryParse(_montantCongesCtrl.text) ?? 0) : 0,
      aAvanceSalaire:       _avance,
      montantAvanceSalaire: _avance ? (double.tryParse(_avanceCtrl.text) ?? 0) : 0,
      aAutresRetenues:      _retenues,
      motifRetenue:         _retenues ? _motifCtrl.text.trim() : null,
      montantRetenue:       _retenues ? (double.tryParse(_retenueCtrl.text) ?? 0) : 0,
      soumisIpres:      _soumisIpres,
      soumisCss:        _soumisCss,
      aAssurance:       _aAssurance,
      montantAssurance: _aAssurance ? (double.tryParse(_assuranceCtrl.text) ?? 0) : 0,
      soumisIr:          _soumisIr,
      situationFamiliale: _situation,
      nombreEnfants:      int.tryParse(_enfantsCtrl.text) ?? 0,
      modePaiement: _paiement,
      datePaiement: (_datePaiement ?? DateTime.now()).toIso8601String(),
    );
    context.read<FichePaieBloc>().add(CreerFichePaieEvent(fiche));
  }

  void _showErr(String msg) => showToast(context, 'Erreur', msg, ToastificationType.error);

  // ─────────────────────────────────────────────────────────────────────────
  // UI HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _initials(dynamic emp, double r) {
    final p = (emp['prenom'] ?? '').toString();
    final n = (emp['nom']    ?? '').toString();
    final letters = '${p.isNotEmpty ? p[0] : ''}${n.isNotEmpty ? n[0] : ''}'.toUpperCase();
    final palette = [_P.accent, _P.gold, _P.success, const Color(0xFF7C3AED)];
    final col = letters.isNotEmpty ? palette[letters.codeUnitAt(0) % palette.length] : _P.accent;
    return CircleAvatar(
      radius: r,
      backgroundColor: col.withOpacity(0.12),
      child: Text(letters, style: TextStyle(fontSize: r * 0.75, fontWeight: FontWeight.w700, color: col)),
    );
  }

  Widget _card({required String icon, required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _P.divider),
        boxShadow: [BoxShadow(color: _P.ink.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: _P.accentSoft, borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(icon, style: const TextStyle(fontSize: 17))),
            ),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _P.ink, letterSpacing: -0.3)),
          ]),
        ),
        const Divider(height: 1, color: _P.divider),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ]),
    );
  }

  Widget _label(String text, {bool req = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: RichText(text: TextSpan(
      text: text,
      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _P.inkLight, letterSpacing: 0.1),
      children: req ? [const TextSpan(text: ' *', style: TextStyle(color: _P.danger))] : [],
    )),
  );

  InputDecoration _deco({String? hint, Widget? prefix, Widget? suffix}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: _P.inkFaint, fontSize: 13.5),
    prefixIcon: prefix,
    suffixIcon: suffix,
    filled: true,
    fillColor: const Color(0xFFFAFAF8),
    border:             OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _P.divider)),
    enabledBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _P.divider)),
    focusedBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _P.accent, width: 1.5)),
    errorBorder:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _P.danger)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _P.danger, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
  );

  Widget _field(String label, TextEditingController ctrl, {
    String? hint, TextInputType? type, bool req = false, int maxLines = 1,
  }) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _label(label, req: req),
    TextFormField(
      controller: ctrl,
      keyboardType: type,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: _P.ink, fontWeight: FontWeight.w500),
      decoration: _deco(hint: hint),
      validator: req ? (v) => (v == null || v.trim().isEmpty) ? 'Ce champ est requis' : null : null,
    ),
    const SizedBox(height: 14),
  ]);

  Widget _drop<T>(String label, T value, List<T> items, void Function(T?) fn, {bool req = false}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(label, req: req),
        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          onChanged: fn,
          style: const TextStyle(fontSize: 14, color: _P.ink, fontWeight: FontWeight.w500),
          decoration: _deco(),
          borderRadius: BorderRadius.circular(14),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _P.inkLight),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e.toString()))).toList(),
        ),
        const SizedBox(height: 14),
      ]);

  Widget _row2(Widget a, Widget b) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)],
  );

  // ── Toggle avec sous-champs animés via AnimatedCrossFade ─────────────────
  Widget _toggle(
      String label,
      bool val,
      void Function(bool) fn, {
        String? sub,
        List<Widget> Function()? childrenBuilder,
      }) {
    final hasChildren = childrenBuilder != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(
        onTap: () { HapticFeedback.lightImpact(); fn(!val); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: val ? _P.accentSoft : const Color(0xFFFAFAF8),
            borderRadius: BorderRadius.only(
              topLeft:     const Radius.circular(12),
              topRight:    const Radius.circular(12),
              bottomLeft:  Radius.circular(val && hasChildren ? 0 : 12),
              bottomRight: Radius.circular(val && hasChildren ? 0 : 12),
            ),
            border: Border.all(color: val ? _P.accent.withOpacity(0.35) : _P.divider),
          ),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: val ? _P.accent : _P.ink)),
              if (sub != null) ...[
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(fontSize: 11.5, color: _P.inkFaint)),
              ],
            ])),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, height: 25,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                color: val ? _P.accent : _P.toggleOff,
                borderRadius: BorderRadius.circular(13),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: val ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20, height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
      // Sous-champs
      if (hasChildren)
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState: val ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
            decoration: BoxDecoration(
              color: _P.accentSoft.withOpacity(0.45),
              borderRadius: const BorderRadius.only(
                bottomLeft:  Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border(
                left:   BorderSide(color: _P.accent.withOpacity(0.2)),
                right:  BorderSide(color: _P.accent.withOpacity(0.2)),
                bottom: BorderSide(color: _P.accent.withOpacity(0.2)),
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: childrenBuilder()),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      const SizedBox(height: 10),
    ]);
  }

  // ── Date picker ─────────────────────────────────────────────────────────
  Future<void> _pickDate(DateTime? current, void Function(DateTime) onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2099),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(colorScheme: const ColorScheme.light(primary: _P.accent)),
        child: child!,
      ),
    );
    if (picked != null) onPicked(picked);
  }

  String _fmtDate(DateTime? d) => d == null
      ? 'Sélectionner une date'
      : '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';

  Widget _datePicker(String label, DateTime? val, void Function(DateTime) fn) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _label(label),
      GestureDetector(
        onTap: () => _pickDate(val, fn),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAF8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _P.divider),
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today_rounded, size: 16, color: _P.inkLight),
            const SizedBox(width: 10),
            Text(_fmtDate(val), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: val == null ? _P.inkFaint : _P.ink)),
          ]),
        ),
      ),
      const SizedBox(height: 14),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────────
  // SECTIONS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _sectionEmploye() => _card(
    icon: '👤', title: 'Employé',
    children: [
      if (_selected != null) ...[
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_P.successSoft, _P.accentSoft.withOpacity(0.5)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _P.success.withOpacity(0.25)),
          ),
          child: Row(children: [
            _initials(_selected, 24),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${_selected!['prenom']} ${_selected!['nom']}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _P.ink)),
              if ((_selected!['email'] ?? '').toString().isNotEmpty)
                Text(_selected!['email'], style: const TextStyle(fontSize: 12, color: _P.inkLight)),
              if ((_selected!['telephone'] ?? '').toString().isNotEmpty)
                Text(_selected!['telephone'], style: const TextStyle(fontSize: 11.5, color: _P.inkFaint)),
            ])),
            GestureDetector(
              onTap: () => setState(() => _selected = null),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: _P.danger.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, size: 16, color: _P.danger),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
      ],
      _label('Rechercher un employé', req: true),
      TextField(
        controller: _searchCtrl,
        focusNode: _searchFocus,
        style: const TextStyle(fontSize: 14, color: _P.ink, fontWeight: FontWeight.w500),
        onChanged: _onSearchChanged,
        decoration: _deco(
          hint: 'Nom, prénom, email, téléphone…',
          prefix: const Icon(Icons.search_rounded, color: _P.inkLight, size: 20),
          suffix: _searching
              ? const Padding(padding: EdgeInsets.all(12),
              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _P.accent)))
              : (_searchCtrl.text.isNotEmpty
              ? GestureDetector(
            onTap: () { _searchCtrl.clear(); setState(() => _results = []); },
            child: const Icon(Icons.close_rounded, size: 18, color: _P.inkFaint),
          )
              : null),
        ),
      ),
      if (_results.isNotEmpty) ...[
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _P.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _P.divider),
            boxShadow: [BoxShadow(color: _P.ink.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 6))],
          ),
          constraints: const BoxConstraints(maxHeight: 260),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: _P.divider),
              itemBuilder: (_, i) {
                final emp = _results[i];
                final sel = _selected != null && _selected!['id'] == emp['id'];
                return Material(
                  color: sel ? _P.accentSoft : Colors.transparent,
                  child: InkWell(
                    onTap: () => _selectEmployee(emp),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(children: [
                        _initials(emp, 20),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${emp['prenom']} ${emp['nom']}',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5,
                                  color: sel ? _P.accent : _P.ink)),
                          if ((emp['email'] ?? '').toString().isNotEmpty)
                            Text(emp['email'], style: const TextStyle(fontSize: 12, color: _P.inkLight)),
                          if ((emp['telephone'] ?? '').toString().isNotEmpty)
                            Text(emp['telephone'], style: const TextStyle(fontSize: 11.5, color: _P.inkFaint)),
                        ])),
                        Icon(sel ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                            size: 22, color: sel ? _P.success : _P.inkFaint),
                      ]),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
      if (_selected == null && _results.isEmpty && _searchCtrl.text.isEmpty) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _P.bg, borderRadius: BorderRadius.circular(10)),
          child: const Row(children: [
            Icon(Icons.info_outline_rounded, size: 15, color: _P.inkFaint),
            SizedBox(width: 8),
            Expanded(child: Text(
              'Recherchez par nom, email ou téléphone puis sélectionnez l\'employé.',
              style: TextStyle(fontSize: 12, color: _P.inkLight, height: 1.5),
            )),
          ]),
        ),
      ],
    ],
  );

  Widget _sectionIdSalarie() => _card(
    icon: '🪪', title: 'Identification salarié',
    children: [
      _row2(
        _field('N° IPRES', _ipresCtrl, hint: 'IPRES-000000'),
        _field('N° CSS',   _cssNumCtrl, hint: 'CSS-000000'),
      ),
      _field('Poste occupé', _posteCtrl, hint: 'Ex: Technicien, Comptable…'),
      _datePicker('Date d\'embauche', _dateEmbauche, (d) => setState(() => _dateEmbauche = d)),
    ],
  );

  Widget _sectionRemuneration() => _card(
    icon: '💰', title: 'Rémunération',
    children: [
      _field('Salaire brut (FCFA)', _brutCtrl, hint: '500 000', type: TextInputType.number, req: true),
      _row2(
        _drop('Type de contrat', _contrat, ['CDI','CDD','Intérim','Domestique'], (v) => setState(() => _contrat = v!)),
        _drop('Mode de calcul', _calcul, ['Mensuel','Journalier','Horaire'], (v) => setState(() => _calcul = v!)),
      ),
      _row2(
        _drop('Mois', _mois, _moisList, (v) => setState(() => _mois = v!)),
        _drop('Année', _annee, List.generate(10, (i) => DateTime.now().year - 2 + i), (v) => setState(() => _annee = v!)),
      ),
    ],
  );

  Widget _sectionTempsTravail() => _card(
    icon: '⏱️', title: 'Temps de travail',
    children: [
      _row2(
        _field('Jours travaillés', _joursTravCtrl, hint: '26', type: TextInputType.number),
        _field('Heures travaillées', _heuresTravCtrl, hint: '208', type: TextInputType.number),
      ),
      _toggle(
        'Absence(s) ce mois', _absence, (v) => setState(() => _absence = v),
        sub: 'Maladie, congé non payé, absence injustifiée…',
        childrenBuilder: () => [
          _row2(
            _field('Jours d\'absence', _joursAbsCtrl, hint: '3', type: TextInputType.number),
            _drop('Type d\'absence', _typeAbsence,
                ['Maladie','Absence non justifiée','Congé','Autre'],
                    (v) => setState(() => _typeAbsence = v!)),
          ),
          if (_typeAbsence == 'Autre')
            _field('Préciser le motif', _autreAbsCtrl, hint: 'Motif…'),
        ],
      ),
    ],
  );

  Widget _sectionHeuresSupp() => _card(
    icon: '⚡', title: 'Heures supplémentaires',
    children: [
      _toggle(
        'Heures supplémentaires effectuées', _hSupp, (v) => setState(() => _hSupp = v),
        sub: 'Majoration légale de 25%',
        childrenBuilder: () => [
          _field('Nombre d\'heures supplémentaires', _hSuppCtrl, hint: '10', type: TextInputType.number),
        ],
      ),
    ],
  );

  Widget _sectionPrimes() => _card(
    icon: '🎁', title: 'Primes & Avantages',
    children: [
      _toggle(
        'Primes accordées ce mois', _primes, (v) => setState(() => _primes = v),
        childrenBuilder: () => [
          _row2(
            _field('Prime transport',    _pTransportCtrl, hint: '20 000', type: TextInputType.number),
            _field('Prime logement',     _pLogCtrl,       hint: '50 000', type: TextInputType.number),
          ),
          _row2(
            _field('Prime performance',   _pPerfCtrl, hint: '75 000',  type: TextInputType.number),
            _field('Prime exceptionnelle',_pExcCtrl,  hint: '100 000', type: TextInputType.number),
          ),
          _field('Autres primes', _pAutresCtrl, hint: '0', type: TextInputType.number),
        ],
      ),
      _toggle(
        'Avantages en nature', _avantages, (v) => setState(() => _avantages = v),
        sub: 'Logement, nourriture, transport fourni…',
        childrenBuilder: () => [
          _drop('Type d\'avantage', _typeAvantage,
              ['Logement','Nourriture','Transport','Autres'],
                  (v) => setState(() => _typeAvantage = v!)),
          if (_typeAvantage == 'Autres')
            _field('Préciser', _autreAvantCtrl, hint: 'Détail…'),
          _field('Valeur estimée (FCFA)', _valeurAvantCtrl, hint: '30 000', type: TextInputType.number),
        ],
      ),
    ],
  );

  Widget _sectionConges() => _card(
    icon: '🏖️', title: 'Congés payés',
    children: [
      _toggle(
        'Congés pris ce mois', _conges, (v) => setState(() => _conges = v),
        childrenBuilder: () => [
          _row2(
            _field('Nombre de jours',     _joursCongesCtrl,   hint: '5', type: TextInputType.number),
            _field('Montant congés (FCFA)',_montantCongesCtrl, hint: '0', type: TextInputType.number),
          ),
        ],
      ),
    ],
  );

  Widget _sectionRetenues() => _card(
    icon: '📉', title: 'Avances & Retenues',
    children: [
      _toggle(
        'Avance sur salaire', _avance, (v) => setState(() => _avance = v),
        childrenBuilder: () => [
          _field('Montant de l\'avance (FCFA)', _avanceCtrl, hint: '100 000', type: TextInputType.number),
        ],
      ),
      _toggle(
        'Autres retenues', _retenues, (v) => setState(() => _retenues = v),
        childrenBuilder: () => [
          _field('Montant retenue (FCFA)', _retenueCtrl, hint: '25 000', type: TextInputType.number),
          _field('Motif de la retenue',    _motifCtrl,   hint: 'Prêt, matériel, avarie…'),
        ],
      ),
    ],
  );

  Widget _sectionCotisations() => _card(
    icon: '🛡️', title: 'Cotisations sociales',
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(color: _P.amberBg, borderRadius: BorderRadius.circular(10)),
        child: const Row(children: [
          Icon(Icons.info_outline_rounded, size: 15, color: _P.gold),
          SizedBox(width: 8),
          Expanded(child: Text(
            'Par défaut, le salarié est soumis à l\'IPRES, la CSS et l\'IR. Décochez si non applicable.',
            style: TextStyle(fontSize: 12, color: Color(0xFF78350F), height: 1.5),
          )),
        ]),
      ),
      _toggle('Soumis à l\'IPRES', _soumisIpres, (v) => setState(() => _soumisIpres = v),
          sub: 'Institution de Prévoyance Retraite du Sénégal'),
      _toggle('Soumis à la CSS', _soumisCss, (v) => setState(() => _soumisCss = v),
          sub: 'Caisse de Sécurité Sociale'),
      _toggle(
        'Assurance complémentaire', _aAssurance, (v) => setState(() => _aAssurance = v),
        childrenBuilder: () => [
          _field('Montant assurance (FCFA)', _assuranceCtrl, hint: '5 000', type: TextInputType.number),
        ],
      ),
    ],
  );

  Widget _sectionImpots() => _card(
    icon: '📋', title: 'Impôts & Situation familiale',
    children: [
      _toggle('Soumis à l\'IR', _soumisIr, (v) => setState(() => _soumisIr = v),
          sub: 'Impôt sur le Revenu'),
      const SizedBox(height: 4),
      _drop('Situation familiale', _situation, ['Célibataire','Marié'], (v) => setState(() => _situation = v!)),
      _field('Nombre d\'enfants à charge', _enfantsCtrl, hint: '0', type: TextInputType.number),
    ],
  );

  Widget _sectionPaiement() => _card(
    icon: '💳', title: 'Paiement',
    children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label('Mode de paiement', req: true),
        DropdownButtonFormField<String>(
          value: _paiement,
          isExpanded: true,
          onChanged: (v) => setState(() => _paiement = v!),
          style: const TextStyle(fontSize: 14, color: _P.ink, fontWeight: FontWeight.w500),
          decoration: _deco(),
          borderRadius: BorderRadius.circular(14),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _P.inkLight),
          items: const [
            DropdownMenuItem(value: 'Espèces', child: Text('Espèces')),
            DropdownMenuItem(value: 'Virement bancaire', child: Text('Virement bancaire')),
            DropdownMenuItem(value: 'Wave / Orange Money', child: Text('Wave / Orange Money')),
            DropdownMenuItem(value: 'ALL', child: Text('Tout mode de paiement')),
          ],
        ),
        const SizedBox(height: 14),
      ]),
      _datePicker('Date de paiement', _datePaiement, (d) => setState(() => _datePaiement = d)),
      _field('Numéro de fiche', _numCtrl, hint: 'FP-2025-001', req: true),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.bg,
      appBar: _appBar(),
      body: BlocListener<FichePaieBloc, FichePaieState>(
        listener: (ctx, state) {
          if (state is FichePaieSuccess) {
            showToast(ctx, 'Fiche créée', 'La fiche de paie a été créée avec succès.', ToastificationType.success);
            Navigator.pop(ctx);
          }
          if (state is FichePaieError) _showErr(state.message);
        },
        child: FadeTransition(
          opacity: _fadeAnim,
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                children: [
                  _sectionEmploye(),
                  _sectionIdSalarie(),
                  _sectionRemuneration(),
                  _sectionTempsTravail(),
                  _sectionHeuresSupp(),
                  _sectionPrimes(),
                  _sectionConges(),
                  _sectionRetenues(),
                  _sectionCotisations(),
                  _sectionImpots(),
                  _sectionPaiement(),
                  const SizedBox(height: 8),
                  _submitBtn(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
    backgroundColor: _P.surface,
    elevation: 0,
    scrolledUnderElevation: 1,
    shadowColor: _P.divider,
    foregroundColor: _P.ink,
    titleSpacing: 0,
    leading: GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _P.bg, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _P.divider),
        ),
        child: const Icon(Icons.arrow_back_rounded, size: 20),
      ),
    ),
    title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Nouvelle fiche de paie',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _P.ink, letterSpacing: -0.3)),
      Text('$_mois $_annee',
          style: const TextStyle(fontSize: 12, color: _P.inkLight, fontWeight: FontWeight.w500)),
    ]),
    actions: [
      Container(
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: _P.accentSoft, borderRadius: BorderRadius.circular(8)),
        child: const Text('Brouillon', style: TextStyle(fontSize: 12, color: _P.accent, fontWeight: FontWeight.w600)),
      ),
    ],
  );

  Widget _submitBtn() => BlocBuilder<FichePaieBloc, FichePaieState>(
    builder: (ctx, state) {
      final loading = state is FichePaieLoading;
      return SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: loading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _P.accent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _P.divider,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          child: loading
              ? const SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.save_rounded, size: 20),
            SizedBox(width: 8),
            Text('Enregistrer la fiche',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.2)),
          ]),
        ),
      );
    },
  );
}
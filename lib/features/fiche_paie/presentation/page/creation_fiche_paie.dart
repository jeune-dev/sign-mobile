// 📁 lib/features/fiche_paie/presentation/page/creation_fiche_paie.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sign_application/features/auth/domain/entities/user.dart';
import 'package:sign_application/features/client/domain/entities/client.dart';
import 'package:sign_application/features/client/presentation/bloc/client_bloc.dart';
import 'package:sign_application/features/client/presentation/bloc/client_event.dart';
import 'package:sign_application/features/client/presentation/bloc/client_state.dart';
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
  static const bg          = Color(0xFFF2F2F7);
  static const surface     = Color(0xFFFFFFFF);
  static const ink         = Color(0xFF111827);
  static const inkLight    = Color(0xFF6B7280);
  static const inkFaint    = Color(0xFF9CA3AF);
  static const accent      = Color(0xFF000000);
  static const accentSoft  = Color(0xFFF3F4F6);
  static const success     = Color(0xFF111827);
  static const danger      = Color(0xFF6B7280);
  static const divider     = Color(0xFFE5E7EB);
  static const toggleOff   = Color(0xFFE5E7EB);
  static const gold        = Color(0xFF6B7280);
  static const amberBg     = Color(0xFFF3F4F6);
  static const field       = Color(0xFFF8F8FA);
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget principal
// ─────────────────────────────────────────────────────────────────────────────
class FichePaieFormPage extends StatelessWidget {
  final User? user;
  const FichePaieFormPage({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<FichePaieBloc>(),
      child: _FichePaieFormView(user: user),
    );
  }
}

class _FichePaieFormView extends StatefulWidget {
  final User? user;
  const _FichePaieFormView({this.user});
  @override
  State<_FichePaieFormView> createState() => _FichePaieFormPageState();
}

class _FichePaieFormPageState extends State<_FichePaieFormView>
    with SingleTickerProviderStateMixin {

  final _formKey = GlobalKey<FormState>();

  // ── Recherche employé (basée sur la base clients via ClientBloc)
  final _searchCtrl = TextEditingController();
  Client? _selected;

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
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
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

  // ── Recherche (base clients, via ClientBloc) ───────────────────────────────
  void _onSearchChanged(String q) {
    if (q.trim().length >= 2) {
      context.read<ClientBloc>().add(RechercherClientsEvent(q.trim()));
    }
  }

  void _selectEmployee(Client emp) {
    HapticFeedback.selectionClick();
    setState(() {
      _selected = emp;
      _searchCtrl.clear();
    });
    FocusScope.of(context).unfocus();
  }

  // ── Soumission ────────────────────────────────────────────────────────────
  void _submit() {
    if (_selected == null) { _showErr('Veuillez sélectionner un employé.'); return; }
    if (!_formKey.currentState!.validate()) return;

    final fiche = FichePaie(
      numeroFiche:   _numCtrl.text.trim(),
      employeurId:   widget.user?.id ?? '',
      salarieId:     _selected!.id,
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

  Widget _initials(Client emp, double r) {
    final p = emp.prenom;
    final n = emp.nom;
    final letters = '${p.isNotEmpty ? p[0] : ''}${n.isNotEmpty ? n[0] : ''}'.toUpperCase();
    final palette = [_P.accent, _P.gold, _P.success, const Color(0xFF1A1A1A)];
    final col = letters.isNotEmpty ? palette[letters.codeUnitAt(0) % palette.length] : _P.accent;
    return CircleAvatar(
      radius: r,
      backgroundColor: col.withValues(alpha: 0.12),
      child: Text(letters, style: TextStyle(fontSize: r * 0.75, fontWeight: FontWeight.w700, color: col)),
    );
  }

  // Carte identique à la page « Nouvelle quittance » : carte blanche + titre de
  // section avec carré noir (icône blanche), sans séparateur.
  Widget _card({required IconData icon, required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
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
        ),
        ...children,
      ]),
    );
  }

  Widget _label(String text, {bool req = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: RichText(text: TextSpan(
      text: text,
      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
      children: req ? [const TextSpan(text: ' *', style: TextStyle(color: Color(0xFF1A1A1A)))] : [],
    )),
  );

  InputDecoration _deco({String? hint, Widget? prefix, Widget? suffix}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: _P.inkFaint, fontSize: 13.5),
    prefixIcon: prefix,
    suffixIcon: suffix,
    filled: true,
    fillColor: _P.field,
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
          initialValue: value,
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
            color: val ? _P.accentSoft : _P.field,
            borderRadius: BorderRadius.only(
              topLeft:     const Radius.circular(12),
              topRight:    const Radius.circular(12),
              bottomLeft:  Radius.circular(val && hasChildren ? 0 : 12),
              bottomRight: Radius.circular(val && hasChildren ? 0 : 12),
            ),
            border: Border.all(color: val ? _P.accent.withValues(alpha: 0.35) : _P.divider),
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
              color: _P.accentSoft.withValues(alpha: 0.45),
              borderRadius: const BorderRadius.only(
                bottomLeft:  Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border(
                left:   BorderSide(color: _P.accent.withValues(alpha: 0.2)),
                right:  BorderSide(color: _P.accent.withValues(alpha: 0.2)),
                bottom: BorderSide(color: _P.accent.withValues(alpha: 0.2)),
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
            color: _P.field,
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
    icon: Icons.person_outline, title: 'Employé',
    children: [
      // Un employé sélectionné => on masque la recherche (une fiche = un seul employé).
      if (_selected != null)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _P.accentSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _P.divider),
          ),
          child: Row(children: [
            _initials(_selected!, 24),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${_selected!.prenom} ${_selected!.nom}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _P.ink)),
              if ((_selected!.email ?? '').isNotEmpty)
                Text(_selected!.email!, style: const TextStyle(fontSize: 12, color: _P.inkLight)),
              if ((_selected!.telephone ?? '').isNotEmpty)
                Text(_selected!.telephone!, style: const TextStyle(fontSize: 11.5, color: _P.inkFaint)),
            ])),
            GestureDetector(
              onTap: () => setState(() => _selected = null),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: _P.danger.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, size: 16, color: _P.danger),
              ),
            ),
          ]),
        )
      else ...[
        _label('Rechercher un employé', req: true),
        TextField(
          controller: _searchCtrl,
          style: const TextStyle(fontSize: 14, color: _P.ink, fontWeight: FontWeight.w500),
          onChanged: (v) { setState(() {}); _onSearchChanged(v); },
          decoration: _deco(
            hint: 'Nom, prénom, email, téléphone…',
            prefix: const Icon(Icons.search_rounded, color: _P.inkLight, size: 20),
            suffix: _searchCtrl.text.isNotEmpty
                ? GestureDetector(
                    onTap: () => setState(() => _searchCtrl.clear()),
                    child: const Icon(Icons.close_rounded, size: 18, color: _P.inkFaint),
                  )
                : null,
          ),
        ),
        // Résultats issus de la base clients (ClientBloc)
        BlocBuilder<ClientBloc, ClientState>(
          builder: (ctx, state) {
            if (_searchCtrl.text.trim().length < 2) return const SizedBox.shrink();
            if (state is ClientLoading) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _P.accent))),
              );
            }
            if (state is ClientsRechercheLoaded) {
              if (state.clients.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text('Aucun client trouvé.', style: TextStyle(fontSize: 12.5, color: _P.inkFaint)),
                );
              }
              return Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: _P.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _P.divider),
                  boxShadow: [BoxShadow(color: _P.ink.withValues(alpha: 0.07), blurRadius: 20, offset: const Offset(0, 6))],
                ),
                constraints: const BoxConstraints(maxHeight: 260),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: state.clients.take(6).length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: _P.divider),
                    itemBuilder: (_, i) {
                      final emp = state.clients[i];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _selectEmployee(emp),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(children: [
                              _initials(emp, 20),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('${emp.prenom} ${emp.nom}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: _P.ink)),
                                if ((emp.email ?? '').isNotEmpty)
                                  Text(emp.email!, style: const TextStyle(fontSize: 12, color: _P.inkLight)),
                                if ((emp.telephone ?? '').isNotEmpty)
                                  Text(emp.telephone!, style: const TextStyle(fontSize: 11.5, color: _P.inkFaint)),
                              ])),
                              const Icon(Icons.add_circle_outline_rounded, size: 22, color: _P.inkFaint),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        if (_searchCtrl.text.isEmpty) ...[
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
    ],
  );

  Widget _sectionIdSalarie() => _card(
    icon: Icons.badge_outlined, title: 'Identification salarié',
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
    icon: Icons.payments_outlined, title: 'Rémunération',
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
    icon: Icons.schedule_outlined, title: 'Temps de travail',
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
    icon: Icons.bolt_outlined, title: 'Heures supplémentaires',
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
    icon: Icons.card_giftcard_outlined, title: 'Primes & Avantages',
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
    icon: Icons.beach_access_outlined, title: 'Congés payés',
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
    icon: Icons.remove_circle_outline, title: 'Avances & Retenues',
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
    icon: Icons.shield_outlined, title: 'Cotisations sociales',
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
            style: TextStyle(fontSize: 12, color: Color(0xFF374151), height: 1.5),
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
    icon: Icons.assignment_outlined, title: 'Impôts & Situation familiale',
    children: [
      _toggle('Soumis à l\'IR', _soumisIr, (v) => setState(() => _soumisIr = v),
          sub: 'Impôt sur le Revenu'),
      const SizedBox(height: 4),
      _drop('Situation familiale', _situation, ['Célibataire','Marié'], (v) => setState(() => _situation = v!)),
      _field('Nombre d\'enfants à charge', _enfantsCtrl, hint: '0', type: TextInputType.number),
    ],
  );

  Widget _sectionPaiement() => _card(
    icon: Icons.credit_card_outlined, title: 'Paiement',
    children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label('Mode de paiement', req: true),
        DropdownButtonFormField<String>(
          initialValue: _paiement,
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
    backgroundColor: const Color(0xFF1A1A1A),
    elevation: 0,
    scrolledUnderElevation: 0,
    foregroundColor: Colors.white,
    centerTitle: true,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
      onPressed: () => Navigator.pop(context),
    ),
    title: const Text('Nouvelle fiche de paie',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3)),
  );

  Widget _submitBtn() => BlocBuilder<FichePaieBloc, FichePaieState>(
    builder: (ctx, state) {
      final loading = state is FichePaieLoading;
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: loading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.black38,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          child: loading
              ? const SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Enregistrer la fiche',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(width: 8),
            const Icon(Icons.save_rounded, size: 18),
          ]),
        ),
      );
    },
  );
}

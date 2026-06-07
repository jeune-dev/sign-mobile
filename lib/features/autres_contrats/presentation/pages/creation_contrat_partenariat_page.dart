import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_application/features/client/domain/entities/client.dart';
import '../bloc/autres_contrats_bloc.dart';
import '../bloc/autres_contrats_event.dart';
import '../bloc/autres_contrats_state.dart';
import '../widgets/client_search_field.dart';
import '../widgets/contrat_form_widgets.dart';

class CreationContratPartenariatPage extends StatefulWidget {
  const CreationContratPartenariatPage({super.key});

  @override
  State<CreationContratPartenariatPage> createState() => _State();
}

class _State extends State<CreationContratPartenariatPage> {
  int _step = 0;
  static const int _totalSteps = 3;
  static const _steps = ['Partenaire', 'Accord', 'Revenus'];

  static const _accent = Color(0xFF7C3AED);
  static const _icon   = Icons.people_alt_outlined;
  static const _titre  = 'Contrat de partenariat';

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  Client? _client;

  final _objetCtrl   = TextEditingController();
  final _dureeCtrl   = TextEditingController();
  final _resp1Ctrl   = TextEditingController();
  final _resp2Ctrl   = TextEditingController();
  final _contrib1Ctrl = TextEditingController();
  final _contrib2Ctrl = TextEditingController();
  final _pct1Ctrl    = TextEditingController();
  final _pct2Ctrl    = TextEditingController();
  final _villeCtrl   = TextEditingController();

  bool _partageRevenus = false;

  @override
  void dispose() {
    _objetCtrl.dispose(); _dureeCtrl.dispose(); _resp1Ctrl.dispose();
    _resp2Ctrl.dispose(); _contrib1Ctrl.dispose(); _contrib2Ctrl.dispose();
    _pct1Ctrl.dispose(); _pct2Ctrl.dispose(); _villeCtrl.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_step == 0) {
      if (_client == null) { _showError('Veuillez sélectionner un partenaire'); return; }
      setState(() => _step = 1);
    } else if (_step == 1) {
      if (!(_formKey1.currentState?.validate() ?? false)) return;
      setState(() => _step = 2);
    } else {
      _submit();
    }
  }

  void _onBack() => setState(() => _step--);

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: Colors.red[600], behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
  );

  void _submit() {
    context.read<AutresContratsBloc>().add(CreerContrat('contrat-partenariat', {
      'autrePartieId': _client!.id,
      'data': {
        'objet_partenariat':       _objetCtrl.text.trim(),
        'duree':                   _dureeCtrl.text.trim(),
        'responsabilites_partie1': _resp1Ctrl.text.trim(),
        'responsabilites_partie2': _resp2Ctrl.text.trim(),
        'contribution_partie1':    _contrib1Ctrl.text.trim(),
        'contribution_partie2':    _contrib2Ctrl.text.trim(),
        'partage_revenus':         _partageRevenus,
        if (_partageRevenus && _pct1Ctrl.text.isNotEmpty) 'pourcentage_partie1': double.tryParse(_pct1Ctrl.text),
        if (_partageRevenus && _pct2Ctrl.text.isNotEmpty) 'pourcentage_partie2': double.tryParse(_pct2Ctrl.text),
        if (_villeCtrl.text.trim().isNotEmpty) 'ville_signature': _villeCtrl.text.trim(),
      },
      'signature_generateur': '',
    }));
  }

  String get _stepSubtitle {
    switch (_step) {
      case 0: return 'Identifiez le partenaire commercial';
      case 1: return 'Définissez les termes du partenariat';
      default: return 'Partage des revenus et finalisation';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: BlocListener<AutresContratsBloc, AutresContratsState>(
        listener: (ctx, state) {
          if (state is AutresContratsSuccess) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.green[600], behavior: SnackBarBehavior.floating));
            Navigator.pop(ctx);
          }
          if (state is AutresContratsError) _showError(state.message);
        },
        child: Column(
          children: [
            CFormHeader(
              titre: _titre, stepTitle: _steps[_step], stepSubtitle: _stepSubtitle,
              icon: _icon, accentColor: _accent, currentStep: _step,
              totalSteps: _totalSteps, stepLabels: _steps,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, anim) => SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero)
                      .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: KeyedSubtree(key: ValueKey(_step), child: _buildStep()),
              ),
            ),
            BlocBuilder<AutresContratsBloc, AutresContratsState>(
              builder: (ctx, state) => CBottomBar(
                step: _step, totalSteps: _totalSteps,
                onBack: _onBack, onNext: _onNext, accentColor: _accent,
                isLoading: state is AutresContratsLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _step0();
      case 1: return _step1();
      default: return _step2();
    }
  }

  Widget _step0() => ListView(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
    children: [
      CInfoBanner(
        title: 'Contrat de partenariat',
        description: 'Définissez les droits, responsabilités et contributions de chaque partenaire dans un cadre légal solide.',
        icon: _icon, accentColor: _accent,
      ),
      kGapLg,
      CSection(
        title: 'Partenaire',
        icon: Icons.person_search_outlined,
        accentColor: _accent,
        subtitle: 'La seconde partie de ce partenariat',
        children: [
          if (_client != null)
            CClientDisplay(client: _client!, accentColor: _accent, role: 'Partenaire (partie 2)', onClear: () => setState(() => _client = null))
          else
            ClientSearchField(label: 'Rechercher un partenaire', onClientSelected: (c) => setState(() => _client = c)),
        ],
      ),
    ],
  );

  Widget _step1() => Form(
    key: _formKey1,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      children: [
        CSection(
          title: 'Objet & Durée',
          icon: Icons.handshake_outlined,
          accentColor: _accent,
          children: [
            CField(controller: _objetCtrl, label: 'Objet du partenariat', accentColor: _accent, maxLines: 3, hint: 'Décrivez la nature et les objectifs du partenariat…'),
            kGap,
            CField(controller: _dureeCtrl, label: 'Durée', accentColor: _accent, icon: Icons.timer_outlined, hint: 'Ex: 1 an, 24 mois…'),
          ],
        ),
        kGapLg,
        CSection(
          title: 'Responsabilités',
          icon: Icons.balance_outlined,
          accentColor: _accent,
          subtitle: 'Ce que chaque partie s\'engage à faire',
          children: [
            _partyLabel('Partie 1 — Vous'),
            kGapSm,
            CField(controller: _resp1Ctrl, label: 'Responsabilités', accentColor: _accent, maxLines: 2, hint: 'Ce que vous apportez et gérez…'),
            kGap,
            CField(controller: _contrib1Ctrl, label: 'Contribution', accentColor: _accent, hint: 'Ressources, moyens, compétences…'),
            kGapLg,
            _partyLabel('Partie 2 — Partenaire'),
            kGapSm,
            CField(controller: _resp2Ctrl, label: 'Responsabilités', accentColor: _accent, maxLines: 2, hint: 'Ce que le partenaire apporte et gère…'),
            kGap,
            CField(controller: _contrib2Ctrl, label: 'Contribution', accentColor: _accent, hint: 'Ressources, moyens, compétences…'),
          ],
        ),
      ],
    ),
  );

  Widget _step2() => Form(
    key: _formKey2,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      children: [
        CSection(
          title: 'Partage des revenus',
          icon: Icons.pie_chart_outline_rounded,
          accentColor: _accent,
          subtitle: 'Optionnel — définissez la répartition des bénéfices',
          children: [
            CToggle(
              title: 'Partage des revenus',
              subtitle: 'Activez pour définir les pourcentages',
              value: _partageRevenus,
              accentColor: _accent,
              onChanged: (v) => setState(() => _partageRevenus = v),
            ),
            if (_partageRevenus) ...[
              kGap,
              Row(children: [
                Expanded(child: CField(controller: _pct1Ctrl, label: '% Partie 1', accentColor: _accent,
                    icon: Icons.percent_rounded, keyboardType: TextInputType.number, required: false, hint: '50')),
                const SizedBox(width: 12),
                Expanded(child: CField(controller: _pct2Ctrl, label: '% Partie 2', accentColor: _accent,
                    icon: Icons.percent_rounded, keyboardType: TextInputType.number, required: false, hint: '50')),
              ]),
            ],
          ],
        ),
        kGapLg,
        CSection(
          title: 'Récapitulatif',
          icon: Icons.summarize_outlined,
          accentColor: _accent,
          children: [
            if (_client != null) CSummaryRow(label: 'Partenaire', value: '${_client!.prenom} ${_client!.nom}', icon: Icons.person_outline, accentColor: _accent),
            CSummaryRow(label: 'Objet', value: _objetCtrl.text.isNotEmpty ? _objetCtrl.text : '—', icon: Icons.handshake_outlined, accentColor: _accent),
            CSummaryRow(label: 'Durée', value: _dureeCtrl.text.isNotEmpty ? _dureeCtrl.text : '—', icon: Icons.timer_outlined, accentColor: _accent),
            CSummaryRow(label: 'Partage revenus', value: _partageRevenus ? 'Oui' : 'Non', icon: Icons.pie_chart_outline_rounded, accentColor: _accent),
          ],
        ),
        kGapLg,
        CSection(
          title: 'Lieu de signature',
          icon: Icons.place_outlined,
          accentColor: _accent,
          children: [
            CField(controller: _villeCtrl, label: 'Ville de signature', accentColor: _accent, required: false, icon: Icons.location_city_outlined, hint: 'Ex: Dakar, Abidjan…'),
          ],
        ),
      ],
    ),
  );

  Widget _partyLabel(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: _accent.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _accent)),
  );
}

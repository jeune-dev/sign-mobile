import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_application/features/client/domain/entities/client.dart';
import '../bloc/autres_contrats_bloc.dart';
import '../bloc/autres_contrats_event.dart';
import '../bloc/autres_contrats_state.dart';
import '../widgets/client_search_field.dart';
import '../widgets/contrat_form_widgets.dart';

class CreationContratConfidentialitePage extends StatefulWidget {
  const CreationContratConfidentialitePage({super.key});

  @override
  State<CreationContratConfidentialitePage> createState() => _State();
}

class _State extends State<CreationContratConfidentialitePage> {
  int _step = 0;
  static const int _totalSteps = 3;
  static const _steps = ['Partie', 'Confidentialité', 'Détails'];

  static const _accent = Color(0xFF1D4ED8);
  static const _icon   = Icons.lock_outline;
  static const _titre  = 'Accord de confidentialité';

  final _formKey1 = GlobalKey<FormState>();

  Client? _client;

  final _typeInfoCtrl  = TextEditingController();
  final _dureeCtrl     = TextEditingController();
  final _sanctionsCtrl = TextEditingController();
  final _documentsCtrl = TextEditingController();
  final _personnesCtrl = TextEditingController();
  final _villeCtrl     = TextEditingController();

  String _niveauConf = 'moyen';

  @override
  void dispose() {
    _typeInfoCtrl.dispose(); _dureeCtrl.dispose(); _sanctionsCtrl.dispose();
    _documentsCtrl.dispose(); _personnesCtrl.dispose(); _villeCtrl.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_step == 0) {
      if (_client == null) { _showError('Veuillez sélectionner l\'autre partie'); return; }
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
    context.read<AutresContratsBloc>().add(CreerContrat('contrat-confidentialite', {
      'autrePartieId': _client!.id,
      'data': {
        'type_informations':        _typeInfoCtrl.text.trim(),
        'niveau_confidentialite':   _niveauConf,
        'duree_confidentialite':    _dureeCtrl.text.trim(),
        'sanctions_violation':      _sanctionsCtrl.text.trim(),
        if (_documentsCtrl.text.trim().isNotEmpty) 'documents_concernes': _documentsCtrl.text.trim(),
        if (_personnesCtrl.text.trim().isNotEmpty) 'personnes_autorisees': _personnesCtrl.text.trim(),
        if (_villeCtrl.text.trim().isNotEmpty) 'ville_signature': _villeCtrl.text.trim(),
      },
      'signature_generateur': '',
    }));
  }

  String get _stepSubtitle {
    switch (_step) {
      case 0: return 'La partie qui doit respecter la confidentialité';
      case 1: return 'Nature et niveau de confidentialité';
      default: return 'Documents, personnes autorisées et finalisation';
    }
  }

  // Couleur selon niveau
  Color get _niveauColor {
    switch (_niveauConf) {
      case 'faible': return Colors.green;
      case 'élevé':  return Colors.red;
      default:       return Colors.orange;
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
                submitLabel: 'Créer le contrat de confidentialité',
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
        title: 'Contrat de Confidentialité',
        description: 'Protégez vos informations sensibles, secrets commerciaux et données confidentielles partagés avec un tiers.',
        icon: _icon, accentColor: _accent,
      ),
      kGapLg,
      // NDA scope explanation
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _accent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(kCardRadius),
          border: Border.all(color: _accent.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.lightbulb_outline, size: 16, color: _accent),
              const SizedBox(width: 8),
              Text('Protège notamment :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _accent)),
            ]),
            const SizedBox(height: 8),
            ...[
              'Secrets commerciaux & know-how',
              'Données clients et financières',
              'Stratégies et plans de développement',
              'Codes sources et algorithmes',
            ].map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                Icon(Icons.check_circle_outline, size: 13, color: _accent.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Text(e, style: const TextStyle(fontSize: 11, color: kLabelColor)),
              ]),
            )),
          ],
        ),
      ),
      kGapLg,
      CSection(
        title: 'Autre partie',
        icon: Icons.person_search_outlined,
        accentColor: _accent,
        subtitle: 'La personne qui s\'engage à la confidentialité',
        children: [
          if (_client != null)
            CClientDisplay(client: _client!, accentColor: _accent, role: 'Autre partie (récipiendaire)', onClear: () => setState(() => _client = null))
          else
            ClientSearchField(label: 'Rechercher un client', onClientSelected: (c) => setState(() => _client = c)),
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
          title: 'Informations protégées',
          icon: Icons.lock_outline,
          accentColor: _accent,
          children: [
            CField(controller: _typeInfoCtrl, label: "Type d'informations confidentielles", accentColor: _accent,
                hint: 'Ex: données financières, code source, plans stratégiques…', icon: Icons.info_outline),
            kGap,
            // Niveau selector (chips)
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildLabel('Niveau de confidentialité', required: true),
              const SizedBox(height: 8),
              Row(children: [
                _levelChip('faible', 'Faible', Colors.green),
                const SizedBox(width: 8),
                _levelChip('moyen', 'Moyen', Colors.orange),
                const SizedBox(width: 8),
                _levelChip('élevé', 'Élevé', Colors.red),
              ]),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _niveauColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _niveauConf == 'faible'
                      ? 'Informations générales non critiques — divulgation peu préjudiciable.'
                      : _niveauConf == 'moyen'
                          ? 'Informations sensibles — divulgation pourrait nuire aux activités.'
                          : 'Informations hautement sensibles — divulgation pourrait causer un préjudice grave.',
                  style: TextStyle(fontSize: 11, color: _niveauColor, height: 1.4),
                ),
              ),
            ]),
          ],
        ),
        kGapLg,
        CSection(
          title: 'Engagement',
          icon: Icons.gavel_outlined,
          accentColor: _accent,
          subtitle: 'Durée et sanctions applicables',
          children: [
            CField(controller: _dureeCtrl, label: 'Durée de confidentialité', accentColor: _accent,
                icon: Icons.timer_outlined, hint: 'Ex: 3 ans, indéterminée…'),
            kGap,
            CField(controller: _sanctionsCtrl, label: 'Sanctions en cas de violation', accentColor: _accent,
                maxLines: 3, hint: 'Ex: dommages et intérêts, résiliation immédiate, poursuites judiciaires…'),
          ],
        ),
      ],
    ),
  );

  Widget _step2() => ListView(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
    children: [
      CSection(
        title: 'Périmètre précis',
        icon: Icons.article_outlined,
        accentColor: _accent,
        subtitle: 'Optionnel — précisez davantage le cadre',
        children: [
          CField(controller: _documentsCtrl, label: 'Documents concernés', accentColor: _accent,
              required: false, icon: Icons.folder_outlined, hint: 'Ex: rapport X, contrat Y, fichier Z…'),
          kGap,
          CField(controller: _personnesCtrl, label: 'Personnes autorisées à accéder', accentColor: _accent,
              required: false, icon: Icons.group_outlined, hint: 'Ex: directeur général, équipe technique…'),
        ],
      ),
      kGapLg,
      CSection(
        title: 'Récapitulatif',
        icon: Icons.summarize_outlined,
        accentColor: _accent,
        children: [
          if (_client != null) CSummaryRow(label: 'Autre partie', value: '${_client!.prenom} ${_client!.nom}', icon: Icons.person_outline, accentColor: _accent),
          CSummaryRow(label: 'Type d\'info', value: _typeInfoCtrl.text.isNotEmpty ? _typeInfoCtrl.text : '—', icon: Icons.info_outline, accentColor: _accent),
          CSummaryRow(label: 'Niveau', value: _niveauConf[0].toUpperCase() + _niveauConf.substring(1), icon: Icons.security_outlined, accentColor: _niveauColor),
          if (_dureeCtrl.text.isNotEmpty) CSummaryRow(label: 'Durée', value: _dureeCtrl.text, icon: Icons.timer_outlined, accentColor: _accent),
        ],
      ),
      kGapLg,
      CSection(
        title: 'Lieu de signature',
        icon: Icons.place_outlined,
        accentColor: _accent,
        children: [
          CField(controller: _villeCtrl, label: 'Ville de signature', accentColor: _accent, required: false, icon: Icons.location_city_outlined, hint: 'Ex: Dakar…'),
        ],
      ),
    ],
  );

  Widget _levelChip(String value, String label, Color color) {
    final selected = _niveauConf == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _niveauConf = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : kSubtleColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? color : kBorderColor, width: selected ? 1.5 : 1),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : kLabelColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label, {bool required = false}) => RichText(
    text: TextSpan(
      text: label,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kLabelColor),
      children: required
          ? [TextSpan(text: '  *', style: TextStyle(color: _accent, fontWeight: FontWeight.w800))]
          : [],
    ),
  );
}

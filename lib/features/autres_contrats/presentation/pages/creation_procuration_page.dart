import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_application/core/config/contrat_type.dart';
import 'package:sign_application/features/client/domain/entities/client.dart';
import '../bloc/autres_contrats_bloc.dart';
import '../bloc/autres_contrats_event.dart';
import '../bloc/autres_contrats_state.dart';
import '../widgets/client_search_field.dart';
import '../widgets/contrat_form_widgets.dart';
import 'package:toastification/toastification.dart';
import 'package:sign_application/core/widgets/toastNotif.dart';

class CreationProcurationPage extends StatefulWidget {
  const CreationProcurationPage({super.key});

  @override
  State<CreationProcurationPage> createState() => _State();
}

class _State extends State<CreationProcurationPage> {
  int _step = 0;
  static const int _totalSteps = 3;
  static const _steps = ['Mandataire', 'Mandat', 'Finalisation'];

  static const _accent = Color(0xFFD97706);
  static const _icon   = Icons.gavel_outlined;
  static const _titre  = 'Procuration';

  final _formKey1 = GlobalKey<FormState>();

  Client? _client;

  final _objetCtrl    = TextEditingController();
  final _pouvoirsCtrl = TextEditingController();
  final _dureeCtrl    = TextEditingController();
  final _limitesCtrl  = TextEditingController();
  final _villeCtrl    = TextEditingController();

  String _typeProcuration = 'générale';
  File?  _signatureImage;

  @override
  void dispose() {
    _objetCtrl.dispose(); _pouvoirsCtrl.dispose(); _dureeCtrl.dispose();
    _limitesCtrl.dispose(); _villeCtrl.dispose();
    super.dispose();
  }

  Future<void> _openSignaturePad() async {
    final file = await openSignaturePad(context);
    if (file != null && mounted) setState(() => _signatureImage = file);
  }

  void _onNext() {
    if (_step == 0) {
      if (_client == null) { _showError('Veuillez sélectionner le mandataire'); return; }
      setState(() => _step = 1);
    } else if (_step == 1) {
      if (!(_formKey1.currentState?.validate() ?? false)) return;
      setState(() => _step = 2);
    } else {
      _submit();
    }
  }

  void _onBack() => setState(() => _step--);

  void _showError(String msg) => showToast(context, 'Erreur', msg, ToastificationType.error);

  Future<void> _submit() async {
    if (_signatureImage == null) { _showError('Veuillez apposer votre signature'); return; }
    final sigBase64 = base64Encode(await _signatureImage!.readAsBytes());
    context.read<AutresContratsBloc>().add(CreerContrat(ContratType.procuration.apiValue, {
      'autrePartieId': _client!.id,
      'data': {
        'objet_procuration': _objetCtrl.text.trim(),
        'pouvoirs_accordes': _pouvoirsCtrl.text.trim(),
        'duree':             _dureeCtrl.text.trim(),
        'type_procuration':  _typeProcuration,
        if (_typeProcuration == 'limitée' && _limitesCtrl.text.trim().isNotEmpty)
          'limites_precises': _limitesCtrl.text.trim(),
        if (_villeCtrl.text.trim().isNotEmpty) 'ville_signature': _villeCtrl.text.trim(),
      },
      'signature_generateur': sigBase64,
    }));
  }

  String get _stepSubtitle {
    switch (_step) {
      case 0: return 'La personne qui recevra les pouvoirs';
      case 1: return 'Définissez l\'étendue du mandat';
      default: return 'Limites éventuelles et lieu de signature';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: BlocListener<AutresContratsBloc, AutresContratsState>(
        listener: (ctx, state) {
          if (state is AutresContratsSuccess) {
            showToast(ctx, 'Contrat créé', 'La procuration a été créée avec succès.', ToastificationType.success);
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
                submitLabel: 'Créer la procuration',
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
        title: 'Procuration / Mandat',
        description: 'Déléguez des pouvoirs spécifiques à une tierce personne pour agir en votre nom dans un cadre défini.',
        icon: _icon, accentColor: _accent,
      ),
      kGapLg,
      // Schéma mandant → mandataire
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _accent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(kCardRadius),
          border: Border.all(color: _accent.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          _partyBox('Vous\n(mandant)', Icons.person_rounded, Colors.black),
          Expanded(child: Column(children: [
            Icon(Icons.arrow_forward_rounded, color: _accent),
            Text('pouvoirs', style: TextStyle(fontSize: 10, color: _accent, fontWeight: FontWeight.w600)),
          ])),
          _partyBox('Mandataire\n(ci-dessous)', Icons.person_outlined, _accent),
        ]),
      ),
      kGapLg,
      CSection(
        title: 'Mandataire',
        icon: Icons.person_search_outlined,
        accentColor: _accent,
        subtitle: 'La personne qui agira en votre nom',
        children: [
          if (_client != null)
            CClientDisplay(client: _client!, accentColor: _accent, role: 'Mandataire', onClear: () => setState(() => _client = null))
          else
            ClientSearchField(label: 'Rechercher le mandataire', onClientSelected: (c) => setState(() => _client = c)),
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
          title: 'Objet du mandat',
          icon: Icons.assignment_outlined,
          accentColor: _accent,
          children: [
            CField(controller: _objetCtrl, label: 'Objet de la procuration', accentColor: _accent, maxLines: 3,
                hint: 'Ex: gérer mon compte bancaire, signer des documents, représenter mon entreprise…'),
          ],
        ),
        kGapLg,
        CSection(
          title: 'Type et étendue',
          icon: Icons.tune_rounded,
          accentColor: _accent,
          subtitle: 'Définissez la portée des pouvoirs accordés',
          children: [
            // Type selector (chips)
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Type de procuration  *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kLabelColor)),
              const SizedBox(height: 8),
              Row(children: [
                _typeChip('générale',  'Générale',  Icons.open_in_full_rounded),
                const SizedBox(width: 10),
                _typeChip('limitée',  'Limitée',  Icons.tune_rounded),
              ]),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _typeProcuration == 'générale'
                      ? 'Procuration générale : le mandataire peut agir sur l\'ensemble de vos affaires.'
                      : 'Procuration limitée : restreinte à des actes spécifiques que vous précisez.',
                  style: TextStyle(fontSize: 11, color: _accent, height: 1.4),
                ),
              ),
            ]),
            kGap,
            CField(controller: _pouvoirsCtrl, label: 'Pouvoirs accordés', accentColor: _accent, maxLines: 4,
                icon: Icons.admin_panel_settings_outlined,
                hint: 'Listez précisément les actes autorisés : signer, encaisser, vendre, représenter…'),
            kGap,
            CField(controller: _dureeCtrl, label: 'Durée du mandat', accentColor: _accent,
                icon: Icons.timer_outlined, hint: 'Ex: 6 mois, jusqu\'au 31/12/2025, indéterminée…'),
          ],
        ),
      ],
    ),
  );

  Widget _step2() => ListView(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
    children: [
      if (_typeProcuration == 'limitée') ...[
        CSection(
          title: 'Limites précises',
          icon: Icons.block_outlined,
          accentColor: _accent,
          subtitle: 'Ce que le mandataire ne peut PAS faire',
          children: [
            CField(controller: _limitesCtrl, label: 'Restrictions et limites', accentColor: _accent,
                required: false, maxLines: 3,
                hint: 'Ex: ne peut pas vendre d\'immeubles, limité à 5 000 000 FCFA par opération…'),
          ],
        ),
        kGapLg,
      ],
      CSection(
        title: 'Récapitulatif',
        icon: Icons.summarize_outlined,
        accentColor: _accent,
        children: [
          if (_client != null) CSummaryRow(label: 'Mandataire', value: '${_client!.prenom} ${_client!.nom}', icon: Icons.person_outline, accentColor: _accent),
          CSummaryRow(label: 'Type', value: _typeProcuration[0].toUpperCase() + _typeProcuration.substring(1), icon: Icons.tune_rounded, accentColor: _accent),
          if (_objetCtrl.text.isNotEmpty) CSummaryRow(label: 'Objet', value: _objetCtrl.text, icon: Icons.assignment_outlined, accentColor: _accent),
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
      kGapLg,
      CSection(
        title: 'Signature',
        icon: Icons.draw_outlined,
        accentColor: _accent,
        subtitle: 'Signez pour valider la création du contrat',
        children: [
          CSignatureSection(image: _signatureImage, onTap: _openSignaturePad, accentColor: _accent),
        ],
      ),
    ],
  );

  Widget _partyBox(String label, IconData icon, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.25)),
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 4),
      Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700, height: 1.3)),
    ]),
  );

  Widget _typeChip(String value, String label, IconData icon) {
    final selected = _typeProcuration == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _typeProcuration = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? _accent : kSubtleColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? _accent : kBorderColor, width: selected ? 1.5 : 1),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 16, color: selected ? Colors.white : kLabelColor),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: selected ? Colors.white : kLabelColor)),
          ]),
        ),
      ),
    );
  }
}

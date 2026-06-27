import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class CreationContratCautionPage extends StatefulWidget {
  const CreationContratCautionPage({super.key});

  @override
  State<CreationContratCautionPage> createState() => _CreationContratCautionPageState();
}

class _CreationContratCautionPageState extends State<CreationContratCautionPage> {
  int _step = 0;
  static const int _totalSteps = 2;
  static const _steps = ['Client', 'Caution'];

  static const _accent = Color(0xFFDC2626);
  static const _icon   = Icons.verified_user_outlined;
  static const _titre  = 'Contrat de caution';

  final _formKey = GlobalKey<FormState>();

  Client? _client;

  final _montantCtrl = TextEditingController();
  final _dureeCtrl   = TextEditingController();
  final _villeCtrl   = TextEditingController();

  String _typeCaution = 'simple';
  File? _signatureImage;

  @override
  void dispose() {
    _montantCtrl.dispose(); _dureeCtrl.dispose(); _villeCtrl.dispose();
    super.dispose();
  }

  Future<void> _openSignaturePad() async {
    final file = await openSignaturePad(context);
    if (file != null && mounted) setState(() => _signatureImage = file);
  }

  void _onNext() {
    if (_step == 0) {
      if (_client == null) { _showError('Veuillez sélectionner un client'); return; }
      setState(() => _step = 1);
    } else {
      if (!(_formKey.currentState?.validate() ?? false)) return;
      _submit();
    }
  }

  void _onBack() => setState(() => _step--);

  void _showError(String msg) => showToast(context, 'Erreur', msg, ToastificationType.error);

  Future<void> _submit() async {
    if (_signatureImage == null) {
      _showError('Veuillez apposer votre signature');
      return;
    }
    final sigBase64 = base64Encode(await _signatureImage!.readAsBytes());
    context.read<AutresContratsBloc>().add(CreerContrat(ContratType.caution.apiValue, {
      'autrePartieId': _client!.id,
      'data': {
        'montant_garanti': double.tryParse(_montantCtrl.text) ?? 0,
        'duree':           _dureeCtrl.text.trim(),
        'type_caution':    _typeCaution,
        if (_villeCtrl.text.trim().isNotEmpty) 'ville_signature': _villeCtrl.text.trim(),
      },
      'signature_generateur': sigBase64,
    }));
  }

  String get _stepSubtitle {
    switch (_step) {
      case 0: return 'Identifiez le client (débiteur ou créancier)';
      default: return 'Montant, durée et type de caution';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: BlocListener<AutresContratsBloc, AutresContratsState>(
        listener: (ctx, state) {
          if (state is AutresContratsSuccess) {
            showToast(ctx, 'Contrat créé', 'Le contrat de caution a été créé avec succès.', ToastificationType.success);
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
                submitLabel: 'Créer la caution',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() => _step == 0 ? _step0() : _step1();

  Widget _step0() => ListView(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
    children: [
      CInfoBanner(
        title: 'Contrat de cautionnement',
        description: 'Garantissez le paiement ou l\'exécution d\'une obligation pour le compte d\'un tiers auprès d\'un créancier.',
        icon: _icon, accentColor: _accent,
      ),
      kGapLg,
      // Explication du cautionnement
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(kCardRadius),
          border: Border.all(color: _accent.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            _roleRow(Icons.person_outlined, 'Vous (caution)', 'Vous vous portez garant de l\'obligation'),
            const Divider(height: 20),
            _roleRow(Icons.people_outline, 'Débiteur principal', 'La personne dont vous garantissez l\'obligation'),
            const Divider(height: 20),
            _roleRow(Icons.account_balance_outlined, 'Créancier', 'Le bénéficiaire de la garantie'),
          ],
        ),
      ),
      kGapLg,
      CSection(
        title: 'Client concerné',
        icon: Icons.person_search_outlined,
        accentColor: _accent,
        subtitle: 'Débiteur ou créancier selon votre rôle',
        children: [
          if (_client != null)
            CClientDisplay(client: _client!, accentColor: _accent, role: 'Client (débiteur / créancier)', onClear: () => setState(() => _client = null))
          else
            ClientSearchField(label: 'Rechercher un client', onClientSelected: (c) => setState(() => _client = c)),
        ],
      ),
    ],
  );

  Widget _step1() => Form(
    key: _formKey,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      children: [
        CSection(
          title: 'Détails de la caution',
          icon: Icons.shield_outlined,
          accentColor: _accent,
          subtitle: 'Paramètres de votre engagement',
          children: [
            CDropdown<String>(
              label: 'Type de caution',
              value: _typeCaution,
              accentColor: _accent,
              icon: Icons.category_outlined,
              items: [
                DropdownMenuItem(
                  value: 'simple',
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    const Text('Simple', style: TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                ),
                DropdownMenuItem(
                  value: 'solidaire',
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    const Text('Solidaire', style: TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                ),
              ],
              onChanged: (v) => setState(() => _typeCaution = v!),
            ),
            kGap,
            // Type explanation
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Icon(Icons.info_outline, size: 16, color: _accent),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  _typeCaution == 'simple'
                      ? 'Caution simple : le créancier doit d\'abord poursuivre le débiteur principal.'
                      : 'Caution solidaire : le créancier peut vous poursuivre directement, sans passer par le débiteur.',
                  style: TextStyle(fontSize: 11, color: _accent, height: 1.4),
                )),
              ]),
            ),
            kGap,
            CField(
              controller: _montantCtrl,
              label: 'Montant garanti (FCFA)',
              accentColor: _accent,
              icon: Icons.monetization_on_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              hint: '0',
            ),
            kGap,
            CField(controller: _dureeCtrl, label: 'Durée de la caution', accentColor: _accent, icon: Icons.timer_outlined,
                hint: 'Ex: 12 mois, indéterminée…'),
          ],
        ),
        kGapLg,
        CSection(
          title: 'Récapitulatif',
          icon: Icons.summarize_outlined,
          accentColor: _accent,
          children: [
            if (_client != null) CSummaryRow(label: 'Client', value: '${_client!.prenom} ${_client!.nom}', icon: Icons.person_outline, accentColor: _accent),
            CSummaryRow(label: 'Type', value: _typeCaution[0].toUpperCase() + _typeCaution.substring(1), icon: Icons.shield_outlined, accentColor: _accent),
            if (_montantCtrl.text.isNotEmpty) CSummaryRow(label: 'Montant garanti', value: '${_montantCtrl.text} FCFA', icon: Icons.monetization_on_outlined, accentColor: _accent),
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
    ),
  );

  Widget _roleRow(IconData icon, String title, String desc) => Row(children: [
    Container(
      width: 32, height: 32,
      decoration: BoxDecoration(color: _accent.withValues(alpha: 0.12), shape: BoxShape.circle),
      child: Icon(icon, size: 16, color: _accent),
    ),
    const SizedBox(width: 10),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kValueColor)),
      Text(desc, style: const TextStyle(fontSize: 11, color: kLabelColor)),
    ])),
  ]);
}

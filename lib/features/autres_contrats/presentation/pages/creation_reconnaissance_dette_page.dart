import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sign_application/core/config/contrat_type.dart';
import 'package:sign_application/features/client/domain/entities/client.dart';
import '../bloc/autres_contrats_bloc.dart';
import '../bloc/autres_contrats_event.dart';
import '../bloc/autres_contrats_state.dart';
import '../widgets/client_search_field.dart';
import '../widgets/contrat_form_widgets.dart';
import 'package:toastification/toastification.dart';
import 'package:sign_application/core/widgets/toastNotif.dart';

class CreationReconnaissanceDettePage extends StatefulWidget {
  const CreationReconnaissanceDettePage({super.key});

  @override
  State<CreationReconnaissanceDettePage> createState() => _State();
}

class _State extends State<CreationReconnaissanceDettePage> {
  int _step = 0;
  static const int _totalSteps = 3;
  static const _steps = ['Débiteur', 'Dette', 'Remboursement'];

  static const _accent = Color(0xFF0891B2);
  static const _icon   = Icons.receipt_long_outlined;
  static const _titre  = 'Reconnaissance de dette';

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  Client? _client;

  final _montantCtrl     = TextEditingController();
  final _motifCtrl       = TextEditingController();
  final _nbEchCtrl       = TextEditingController();
  final _montantEchCtrl  = TextEditingController();
  final _freqCtrl        = TextEditingController();
  final _villeCtrl       = TextEditingController();

  String    _devise     = 'FCFA';
  bool      _echelonne  = false;
  DateTime? _dateLimite;
  File?     _signatureImage;

  @override
  void dispose() {
    _montantCtrl.dispose(); _motifCtrl.dispose(); _nbEchCtrl.dispose();
    _montantEchCtrl.dispose(); _freqCtrl.dispose(); _villeCtrl.dispose();
    super.dispose();
  }

  Future<void> _openSignaturePad() async {
    final file = await openSignaturePad(context);
    if (file != null && mounted) setState(() => _signatureImage = file);
  }

  void _onNext() {
    if (_step == 0) {
      if (_client == null) { _showError('Veuillez sélectionner le débiteur'); return; }
      setState(() => _step = 1);
    } else if (_step == 1) {
      if (!(_formKey1.currentState?.validate() ?? false)) return;
      setState(() => _step = 2);
    } else {
      if (_dateLimite == null) { _showError('Veuillez sélectionner la date limite de remboursement'); return; }
      _submit();
    }
  }

  void _onBack() => setState(() => _step--);

  void _showError(String msg) => showToast(context, 'Erreur', msg, ToastificationType.error);

  Future<void> _submit() async {
    if (_signatureImage == null) { _showError('Veuillez apposer votre signature'); return; }
    final sigBase64 = base64Encode(await _signatureImage!.readAsBytes());
    if (!mounted) return;
    context.read<AutresContratsBloc>().add(CreerContrat(ContratType.reconnaissanceDette.apiValue, {
      'autrePartieId': _client!.id,
      'data': {
        'montant':                      double.tryParse(_montantCtrl.text) ?? 0,
        'devise':                       _devise,
        'motif_dette':                  _motifCtrl.text.trim(),
        'date_limite_remboursement':    _dateLimite!.toIso8601String().substring(0, 10),
        'remboursement_echelonne':      _echelonne,
        if (_echelonne && _nbEchCtrl.text.isNotEmpty)     'nombre_echeances': int.tryParse(_nbEchCtrl.text),
        if (_echelonne && _montantEchCtrl.text.isNotEmpty) 'montant_par_echeance': double.tryParse(_montantEchCtrl.text),
        if (_echelonne && _freqCtrl.text.isNotEmpty)       'frequence_paiements': _freqCtrl.text.trim(),
        if (_villeCtrl.text.trim().isNotEmpty) 'ville_signature': _villeCtrl.text.trim(),
      },
      'signature_generateur': sigBase64,
    }));
  }

  String get _stepSubtitle {
    switch (_step) {
      case 0: return 'La personne qui doit de l\'argent';
      case 1: return 'Montant, devise et motif de la dette';
      default: return 'Modalités de remboursement et finalisation';
    }
  }

  String _formatMontant(String raw, String devise) {
    final n = double.tryParse(raw);
    if (n == null) return '—';
    return '${NumberFormat('#,###', 'fr_FR').format(n).replaceAll(',', ' ')} $devise';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: BlocListener<AutresContratsBloc, AutresContratsState>(
        listener: (ctx, state) {
          if (state is AutresContratsSuccess) {
            showToast(ctx, 'Contrat créé', 'La reconnaissance de dette a été créée avec succès.', ToastificationType.success);
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
                submitLabel: 'Créer la reconnaissance',
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

  // ── Step 0 : Débiteur ────────────────────────────────────────────────────

  Widget _step0() => ListView(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
    children: [
      CInfoBanner(
        title: 'Reconnaissance de dette',
        description: 'Document juridique par lequel le débiteur reconnaît formellement devoir une somme d\'argent au créancier (vous).',
        icon: _icon, accentColor: _accent,
      ),
      kGapLg,
      // Schema créancier ← débiteur
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _accent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(kCardRadius),
          border: Border.all(color: _accent.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.info_outline, size: 15, color: _accent),
              const SizedBox(width: 6),
              Text('Parties impliquées', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _accent)),
            ]),
            const SizedBox(height: 12),
            _roleRow(Icons.person_rounded, 'Vous (créancier)', 'Vous avez prêté ou avancé la somme', Colors.black),
            const SizedBox(height: 10),
            _roleRow(Icons.person_outlined, 'Débiteur (ci-dessous)', 'La personne qui doit rembourser', _accent),
          ],
        ),
      ),
      kGapLg,
      CSection(
        title: 'Débiteur',
        icon: Icons.person_search_outlined,
        accentColor: _accent,
        subtitle: 'La personne qui reconnaît la dette',
        children: [
          if (_client != null)
            CClientDisplay(
              client: _client!, accentColor: _accent,
              role: 'Débiteur', onClear: () => setState(() => _client = null),
            )
          else
            ClientSearchField(
              label: 'Rechercher le débiteur',
              onClientSelected: (c) => setState(() => _client = c),
            ),
        ],
      ),
    ],
  );

  // ── Step 1 : Dette ───────────────────────────────────────────────────────

  Widget _step1() => Form(
    key: _formKey1,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      children: [
        CSection(
          title: 'Montant de la dette',
          icon: Icons.monetization_on_outlined,
          accentColor: _accent,
          subtitle: 'Somme exacte reconnue par le débiteur',
          children: [
            // Montant + devise sur la même ligne
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CField(
                    controller: _montantCtrl,
                    label: 'Montant',
                    accentColor: _accent,
                    icon: Icons.payments_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    hint: '0',
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 110,
                  child: CDropdown<String>(
                    label: 'Devise',
                    value: _devise,
                    accentColor: _accent,
                    items: const [
                      DropdownMenuItem(value: 'FCFA', child: Text('FCFA')),
                      DropdownMenuItem(value: 'EUR',  child: Text('EUR')),
                      DropdownMenuItem(value: 'USD',  child: Text('USD')),
                      DropdownMenuItem(value: 'GBP',  child: Text('GBP')),
                    ],
                    onChanged: (v) => setState(() => _devise = v!),
                  ),
                ),
              ],
            ),
            // Preview du montant formaté
            if (_montantCtrl.text.isNotEmpty)
              Builder(builder: (_) {
                _montantCtrl.addListener(() => setState(() {}));
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      Icon(Icons.check_circle_outline, size: 15, color: _accent),
                      const SizedBox(width: 8),
                      Text(
                        _formatMontant(_montantCtrl.text, _devise),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _accent),
                      ),
                    ]),
                  ),
                );
              }),
          ],
        ),
        kGapLg,
        CSection(
          title: 'Motif de la dette',
          icon: Icons.notes_outlined,
          accentColor: _accent,
          subtitle: 'Expliquez l\'origine de la dette',
          children: [
            CField(
              controller: _motifCtrl,
              label: 'Motif ou cause de la dette',
              accentColor: _accent,
              maxLines: 4,
              hint: 'Ex: prêt personnel accordé le …, avance sur salaire, remboursement de frais…',
            ),
          ],
        ),
      ],
    ),
  );

  // ── Step 2 : Remboursement ───────────────────────────────────────────────

  Widget _step2() => Form(
    key: _formKey2,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      children: [
        CSection(
          title: 'Date limite de remboursement',
          icon: Icons.event_available_outlined,
          accentColor: _accent,
          subtitle: 'Échéance finale pour solder la dette',
          children: [
            CDateField(
              label: 'Date limite de remboursement',
              value: _dateLimite,
              accentColor: _accent,
              onTap: () async {
                final d = await cPickDate(context, firstDate: DateTime.now());
                if (d != null) setState(() => _dateLimite = d);
              },
            ),
          ],
        ),
        kGapLg,
        CSection(
          title: 'Modalités de remboursement',
          icon: Icons.calendar_month_outlined,
          accentColor: _accent,
          subtitle: 'Optionnel — si remboursement par tranches',
          children: [
            CToggle(
              title: 'Remboursement échelonné',
              subtitle: 'Paiement en plusieurs tranches',
              value: _echelonne,
              accentColor: _accent,
              onChanged: (v) => setState(() => _echelonne = v),
            ),
            if (_echelonne) ...[
              kGapLg,
              // Grille d'échéances
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: CField(
                  controller: _nbEchCtrl,
                  label: 'Nombre d\'échéances',
                  accentColor: _accent,
                  icon: Icons.format_list_numbered_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  required: false,
                  hint: '12',
                )),
                const SizedBox(width: 10),
                Expanded(child: CField(
                  controller: _montantEchCtrl,
                  label: 'Montant / échéance',
                  accentColor: _accent,
                  icon: Icons.monetization_on_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  required: false,
                  hint: '0',
                )),
              ]),
              kGap,
              CField(
                controller: _freqCtrl,
                label: 'Fréquence des paiements',
                accentColor: _accent,
                icon: Icons.repeat_rounded,
                required: false,
                hint: 'Ex: mensuel, hebdomadaire, trimestriel…',
              ),
              // Preview plan de remboursement
              if (_nbEchCtrl.text.isNotEmpty && _montantEchCtrl.text.isNotEmpty) ...[
                kGap,
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_accent.withValues(alpha: 0.08), _accent.withValues(alpha: 0.03)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _accent.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    Icon(Icons.calculate_outlined, color: _accent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Plan estimé', style: TextStyle(fontSize: 11, color: _accent, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        '${_nbEchCtrl.text} échéances × ${_formatMontant(_montantEchCtrl.text, _devise)} = ${_formatMontant(
                          ((double.tryParse(_nbEchCtrl.text) ?? 0) * (double.tryParse(_montantEchCtrl.text) ?? 0)).toStringAsFixed(0), _devise,
                        )}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kValueColor),
                      ),
                    ])),
                  ]),
                ),
              ],
            ],
          ],
        ),
        kGapLg,
        // Récapitulatif
        CSection(
          title: 'Récapitulatif',
          icon: Icons.summarize_outlined,
          accentColor: _accent,
          children: [
            if (_client != null)
              CSummaryRow(label: 'Débiteur', value: '${_client!.prenom} ${_client!.nom}', icon: Icons.person_outline, accentColor: _accent),
            if (_montantCtrl.text.isNotEmpty)
              CSummaryRow(label: 'Montant', value: _formatMontant(_montantCtrl.text, _devise), icon: Icons.payments_outlined, accentColor: _accent),
            if (_dateLimite != null)
              CSummaryRow(
                label: 'Échéance finale',
                value: DateFormat('dd MMMM yyyy', 'fr_FR').format(_dateLimite!),
                icon: Icons.event_outlined,
                accentColor: _accent,
              ),
            CSummaryRow(label: 'Échelonné', value: _echelonne ? 'Oui' : 'Non', icon: Icons.calendar_month_outlined, accentColor: _accent),
          ],
        ),
        kGapLg,
        CSection(
          title: 'Lieu de signature',
          icon: Icons.place_outlined,
          accentColor: _accent,
          children: [
            CField(
              controller: _villeCtrl,
              label: 'Ville de signature',
              accentColor: _accent,
              required: false,
              icon: Icons.location_city_outlined,
              hint: 'Ex: Dakar, Abidjan…',
            ),
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

  Widget _roleRow(IconData icon, String title, String desc, Color color) => Row(children: [
    Container(
      width: 34, height: 34,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: Icon(icon, size: 17, color: color),
    ),
    const SizedBox(width: 10),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kValueColor)),
      Text(desc, style: const TextStyle(fontSize: 11, color: kLabelColor)),
    ])),
  ]);
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_application/features/client/domain/entities/client.dart';
import '../bloc/autres_contrats_bloc.dart';
import '../bloc/autres_contrats_event.dart';
import '../bloc/autres_contrats_state.dart';
import '../widgets/client_search_field.dart';
import '../widgets/contrat_form_widgets.dart';

class CreationContratLocationPage extends StatefulWidget {
  const CreationContratLocationPage({super.key});

  @override
  State<CreationContratLocationPage> createState() => _State();
}

class _State extends State<CreationContratLocationPage> {
  int _step = 0;
  static const int _totalSteps = 3;
  static const _steps = ['Locataire', 'Bien', 'Conditions'];

  static const _accent = Color(0xFF059669);
  static const _icon   = Icons.directions_car_outlined;
  static const _titre  = 'Contrat de location';

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  Client? _client;

  final _descCtrl         = TextEditingController();
  final _etatCtrl         = TextEditingController();
  final _valeurCtrl       = TextEditingController();
  final _dureeCtrl        = TextEditingController();
  final _montantCtrl      = TextEditingController();
  final _montantCautionCtrl = TextEditingController();
  final _villeCtrl        = TextEditingController();

  String _typeBien = 'matériel';
  bool   _caution  = false;

  @override
  void dispose() {
    _descCtrl.dispose(); _etatCtrl.dispose(); _valeurCtrl.dispose();
    _dureeCtrl.dispose(); _montantCtrl.dispose(); _montantCautionCtrl.dispose();
    _villeCtrl.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_step == 0) {
      if (_client == null) { _showError('Veuillez sélectionner un locataire'); return; }
      setState(() => _step = 1);
    } else if (_step == 1) {
      if (!(_formKey1.currentState?.validate() ?? false)) return;
      setState(() => _step = 2);
    } else {
      if (!(_formKey2.currentState?.validate() ?? false)) return;
      _submit();
    }
  }

  void _onBack() => setState(() => _step--);

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: Colors.red[600], behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
  );

  void _submit() {
    context.read<AutresContratsBloc>().add(CreerContrat('contrat-location', {
      'autrePartieId': _client!.id,
      'data': {
        'type_bien':         _typeBien,
        'description_bien':  _descCtrl.text.trim(),
        'etat_bien':         _etatCtrl.text.trim(),
        'valeur_estimee':    double.tryParse(_valeurCtrl.text) ?? 0,
        'duree_location':    _dureeCtrl.text.trim(),
        'montant_location':  double.tryParse(_montantCtrl.text) ?? 0,
        'caution':           _caution,
        if (_caution && _montantCautionCtrl.text.isNotEmpty)
          'montant_caution': double.tryParse(_montantCautionCtrl.text),
        if (_villeCtrl.text.trim().isNotEmpty) 'ville_signature': _villeCtrl.text.trim(),
      },
      'signature_generateur': '',
    }));
  }

  String get _stepSubtitle {
    switch (_step) {
      case 0: return 'Identifiez le locataire';
      case 1: return 'Décrivez le bien à louer';
      default: return 'Durée, loyer et caution';
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
        title: 'Contrat de location de bien',
        description: 'Formalisez la mise à disposition d\'un véhicule, matériel ou équipement avec toutes les garanties nécessaires.',
        icon: _icon, accentColor: _accent,
      ),
      kGapLg,
      CSection(
        title: 'Locataire',
        icon: Icons.person_search_outlined,
        accentColor: _accent,
        subtitle: 'La personne qui loue le bien',
        children: [
          if (_client != null)
            CClientDisplay(client: _client!, accentColor: _accent, role: 'Locataire', onClear: () => setState(() => _client = null))
          else
            ClientSearchField(label: 'Rechercher un locataire', onClientSelected: (c) => setState(() => _client = c)),
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
          title: 'Identification du bien',
          icon: Icons.inventory_2_outlined,
          accentColor: _accent,
          subtitle: 'Caractéristiques du bien loué',
          children: [
            CDropdown<String>(
              label: 'Type de bien',
              value: _typeBien,
              accentColor: _accent,
              icon: Icons.category_outlined,
              items: const [
                DropdownMenuItem(value: 'véhicule',     child: Text('Véhicule')),
                DropdownMenuItem(value: 'matériel',     child: Text('Matériel')),
                DropdownMenuItem(value: 'équipement',   child: Text('Équipement')),
                DropdownMenuItem(value: 'électronique', child: Text('Électronique')),
                DropdownMenuItem(value: 'autre',        child: Text('Autre')),
              ],
              onChanged: (v) => setState(() => _typeBien = v!),
            ),
            kGap,
            CField(controller: _descCtrl, label: 'Description du bien', accentColor: _accent, maxLines: 3,
                hint: 'Marque, modèle, numéro de série, caractéristiques…'),
            kGap,
            CField(controller: _etatCtrl, label: 'État du bien', accentColor: _accent, icon: Icons.info_outline,
                hint: 'Neuf, bon état, usage normal…'),
            kGap,
            CField(
              controller: _valeurCtrl,
              label: 'Valeur estimée (FCFA)',
              accentColor: _accent,
              icon: Icons.monetization_on_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              hint: '0',
            ),
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
          title: 'Conditions de location',
          icon: Icons.receipt_long_outlined,
          accentColor: _accent,
          children: [
            CField(controller: _dureeCtrl, label: 'Durée de location', accentColor: _accent, icon: Icons.timer_outlined,
                hint: 'Ex: 7 jours, 1 mois…'),
            kGap,
            CField(
              controller: _montantCtrl,
              label: 'Montant de location (FCFA)',
              accentColor: _accent,
              icon: Icons.payments_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              hint: '0',
            ),
          ],
        ),
        kGapLg,
        CSection(
          title: 'Caution',
          icon: Icons.shield_outlined,
          accentColor: _accent,
          subtitle: 'Garantie en cas de dommage ou manquement',
          children: [
            CToggle(
              title: 'Caution requise',
              subtitle: 'Montant récupérable à la restitution du bien',
              value: _caution,
              accentColor: _accent,
              onChanged: (v) => setState(() => _caution = v),
            ),
            if (_caution) ...[
              kGap,
              CField(
                controller: _montantCautionCtrl,
                label: 'Montant de la caution (FCFA)',
                accentColor: _accent,
                icon: Icons.shield_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                required: false,
                hint: '0',
              ),
            ],
          ],
        ),
        kGapLg,
        CSection(
          title: 'Récapitulatif',
          icon: Icons.summarize_outlined,
          accentColor: _accent,
          children: [
            if (_client != null) CSummaryRow(label: 'Locataire', value: '${_client!.prenom} ${_client!.nom}', icon: Icons.person_outline, accentColor: _accent),
            CSummaryRow(label: 'Type de bien', value: _typeBien, icon: Icons.inventory_2_outlined, accentColor: _accent),
            if (_dureeCtrl.text.isNotEmpty) CSummaryRow(label: 'Durée', value: _dureeCtrl.text, icon: Icons.timer_outlined, accentColor: _accent),
            if (_montantCtrl.text.isNotEmpty) CSummaryRow(label: 'Loyer', value: '${_montantCtrl.text} FCFA', icon: Icons.payments_outlined, accentColor: _accent),
            CSummaryRow(label: 'Caution', value: _caution ? 'Oui' : 'Non', icon: Icons.shield_outlined, accentColor: _accent),
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
    ),
  );
}

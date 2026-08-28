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
import 'package:sign_application/core/theme/app_color.dart';
import 'package:sign_application/features/autres_contrats/domain/usecases/telecharger_autre_contrat.dart';
import 'package:sign_application/features/parcours/presentation/afficher_document_genere.dart';
import 'package:sign_application/injection_container.dart';
import 'package:sign_application/features/parcours/presentation/widgets/section_emetteur.dart';

class CreationContratPrestationPage extends StatefulWidget {
  const CreationContratPrestationPage({super.key});

  @override
  State<CreationContratPrestationPage> createState() => _State();
}

class _State extends State<CreationContratPrestationPage>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    // Prerempli la section « Vos informations » pendant que l'utilisateur
    // remplit les premieres etapes.
    _emetteur.charger();
  }

  // ── Stepper ───────────────────────────────────────────────────────────────
  int _step = 0;
  static const int _totalSteps = 3;
  static const _steps = ['Partie', 'Mission', 'Finalisation'];

  static const _accent  = AppColor.kTexte;
  static const _icon    = Icons.handshake_outlined;
  static const _titre   = 'Contrat de prestation';

  // ── Form state ────────────────────────────────────────────────────────────
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  Client? _client;

  /// Informations qui figureront sur le contrat : preremplies depuis le
  /// profil, modifiables, et figees avec le document cote serveur.
  final _emetteur = ControleurEmetteur();

  final _titreCtrl   = TextEditingController();
  final _objetCtrl   = TextEditingController();
  final _typeCtrl    = TextEditingController();
  final _descCtrl    = TextEditingController();
  final _dureeCtrl   = TextEditingController();
  final _montantCtrl = TextEditingController();
  final _villeCtrl   = TextEditingController();

  DateTime? _dateContrat;
  DateTime? _dateDebut;
  DateTime? _dateFin;
  String _modePaiement = 'Virement bancaire';
  File?  _signatureImage;

  @override
  void dispose() {
    _emetteur.dispose();
    _titreCtrl.dispose(); _objetCtrl.dispose(); _typeCtrl.dispose();
    _descCtrl.dispose(); _dureeCtrl.dispose(); _montantCtrl.dispose();
    _villeCtrl.dispose();
    super.dispose();
  }

  Future<void> _openSignaturePad() async {
    final file = await openSignaturePad(context);
    if (file != null && mounted) setState(() => _signatureImage = file);
  }

  // ── Navigation ────────────────────────────────────────────────────────────
  void _onNext() {
    if (_step == 0) {
      if (_client == null) {
        _showError('Veuillez sélectionner un client');
        return;
      }
      setState(() => _step = 1);
    } else if (_step == 1) {
      if (!(_formKey1.currentState?.validate() ?? false)) return;
      setState(() => _step = 2);
    } else {
      if (!(_formKey2.currentState?.validate() ?? false)) return;
      if (_dateContrat == null || _dateDebut == null || _dateFin == null) {
        _showError('Veuillez renseigner toutes les dates');
        return;
      }
      _submit();
    }
  }

  void _onBack() => setState(() => _step--);

  void _showError(String msg) => showToast(context, 'Erreur', msg, ToastificationType.error);

  Future<void> _submit() async {
    if (_signatureImage == null) { _showError('Veuillez apposer votre signature'); return; }
    final sigBase64 = base64Encode(await _signatureImage!.readAsBytes());
    if (!mounted) return;
    context.read<AutresContratsBloc>().add(CreerContrat(ContratType.prestation.apiValue, {
      'autrePartieId': _client!.id,
      'data': {
        'titre_contrat':      _titreCtrl.text.trim(),
        'date_contrat':       _dateContrat!.toIso8601String().substring(0, 10),
        'ville_signature':    _villeCtrl.text.trim(),
        'objet_prestation':   _objetCtrl.text.trim(),
        'type_prestation':    _typeCtrl.text.trim(),
        'description_mission': _descCtrl.text.trim(),
        'duree_mission':      _dureeCtrl.text.trim(),
        'date_debut':         _dateDebut!.toIso8601String().substring(0, 10),
        'date_fin':           _dateFin!.toIso8601String().substring(0, 10),
        'montant_total':      double.tryParse(_montantCtrl.text) ?? 0,
        'mode_paiement':      _modePaiement,
      },
      'signature_generateur': sigBase64,
      // Ce qui sera imprime sur le contrat. Le serveur fige ces valeurs :
      // une regeneration a la signature produira le meme document.
      'emetteur': _emetteur.valeursPourEnvoi(),
    }));
  }

  // ── Step subtitles ────────────────────────────────────────────────────────
  String get _stepSubtitle {
    switch (_step) {
      case 0: return 'Sélectionnez le prestataire ou le client';
      case 1: return 'Décrivez la mission et ses modalités';
      default: return 'Dates, montant et lieu de signature';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: BlocListener<AutresContratsBloc, AutresContratsState>(
        listener: (ctx, state) {
          if (state is AutresContratsSuccess) {
            showToast(ctx, 'Contrat créé', 'Le contrat de prestation a été créé avec succès.', ToastificationType.success);
            // Le document est montre a l'utilisateur avant tout retour
            // a la liste (§ 9), puis le parcours reprend la main (§ 10).
            afficherDocumentGenere(
              ctx,
              libelle: 'contrat de prestation',
              feminin: false,
              document: state.documentCree,
              telecharger: (id) async {
                final resultat = await sl<TelechargerAutreContrat>()(
                    ContratType.prestation.apiValue, id);
                return resultat.fold(
                  (echec) => throw Exception(echec.errorMessage),
                  (octets) => octets,
                );
              },
            );
          }
          if (state is AutresContratsError) _showError(state.message);
        },
        child: Column(
          children: [
            CFormHeader(
              titre: _titre,
              stepTitle: _steps[_step],
              stepSubtitle: _stepSubtitle,
              icon: _icon,
              accentColor: _accent,
              currentStep: _step,
              totalSteps: _totalSteps,
              stepLabels: _steps,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, anim) => SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                  ),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: _buildStep(),
                ),
              ),
            ),
            BlocBuilder<AutresContratsBloc, AutresContratsState>(
              builder: (ctx, state) => CBottomBar(
                step: _step,
                totalSteps: _totalSteps,
                onBack: _onBack,
                onNext: _onNext,
                accentColor: _accent,
                isLoading: state is AutresContratsLoading,
                submitLabel: 'Créer le contrat',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _buildStep0();
      case 1: return _buildStep1();
      default: return _buildStep2();
    }
  }

  // ── Step 0 : Partie ───────────────────────────────────────────────────────
  Widget _buildStep0() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      children: [
        CInfoBanner(
          title: 'Contrat de prestation de services',
          description: 'Formalisez une mission entre vous et un client ou prestataire. Définissez l\'objet, la durée et la rémunération.',
          icon: _icon,
          accentColor: _accent,
        ),
        kGapLg,
        CSection(
          title: 'Interlocuteur',
          icon: Icons.person_search_outlined,
          accentColor: _accent,
          subtitle: 'Recherchez le client concerné par ce contrat',
          children: [
            if (_client != null)
              CClientDisplay(
                client: _client!,
                accentColor: _accent,
                role: 'Autre partie',
                onClear: () => setState(() => _client = null),
              )
            else
              ClientSearchField(
                label: 'Rechercher un client',
                onClientSelected: (c) => setState(() => _client = c),
              ),
          ],
        ),
      ],
    );
  }

  // ── Step 1 : Mission ──────────────────────────────────────────────────────
  Widget _buildStep1() {
    return Form(
      key: _formKey1,
      // SingleChildScrollView et non ListView : un ListView ne monte que les
      // sections visibles, et un TextFormField demonte n est plus rattache au
      // Form — validate() laissait alors passer des champs obligatoires vides.
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CSection(
              title: 'Identification',
              icon: Icons.title_rounded,
              accentColor: _accent,
              subtitle: 'Nommez et catégorisez ce contrat',
              children: [
                CField(controller: _titreCtrl, label: 'Titre du contrat', accentColor: _accent, hint: 'Ex: Développement site web'),
                kGap,
                CField(controller: _objetCtrl, label: 'Objet de la prestation', accentColor: _accent, hint: 'Décrivez l\'objet principal'),
                kGap,
                CField(controller: _typeCtrl, label: 'Type de prestation', accentColor: _accent, hint: 'Ex: Conseil, Développement, Design…'),
              ],
            ),
            kGapLg,
            CSection(
              title: 'Description de la mission',
              icon: Icons.assignment_outlined,
              accentColor: _accent,
              subtitle: 'Décrivez en détail ce qui doit être réalisé',
              children: [
                CField(controller: _descCtrl, label: 'Description détaillée', accentColor: _accent, maxLines: 4, hint: 'Listez les livrables, étapes, contraintes…'),
                kGap,
                CDurationField(controller: _dureeCtrl, label: 'Durée estimée', accentColor: _accent, icon: Icons.timer_outlined),
              ],
            ),
                  ],
        ),
      ),
    );
  }

  // ── Step 2 : Finalisation ─────────────────────────────────────────────────
  Widget _buildStep2() {
    final fmt = DateFormat('dd/MM/yyyy');
    return Form(
      key: _formKey2,
      // SingleChildScrollView et non ListView : un ListView ne monte que les
      // sections visibles, et un TextFormField demonte n est plus rattache au
      // Form — validate() laissait alors passer des champs obligatoires vides.
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CSection(
              title: 'Vos informations',
              icon: Icons.person_outline,
              accentColor: _accent,
              subtitle: 'Ce qui figurera sur le contrat',
              children: [
                SectionEmetteur(controleur: _emetteur, titre: ''),
              ],
            ),
            kGapLg,
            CSection(
              title: 'Calendrier',
              icon: Icons.date_range_outlined,
              accentColor: _accent,
              subtitle: 'Définissez les jalons temporels',
              children: [
                CDateField(
                  label: 'Date du contrat',
                  value: _dateContrat,
                  accentColor: _accent,
                  onTap: () async {
                    final d = await cPickDate(context);
                    if (d != null) setState(() => _dateContrat = d);
                  },
                ),
                kGap,
                Row(children: [
                  Expanded(child: CDateField(
                    label: 'Début mission',
                    value: _dateDebut,
                    accentColor: _accent,
                    onTap: () async {
                      final d = await cPickDate(context);
                      if (d != null) setState(() => _dateDebut = d);
                    },
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: CDateField(
                    label: 'Fin mission',
                    value: _dateFin,
                    accentColor: _accent,
                    onTap: () async {
                      final d = await cPickDate(context);
                      if (d != null) setState(() => _dateFin = d);
                    },
                  )),
                ]),
              ],
            ),
            kGapLg,
            CSection(
              title: 'Rémunération',
              icon: Icons.payments_outlined,
              accentColor: _accent,
              subtitle: 'Conditions financières de la prestation',
              children: [
                CField(
                  controller: _montantCtrl,
                  label: 'Montant total (FCFA)',
                  accentColor: _accent,
                  icon: Icons.monetization_on_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  hint: '0',
                ),
                kGap,
                CDropdown<String>(
                  label: 'Mode de paiement',
                  value: _modePaiement,
                  accentColor: _accent,
                  icon: Icons.credit_card_outlined,
                  items: const [
                    DropdownMenuItem(value: 'Espèces', child: Text('Espèces')),
                    DropdownMenuItem(value: 'Virement bancaire', child: Text('Virement bancaire')),
                    DropdownMenuItem(value: 'Mobile Money', child: Text('Mobile Money')),
                    DropdownMenuItem(value: 'Chèque', child: Text('Chèque')),
                    DropdownMenuItem(value: 'ALL', child: Text('Tout mode de paiement')),
                    DropdownMenuItem(value: 'Autre', child: Text('Autre')),
                  ],
                  onChanged: (v) => setState(() => _modePaiement = v!),
                ),
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
                  CSummaryRow(label: 'Interlocuteur', value: '${_client!.prenom} ${_client!.nom}', icon: Icons.person_outline, accentColor: _accent),
                CSummaryRow(label: 'Titre', value: _titreCtrl.text.isNotEmpty ? _titreCtrl.text : '—', icon: Icons.title, accentColor: _accent),
                CSummaryRow(label: 'Type', value: _typeCtrl.text.isNotEmpty ? _typeCtrl.text : '—', icon: Icons.category_outlined, accentColor: _accent),
                CSummaryRow(label: 'Durée', value: _dureeCtrl.text.isNotEmpty ? _dureeCtrl.text : '—', icon: Icons.timer_outlined, accentColor: _accent),
                if (_dateDebut != null && _dateFin != null)
                  CSummaryRow(label: 'Période', value: '${fmt.format(_dateDebut!)} → ${fmt.format(_dateFin!)}', icon: Icons.date_range_outlined, accentColor: _accent),
                if (_montantCtrl.text.isNotEmpty)
                  CSummaryRow(label: 'Montant', value: '${_montantCtrl.text} FCFA', icon: Icons.payments_outlined, accentColor: _accent),
              ],
            ),
            kGapLg,
            CSection(
              title: 'Lieu de signature',
              icon: Icons.place_outlined,
              accentColor: _accent,
              children: [
                // Obligatoire ici, contrairement aux autres contrats : le
                // serveur exige ville_signature pour la prestation
                // (contrats.validation.js, creerContratPrestationSchema).
                CField(controller: _villeCtrl, label: 'Ville de signature', accentColor: _accent, icon: Icons.location_city_outlined, hint: 'Ex: Dakar, Abidjan…'),
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
      ),
    );
  }
}

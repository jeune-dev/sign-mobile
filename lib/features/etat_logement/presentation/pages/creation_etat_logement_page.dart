import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';
import 'package:toastification/toastification.dart';

import 'package:sign_application/core/widgets/toastNotif.dart';
import 'package:sign_application/features/autres_contrats/presentation/widgets/contrat_form_widgets.dart';
import 'package:sign_application/features/contrat/domain/entities/contrat_bail.dart';
import 'package:sign_application/features/etat_logement/domain/entities/etat_logement.dart';
import 'package:sign_application/features/etat_logement/presentation/bloc/etat_logement_bloc.dart';
import 'package:sign_application/features/etat_logement/presentation/bloc/etat_logement_event.dart';
import 'package:sign_application/features/etat_logement/presentation/bloc/etat_logement_state.dart';

/// Couleur d'accent dédiée à l'état des lieux.
const Color _kAccent = Color(0xFF059669);

/// Valeurs possibles pour l'état d'un élément d'une pièce.
const List<String> _kEtatValues = ['Neuf', 'Bon', 'Moyen', 'Mauvais'];

/// Modèle mutable d'édition d'une pièce dans le formulaire.
class _PieceForm {
  final TextEditingController nom;
  final TextEditingController observations;
  String? etatSol = 'Bon';
  String? etatMurs = 'Bon';
  String? etatPlafond = 'Bon';
  String? etatFenetres = 'Bon';
  String? etatPortes = 'Bon';
  String? etatElectricite = 'Bon';
  String? etatEclairage = 'Bon';
  String? proprete = 'Bon';
  bool humidite = false;
  bool degradations = false;

  _PieceForm({String nom = ''})
      : nom = TextEditingController(text: nom),
        observations = TextEditingController();

  void dispose() {
    nom.dispose();
    observations.dispose();
  }

  PieceEtat toEntity() => PieceEtat(
        nom: nom.text.trim().isEmpty ? 'Pièce' : nom.text.trim(),
        etatSol: etatSol,
        etatMurs: etatMurs,
        etatPlafond: etatPlafond,
        etatFenetres: etatFenetres,
        etatPortes: etatPortes,
        etatElectricite: etatElectricite,
        etatEclairage: etatEclairage,
        proprete: proprete,
        humidite: humidite,
        degradations: degradations,
        observations: observations.text.trim(),
      );
}

class CreationEtatLogementPage extends StatefulWidget {
  final ContratBail contrat;
  const CreationEtatLogementPage({super.key, required this.contrat});

  @override
  State<CreationEtatLogementPage> createState() =>
      _CreationEtatLogementPageState();
}

class _CreationEtatLogementPageState extends State<CreationEtatLogementPage> {
  int _step = 0;
  static const _totalSteps = 3;

  // Étape 1 — Infos générales
  DateTime? _date;
  TimeOfDay? _heure;
  final _observationsCtrl = TextEditingController();
  int _salons = 0, _chambres = 0, _cuisines = 0, _sallesBain = 0, _wc = 0, _balcons = 0;
  final _autresPiecesCtrl = TextEditingController();

  // Étape 2 — Pièces
  final List<_PieceForm> _pieces = [];

  // Étape 3 — Signature
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  bool _consent = false;

  @override
  void dispose() {
    _observationsCtrl.dispose();
    _autresPiecesCtrl.dispose();
    for (final p in _pieces) {
      p.dispose();
    }
    _signatureController.dispose();
    super.dispose();
  }

  // ─── Génération automatique des pièces depuis la composition ─────────────────
  void _genererPieces() {
    void add(String base, int n) {
      for (var i = 1; i <= n; i++) {
        _pieces.add(_PieceForm(nom: n > 1 ? '$base $i' : base));
      }
    }

    setState(() {
      for (final p in _pieces) {
        p.dispose();
      }
      _pieces.clear();
      add('Salon', _salons);
      add('Chambre', _chambres);
      add('Cuisine', _cuisines);
      add('Salle de bain', _sallesBain);
      add('WC', _wc);
      add('Balcon', _balcons);
      for (final autre in _autresPiecesList()) {
        _pieces.add(_PieceForm(nom: autre));
      }
      if (_pieces.isEmpty) _pieces.add(_PieceForm(nom: 'Pièce 1'));
    });
  }

  List<String> _autresPiecesList() => _autresPiecesCtrl.text
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  // ─── Navigation entre étapes ─────────────────────────────────────────────────
  bool _validateStep() {
    if (_step == 0) {
      if (_date == null || _heure == null) {
        showToast(context, 'Champs requis',
            'La date et l\'heure de visite sont obligatoires.',
            ToastificationType.warning);
        return false;
      }
    } else if (_step == 1) {
      if (_pieces.isEmpty) {
        showToast(context, 'Aucune pièce',
            'Ajoutez au moins une pièce à inspecter.',
            ToastificationType.warning);
        return false;
      }
    }
    return true;
  }

  void _next() {
    if (!_validateStep()) return;
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submit() async {
    if (!_consent) {
      showToast(context, 'Consentement requis',
          'Veuillez confirmer l\'exactitude des informations.',
          ToastificationType.warning);
      return;
    }
    if (_signatureController.isEmpty) {
      showToast(context, 'Signature manquante',
          'Veuillez apposer votre signature (bailleur).',
          ToastificationType.warning);
      return;
    }

    final Uint8List? sig = await _signatureController.toPngBytes();
    if (sig == null) return;
    final signatureBase64 = 'data:image/png;base64,${base64Encode(sig)}';

    final data = <String, dynamic>{
      'date_etat_des_lieux': DateFormat('yyyy-MM-dd').format(_date!),
      'heure_visite':
          '${_heure!.hour.toString().padLeft(2, '0')}:${_heure!.minute.toString().padLeft(2, '0')}',
      'observations_generales': _observationsCtrl.text.trim(),
      'nombre_salons': _salons,
      'nombre_chambres': _chambres,
      'nombre_cuisines': _cuisines,
      'nombre_salles_bain': _sallesBain,
      'nombre_wc': _wc,
      'nombre_balcons': _balcons,
      'autres_pieces': _autresPiecesList(),
      'pieces': _pieces.map((p) => p.toEntity().toJson()).toList(),
      'signature_bailleur': signatureBase64,
    };

    if (!mounted) return;
    context.read<EtatLogementBloc>().add(
          CreerEtatLogementEvent(contratId: widget.contrat.id, data: data),
        );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocListener<EtatLogementBloc, EtatLogementState>(
      listener: (ctx, state) {
        if (state is EtatLogementSuccess) {
          showToast(ctx, 'Succès', state.message, ToastificationType.success);
          Navigator.pop(ctx, true);
        } else if (state is EtatLogementError) {
          showToast(ctx, 'Erreur', state.message, ToastificationType.error);
        }
      },
      child: Scaffold(
        backgroundColor: kBgColor,
        body: Column(
          children: [
            CFormHeader(
              titre: 'État des lieux',
              stepTitle: '',
              stepSubtitle: widget.contrat.numeroContrat ?? 'Contrat de bail',
              icon: Icons.fact_check_outlined,
              accentColor: _kAccent,
              currentStep: _step,
              totalSteps: _totalSteps,
              stepLabels: const ['Général', 'Pièces', 'Signature'],
              onBack: _back,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: _buildStep(),
              ),
            ),
            BlocBuilder<EtatLogementBloc, EtatLogementState>(
              builder: (context, state) => CBottomBar(
                step: _step,
                totalSteps: _totalSteps,
                onBack: _back,
                onNext: _next,
                accentColor: _kAccent,
                isLoading: state is EtatLogementLoading,
                submitLabel: 'Créer l\'état des lieux',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildGeneral();
      case 1:
        return _buildPieces();
      default:
        return _buildSignature();
    }
  }

  // ─── Étape 1 ───────────────────────────────────────────────────────────────
  Widget _buildGeneral() {
    return Column(
      children: [
        CInfoBanner(
          title: widget.contrat.numeroContrat ?? 'Contrat de bail',
          description:
              '${widget.contrat.bienAdresse ?? ''}${widget.contrat.bienVille != null ? ' · ${widget.contrat.bienVille}' : ''}',
          icon: Icons.home_work_outlined,
          accentColor: _kAccent,
        ),
        kGap,
        CSection(
          title: 'Date & heure de visite',
          icon: Icons.event_rounded,
          accentColor: _kAccent,
          children: [
            CDateField(
              label: 'Date de l\'état des lieux',
              accentColor: _kAccent,
              value: _date,
              onTap: () async {
                final picked = await cPickDate(context, initial: _date);
                if (picked != null) setState(() => _date = picked);
              },
            ),
            kGap,
            _buildTimeField(),
          ],
        ),
        kGap,
        CSection(
          title: 'Composition du logement',
          icon: Icons.meeting_room_outlined,
          accentColor: _kAccent,
          subtitle: 'Nombre de pièces par type',
          children: [
            _counter('Salons', _salons, (v) => setState(() => _salons = v)),
            _counter('Chambres', _chambres, (v) => setState(() => _chambres = v)),
            _counter('Cuisines', _cuisines, (v) => setState(() => _cuisines = v)),
            _counter('Salles de bain', _sallesBain, (v) => setState(() => _sallesBain = v)),
            _counter('WC', _wc, (v) => setState(() => _wc = v)),
            _counter('Balcons', _balcons, (v) => setState(() => _balcons = v)),
            kGap,
            CField(
              controller: _autresPiecesCtrl,
              label: 'Autres pièces (séparées par des virgules)',
              accentColor: _kAccent,
              required: false,
              hint: 'Garage, Bureau, Cave…',
            ),
          ],
        ),
        kGap,
        CSection(
          title: 'Observations générales',
          icon: Icons.notes_rounded,
          accentColor: _kAccent,
          children: [
            CField(
              controller: _observationsCtrl,
              label: 'Remarques générales',
              accentColor: _kAccent,
              required: false,
              maxLines: 4,
              hint: 'État global du logement, remarques…',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeField() {
    final formatted = _heure != null
        ? '${_heure!.hour.toString().padLeft(2, '0')}:${_heure!.minute.toString().padLeft(2, '0')}'
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Heure de visite',
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: kLabelColor),
            children: [
              TextSpan(
                text: '  *',
                style: TextStyle(color: _kAccent, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: _heure ?? TimeOfDay.now(),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.light(primary: Colors.black),
                ),
                child: child!,
              ),
            );
            if (picked != null) setState(() => _heure = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: _heure != null ? _kAccent.withValues(alpha: 0.06) : kSubtleColor,
              borderRadius: BorderRadius.circular(kFieldRadius),
              border: Border.all(
                color: _heure != null ? _kAccent.withValues(alpha: 0.4) : kBorderColor,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 18, color: _heure != null ? _kAccent : kLabelColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    formatted ?? 'Sélectionner une heure',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: _heure != null ? FontWeight.w600 : FontWeight.w400,
                      color: _heure != null ? kValueColor : kLabelColor,
                    ),
                  ),
                ),
                Icon(
                  _heure != null ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                  size: 18,
                  color: _heure != null ? _kAccent : kLabelColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _counter(String label, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: kValueColor)),
          ),
          _roundBtn(Icons.remove_rounded,
              () => onChanged(value > 0 ? value - 1 : 0)),
          SizedBox(
            width: 36,
            child: Text('$value',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: kValueColor)),
          ),
          _roundBtn(Icons.add_rounded, () => onChanged(value + 1)),
        ],
      ),
    );
  }

  Widget _roundBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: _kAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: _kAccent),
      ),
    );
  }

  // ─── Étape 2 ───────────────────────────────────────────────────────────────
  Widget _buildPieces() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _actionBtn(
                Icons.auto_awesome_rounded,
                'Générer depuis la composition',
                _genererPieces,
              ),
            ),
          ],
        ),
        kGap,
        ..._pieces.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildPieceCard(e.key, e.value),
            )),
        _actionBtn(
          Icons.add_rounded,
          'Ajouter une pièce',
          () => setState(() =>
              _pieces.add(_PieceForm(nom: 'Pièce ${_pieces.length + 1}'))),
          filled: true,
        ),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap,
      {bool filled = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: filled ? _kAccent : _kAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(kFieldRadius),
          border: Border.all(color: _kAccent.withValues(alpha: filled ? 1 : 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: filled ? Colors.white : _kAccent),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: filled ? Colors.white : _kAccent)),
          ],
        ),
      ),
    );
  }

  Widget _buildPieceCard(int index, _PieceForm piece) {
    return Container(
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(kCardRadius),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _kAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(Icons.meeting_room_outlined, size: 16, color: _kAccent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Pièce ${index + 1}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800, color: kValueColor)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                  onPressed: () => setState(() {
                    _pieces.removeAt(index).dispose();
                  }),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: kBorderColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CField(
                  controller: piece.nom,
                  label: 'Nom de la pièce',
                  accentColor: _kAccent,
                ),
                kGap,
                _etatDrop('Sol', piece.etatSol, (v) => setState(() => piece.etatSol = v)),
                kGapSm,
                _etatDrop('Murs', piece.etatMurs, (v) => setState(() => piece.etatMurs = v)),
                kGapSm,
                _etatDrop('Plafond', piece.etatPlafond, (v) => setState(() => piece.etatPlafond = v)),
                kGapSm,
                _etatDrop('Fenêtres', piece.etatFenetres, (v) => setState(() => piece.etatFenetres = v)),
                kGapSm,
                _etatDrop('Portes', piece.etatPortes, (v) => setState(() => piece.etatPortes = v)),
                kGapSm,
                _etatDrop('Électricité', piece.etatElectricite, (v) => setState(() => piece.etatElectricite = v)),
                kGapSm,
                _etatDrop('Éclairage', piece.etatEclairage, (v) => setState(() => piece.etatEclairage = v)),
                kGapSm,
                _etatDrop('Propreté', piece.proprete, (v) => setState(() => piece.proprete = v)),
                kGap,
                CToggle(
                  title: 'Présence d\'humidité',
                  value: piece.humidite,
                  accentColor: _kAccent,
                  onChanged: (v) => setState(() => piece.humidite = v),
                ),
                kGapSm,
                CToggle(
                  title: 'Dégradations constatées',
                  value: piece.degradations,
                  accentColor: _kAccent,
                  onChanged: (v) => setState(() => piece.degradations = v),
                ),
                kGap,
                CField(
                  controller: piece.observations,
                  label: 'Observations',
                  accentColor: _kAccent,
                  required: false,
                  maxLines: 2,
                  hint: 'Détails, fissures, traces…',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _etatDrop(String label, String? value, ValueChanged<String?> onChanged) {
    return CDropdown<String>(
      label: label,
      value: value ?? 'Bon',
      accentColor: _kAccent,
      items: _kEtatValues
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }

  // ─── Étape 3 ───────────────────────────────────────────────────────────────
  Widget _buildSignature() {
    return Column(
      children: [
        CSection(
          title: 'Récapitulatif',
          icon: Icons.summarize_rounded,
          accentColor: _kAccent,
          children: [
            CSummaryRow(
              label: 'Contrat',
              value: widget.contrat.numeroContrat ?? '—',
              accentColor: _kAccent,
              icon: Icons.description_outlined,
            ),
            CSummaryRow(
              label: 'Date',
              value: _date != null
                  ? DateFormat('dd/MM/yyyy').format(_date!)
                  : '—',
              accentColor: _kAccent,
              icon: Icons.event_rounded,
            ),
            CSummaryRow(
              label: 'Heure',
              value: _heure != null
                  ? '${_heure!.hour.toString().padLeft(2, '0')}:${_heure!.minute.toString().padLeft(2, '0')}'
                  : '—',
              accentColor: _kAccent,
              icon: Icons.access_time_rounded,
            ),
            CSummaryRow(
              label: 'Pièces inspectées',
              value: '${_pieces.length}',
              accentColor: _kAccent,
              icon: Icons.meeting_room_outlined,
            ),
          ],
        ),
        kGap,
        CSection(
          title: 'Signature du bailleur',
          icon: Icons.draw_rounded,
          accentColor: _kAccent,
          subtitle: 'Signez dans le cadre ci-dessous',
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: kBorderColor, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Signature(
                  controller: _signatureController,
                  height: 180,
                  backgroundColor: kSubtleColor,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
                label: const Text('Effacer', style: TextStyle(color: Colors.grey)),
                onPressed: () => _signatureController.clear(),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _consent = !_consent),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _consent ? _kAccent : Colors.white,
                      border: Border.all(color: _consent ? _kAccent : Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: _consent
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Je certifie l\'exactitude des informations de cet état des lieux.',
                      style: TextStyle(fontSize: 12, color: kValueColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

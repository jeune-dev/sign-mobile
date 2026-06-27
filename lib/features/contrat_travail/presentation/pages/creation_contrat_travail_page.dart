import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
import 'package:sign_application/features/client/domain/entities/client.dart';
import 'package:sign_application/features/client/presentation/bloc/client_bloc.dart';
import 'package:sign_application/features/client/presentation/bloc/client_event.dart';
import 'package:sign_application/features/client/presentation/bloc/client_state.dart';
import '../bloc/contrat_travail_bloc.dart';
import '../bloc/contrat_travail_event.dart';
import '../bloc/contrat_travail_state.dart';
import 'package:toastification/toastification.dart';
import 'package:sign_application/core/widgets/toastNotif.dart';

class CreationContratTravailPage extends StatefulWidget {
  const CreationContratTravailPage({super.key});

  @override
  State<CreationContratTravailPage> createState() => _CreationContratTravailPageState();
}

class _CreationContratTravailPageState extends State<CreationContratTravailPage> {
  final _formKey = GlobalKey<FormState>();
  final _posteCtrl = TextEditingController();
  final _lieuCtrl = TextEditingController();
  final _salaireCtrl = TextEditingController();
  final _nbrCongesCtrl = TextEditingController();
  final _clientSearchCtrl = TextEditingController();

  String _typeContrat = 'CDI';
  String _moyenPaiement = 'Virement bancaire';
  String _remunerationFeries = 'rémunérés';
  String _remunerationMaladie = 'rémunérés';
  bool _avanceSalaire = false;
  DateTime? _dateDebut;
  DateTime? _dateFin;
  Client? _selectedClient;
  File? _signatureImage;

  // Planning : liste de { jour, debut, fin }
  final List<_JourTravail> _planning = [
    _JourTravail(jour: 'Lundi'),
  ];

  static const _jours = ['Lundi','Mardi','Mercredi','Jeudi','Vendredi','Samedi','Dimanche'];

  static const _minutes = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55];

  Future<TimeOfDay?> _pickTime({required String title, TimeOfDay? initial}) async {
    final initH = initial?.hour ?? 8;
    final initM = initial?.minute ?? 0;
    int selHour = initH;
    int selMin = _minutes.contains(initM) ? initM : 0;

    final hourCtrl = FixedExtentScrollController(initialItem: initH);
    final minCtrl  = FixedExtentScrollController(
        initialItem: _minutes.indexOf(selMin).clamp(0, _minutes.length - 1));

    return showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final h = selHour.toString().padLeft(2, '0');
          final m = selMin.toString().padLeft(2, '0');
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header noir
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$h : $m',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                letterSpacing: 1.5)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Légendes
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('Heure',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                              letterSpacing: 0.5)),
                      Text('Minute',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                              letterSpacing: 0.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Roues défilantes
                SizedBox(
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Bande de sélection
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.center,
                          child: Container(
                            height: 52,
                            margin: const EdgeInsets.symmetric(horizontal: 40),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: Colors.grey[200]!, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Roue heures
                          SizedBox(
                            width: 110,
                            child: ListWheelScrollView.useDelegate(
                              controller: hourCtrl,
                              itemExtent: 52,
                              perspective: 0.003,
                              diameterRatio: 1.8,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (i) =>
                                  setS(() => selHour = i),
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: 24,
                                builder: (_, i) {
                                  final sel = i == selHour;
                                  return Center(
                                    child: Text(
                                      i.toString().padLeft(2, '0'),
                                      style: TextStyle(
                                        fontSize: sel ? 28 : 20,
                                        fontWeight: sel
                                            ? FontWeight.w900
                                            : FontWeight.w400,
                                        color: sel
                                            ? Colors.black
                                            : Colors.grey[400],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          // Séparateur
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: 4),
                            child: Text(':',
                                style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.grey[700])),
                          ),
                          // Roue minutes
                          SizedBox(
                            width: 110,
                            child: ListWheelScrollView(
                              controller: minCtrl,
                              itemExtent: 52,
                              perspective: 0.003,
                              diameterRatio: 1.8,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (i) =>
                                  setS(() => selMin = _minutes[i]),
                              children: _minutes.map((mm) {
                                final sel = mm == selMin;
                                return Center(
                                  child: Text(
                                    mm.toString().padLeft(2, '0'),
                                    style: TextStyle(
                                      fontSize: sel ? 28 : 20,
                                      fontWeight: sel
                                          ? FontWeight.w900
                                          : FontWeight.w400,
                                      color: sel
                                          ? Colors.black
                                          : Colors.grey[400],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Bouton confirmer
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(
                          ctx,
                          TimeOfDay(
                              hour: selHour, minute: selMin)),
                      child: Text(
                        'Confirmer  $h h $m',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Affichage UI : "08h30"
  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2,'0')}h${t.minute.toString().padLeft(2,'0')}';

  // Stockage BDD : "08:30:00"
  String _fmtTimeBd(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}:00';

  Widget _buildPlanningSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre + bouton ajouter
        Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF00C896).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.calendar_month_outlined,
                  color: Color(0xFF00C896), size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Planning hebdomadaire *',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
            const Spacer(),
            GestureDetector(
              onTap: () {
                // Trouver le prochain jour non utilisé
                final utilises = _planning.map((j) => j.jour).toSet();
                final suivant = _jours.firstWhere(
                  (j) => !utilises.contains(j),
                  orElse: () => _jours[0],
                );
                setState(() => _planning.add(_JourTravail(jour: suivant)));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text('Ajouter', style: TextStyle(color: Colors.white,
                        fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // En-tête colonnes
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Expanded(flex: 3, child: Text('Jour',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54))),
              const SizedBox(width: 8),
              const Expanded(flex: 3, child: Text('Heure début',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54))),
              const SizedBox(width: 8),
              const Expanded(flex: 3, child: Text('Heure fin',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54))),
              const SizedBox(width: 36),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Lignes de planning
        ..._planning.asMap().entries.map((entry) {
          final i = entry.key;
          final j = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                // Dropdown jour
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: j.jour,
                        isExpanded: true,
                        style: const TextStyle(fontSize: 12, color: Colors.black87,
                            fontWeight: FontWeight.w600),
                        items: _jours.map((jour) => DropdownMenuItem(
                          value: jour,
                          child: Text(jour, style: const TextStyle(fontSize: 12)),
                        )).toList(),
                        onChanged: (v) => setState(() => _planning[i] = _JourTravail(
                          jour: v!, debut: j.debut, fin: j.fin)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Heure début
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: () async {
                      final t = await _pickTime(title: 'Heure de début', initial: j.debut ?? const TimeOfDay(hour: 8, minute: 0));
                      if (t != null) setState(() => _planning[i] = _JourTravail(
                        jour: j.jour, debut: t, fin: j.fin));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
                      decoration: BoxDecoration(
                        color: j.debut != null ? const Color(0xFF00C896).withOpacity(0.08) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: j.debut != null
                            ? const Color(0xFF00C896).withOpacity(0.4) : Colors.grey[200]!),
                      ),
                      child: Text(
                        j.debut != null ? _fmtTime(j.debut!) : '—',
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: j.debut != null ? const Color(0xFF00C896) : Colors.grey[400],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Heure fin
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: () async {
                      final t = await _pickTime(title: 'Heure de fin', initial: j.fin ?? const TimeOfDay(hour: 17, minute: 0));
                      if (t != null) setState(() => _planning[i] = _JourTravail(
                        jour: j.jour, debut: j.debut, fin: t));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
                      decoration: BoxDecoration(
                        color: j.fin != null ? Colors.red.withOpacity(0.06) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: j.fin != null
                            ? Colors.red.withOpacity(0.3) : Colors.grey[200]!),
                      ),
                      child: Text(
                        j.fin != null ? _fmtTime(j.fin!) : '—',
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: j.fin != null ? Colors.red[400] : Colors.grey[400],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Supprimer
                GestureDetector(
                  onTap: _planning.length > 1
                      ? () => setState(() => _planning.removeAt(i))
                      : null,
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: _planning.length > 1 ? Colors.red[50] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.close_rounded,
                      size: 14,
                      color: _planning.length > 1 ? Colors.red[400] : Colors.grey[300],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  @override
  void dispose() {
    _posteCtrl.dispose(); _lieuCtrl.dispose();
    _salaireCtrl.dispose(); _nbrCongesCtrl.dispose(); _clientSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openSignaturePad() async {
    final controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Votre signature', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8FA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Signature(controller: controller, width: double.infinity, height: 180),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Dessinez votre signature ci-dessus', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            ],
          ),
          actions: [
            TextButton(onPressed: () => controller.clear(), child: const Text('Effacer', style: TextStyle(color: Color(0xFF6B7280)))),
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler', style: TextStyle(color: Color(0xFF6B7280)))),
            ElevatedButton(
              onPressed: () async {
                if (controller.isEmpty) return;
                final data = await controller.toPngBytes();
                if (!dialogContext.mounted) return;
                if (data != null) {
                  final tempDir = await getTemporaryDirectory();
                  final file = File('${tempDir.path}/sig_travail_${DateTime.now().millisecondsSinceEpoch}.png');
                  await file.writeAsBytes(data);
                  if (mounted) setState(() => _signatureImage = file);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Valider'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _pickDate({required void Function(DateTime) onPicked, DateTime? initial}) async {
    final dt = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (dt != null) onPicked(dt);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClient == null) {
      showToast(context, 'Champ requis', 'Veuillez sélectionner un salarié', ToastificationType.error);
      return;
    }
    if (_dateDebut == null) {
      showToast(context, 'Champ requis', 'Veuillez sélectionner la date de début', ToastificationType.error);
      return;
    }
    final planningInvalide = _planning.any((j) => j.debut == null || j.fin == null);
    if (_planning.isEmpty || planningInvalide) {
      showToast(context, 'Planning incomplet', 'Veuillez renseigner les heures pour chaque jour de travail', ToastificationType.error);
      return;
    }
    if (_signatureImage == null) {
      showToast(context, 'Signature requise', 'Veuillez apposer votre signature', ToastificationType.error);
      return;
    }
    final sigBase64 = base64Encode(await _signatureImage!.readAsBytes());
    if (!mounted) return;

    context.read<ContratTravailBloc>().add(CreerContratTravailEvent({
      'salarieId': _selectedClient!.id,
      'poste': _posteCtrl.text.trim(),
      'type_contrat': _typeContrat,
      'lieu_travail': _lieuCtrl.text.trim(),
      'jour_travail': _planning.map((j) => {
        'jour':  j.jour,
        'debut': _fmtTimeBd(j.debut!),
        'fin':   _fmtTimeBd(j.fin!),
      }).toList(),
      'date_debut': _dateDebut!.toIso8601String().substring(0, 10),
      if (_dateFin != null) 'date_fin': _dateFin!.toIso8601String().substring(0, 10),
      'salaire_mensuel': double.tryParse(_salaireCtrl.text) ?? 0,
      'moyen_paiement': _moyenPaiement,
      'nbr_jours_conges': int.tryParse(_nbrCongesCtrl.text.trim()) ?? 0,
      'remuneration_jours_feries': _remunerationFeries,
      'remuneration_absences_maladie': _remunerationMaladie,
      'avance_salaire': _avanceSalaire,
      'missions': [],
      'signature_employeur': sigBase64,
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Nouveau contrat de travail', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: BlocListener<ContratTravailBloc, ContratTravailState>(
        listener: (context, state) {
          if (state is ContratTravailSuccess) {
            showToast(context, 'Contrat créé', 'Le contrat de travail a été créé avec succès.', ToastificationType.success);
            Navigator.pop(context);
          }
          if (state is ContratTravailError) {
            showToast(context, 'Erreur', state.message, ToastificationType.error);
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Salarié', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              if (_selectedClient != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${_selectedClient!.prenom} ${_selectedClient!.nom}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _selectedClient = null),
                        child: const Icon(Icons.close, color: Colors.white70, size: 18),
                      ),
                    ],
                  ),
                )
              else ...[
                TextField(
                  controller: _clientSearchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un salarié...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.black),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  onChanged: (v) {
                    if (v.length >= 2) context.read<ClientBloc>().add(RechercherClientsEvent(v));
                  },
                ),
                BlocBuilder<ClientBloc, ClientState>(
                  builder: (context, state) {
                    if (state is ClientsRechercheLoaded && state.clients.isNotEmpty) {
                      return Container(
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                        child: Column(
                          children: state.clients.take(5).map((client) => ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.black,
                              child: Text(
                                client.prenom.isNotEmpty ? client.prenom[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                            title: Text('${client.prenom} ${client.nom}', style: const TextStyle(fontSize: 13)),
                            onTap: () {
                              setState(() => _selectedClient = client);
                              _clientSearchCtrl.clear();
                            },
                          )).toList(),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
              const SizedBox(height: 20),
              const Text('Informations du poste', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              _field(_posteCtrl, 'Poste *'),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _typeContrat,
                decoration: _dec('Type de contrat *'),
                items: const [
                  DropdownMenuItem(value: 'CDI', child: Text('CDI')),
                  DropdownMenuItem(value: 'CDD', child: Text('CDD')),
                  DropdownMenuItem(value: 'Stage', child: Text('Stage')),
                  DropdownMenuItem(value: 'Freelance', child: Text('Freelance')),
                  DropdownMenuItem(value: 'Intérim', child: Text('Intérim')),
                ],
                onChanged: (v) => setState(() => _typeContrat = v!),
              ),
              const SizedBox(height: 14),
              _field(_lieuCtrl, 'Lieu de travail *'),
              const SizedBox(height: 20),
              _buildPlanningSection(),
              const SizedBox(height: 14),
              _datePicker('Date de début *', _dateDebut, (dt) => setState(() => _dateDebut = dt)),
              const SizedBox(height: 14),
              _datePicker('Date de fin (optionnel)', _dateFin, (dt) => setState(() => _dateFin = dt), required: false),
              const SizedBox(height: 14),
              _field(_salaireCtrl, 'Salaire mensuel *', keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _moyenPaiement,
                decoration: _dec('Moyen de paiement *'),
                items: const [
                  DropdownMenuItem(value: 'Espèces', child: Text('Espèces')),
                  DropdownMenuItem(value: 'Virement bancaire', child: Text('Virement bancaire')),
                  DropdownMenuItem(value: 'Mobile Money', child: Text('Mobile Money')),
                  DropdownMenuItem(value: 'Chèque', child: Text('Chèque')),
                  DropdownMenuItem(value: 'ALL', child: Text('Tout mode de paiement')),
                  DropdownMenuItem(value: 'Autre', child: Text('Autre')),
                ],
                onChanged: (v) => setState(() => _moyenPaiement = v!),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _remunerationFeries,
                decoration: _dec('Rémunération jours fériés *'),
                items: const [
                  DropdownMenuItem(value: 'rémunérés', child: Text('Rémunérés')),
                  DropdownMenuItem(value: 'non rémunérés', child: Text('Non rémunérés')),
                  DropdownMenuItem(value: 'travail_effectif', child: Text('Travail effectif')),
                ],
                onChanged: (v) => setState(() => _remunerationFeries = v!),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _remunerationMaladie,
                decoration: _dec('Rémunération absences maladie *'),
                items: const [
                  DropdownMenuItem(value: 'rémunérés', child: Text('Rémunérées')),
                  DropdownMenuItem(value: 'non rémunérés', child: Text('Non rémunérées')),
                  DropdownMenuItem(value: 'sous_conditions', child: Text('Sous conditions')),
                ],
                onChanged: (v) => setState(() => _remunerationMaladie = v!),
              ),
              const SizedBox(height: 14),
              _field(_nbrCongesCtrl, 'Nombre de jours de congés', required: false, keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Avance sur salaire possible', style: TextStyle(fontWeight: FontWeight.w600)),
                value: _avanceSalaire,
                activeColor: Colors.black,
                onChanged: (v) => setState(() => _avanceSalaire = v),
              ),
              const SizedBox(height: 24),
              const Text('Votre signature', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _openSignaturePad,
                child: Container(
                  height: 110,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: const Color(0xFFF8F8FA),
                    border: Border.all(
                      color: _signatureImage != null ? Colors.black : const Color(0xFFE5E7EB),
                      width: _signatureImage != null ? 2 : 1,
                    ),
                  ),
                  child: _signatureImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_signatureImage!, fit: BoxFit.contain),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.draw_outlined, size: 28, color: Colors.black54),
                            SizedBox(height: 6),
                            Text('Signez ici', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13)),
                            Text('Touchez pour ouvrir le pad de signature', style: TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 32),
              BlocBuilder<ContratTravailBloc, ContratTravailState>(
                builder: (context, state) {
                  final isLoading = state is ContratTravailLoading;
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Créer le contrat', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _datePicker(String label, DateTime? value, void Function(DateTime) onPicked, {bool required = true}) {
    return GestureDetector(
      onTap: () => _pickDate(onPicked: onPicked, initial: value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              value != null ? value.toIso8601String().substring(0, 10) : label,
              style: TextStyle(color: value != null ? Colors.black : Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {
    bool required = true, int maxLines = 1, TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: _dec(label),
      validator: required ? (v) => (v == null || v.isEmpty) ? 'Ce champ est requis' : null : null,
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  );
}


// Modèle local pour une ligne du planning
class _JourTravail {
  final String jour;
  final TimeOfDay? debut;
  final TimeOfDay? fin;
  const _JourTravail({required this.jour, this.debut, this.fin});
}

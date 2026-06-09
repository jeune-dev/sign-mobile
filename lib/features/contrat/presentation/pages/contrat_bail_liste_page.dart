import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sign_application/core/config/env.dart';
import 'package:sign_application/core/utils/download_helper.dart';
import 'package:sign_application/core/widgets/pdf_viewer_page.dart';
import 'package:sign_application/features/contrat/domain/entities/contrat_bail.dart';
import 'package:sign_application/features/contrat/presentation/bloc/contrat_bloc.dart';
import 'package:sign_application/features/contrat/presentation/bloc/contrat_event.dart';
import 'package:sign_application/features/contrat/presentation/bloc/contrat_state.dart';
import 'package:sign_application/features/contrat/presentation/pages/creation_contrat_bail_page.dart';
import 'package:sign_application/injection_container.dart' as di;

class ContratBailListePage extends StatefulWidget {
  const ContratBailListePage({super.key});

  @override
  State<ContratBailListePage> createState() => _ContratBailListePageState();
}

class _ContratBailListePageState extends State<ContratBailListePage> {
  int _statsTotal = 0, _statsSignes = 0, _statsEnAttente = 0;
  bool _statsLoading = true;
  final Set<String> _downloading = {};
  String _pendingTitre = '';
  ContratsLoaded? _lastLoaded;

  @override
  void initState() {
    super.initState();
    context.read<ContratBloc>().add(LoadContratsImmobilier());
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _statsLoading = true);
    try {
      final resp = await di.sl<Dio>().get(Env.contratBailStats);
      final data = resp.data['data'] as Map<String, dynamic>? ?? {};
      if (!mounted) return;
      setState(() {
        _statsTotal     = (data['total']     as num?)?.toInt() ?? 0;
        _statsSignes    = (data['signes']    as num?)?.toInt() ?? 0;
        _statsEnAttente = (data['enAttente'] as num?)?.toInt() ?? 0;
        _statsLoading   = false;
      });
    } catch (_) {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  void _ouvrirContrat(ContratBail c) {
    _pendingTitre = c.numeroContrat ?? c.id;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 60),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30)]),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.black87, strokeWidth: 2.5),
              SizedBox(height: 18),
              Text('Ouverture…', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
    context.read<ContratBloc>().add(TelechargerContratEvent(c.id));
  }

  Future<void> _saveAndOpen(List<int> bytes, String id) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/bail_$id.pdf');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => PdfViewerPage(
          filePath: file.path,
          titre: _pendingTitre.isNotEmpty ? _pendingTitre : id,
        ),
      ));
      if (mounted) {
        context.read<ContratBloc>().add(LoadContratsImmobilier());
        _loadStats();
      }
    } catch (e) {
      if (mounted) showDownloadErrorSnackBar(context, e.toString());
    }
  }

  Future<void> _telecharger(ContratBail c) async {
    if (_downloading.contains(c.id)) return;
    setState(() => _downloading.add(c.id));
    try {
      final resp = await di.sl<Dio>().get(
        '${Env.contratBailTelecharger}/${c.id}',
        options: Options(responseType: ResponseType.bytes),
      );
      if (resp.statusCode != 200) throw Exception('Erreur ${resp.statusCode}');
      final Uint8List bytes = resp.data is Uint8List
          ? resp.data
          : Uint8List.fromList(List<int>.from(resp.data));
      final name = '${(c.numeroContrat ?? c.id).replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '_')}.pdf';
      final path = await savePdfToDownloads(bytes, name);
      if (!mounted) return;
      showDownloadSuccessSnackBar(context, name, path);
    } catch (e) {
      if (!mounted) return;
      showDownloadErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _downloading.remove(c.id));
    }
  }

  String _fmt(String? d) {
    if (d == null || d.isEmpty) return '—';
    try { return DateFormat('dd/MM/yyyy').format(DateTime.parse(d)); }
    catch (_) { return d; }
  }

  String _montant(dynamic v, String devise) {
    if (v == null) return '—';
    try { return '${NumberFormat('#,###', 'fr_FR').format(num.parse(v.toString())).replaceAll(',', ' ')} $devise'; }
    catch (_) { return '$v $devise'; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: BlocListener<ContratBloc, ContratState>(
        listener: (ctx, state) {
          if (state is ContratsLoaded) _lastLoaded = state;
          if (state is ContratBytes) {
            if (Navigator.canPop(context)) Navigator.pop(context);
            _saveAndOpen(state.bytes, state.contratId);
          }
          if (state is ContratError) {
            if (Navigator.canPop(context)) Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red[400],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ));
          }
        },
        child: BlocBuilder<ContratBloc, ContratState>(
          builder: (ctx, state) {
            final loading = state is ContratLoading && _lastLoaded == null;
            final eff = state is ContratsLoaded ? state
                : (state is! ContratError && _lastLoaded != null) ? _lastLoaded! : state;
            final contrats = eff is ContratsLoaded ? eff.contrats : <ContratBail>[];

            return Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2.5))
                      : state is ContratError && contrats.isEmpty
                          ? _buildError(state.message)
                          : RefreshIndicator(
                              color: Colors.black87,
                              onRefresh: () async {
                                context.read<ContratBloc>().add(LoadContratsImmobilier());
                                _loadStats();
                              },
                              child: contrats.isEmpty ? _buildEmpty()
                                  : ListView.separated(
                                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                                      itemCount: contrats.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                                      itemBuilder: (_, i) => _buildCard(contrats[i]),
                                    ),
                            ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CreationContratPage()))
            .then((_) { context.read<ContratBloc>().add(LoadContratsImmobilier()); _loadStats(); }),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouveau', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildTopBar() {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, top + 14, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.15))),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Contrats de bail',
                        style: TextStyle(color: Colors.white, fontSize: 20,
                            fontWeight: FontWeight.w900, letterSpacing: -0.5, height: 1.1)),
                    const SizedBox(height: 2),
                    Text('Location immobilière',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.home_work_outlined, color: Colors.white, size: 14),
                  SizedBox(width: 5),
                  Text('Immobilier',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _statBadge('Total', _statsTotal),
              const SizedBox(width: 10),
              _statBadge('Signés', _statsSignes, color: Colors.green),
              const SizedBox(width: 10),
              _statBadge('En attente', _statsEnAttente, color: const Color(0xFFFFB347)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String label, int value, {Color color = Colors.white}) {
    final bg = color == Colors.white
        ? Colors.white.withOpacity(0.12)
        : color.withOpacity(0.25);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            _statsLoading
                ? SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(color: color, strokeWidth: 2))
                : Text('$value',
                    style: TextStyle(color: color, fontSize: 22,
                        fontWeight: FontWeight.w900, height: 1)),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(color: color.withOpacity(0.7),
                    fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(ContratBail c) {
    final isSigne = c.statut == 'signe';
    final statusColor = isSigne ? Colors.green : const Color(0xFFFFB347);
    final statusLabel = isSigne ? 'Signé' : 'En attente de signature';
    final isDown = _downloading.contains(c.id);
    final locataires = c.locataires
        ?.map((l) => '${l['prenom'] ?? ''} ${l['nom'] ?? ''}').join(', ')
        ?? '—';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                      color: Colors.black, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.home_work_outlined, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.numeroContrat ?? '—',
                          style: const TextStyle(fontWeight: FontWeight.w800,
                              fontSize: 14, color: Colors.black87)),
                      const SizedBox(height: 3),
                      Row(children: [
                        Icon(Icons.location_on_outlined, size: 11, color: Colors.grey[400]),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${c.bienAdresse ?? ''}${c.bienVille != null ? " · ${c.bienVille}" : ""}'.trim(),
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(color: statusColor,
                          fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey[100], height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(children: [
                  Expanded(child: _chip(Icons.monetization_on_outlined, 'Loyer mensuel',
                      _montant(c.loyerMensuel, c.devise ?? 'FCFA'))),
                  const SizedBox(width: 10),
                  Expanded(child: _chip(Icons.calendar_today_outlined, 'Début bail',
                      _fmt(c.dateDebutBail))),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _chip(Icons.home_outlined, 'Type', c.bienType ?? '—')),
                  const SizedBox(width: 10),
                  Expanded(child: _chip(Icons.person_outline, 'Locataire', locataires)),
                ]),
              ],
            ),
          ),
          Divider(color: Colors.grey[100], height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: isDown ? null : () => _telecharger(c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!)),
                      child: isDown
                          ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              SizedBox(width: 14, height: 14,
                                  child: CircularProgressIndicator(color: Colors.black54, strokeWidth: 2)),
                              SizedBox(width: 8),
                              Text('Téléchargement…',
                                  style: TextStyle(color: Colors.black45, fontSize: 12, fontWeight: FontWeight.w600)),
                            ])
                          : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.download_rounded, size: 16, color: Colors.black54),
                              SizedBox(width: 6),
                              Text('Télécharger',
                                  style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w700)),
                            ]),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _ouvrirContrat(c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                          color: Colors.black, borderRadius: BorderRadius.circular(12)),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.open_in_new_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text('Voir Contrat de Bail',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 9, color: Colors.black38, fontWeight: FontWeight.w500)),
                const SizedBox(height: 1),
                Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black87),
                    overflow: TextOverflow.ellipsis, maxLines: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() => ListView(children: [
    const SizedBox(height: 80),
    Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 72, height: 72,
            decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
            child: Icon(Icons.home_work_outlined, size: 36, color: Colors.grey[400])),
        const SizedBox(height: 16),
        Text('Aucun contrat de bail',
            style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Créez votre premier bail', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
      ]),
    ),
  ]);

  Widget _buildError(String message) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 64, height: 64,
          decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
          child: Icon(Icons.error_outline, color: Colors.red[300], size: 32)),
      const SizedBox(height: 14),
      const Text('Erreur de chargement',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      const SizedBox(height: 6),
      Text(message, style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
      const SizedBox(height: 20),
      GestureDetector(
        onTap: () { context.read<ContratBloc>().add(LoadContratsImmobilier()); _loadStats(); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
          child: const Text('Réessayer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ),
    ]),
  );
}

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
import 'package:sign_application/injection_container.dart' as di;
import '../bloc/contrat_travail_bloc.dart';
import '../bloc/contrat_travail_event.dart';
import '../bloc/contrat_travail_state.dart';
import '../../domain/entities/contrat_travail.dart';
import 'creation_contrat_travail_page.dart';

class ContratsTravailListePage extends StatefulWidget {
  const ContratsTravailListePage({super.key});

  @override
  State<ContratsTravailListePage> createState() =>
      _ContratsTravailListePageState();
}

class _ContratsTravailListePageState extends State<ContratsTravailListePage> {
  // Stats depuis l'API
  int _statsTotal     = 0;
  int _statsSignes    = 0;
  int _statsEnAttente = 0;
  bool _statsLoading  = true;

  // Suivi des téléchargements
  final Set<String> _downloading = {};
  String _pendingTitreContrat    = '';

  // Cache liste pour éviter l'écran vide pendant reload
  ContratsTravailLoaded? _lastLoaded;

  @override
  void initState() {
    super.initState();
    context.read<ContratTravailBloc>().add(LoadContratsTravail());
    _loadStats();
  }

  // ── Stats API ─────────────────────────────────────────────────────────────
  Future<void> _loadStats() async {
    setState(() => _statsLoading = true);
    try {
      final resp = await di.sl<Dio>().get(Env.contratTravailStats);
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

  // ── Ouvrir PDF ────────────────────────────────────────────────────────────
  void _ouvrirContrat(ContratTravail contrat) {
    _pendingTitreContrat = contrat.numeroContrat ?? contrat.id;
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
              Text('Ouverture…', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
    context.read<ContratTravailBloc>().add(TelechargerContratTravailEvent(contrat.id));
  }

  Future<void> _handleBytes(List<int> bytes, String contratId) async {
    try {
      final dir  = await getTemporaryDirectory();
      final file = File('${dir.path}/ct_$contratId.pdf');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerPage(
            filePath: file.path,
            titre: _pendingTitreContrat.isNotEmpty
                ? _pendingTitreContrat
                : contratId,
          ),
        ),
      );
      if (mounted) {
        context.read<ContratTravailBloc>().add(LoadContratsTravail());
        _loadStats();
      }
    } catch (e) {
      if (mounted) showDownloadErrorSnackBar(context, e.toString());
    }
  }

  // ── Télécharger dans Downloads ────────────────────────────────────────────
  Future<void> _telechargerContrat(ContratTravail contrat) async {
    if (_downloading.contains(contrat.id)) return;
    setState(() => _downloading.add(contrat.id));
    try {
      final url = '${Env.contratTravailTelecharger}/${contrat.id}/download';
      final resp = await di.sl<Dio>().get(url,
          options: Options(responseType: ResponseType.bytes));
      if (resp.statusCode != 200) {
        throw Exception('Erreur serveur (${resp.statusCode})');
      }
      final Uint8List bytes = resp.data is Uint8List
          ? resp.data
          : Uint8List.fromList(List<int>.from(resp.data));
      final fileName =
          '${(contrat.numeroContrat ?? contrat.id).replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '_')}.pdf';
      final savedPath = await savePdfToDownloads(bytes, fileName);
      if (!mounted) return;
      showDownloadSuccessSnackBar(context, fileName, savedPath);
    } catch (e) {
      if (!mounted) return;
      showDownloadErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _downloading.remove(contrat.id));
    }
  }

  String _formatDate(String? d) {
    if (d == null || d.isEmpty) return '—';
    try { return DateFormat('dd/MM/yyyy').format(DateTime.parse(d)); }
    catch (_) { return d; }
  }

  String _formatMontant(double? v) {
    if (v == null) return '—';
    return '${NumberFormat('#,###', 'fr_FR').format(v).replaceAll(',', ' ')} FCFA';
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: BlocListener<ContratTravailBloc, ContratTravailState>(
        listener: (context, state) {
          if (state is ContratsTravailLoaded) _lastLoaded = state;
          if (state is ContratTravailBytes) {
            if (Navigator.canPop(context)) Navigator.pop(context);
            _handleBytes(state.bytes, state.contratId);
          }
          if (state is ContratTravailError) {
            if (Navigator.canPop(context)) Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red[400],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ));
          }
          if (state is ContratTravailSuccess) {
            context.read<ContratTravailBloc>().add(LoadContratsTravail());
            _loadStats();
          }
        },
        child: BlocBuilder<ContratTravailBloc, ContratTravailState>(
          builder: (context, state) {
            final isLoading = state is ContratTravailLoading && _lastLoaded == null;
            final effectiveState = state is ContratsTravailLoaded
                ? state
                : (state is! ContratTravailError && _lastLoaded != null)
                    ? _lastLoaded!
                    : state;
            final contrats = effectiveState is ContratsTravailLoaded
                ? effectiveState.contrats
                : <ContratTravail>[];

            return Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2.5))
                      : state is ContratTravailError && contrats.isEmpty
                          ? _buildError(state.message)
                          : RefreshIndicator(
                              color: Colors.black87,
                              onRefresh: () async {
                                context.read<ContratTravailBloc>().add(LoadContratsTravail());
                                _loadStats();
                              },
                              child: contrats.isEmpty
                                  ? _buildEmpty()
                                  : ListView.separated(
                                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                                      itemCount: contrats.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                                      itemBuilder: (context, index) => _buildCard(contrats[index]),
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
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreationContratTravailPage()),
        ).then((_) {
          context.read<ContratTravailBloc>().add(LoadContratsTravail());
          _loadStats();
        }),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouveau', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Ligne retour + titre ──────────────────────────
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contrats de travail',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'CDI · CDD · Stage · Freelance',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Badge type
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00C896).withOpacity(0.8),
                      const Color(0xFF00C896).withOpacity(0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.work_outline_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 5),
                    Text('Travail', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // ── Stats depuis API ──────────────────────────────
          Row(
            children: [
              _statBadge('Total', _statsTotal, Colors.white.withOpacity(0.12), Colors.white),
              const SizedBox(width: 10),
              _statBadge('Signés', _statsSignes, const Color(0xFF00C896).withOpacity(0.25), const Color(0xFF00C896)),
              const SizedBox(width: 10),
              _statBadge('En attente', _statsEnAttente, const Color(0xFFFFB347).withOpacity(0.25), const Color(0xFFFFB347)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String label, int value, Color bg, Color fg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            _statsLoading
                ? SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(color: fg, strokeWidth: 2))
                : Text('$value',
                    style: TextStyle(
                        color: fg, fontSize: 22, fontWeight: FontWeight.w900, height: 1)),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(color: fg.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ── Card contrat travail ──────────────────────────────────────────────────
  Widget _buildCard(ContratTravail c) {
    final isSigne    = c.statut == 'signe';
    final statusColor = isSigne ? Colors.green : const Color(0xFFFFB347);
    final statusLabel = isSigne ? 'Signé' : 'En attente';

    final typeColor = _typeColor(c.typeContrat);
    final salarieNom = c.salarie != null
        ? '${c.salarie!['prenom'] ?? ''} ${c.salarie!['nom'] ?? ''}'.trim()
        : '—';
    final isDown = _downloading.contains(c.id);
    final numero = c.numeroContrat ?? c.id.substring(0, 8).toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // ── Header ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C896).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.work_outline_rounded,
                      color: Color(0xFF00C896), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(numero,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: Colors.black87)),
                      const SizedBox(height: 3),
                      if (c.poste != null)
                        Text(c.poste!,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                // Statut badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),

          Divider(color: Colors.grey[100], height: 1),

          // ── Info chips ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _infoChip(Icons.person_outline_rounded, 'Salarié',
                        salarieNom, const Color(0xFF6C63FF))),
                    const SizedBox(width: 10),
                    Expanded(child: _infoChip(Icons.monetization_on_outlined, 'Salaire',
                        _formatMontant(c.salaireMensuel), const Color(0xFF00C896))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _infoChip(Icons.badge_outlined, 'Type',
                        c.typeContrat ?? '—', typeColor)),
                    const SizedBox(width: 10),
                    Expanded(child: _infoChip(Icons.calendar_today_outlined, 'Début',
                        _formatDate(c.dateDebut), const Color(0xFFFFB347))),
                  ],
                ),
              ],
            ),
          ),

          Divider(color: Colors.grey[100], height: 1),

          // ── Boutons ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: isDown ? null : () => _telechargerContrat(c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: isDown
                          ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              SizedBox(width: 14, height: 14,
                                  child: CircularProgressIndicator(color: Colors.black54, strokeWidth: 2)),
                              SizedBox(width: 8),
                              Text('Téléchargement…', style: TextStyle(color: Colors.black45, fontSize: 12, fontWeight: FontWeight.w600)),
                            ])
                          : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.download_rounded, size: 16, color: Colors.black54),
                              SizedBox(width: 6),
                              Text('Télécharger', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w700)),
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
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.open_in_new_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text('Voir le doc', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
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

  Widget _infoChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[400], fontWeight: FontWeight.w500)),
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

  Color _typeColor(String? type) {
    switch (type) {
      case 'CDI':      return const Color(0xFF6C63FF);
      case 'CDD':      return const Color(0xFFFF6B6B);
      case 'Stage':    return const Color(0xFF4ECDC4);
      case 'Freelance':return const Color(0xFFFFB347);
      default:         return Colors.grey;
    }
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                child: Icon(Icons.work_outline_rounded, size: 36, color: Colors.grey[400]),
              ),
              const SizedBox(height: 16),
              Text('Aucun contrat de travail',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Créez votre premier contrat',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
            child: Icon(Icons.error_outline, color: Colors.red[300], size: 32),
          ),
          const SizedBox(height: 14),
          const Text('Erreur de chargement',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 6),
          Text(message, style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              context.read<ContratTravailBloc>().add(LoadContratsTravail());
              _loadStats();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
              child: const Text('Réessayer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

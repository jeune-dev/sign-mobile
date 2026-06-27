import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sign_application/core/config/contrat_type.dart';
import 'package:sign_application/core/config/env.dart';
import 'package:sign_application/core/utils/download_helper.dart';
import 'package:sign_application/core/widgets/empty_state.dart';
import 'package:sign_application/core/widgets/shimmer_list.dart';
import 'package:toastification/toastification.dart';
import 'package:sign_application/core/widgets/toastNotif.dart';
import 'package:sign_application/core/widgets/pdf_viewer_page.dart';
import 'package:sign_application/injection_container.dart' as di;
import '../bloc/autres_contrats_bloc.dart';
import '../bloc/autres_contrats_event.dart';
import '../bloc/autres_contrats_state.dart';
import '../../domain/entities/autre_contrat.dart';
import 'contrat_signature_page.dart';

class AutresContratsListePage extends StatefulWidget {
  final String type;
  final String titre;
  final Widget Function(BuildContext context) createPageBuilder;
  final String? currentUserId;

  const AutresContratsListePage({
    super.key,
    required this.type,
    required this.titre,
    required this.createPageBuilder,
    this.currentUserId,
  });

  @override
  State<AutresContratsListePage> createState() => _AutresContratsListePageState();
}

class _AutresContratsListePageState extends State<AutresContratsListePage> {
  // Stats
  int _statsTotal = 0, _statsSignes = 0, _statsEnAttente = 0;
  bool _statsLoading = true;

  final Set<String> _downloading = {};

  @override
  void initState() {
    super.initState();
    context.read<AutresContratsBloc>().add(LoadContrats(widget.type));
    _loadStats();
  }

  // ── Stats API ────────────────────────────────────────────────────────────
  Future<void> _loadStats() async {
    setState(() => _statsLoading = true);
    try {
      final resp = await di.sl<Dio>().get(Env.autresContratsStats(widget.type));
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
  void _ouvrirContrat(AutreContrat c) {
    final titre = c.numeroContrat ?? c.id;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 60),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30)
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.black87, strokeWidth: 2.5),
              SizedBox(height: 18),
              Text('Ouverture…',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
    context.read<AutresContratsBloc>().add(TelechargerContrat(widget.type, c.id, titre: titre));
  }

  Future<void> _saveAndOpen(List<int> bytes, String titre) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.type}_$titre.pdf');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerPage(filePath: file.path, titre: titre),
        ),
      );
      if (mounted) {
        context.read<AutresContratsBloc>().add(LoadContrats(widget.type));
        _loadStats();
      }
    } catch (e) {
      if (mounted) showDownloadErrorSnackBar(context, e.toString());
    }
  }

  // ── Ouvrir page de signature ─────────────────────────────────────────────
  Future<void> _ouvrirSignature(AutreContrat c) async {
    final signed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<AutresContratsBloc>(),
          child: ContratSignaturePage(contrat: c, type: widget.type),
        ),
      ),
    );
    if ((signed ?? false) && mounted) {
      context.read<AutresContratsBloc>().add(LoadContrats(widget.type));
      _loadStats();
    }
  }

  // ── Télécharger PDF ───────────────────────────────────────────────────────
  Future<void> _telecharger(AutreContrat c) async {
    if (_downloading.contains(c.id)) return;
    setState(() => _downloading.add(c.id));
    try {
      // Route backend : GET /:contratId/download (et non /telecharger)
      final url = '${Env.autresContratsBase(widget.type)}/${c.id}/download';
      final resp = await di.sl<Dio>().get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      if (resp.statusCode != 200) throw Exception('Erreur ${resp.statusCode}');
      final Uint8List bytes = resp.data is Uint8List
          ? resp.data
          : Uint8List.fromList(List<int>.from(resp.data));
      final name =
          '${(c.numeroContrat ?? c.id).replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '_')}.pdf';
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

  // ── Icône selon le type ───────────────────────────────────────────────────
  IconData _iconForType(String type) =>
      ContratTypeX.fromString(type)?.icon ?? Icons.description_outlined;

  // ── Sous-titre selon le type ──────────────────────────────────────────────
  String _subtitleForType(String type) =>
      ContratTypeX.fromString(type)?.label ?? 'Contrat';

  String _labelVoirContrat(String type) =>
      ContratTypeX.fromString(type)?.seeLabel ?? 'Voir Contrat';

  String _fmt(String? d) {
    if (d == null || d.isEmpty) return '—';
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(d));
    } catch (_) {
      return d;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: BlocConsumer<AutresContratsBloc, AutresContratsState>(
        listener: (ctx, state) {
          if (state is AutresContratsBytes) {
            if (Navigator.canPop(context)) Navigator.pop(context);
            _saveAndOpen(state.bytes, state.titre.isNotEmpty ? state.titre : state.id);
          }
          if (state is AutresContratsError) {
            if (Navigator.canPop(context)) Navigator.pop(context);
            showToast(context, 'Erreur', state.message, ToastificationType.error);
          }
        },
        builder: (ctx, state) {
          final loading = state is AutresContratsLoading;
          final contrats = state is AutresContratsListLoaded ? state.contrats : <AutreContrat>[];

          return Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: loading
                    ? const ShimmerList()
                    : state is AutresContratsError && contrats.isEmpty
                        ? _buildError(state.message)
                        : RefreshIndicator(
                            color: Colors.black87,
                            onRefresh: () async {
                              context
                                  .read<AutresContratsBloc>()
                                  .add(LoadContrats(widget.type));
                              _loadStats();
                            },
                            child: contrats.isEmpty
                                ? _buildEmpty()
                                : ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 12, 16, 100),
                                    itemCount: contrats.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (_, i) =>
                                        _buildCard(contrats[i]),
                                  ),
                          ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: widget.createPageBuilder),
        ).then((_) {
          if (!context.mounted) return;
          context.read<AutresContratsBloc>().add(LoadContrats(widget.type));
          _loadStats();
        }),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouveau',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  // ── Top bar (header noir avec stats) ─────────────────────────────────────
  Widget _buildTopBar() {
    final top = MediaQuery.of(context).padding.top;
    final icon = _iconForType(widget.type);
    final subtitle = _subtitleForType(widget.type);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
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
                  width: 40,
                  height: 40,
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
                    Text(
                      widget.titre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 14),
                    const SizedBox(width: 5),
                    const Text('Contrat',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
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
              _statBadge('En attente', _statsEnAttente,
                  color: const Color(0xFFFFB347)),
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
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            _statsLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: color, strokeWidth: 2))
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$value',
                      style: TextStyle(
                          color: color,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1),
                    ),
                  ),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ── Carte contrat ─────────────────────────────────────────────────────────
  Widget _buildCard(AutreContrat c) {
    final isSign = c.statut == 'signe';
    final statusColor = isSign ? Colors.green : const Color(0xFFFFB347);
    final statusLabel = isSign ? 'Signé' : 'En attente';
    final isDown = _downloading.contains(c.id);

    final generateurId = c.generateur?['id']?.toString();
    final estCreateur = widget.currentUserId != null && generateurId == widget.currentUserId;

    final autrePartieNom = c.autrePartie != null
        ? '${c.autrePartie!['prenom'] ?? ''} ${c.autrePartie!['nom'] ?? ''}'
            .trim()
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // ── En-tête carte ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(14)),
                  child: Icon(_iconForType(widget.type),
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.numeroContrat ??
                            'Contrat #${c.id.substring(0, 8)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Colors.black87),
                      ),
                      if (autrePartieNom != null &&
                          autrePartieNom.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.person_outline,
                                size: 11, color: Colors.grey[400]),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                autrePartieNom,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[500]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(statusLabel,
                          style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                    if (widget.currentUserId != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: estCreateur ? Colors.black.withOpacity(0.07) : Colors.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          estCreateur ? 'Créateur' : 'Reçu',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: estCreateur ? Colors.black54 : Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // ── Infos ──────────────────────────────────────────────────────
          if (c.createdAt != null) ...[
            Divider(color: Colors.grey[100], height: 1),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _chip(Icons.calendar_today_outlined,
                        'Date création', _fmt(c.createdAt)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _chip(Icons.description_outlined, 'Type',
                        _subtitleForType(widget.type)),
                  ),
                ],
              ),
            ),
          ],

          // ── Boutons actions ─────────────────────────────────────────────
          Divider(color: Colors.grey[100], height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: !estCreateur && c.statut == 'en_attente'
                // ── Destinataire / En attente → Ouvrir + Signer ──────────
                ? Row(children: [
                    // Ouvrir le contrat (lecture seule)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _ouvrirContrat(c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.visibility_outlined, size: 15, color: Colors.black54),
                              SizedBox(width: 6),
                              Text('Ouvrir', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Signer → page signature
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () => _ouvrirSignature(c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.draw_outlined, color: Colors.white, size: 15),
                              SizedBox(width: 6),
                              Text('Signer le contrat', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ])
                // ── Créateur ou déjà signé → Voir uniquement ─────────────
                : Row(children: [
                    if (estCreateur) ...[
                      Expanded(
                        child: GestureDetector(
                          onTap: isDown ? null : () => _telecharger(c),
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
                                    SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.black54, strokeWidth: 2)),
                                    SizedBox(width: 8),
                                    Text('…', style: TextStyle(color: Colors.black45, fontSize: 12)),
                                  ])
                                : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Icon(Icons.download_rounded, size: 15, color: Colors.black54),
                                    SizedBox(width: 6),
                                    Text('Télécharger', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w700)),
                                  ]),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      flex: estCreateur ? 1 : 2,
                      child: GestureDetector(
                        onTap: () => _ouvrirContrat(c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 15),
                              const SizedBox(width: 6),
                              Text(
                                c.statut == 'signe' ? 'Voir le contrat signé' : _labelVoirContrat(widget.type),
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]),
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
                Text(label,
                    style: const TextStyle(
                        fontSize: 9,
                        color: Colors.black38,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 1),
                Text(value,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() => EmptyState(
    icon: _iconForType(widget.type),
    title: 'Aucun ${widget.titre.toLowerCase()}',
    subtitle: 'Appuyez sur + pour créer votre premier contrat',
  );

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () {
              context
                  .read<AutresContratsBloc>()
                  .add(LoadContrats(widget.type));
              _loadStats();
            },
            child: const Text('Réessayer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

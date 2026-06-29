import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
import 'package:toastification/toastification.dart';

import 'package:sign_application/core/utils/download_helper.dart';
import 'package:sign_application/core/widgets/empty_state.dart';
import 'package:sign_application/core/widgets/pdf_viewer_page.dart';
import 'package:sign_application/core/widgets/shimmer_list.dart';
import 'package:sign_application/core/widgets/toastNotif.dart';
import 'package:sign_application/features/contrat/domain/entities/contrat_bail.dart';
import 'package:sign_application/features/contrat/presentation/bloc/contrat_bloc.dart';
import 'package:sign_application/features/contrat/presentation/bloc/contrat_event.dart';
import 'package:sign_application/features/contrat/presentation/bloc/contrat_state.dart';
import 'package:sign_application/features/etat_logement/domain/entities/etat_logement.dart';
import 'package:sign_application/features/etat_logement/presentation/bloc/etat_logement_bloc.dart';
import 'package:sign_application/features/etat_logement/presentation/bloc/etat_logement_event.dart';
import 'package:sign_application/features/etat_logement/presentation/bloc/etat_logement_state.dart';
import 'package:sign_application/features/etat_logement/presentation/pages/creation_etat_logement_page.dart';

const Color _kAccent = Color(0xFF059669);

class EtatsLogementListePage extends StatefulWidget {
  /// Si fourni → page rattachée à ce bail (filtre + création directe).
  /// Si null → module global : tous les états des lieux + choix du bail à la création.
  final ContratBail? contrat;

  /// Ouvre automatiquement le sélecteur de bail au démarrage (mode module).
  final bool autoSelectBail;

  const EtatsLogementListePage({
    super.key,
    this.contrat,
    this.autoSelectBail = false,
  });

  bool get isScoped => contrat != null;

  @override
  State<EtatsLogementListePage> createState() => _EtatsLogementListePageState();
}

class _EtatsLogementListePageState extends State<EtatsLogementListePage> {
  List<EtatLogement>? _etats;
  final Set<String> _downloading = {};
  static final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    context.read<EtatLogementBloc>().add(LoadEtatsLogement());
    if (widget.autoSelectBail && !widget.isScoped) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _choisirBail();
      });
    }
  }

  void _reload() => context.read<EtatLogementBloc>().add(LoadEtatsLogement());

  // ─── Téléchargement / ouverture du PDF ───────────────────────────────────────
  Future<void> _saveAndOpen(List<int> bytes, String titre) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/edl_$titre.pdf');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerPage(filePath: file.path, titre: titre),
        ),
      );
    } catch (e) {
      if (mounted) showDownloadErrorSnackBar(context, e.toString());
    }
  }

  void _ouvrir(EtatLogement e) {
    context.read<EtatLogementBloc>().add(
          TelechargerEtatLogementEvent(e.id,
              titre: e.numeroEtatDesLieux ?? e.id),
        );
  }

  // ─── Signature locataire ─────────────────────────────────────────────────────
  void _ouvrirSignature(EtatLogement e) {
    final controller = SignatureController(
      penStrokeWidth: 2,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Signature du locataire',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(e.numeroEtatDesLieux ?? '',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 16),
            Container(
              // Column en CrossAxisAlignment.start : sans largeur explicite, le pad
              // s'effondre à 0 px et reste invisible.
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Signature(
                  controller: controller,
                  width: double.infinity,
                  height: 180,
                  backgroundColor: Colors.grey.shade50,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
                label: const Text('Effacer', style: TextStyle(color: Colors.grey)),
                onPressed: () => controller.clear(),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (controller.isEmpty) {
                    showToast(sheetCtx, 'Signature manquante',
                        'Veuillez tracer la signature.',
                        ToastificationType.warning);
                    return;
                  }
                  final Uint8List? data = await controller.toPngBytes();
                  if (data == null) return;
                  final sig = 'data:image/png;base64,${base64Encode(data)}';
                  if (!sheetCtx.mounted) return;
                  Navigator.pop(sheetCtx);
                  if (!mounted) return;
                  context.read<EtatLogementBloc>().add(
                        SignerEtatLogementEvent(etatId: e.id, signature: sig),
                      );
                },
                child: const Text('Confirmer et signer',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(controller.dispose);
  }

  /// Lance la création d'un état des lieux pour un bail donné.
  Future<void> _creationPour(ContratBail bail) async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<EtatLogementBloc>(),
          child: CreationEtatLogementPage(contrat: bail),
        ),
      ),
    );
    if (created == true && mounted) _reload();
  }

  /// Bouton « Nouvel état » : scoped → bail courant ; module → choix du bail.
  void _onNouvelEtat() {
    if (widget.isScoped) {
      _creationPour(widget.contrat!);
    } else {
      _choisirBail();
    }
  }

  /// Affiche un sélecteur de contrat de bail (mode module global).
  void _choisirBail() {
    context.read<ContratBloc>().add(LoadContratsImmobilier());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (ctx, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Choisir le contrat de bail',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('L\'état des lieux sera rattaché à ce bail',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: BlocBuilder<ContratBloc, ContratState>(
                builder: (ctx, state) {
                  if (state is ContratLoading) {
                    return const Center(
                        child: CircularProgressIndicator(color: _kAccent));
                  }
                  final bails =
                      state is ContratsLoaded ? state.contrats : <ContratBail>[];
                  if (bails.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Aucun contrat de bail.\nCréez d\'abord un contrat de bail.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: bails.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final b = bails[i];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          _creationPour(b);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _kAccent.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(14),
                            border:
                                Border.all(color: _kAccent.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _kAccent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.home_work_outlined,
                                    color: _kAccent, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(b.numeroContrat ?? '—',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${b.bienAdresse ?? ''}${b.bienVille != null ? ' · ${b.bienVille}' : ''}',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey[600]),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_rounded,
                                  color: _kAccent, size: 18),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(String? d) {
    if (d == null || d.isEmpty) return '—';
    try {
      return _dateFmt.format(DateTime.parse(d));
    } catch (_) {
      return d;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: BlocConsumer<EtatLogementBloc, EtatLogementState>(
        listener: (ctx, state) {
          if (state is EtatsLogementLoaded) {
            // Mode scoped : filtre sur le bail courant. Mode module : tout.
            setState(() => _etats = widget.isScoped
                ? state.etats
                    .where((e) => e.contratId == widget.contrat!.id)
                    .toList()
                : state.etats);
          } else if (state is EtatLogementBytes) {
            _saveAndOpen(state.bytes,
                state.titre.isNotEmpty ? state.titre : state.etatId);
          } else if (state is EtatLogementSuccess) {
            showToast(ctx, 'Succès', state.message, ToastificationType.success);
            _reload();
          } else if (state is EtatLogementError) {
            showToast(ctx, 'Erreur', state.message, ToastificationType.error);
          }
        },
        builder: (ctx, state) {
          final loadingInitial = _etats == null && state is EtatLogementLoading;
          return Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: loadingInitial
                    ? const ShimmerList()
                    : RefreshIndicator(
                        color: _kAccent,
                        onRefresh: () async => _reload(),
                        child: (_etats == null || _etats!.isEmpty)
                            ? _buildEmpty()
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 16, 100),
                                itemCount: _etats!.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (_, i) => _buildCard(_etats![i]),
                              ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kAccent,
        foregroundColor: Colors.white,
        onPressed: _onNouvelEtat,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvel état',
            style: TextStyle(fontWeight: FontWeight.w700)),
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
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.15))),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('États des lieux',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1.1)),
                const SizedBox(height: 2),
                Text(
                    widget.isScoped
                        ? (widget.contrat!.numeroContrat ?? 'Contrat de bail')
                        : 'Tous vos états des lieux',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.fact_check_outlined,
                color: _kAccent, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(EtatLogement e) {
    final isSigne = e.estSigne;
    final statusColor = isSigne ? Colors.green : const Color(0xFFFFB347);
    final statusLabel = isSigne ? 'Signé' : 'En attente de signature';
    final isDown = _downloading.contains(e.id);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                      color: _kAccent, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.fact_check_outlined,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.numeroEtatDesLieux ?? '—',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: Colors.black87)),
                      const SizedBox(height: 3),
                      Row(children: [
                        Icon(Icons.event_rounded,
                            size: 11, color: Colors.grey[400]),
                        const SizedBox(width: 3),
                        Text('${_fmt(e.dateEtatDesLieux)}  ·  ${e.heureVisite ?? ''}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500])),
                      ]),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.3)),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              Expanded(
                  child: _chip(Icons.meeting_room_outlined, 'Pièces',
                      '${e.pieces.length}')),
              const SizedBox(width: 10),
              Expanded(
                  child: _chip(Icons.assignment_turned_in_outlined, 'Statut',
                      e.statut ?? '—')),
            ]),
          ),
          Divider(color: Colors.grey[100], height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: isDown ? null : () => _ouvrir(e),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!)),
                      child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.picture_as_pdf_rounded,
                                size: 16, color: Colors.black54),
                            SizedBox(width: 6),
                            Text('Voir le PDF',
                                style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ]),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSigne
                          ? Colors.green.withValues(alpha: 0.08)
                          : Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSigne
                            ? Colors.green.withValues(alpha: 0.3)
                            : Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSigne ? Icons.verified_rounded : Icons.schedule_rounded,
                          color: isSigne ? Colors.green : Colors.orange,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isSigne ? 'Locataire signé' : 'En attente locataire',
                          style: TextStyle(
                            color: isSigne ? Colors.green : Colors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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
        icon: Icons.fact_check_outlined,
        title: 'Aucun état des lieux',
        subtitle: widget.isScoped
            ? 'Créez le premier état des lieux de ce contrat avec le bouton « Nouvel état ».'
            : 'Appuyez sur « Nouvel état », puis choisissez le contrat de bail concerné.',
        accentColor: _kAccent,
        scrollable: true,
      );
}

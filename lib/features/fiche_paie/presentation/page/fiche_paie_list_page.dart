import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sign_application/core/utils/download_helper.dart';
import 'package:sign_application/core/widgets/empty_state.dart';
import 'package:sign_application/core/widgets/shimmer_list.dart';
import 'package:toastification/toastification.dart';
import 'package:sign_application/core/widgets/toastNotif.dart';
import 'package:sign_application/core/widgets/pdf_viewer_page.dart';
import 'package:sign_application/features/fiche_paie/domain/entities/fiche_paie.dart';
import '../bloc/fiche_paie_bloc.dart';
import '../bloc/fiche_paie_event.dart';
import '../bloc/fiche_paie_state.dart';
import 'creation_fiche_paie.dart';

class FichePaieListPage extends StatelessWidget {
  const FichePaieListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<FichePaieBloc>()
        ..add(const LoadFichesPaieEvent()),
      child: const _FichePaieListView(),
    );
  }
}

class _FichePaieListView extends StatefulWidget {
  const _FichePaieListView();

  @override
  State<_FichePaieListView> createState() => _FichePaieListViewState();
}

class _FichePaieListViewState extends State<_FichePaieListView> {
  final _scrollController = ScrollController();

  // Filtre actif : 'tous' | 'envoyes' | 'recus'
  String _filtre = 'tous';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  List<FichePaie> _appliquerFiltre(List<FichePaie> all) {
    switch (_filtre) {
      case 'envoyes':
        return all.where((f) => !f.estRecue).toList();
      case 'recus':
        return all.where((f) => f.estRecue).toList();
      default:
        return all;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<FichePaieBloc>().state;
      if (state is FichesPaieLoaded && state.hasMore && !state.isRefreshing) {
        context.read<FichePaieBloc>().add(LoadMoreFichesPaieEvent());
      }
    }
  }

  // mode 'view' = ouvrir le PDF ; mode 'download' = enregistrer dans Téléchargements
  Future<void> _telecharger(FichePaie fiche, String mode) async {
    final titre = fiche.numeroFiche;
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
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircularProgressIndicator(color: Color(0xFF1A1A1A), strokeWidth: 2.5),
            const SizedBox(height: 18),
            Text(mode == 'download' ? 'Téléchargement…' : 'Ouverture…',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ]),
        ),
      ),
    );
    context.read<FichePaieBloc>().add(
          TelechargerFichePaieEvent(ficheId: fiche.id ?? '', titre: titre, mode: mode),
        );
  }

  Future<void> _handleBytes(FichePaieBytes state) async {
    final fileName = 'fp_${state.titre}.pdf';
    try {
      if (state.mode == 'download') {
        final path = await savePdfToDownloads(Uint8List.fromList(state.bytes), fileName);
        if (!mounted) return;
        showDownloadSuccessSnackBar(context, fileName, path);
      } else {
        final dir  = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(state.bytes);
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfViewerPage(filePath: file.path, titre: state.titre),
          ),
        );
      }
      if (mounted) context.read<FichePaieBloc>().add(const LoadFichesPaieEvent());
    } catch (e) {
      if (mounted) showDownloadErrorSnackBar(context, e.toString());
    }
  }

  String _formatMontant(double? v) {
    if (v == null) return '—';
    return '${NumberFormat('#,###', 'fr_FR').format(v).replaceAll(',', ' ')} FCFA';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const FichePaieFormPage()))
              .then((_) {
            if (context.mounted) {
              context.read<FichePaieBloc>().add(const LoadFichesPaieEvent());
            }
          });
        },
      ),
      body: BlocListener<FichePaieBloc, FichePaieState>(
        listener: (context, state) {
          if (state is FichePaieBytes) {
            if (Navigator.canPop(context)) Navigator.pop(context);
            _handleBytes(state);
          }
          if (state is FichePaieError) {
            if (Navigator.canPop(context)) Navigator.pop(context);
            showToast(context, 'Erreur', state.message, ToastificationType.error);
          }
        },
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: BlocBuilder<FichePaieBloc, FichePaieState>(
                builder: (context, state) {
                  if (state is FichePaieLoading) {
                    return const ShimmerList(accentColor: Color(0xFF1A1A1A));
                  }
                  if (state is FichePaieError) {
                    return _buildError(context, state.message);
                  }
                  if (state is FichesPaieLoaded) {
                    final all = state.fiches;
                    if (all.isEmpty) return _buildEmpty();
                    final fiches = _appliquerFiltre(all);
                    return Column(
                      children: [
                        _buildFilterBar(all),
                        Expanded(
                          child: RefreshIndicator(
                            color: const Color(0xFF1A1A1A),
                            onRefresh: () async =>
                                context.read<FichePaieBloc>().add(const LoadFichesPaieEvent()),
                            child: fiches.isEmpty
                                ? _buildEmptyFiltre()
                                : ListView.separated(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                                    itemCount: fiches.length + (state.isRefreshing ? 1 : 0),
                                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      if (index == fiches.length) {
                                        return const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(16),
                                            child: CircularProgressIndicator(
                                                color: Color(0xFF1A1A1A), strokeWidth: 2),
                                          ),
                                        );
                                      }
                                      return _buildCard(fiches[index]);
                                    },
                                  ),
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fiches de paie',
                    style: TextStyle(
                        color: Colors.white, fontSize: 20,
                        fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                SizedBox(height: 2),
                Text('Historique de vos fiches',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.receipt_long_outlined, color: Colors.white, size: 14),
              SizedBox(width: 5),
              Text('Paie', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(FichePaie fiche) {
    final moisAnnee = '${fiche.mois} ${fiche.annee}';
    final estRecue = fiche.estRecue;
    // Contrepartie : si reçue, on affiche l'employeur (expéditeur) ; sinon le salarié.
    final contrepartie = estRecue ? fiche.employeur : fiche.salarie;
    final contrepartieNom = contrepartie != null
        ? '${contrepartie['prenom'] ?? ''} ${contrepartie['nom'] ?? ''}'.trim()
        : '';
    final ligneContrepartie = contrepartieNom.isEmpty
        ? moisAnnee
        : '$moisAnnee · ${estRecue ? 'De' : 'À'} : $contrepartieNom';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 4))],
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
                    color: const Color(0xFF1A1A1A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.receipt_long_outlined, color: Color(0xFF1A1A1A), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                          child: Text(fiche.numeroFiche,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.black87)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: estRecue ? const Color(0xFFEAF2FF) : const Color(0xFFF0FAF2),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(estRecue ? Icons.south_west_rounded : Icons.north_east_rounded,
                                size: 11, color: estRecue ? const Color(0xFF2563EB) : const Color(0xFF16A34A)),
                            const SizedBox(width: 3),
                            Text(estRecue ? 'Reçue' : 'Envoyée',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                    color: estRecue ? const Color(0xFF2563EB) : const Color(0xFF16A34A))),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: 3),
                      Text(ligneContrepartie,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1A1A1A).withValues(alpha: 0.3)),
                  ),
                  child: Text(fiche.typeContrat,
                      style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey[100], height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(child: _infoChip(Icons.monetization_on_outlined, 'Brut',
                    _formatMontant(fiche.salaireBrut), const Color(0xFF1A1A1A))),
                const SizedBox(width: 10),
                Expanded(child: _infoChip(Icons.savings_outlined, 'Net',
                    _formatMontant(fiche.salaireNet), const Color(0xFF1A1A1A))),
              ],
            ),
          ),
          Divider(color: Colors.grey[100], height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(child: _actionBtn('Voir', Icons.visibility_outlined, () => _telecharger(fiche, 'view'), filled: false)),
              const SizedBox(width: 10),
              Expanded(child: _actionBtn('Télécharger', Icons.download_rounded, () => _telecharger(fiche, 'download'), filled: true)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, VoidCallback onTap, {required bool filled}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: filled ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: filled ? const Color(0xFF1A1A1A) : const Color(0xFFE5E7EB)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: filled ? Colors.white : const Color(0xFF374151)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: filled ? Colors.white : const Color(0xFF374151))),
        ]),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.12)),
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
                Text(value,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black87),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Barre de filtres Tous / Envoyées / Reçues ────────────────────────────────
  Widget _buildFilterBar(List<FichePaie> all) {
    final nbEnvoyes = all.where((f) => !f.estRecue).length;
    final nbRecus   = all.where((f) => f.estRecue).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
      child: Row(children: [
        _filterChip('Toutes', 'tous', all.length),
        const SizedBox(width: 8),
        _filterChip('Envoyées', 'envoyes', nbEnvoyes),
        const SizedBox(width: 8),
        _filterChip('Reçues', 'recus', nbRecus),
      ]),
    );
  }

  Widget _filterChip(String label, String value, int count) {
    final selected = _filtre == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filtre = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? const Color(0xFF1A1A1A) : const Color(0xFFE5E7EB)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Flexible(
              child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w700,
                color: selected ? Colors.white : const Color(0xFF374151),
              )),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected ? Colors.white.withValues(alpha: 0.22) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$count', style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: selected ? Colors.white : const Color(0xFF6B7280),
              )),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildEmptyFiltre() => ListView(
    children: [
      const SizedBox(height: 80),
      Icon(_filtre == 'recus' ? Icons.inbox_outlined : Icons.outbox_outlined, size: 48, color: const Color(0xFFB0B0B0)),
      const SizedBox(height: 12),
      Center(child: Text(
        _filtre == 'recus' ? 'Aucune fiche reçue' : 'Aucune fiche envoyée',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
      )),
    ],
  );

  Widget _buildEmpty() => const EmptyState(
    icon: Icons.receipt_long_outlined,
    title: 'Aucune fiche de paie',
    subtitle: 'Vos fiches de paie générées apparaîtront ici',
    accentColor: Color(0xFF1A1A1A),
  );

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: Color(0xFFF3F4F6), shape: BoxShape.circle),
            child: Icon(Icons.error_outline, color: Color(0xFF1A1A1A), size: 32),
          ),
          const SizedBox(height: 14),
          const Text('Erreur de chargement',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 6),
          Text(message, style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => context.read<FichePaieBloc>().add(const LoadFichesPaieEvent()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
              child: const Text('Réessayer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

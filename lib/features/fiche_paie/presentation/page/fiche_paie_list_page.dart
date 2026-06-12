import 'dart:io';
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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

  Future<void> _ouvrirFiche(FichePaie fiche) async {
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30)],
          ),
          child: const Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: Color(0xFF2563EB), strokeWidth: 2.5),
            SizedBox(height: 18),
            Text('Ouverture…', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ]),
        ),
      ),
    );
    context.read<FichePaieBloc>().add(
          TelechargerFichePaieEvent(ficheId: fiche.id ?? '', titre: titre),
        );
  }

  Future<void> _handleBytes(List<int> bytes, String titre) async {
    try {
      final dir  = await getTemporaryDirectory();
      final file = File('${dir.path}/fp_$titre.pdf');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerPage(filePath: file.path, titre: titre),
        ),
      );
      if (mounted) context.read<FichePaieBloc>().add(const LoadFichesPaieEvent());
    } catch (e) {
      if (mounted) showDownloadErrorSnackBar(context, e.toString());
    }
  }

  String _formatDate(String? d) {
    if (d == null || d.isEmpty) return '—';
    try { return DateFormat('MM/yyyy').format(DateTime.parse(d)); } catch (_) { return d; }
  }

  String _formatMontant(double? v) {
    if (v == null) return '—';
    return '${NumberFormat('#,###', 'fr_FR').format(v).replaceAll(',', ' ')} FCFA';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: BlocListener<FichePaieBloc, FichePaieState>(
        listener: (context, state) {
          if (state is FichePaieBytes) {
            if (Navigator.canPop(context)) Navigator.pop(context);
            _handleBytes(state.bytes, state.titre);
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
                    return const ShimmerList(accentColor: Color(0xFF2563EB));
                  }
                  if (state is FichePaieError) {
                    return _buildError(context, state.message);
                  }
                  if (state is FichesPaieLoaded) {
                    if (state.fiches.isEmpty) return _buildEmpty();
                    return RefreshIndicator(
                      color: const Color(0xFF2563EB),
                      onRefresh: () async =>
                          context.read<FichePaieBloc>().add(const LoadFichesPaieEvent()),
                      child: ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: state.fiches.length + (state.isRefreshing ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index == state.fiches.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                    color: Color(0xFF2563EB), strokeWidth: 2),
                              ),
                            );
                          }
                          return _buildCard(state.fiches[index]);
                        },
                      ),
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
        color: Color(0xFF2563EB),
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
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
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
              color: Colors.white.withOpacity(0.2),
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
    final salarieId = fiche.salarieId;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4))],
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
                    color: const Color(0xFF2563EB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.receipt_long_outlined, color: Color(0xFF2563EB), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fiche.numeroFiche,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.black87)),
                      const SizedBox(height: 3),
                      Text(moisAnnee,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.3)),
                  ),
                  child: Text(fiche.typeContrat,
                      style: const TextStyle(color: Color(0xFF2563EB), fontSize: 11, fontWeight: FontWeight.w700)),
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
                    _formatMontant(fiche.salaireBrut), const Color(0xFF16A34A))),
                const SizedBox(width: 10),
                Expanded(child: _infoChip(Icons.savings_outlined, 'Net',
                    _formatMontant(fiche.salaireNet), const Color(0xFF2563EB))),
              ],
            ),
          ),
          Divider(color: Colors.grey[100], height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: GestureDetector(
              onTap: () => _ouvrirFiche(fiche),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.open_in_new_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text('Voir la fiche', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
              ),
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

  Widget _buildEmpty() => const EmptyState(
    icon: Icons.receipt_long_outlined,
    title: 'Aucune fiche de paie',
    subtitle: 'Vos fiches de paie générées apparaîtront ici',
    accentColor: Color(0xFF2563EB),
  );

  Widget _buildError(BuildContext context, String message) {
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
            onTap: () => context.read<FichePaieBloc>().add(const LoadFichesPaieEvent()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(12)),
              child: const Text('Réessayer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

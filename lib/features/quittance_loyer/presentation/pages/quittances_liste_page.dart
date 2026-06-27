import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sign_application/core/widgets/empty_state.dart';
import 'package:sign_application/core/widgets/shimmer_list.dart';
import 'package:toastification/toastification.dart';
import 'package:sign_application/core/widgets/toastNotif.dart';
import '../bloc/quittance_loyer_bloc.dart';
import '../bloc/quittance_loyer_event.dart';
import '../bloc/quittance_loyer_state.dart';
import '../../domain/entities/quittance_loyer.dart';
import 'creation_quittance_page.dart';

class QuittancesListePage extends StatefulWidget {
  const QuittancesListePage({super.key});

  @override
  State<QuittancesListePage> createState() => _QuittancesListePageState();
}

class _QuittancesListePageState extends State<QuittancesListePage> {
  static final _montantFmt = NumberFormat('#,###', 'fr_FR');

  @override
  void initState() {
    super.initState();
    context.read<QuittanceLoyerBloc>().add(LoadQuittances());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Quittances de loyer',
          style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            onPressed: () => context.read<QuittanceLoyerBloc>().add(LoadQuittances()),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: Text('Nouvelle', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreationQuittancePage()))
              .then((_) { if (context.mounted) context.read<QuittanceLoyerBloc>().add(LoadQuittances()); });
        },
      ),
      body: BlocConsumer<QuittanceLoyerBloc, QuittanceLoyerState>(
        listener: (context, state) {
          if (state is QuittanceBytes) {
            showToast(context, 'Téléchargé', 'Quittance téléchargée avec succès', ToastificationType.success);
          }
          if (state is QuittanceLoyerError) {
            showToast(context, 'Erreur', state.message, ToastificationType.error);
          }
        },
        builder: (context, state) {
          if (state is QuittanceLoyerLoading) {
            return const ShimmerList(itemCount: 4, padding: EdgeInsets.fromLTRB(16, 16, 16, 80));
          }

          if (state is QuittancesLoaded) {
            final quittances  = state.quittances;
            final total       = quittances.length;
            final totalPaye   = quittances.where((q) => q.estTotal == true).length;
            final partielles  = total - totalPaye;

            return RefreshIndicator(
              color: Colors.black87,
              onRefresh: () async => context.read<QuittanceLoyerBloc>().add(LoadQuittances()),
              child: CustomScrollView(
                slivers: [

                  // ── Carte stats ─────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1a1a1a), Color(0xFF3a3a3a)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 14, offset: const Offset(0, 6))],
                      ),
                      child: Row(children: [
                        _HeaderStat(label: 'Total',     value: total,      icon: Icons.receipt_long_outlined,    color: Colors.white),
                        _vDivider(),
                        _HeaderStat(label: 'Payées',    value: totalPaye,  icon: Icons.check_circle_outline,     color: const Color(0xFF4ADE80)),
                        _vDivider(),
                        _HeaderStat(label: 'Partielles',value: partielles, icon: Icons.schedule_outlined,        color: const Color(0xFFFFB347)),
                      ]),
                    ),
                  ),

                  if (quittances.isEmpty)
                    const SliverFillRemaining(
                      child: EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'Aucune quittance',
                        subtitle: 'Vos quittances de loyer apparaîtront ici',
                        scrollable: false,
                      ),
                    )
                  else ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _QuittanceCard(
                            quittance:   quittances[index],
                            montantFmt:  _montantFmt,
                            onDownload:  () => context.read<QuittanceLoyerBloc>().add(TelechargerQuittanceEvent(quittances[index].id)),
                          ),
                          childCount: quittances.length,
                        ),
                      ),
                    ),
                  ],

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            );
          }

          if (state is QuittanceLoyerError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                      child: Icon(Icons.error_outline_rounded, color: Colors.red.shade400, size: 32),
                    ),
                    const SizedBox(height: 16),
                    Text('Impossible de charger', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF111827))),
                    const SizedBox(height: 6),
                    Text(state.message, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF6B7280), fontSize: 13), textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87, foregroundColor: Colors.white,
                        elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                      ),
                      onPressed: () => context.read<QuittanceLoyerBloc>().add(LoadQuittances()),
                      child: const Text('Réessayer', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            );
          }

          return const Center(child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2.5));
        },
      ),
    );
  }

  Widget _vDivider() => Container(
    width: 1, height: 36, margin: const EdgeInsets.symmetric(horizontal: 12),
    color: Colors.white.withValues(alpha: 0.15),
  );
}

// ── Stat dans le header ───────────────────────────────────────────────────────
class _HeaderStat extends StatelessWidget {
  final String label;
  final int    value;
  final IconData icon;
  final Color  color;

  const _HeaderStat({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color, height: 1)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ── Carte quittance ───────────────────────────────────────────────────────────
class _QuittanceCard extends StatelessWidget {
  final QuittanceLoyer quittance;
  final NumberFormat   montantFmt;
  final VoidCallback   onDownload;

  const _QuittanceCard({required this.quittance, required this.montantFmt, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    final isPaye = quittance.estTotal == true;
    final locataireNom = quittance.locataire != null
        ? '${quittance.locataire!['prenom'] ?? ''} ${quittance.locataire!['nom'] ?? ''}'.trim()
        : 'N/A';
    final montant = quittance.montantTotal != null
        ? '${montantFmt.format(quittance.montantTotal!).replaceAll(',', ' ')} FCFA'
        : '—';

    final statusColor = isPaye ? const Color(0xFF16A34A) : const Color(0xFFD97706);
    final statusBg    = isPaye ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB);
    final statusText  = isPaye ? 'Payée' : 'Partiel';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          // Icône
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a1a),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),

          // Infos
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                quittance.numeroQuittance ?? 'Quittance #${quittance.id.substring(0, 8)}',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14, color: const Color(0xFF111827)),
              ),
              if (quittance.adresseLogement != null) ...[
                const SizedBox(height: 3),
                Text(quittance.adresseLogement!, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF6B7280)), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 6),
              Row(children: [
                if (quittance.mois != null && quittance.annee != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
                    child: Text('${quittance.mois} ${quittance.annee}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(montant, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: const Color(0xFF111827))),
              ]),
              const SizedBox(height: 4),
              Text(locataireNom, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF9CA3AF))),
            ]),
          ),
          const SizedBox(width: 8),

          // Droite : badge + download
          Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
              child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onDownload,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.download_outlined, size: 18, color: Color(0xFF374151)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

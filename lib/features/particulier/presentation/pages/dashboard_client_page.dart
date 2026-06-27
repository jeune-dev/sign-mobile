import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../features/auth/domain/entities/user.dart';
import '../bloc/particulier_bloc.dart';
import '../bloc/particulier_event.dart';
import '../bloc/particulier_state.dart';
import '../../domain/entities/particulier_facture.dart';

class DashboardClientPage extends StatefulWidget {
  final User? user;
  const DashboardClientPage({super.key, this.user});

  @override
  State<DashboardClientPage> createState() => _DashboardClientPageState();
}

class _DashboardClientPageState extends State<DashboardClientPage> {
  static final _montantFmt = NumberFormat('#,###', 'fr_FR');

  @override
  void initState() {
    super.initState();
    context.read<ParticulierBloc>().add(const LoadDashboardStats());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ParticulierBloc, ParticulierState>(
      builder: (context, state) {
        if (state is ParticulierLoading) {
          return const Center(child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2.5));
        }
        if (state is ParticulierError) return _buildError(state.message);
        if (state is DashboardLoaded)  return _buildContent(state);
        return const Center(child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2.5));
      },
    );
  }

  Widget _buildError(String message) {
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
            Text('Impossible de charger', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF111827))),
            const SizedBox(height: 6),
            Text(message, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF6B7280), fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87, foregroundColor: Colors.white,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              ),
              onPressed: () => context.read<ParticulierBloc>().add(const LoadDashboardStats()),
              child: const Text('Réessayer', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(DashboardLoaded state) {
    final stats    = state.stats;
    final factures = stats['factures'] as Map? ?? {};
    final contrats = stats['contrats'] as Map? ?? {};

    return RefreshIndicator(
      color: Colors.black87,
      onRefresh: () async => context.read<ParticulierBloc>().add(const LoadDashboardStats()),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        children: [

          // ── Bannière bienvenue ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1a1a1a), Color(0xFF3a3a3a)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour, ${widget.user?.prenom ?? 'Client'}',
                        style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Voici un aperçu de vos documents',
                        style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Factures ───────────────────────────────────────────────────────
          _sectionTitle('Factures', Icons.receipt_long_outlined),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _statCard('Total',      '${factures['total'] ?? 0}',      Icons.receipt_long_rounded, const Color(0xFF6C63FF))),
            const SizedBox(width: 10),
            Expanded(child: _statCard('Signées',    '${factures['signees'] ?? 0}',    Icons.check_circle_outline, const Color(0xFF00C896))),
            const SizedBox(width: 10),
            Expanded(child: _statCard('En attente', '${factures['enAttente'] ?? 0}',  Icons.schedule_outlined,    const Color(0xFFFFB347))),
          ]),
          const SizedBox(height: 24),

          // ── Contrats ───────────────────────────────────────────────────────
          _sectionTitle('Contrats', Icons.description_outlined),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _statCard('Total',      '${contrats['total'] ?? 0}',      Icons.article_outlined,    const Color(0xFF4ECDC4))),
            const SizedBox(width: 10),
            Expanded(child: _statCard('Signés',     '${contrats['signes'] ?? 0}',     Icons.verified_outlined,   const Color(0xFF00C896))),
            const SizedBox(width: 10),
            Expanded(child: _statCard('À signer',   '${contrats['enAttente'] ?? 0}',  Icons.edit_outlined,       const Color(0xFFFF6B6B))),
          ]),
          const SizedBox(height: 28),

          // ── Dernières factures ─────────────────────────────────────────────
          _sectionTitle('10 dernières factures', Icons.history_rounded),
          const SizedBox(height: 12),

          if (state.recentesFactures.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.inbox_outlined, size: 36, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text('Aucune facture reçue pour l\'instant',
                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF9CA3AF), fontSize: 14)),
                ]),
              ),
            )
          else
            ...state.recentesFactures.map((f) => _FactureRecente(facture: f, montantFmt: _montantFmt)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(children: [
      Container(
        width: 4, height: 18,
        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(2)),
      ),
      const SizedBox(width: 10),
      Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF111827), letterSpacing: -0.2)),
    ]);
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF111827), letterSpacing: -0.5)),
        ),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF6B7280), fontWeight: FontWeight.w500), textAlign: TextAlign.center),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FactureRecente extends StatelessWidget {
  final ParticulierFacture facture;
  final NumberFormat montantFmt;

  const _FactureRecente({required this.facture, required this.montantFmt});

  @override
  Widget build(BuildContext context) {
    final montant = '${montantFmt.format(facture.montant).replaceAll(',', ' ')} FCFA';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF00C896).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF00C896), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              facture.numeroFacture,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF111827)),
            ),
            if (facture.professionnelEntreprise != null || facture.professionnelNom != null) ...[
              const SizedBox(height: 2),
              Text(
                facture.professionnelEntreprise ?? facture.professionnelNom ?? '',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF6B7280)),
              ),
            ],
          ]),
        ),
        const SizedBox(width: 8),
        Text(
          montant,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13, color: const Color(0xFF111827)),
        ),
      ]),
    );
  }
}

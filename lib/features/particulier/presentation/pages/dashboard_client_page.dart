import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
          return const Center(child: CircularProgressIndicator(color: Colors.black));
        }
        if (state is ParticulierError) {
          return _buildError(state.message);
        }
        if (state is DashboardLoaded) {
          return _buildContent(state);
        }
        return const Center(child: CircularProgressIndicator(color: Colors.black));
      },
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () => context.read<ParticulierBloc>().add(const LoadDashboardStats()),
            child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(DashboardLoaded state) {
    final stats    = state.stats;
    final factures = stats['factures'] as Map? ?? {};
    final contrats = stats['contrats'] as Map? ?? {};

    return RefreshIndicator(
      color: Colors.black,
      onRefresh: () async => context.read<ParticulierBloc>().add(const LoadDashboardStats()),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Bienvenue ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour, ${widget.user?.prenom ?? 'Client'} 👋',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Voici un aperçu de vos documents',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Statistiques Factures ───────────────────────────────
          const _SectionTitle(title: 'Factures'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _StatCard(
                label: 'Total',
                value: '${factures['total'] ?? 0}',
                color: Colors.black,
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                label: 'Signées',
                value: '${factures['signees'] ?? 0}',
                color: Colors.green.shade700,
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                label: 'En attente',
                value: '${factures['enAttente'] ?? 0}',
                color: Colors.orange.shade700,
              )),
            ],
          ),
          const SizedBox(height: 20),

          // ── Statistiques Contrats ───────────────────────────────
          const _SectionTitle(title: 'Contrats'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _StatCard(
                label: 'Total',
                value: '${contrats['total'] ?? 0}',
                color: Colors.black,
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                label: 'Signés',
                value: '${contrats['signes'] ?? 0}',
                color: Colors.green.shade700,
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                label: 'En attente',
                value: '${contrats['enAttente'] ?? 0}',
                color: Colors.orange.shade700,
              )),
            ],
          ),
          const SizedBox(height: 20),

          // ── 10 dernières factures signées ────────────────────────
          const _SectionTitle(title: '10 dernières factures'),
          const SizedBox(height: 8),
          if (state.recentesFactures.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('Aucune facture reçue pour l\'instant.', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...state.recentesFactures.map((f) => _FactureRecente(facture: f)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _FactureRecente extends StatelessWidget {
  final ParticulierFacture facture;
  const _FactureRecente({required this.facture});

  @override
  Widget build(BuildContext context) {
    final montant = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(facture.montant);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.receipt_long, color: Colors.green.shade700, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  facture.numeroFacture,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                if (facture.professionnelEntreprise != null || facture.professionnelNom != null)
                  Text(
                    facture.professionnelEntreprise ?? facture.professionnelNom ?? '',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
          Text(
            montant,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

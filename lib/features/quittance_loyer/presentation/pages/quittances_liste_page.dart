import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  @override
  void initState() {
    super.initState();
    context.read<QuittanceLoyerBloc>().add(LoadQuittances());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Quittances de loyer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<QuittanceLoyerBloc>().add(LoadQuittances()),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreationQuittancePage()),
        ).then((_) => context.read<QuittanceLoyerBloc>().add(LoadQuittances())),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: BlocConsumer<QuittanceLoyerBloc, QuittanceLoyerState>(
        listener: (context, state) {
          if (state is QuittanceBytes) {
            showToast(context, 'Téléchargement', 'Quittance téléchargée avec succès', ToastificationType.success);
          }
          if (state is QuittanceLoyerError) {
            showToast(context, 'Erreur', state.message, ToastificationType.error);
          }
        },
        builder: (context, state) {
          if (state is QuittanceLoyerLoading) {
            return const ShimmerList(itemCount: 4, padding: EdgeInsets.fromLTRB(16, 12, 16, 80));
          }
          if (state is QuittancesLoaded) {
            final quittances = state.quittances;
            final total = quittances.length;
            final totalPaye = quittances.where((q) => q.estTotal == true).length;

            return RefreshIndicator(
              color: Colors.black,
              onRefresh: () async => context.read<QuittanceLoyerBloc>().add(LoadQuittances()),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _StatCard(label: 'Total', value: total.toString(), color: Colors.black),
                          const SizedBox(width: 8),
                          _StatCard(label: 'Payées', value: totalPaye.toString(), color: Colors.green),
                          const SizedBox(width: 8),
                          _StatCard(label: 'Partielles', value: (total - totalPaye).toString(), color: Colors.orange),
                        ],
                      ),
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
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _QuittanceCard(
                          quittance: quittances[index],
                          onDownload: () => context.read<QuittanceLoyerBloc>().add(
                                TelechargerQuittanceEvent(quittances[index].id),
                              ),
                        ),
                        childCount: quittances.length,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            );
          }
          if (state is QuittanceLoyerError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                    onPressed: () => context.read<QuittanceLoyerBloc>().add(LoadQuittances()),
                    child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator(color: Colors.black));
        },
      ),
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }
}

class _QuittanceCard extends StatelessWidget {
  final QuittanceLoyer quittance;
  final VoidCallback onDownload;

  const _QuittanceCard({required this.quittance, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    final isPaye = quittance.estTotal == true;
    final locataireNom = quittance.locataire != null
        ? '${quittance.locataire!['prenom'] ?? ''} ${quittance.locataire!['nom'] ?? ''}'.trim()
        : 'N/A';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.receipt_long, color: Colors.white, size: 24),
        ),
        title: Text(
          quittance.numeroQuittance ?? 'Quittance #${quittance.id.substring(0, 8)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (quittance.adresseLogement != null)
              Text(quittance.adresseLogement!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            Text(locataireNom, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
            const SizedBox(height: 4),
            Row(
              children: [
                if (quittance.mois != null && quittance.annee != null)
                  Text(
                    '${quittance.mois} ${quittance.annee}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
                const SizedBox(width: 8),
                if (quittance.montantTotal != null)
                  Text(
                    '${quittance.montantTotal!.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPaye ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isPaye ? Colors.green : Colors.orange),
                  ),
                  child: Text(
                    isPaye ? 'Payé' : 'Partiel',
                    style: TextStyle(
                      color: isPaye ? Colors.green : Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.download_outlined, color: Colors.black),
          onPressed: onDownload,
          tooltip: 'Télécharger',
        ),
      ),
    );
  }
}

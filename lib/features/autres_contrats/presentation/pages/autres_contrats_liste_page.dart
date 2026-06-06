import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/autres_contrats_bloc.dart';
import '../bloc/autres_contrats_event.dart';
import '../bloc/autres_contrats_state.dart';
import '../../domain/entities/autre_contrat.dart';

class AutresContratsListePage extends StatefulWidget {
  final String type;
  final String titre;
  final Widget Function(BuildContext context) createPageBuilder;

  const AutresContratsListePage({
    super.key,
    required this.type,
    required this.titre,
    required this.createPageBuilder,
  });

  @override
  State<AutresContratsListePage> createState() => _AutresContratsListePageState();
}

class _AutresContratsListePageState extends State<AutresContratsListePage> {
  @override
  void initState() {
    super.initState();
    context.read<AutresContratsBloc>().add(LoadContrats(widget.type));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.titre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AutresContratsBloc>().add(LoadContrats(widget.type)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: widget.createPageBuilder),
          ).then((_) => context.read<AutresContratsBloc>().add(LoadContrats(widget.type)));
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: BlocConsumer<AutresContratsBloc, AutresContratsState>(
        listener: (context, state) {
          if (state is AutresContratsBytes) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Téléchargement réussi'), backgroundColor: Colors.green),
            );
          }
          if (state is AutresContratsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is AutresContratsLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }
          if (state is AutresContratsListLoaded) {
            final contrats = state.contrats;
            final total = contrats.length;
            final signes = contrats.where((c) => c.statut == 'signe').length;
            final enAttente = contrats.where((c) => c.statut == 'en_attente').length;

            return RefreshIndicator(
              color: Colors.black,
              onRefresh: () async {
                context.read<AutresContratsBloc>().add(LoadContrats(widget.type));
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _StatCard(label: 'Total', value: total.toString(), color: Colors.black),
                          const SizedBox(width: 8),
                          _StatCard(label: 'Signés', value: signes.toString(), color: Colors.green),
                          const SizedBox(width: 8),
                          _StatCard(label: 'En attente', value: enAttente.toString(), color: Colors.orange),
                        ],
                      ),
                    ),
                  ),
                  if (contrats.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.description_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Aucun contrat', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _ContratCard(
                          contrat: contrats[index],
                          onDownload: () => context.read<AutresContratsBloc>().add(
                                TelechargerContrat(widget.type, contrats[index].id),
                              ),
                        ),
                        childCount: contrats.length,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            );
          }
          if (state is AutresContratsError) {
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
                    onPressed: () => context.read<AutresContratsBloc>().add(LoadContrats(widget.type)),
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

class _ContratCard extends StatelessWidget {
  final AutreContrat contrat;
  final VoidCallback onDownload;

  const _ContratCard({required this.contrat, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    final isSign = contrat.statut == 'signe';
    final autrePartieNom = contrat.autrePartie != null
        ? '${contrat.autrePartie!['prenom'] ?? ''} ${contrat.autrePartie!['nom'] ?? ''}'.trim()
        : 'N/A';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade100, blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.description, color: Colors.white, size: 24),
        ),
        title: Text(
          contrat.numeroContrat ?? 'Contrat #${contrat.id.substring(0, 8)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(autrePartieNom, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSign ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSign ? Colors.green : Colors.orange),
                  ),
                  child: Text(
                    isSign ? 'Signé' : 'En attente',
                    style: TextStyle(
                      color: isSign ? Colors.green : Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (contrat.createdAt != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    contrat.createdAt!.substring(0, 10),
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                  ),
                ],
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

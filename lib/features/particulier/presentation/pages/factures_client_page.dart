import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sign_application/core/widgets/empty_state.dart';
import 'package:sign_application/core/widgets/shimmer_list.dart';
import '../bloc/particulier_bloc.dart';
import '../bloc/particulier_event.dart';
import '../bloc/particulier_state.dart';
import '../../domain/entities/particulier_facture.dart';

class FacturesClientPage extends StatefulWidget {
  const FacturesClientPage({super.key});

  @override
  State<FacturesClientPage> createState() => _FacturesClientPageState();
}

class _FacturesClientPageState extends State<FacturesClientPage> {
  String? _selectedStatut; // null = toutes

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    context.read<ParticulierBloc>().add(LoadFactures(statut: _selectedStatut));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Boutons filtre ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              _FilterChip(
                label: 'Toutes',
                selected: _selectedStatut == null,
                onTap: () { setState(() => _selectedStatut = null); _load(); },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Signées',
                selected: _selectedStatut == 'signe',
                selectedColor: Colors.green,
                onTap: () { setState(() => _selectedStatut = 'signe'); _load(); },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'En attente',
                selected: _selectedStatut == 'en_attente',
                selectedColor: Colors.orange,
                onTap: () { setState(() => _selectedStatut = 'en_attente'); _load(); },
              ),
            ],
          ),
        ),

        // ── Liste ───────────────────────────────────────────────
        Expanded(
          child: BlocBuilder<ParticulierBloc, ParticulierState>(
            buildWhen: (prev, curr) => curr is FacturesLoaded || curr is ParticulierLoading || curr is ParticulierError,
            builder: (context, state) {
              if (state is ParticulierLoading) {
                return const ShimmerList(itemCount: 4, padding: EdgeInsets.fromLTRB(16, 4, 16, 16));
              }
              if (state is ParticulierError) {
                return _buildError(state.message);
              }
              if (state is FacturesLoaded) {
                if (state.factures.isEmpty) return _buildEmpty();
                return RefreshIndicator(
                  color: Colors.black,
                  onRefresh: () async => _load(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: state.factures.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _FactureCard(facture: state.factures[i]),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    final title = _selectedStatut == null
        ? 'Aucune facture reçue'
        : _selectedStatut == 'signe'
            ? 'Aucune facture signée'
            : 'Aucune facture en attente';
    return EmptyState(
      icon: Icons.receipt_long_outlined,
      title: title,
      subtitle: 'Vos factures reçues apparaîtront ici',
      scrollable: false,
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
            onPressed: _load,
            child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Chip de filtre ────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.selectedColor = Colors.black,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? selectedColor : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── Carte facture ─────────────────────────────────────────────────────────────
class _FactureCard extends StatelessWidget {
  final ParticulierFacture facture;
  const _FactureCard({required this.facture});

  @override
  Widget build(BuildContext context) {
    final montant = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(facture.montant);
    final date = facture.createdAt.isNotEmpty
        ? DateFormat('dd/MM/yyyy').format(DateTime.tryParse(facture.createdAt) ?? DateTime.now())
        : '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Icône statut
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: facture.estSignee ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              facture.estSignee ? Icons.check_circle_outline : Icons.hourglass_empty,
              color: facture.estSignee ? Colors.green.shade700 : Colors.orange.shade700,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  facture.numeroFacture,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                if (facture.professionnelEntreprise != null || facture.professionnelNom != null)
                  Text(
                    facture.professionnelEntreprise ?? facture.professionnelNom ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: facture.estSignee ? Colors.green.shade100 : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        facture.estSignee ? 'Signée' : 'En attente',
                        style: TextStyle(
                          fontSize: 11,
                          color: facture.estSignee ? Colors.green.shade800 : Colors.orange.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(date, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ),
          // Montant
          Text(
            montant,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

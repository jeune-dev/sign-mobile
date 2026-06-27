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
            const Text('Impossible de charger', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF111827))),
            const SizedBox(height: 6),
            Text(message, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87, foregroundColor: Colors.white,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              ),
              onPressed: _load,
              child: const Text('Réessayer', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
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

  static final _montantFmt = NumberFormat('#,###', 'fr_FR');
  static final _dateFmt    = DateFormat('dd/MM/yyyy');

  const _FactureCard({required this.facture});

  @override
  Widget build(BuildContext context) {
    final montant = '${_montantFmt.format(facture.montant).replaceAll(',', ' ')} FCFA';
    final date = facture.createdAt.isNotEmpty
        ? _dateFmt.format(DateTime.tryParse(facture.createdAt) ?? DateTime.now())
        : '';

    final isSigned = facture.estSignee;
    final statusColor  = isSigned ? const Color(0xFF16A34A) : const Color(0xFFD97706);
    final statusBg     = isSigned ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB);
    final statusLabel  = isSigned ? 'Signée'               : 'En attente';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: isSigned ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isSigned ? Icons.check_circle_outline_rounded : Icons.schedule_outlined,
              color: statusColor, size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(facture.numeroFacture, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF111827))),
                if (facture.professionnelEntreprise != null || facture.professionnelNom != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    facture.professionnelEntreprise ?? facture.professionnelNom ?? '',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ],
                const SizedBox(height: 6),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
                    child: Text(statusLabel, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
                  ),
                  if (date.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(date, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                  ],
                ]),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(montant, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF111827))),
        ],
      ),
    );
  }
}

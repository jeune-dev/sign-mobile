import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sign_application/core/widgets/empty_state.dart';
import 'package:sign_application/core/widgets/shimmer_list.dart';
import 'package:sign_application/core/config/contrat_type.dart';
import '../bloc/particulier_bloc.dart';
import '../bloc/particulier_event.dart';
import '../bloc/particulier_state.dart';
import '../../domain/entities/particulier_contrat.dart';
import 'detail_contrat_client_page.dart';

// Types de contrats disponibles pour le particulier.
// contrat-travail et contrat-bail sont des features séparées — pas dans ContratType.
final _kContractTypes = <Map<String, String?>>[
  {'type': null,                                             'label': 'Tous'},
  {'type': 'contrat-travail',                               'label': 'Travail'},
  {'type': ContratType.prestation.apiValue,                 'label': 'Prestation'},
  {'type': 'contrat-bail',                                  'label': 'Bail'},
  {'type': ContratType.partenariat.apiValue,                'label': 'Partenariat'},
  {'type': ContratType.location.apiValue,                   'label': 'Location'},
  {'type': ContratType.reconnaissanceDette.apiValue,        'label': 'Reconnaissance dette'},
  {'type': ContratType.procuration.apiValue,                'label': 'Procuration'},
  {'type': ContratType.caution.apiValue,                    'label': 'Caution'},
  {'type': ContratType.confidentialite.apiValue,            'label': 'Confidentialité'},
];

class ContratsClientPage extends StatefulWidget {
  const ContratsClientPage({super.key});

  @override
  State<ContratsClientPage> createState() => _ContratsClientPageState();
}

class _ContratsClientPageState extends State<ContratsClientPage> {
  String? _selectedType;  // null = tous
  String? _selectedStatut;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    context.read<ParticulierBloc>().add(
      LoadContrats(type: _selectedType, statut: _selectedStatut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Scroll horizontal des types ─────────────────────────
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _kContractTypes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final t = _kContractTypes[i];
              final isSelected = _selectedType == t['type'];
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedType = t['type']);
                  _load();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.black : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? Colors.black : Colors.grey.shade300),
                  ),
                  child: Center(
                    child: Text(
                      t['label'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // ── Filtres signé / en attente ──────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              _FilterChip(
                label: 'Tous',
                selected: _selectedStatut == null,
                onTap: () { setState(() => _selectedStatut = null); _load(); },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Signés',
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
            buildWhen: (prev, curr) =>
                curr is ContratsLoaded || curr is ParticulierLoading || curr is ParticulierError,
            builder: (context, state) {
              if (state is ParticulierLoading) {
                return const ShimmerList(itemCount: 4, padding: EdgeInsets.fromLTRB(16, 4, 16, 16));
              }
              if (state is ParticulierError) {
                return _buildError(state.message);
              }
              if (state is ContratsLoaded) {
                if (state.contrats.isEmpty) return _buildEmpty();
                return RefreshIndicator(
                  color: Colors.black,
                  onRefresh: () async => _load(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: state.contrats.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _ContratCard(
                      contrat: state.contrats[i],
                      onTap: () => _openDetail(state.contrats[i]),
                    ),
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

  void _openDetail(ParticulierContrat contrat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ParticulierBloc>(),
          child: DetailContratClientPage(contrat: contrat),
        ),
      ),
    ).then((_) => _load()); // Recharger après retour (cas signature)
  }

  Widget _buildEmpty() => const EmptyState(
    icon: Icons.description_outlined,
    title: 'Aucun contrat trouvé',
    subtitle: 'Vos contrats signés apparaîtront ici',
    scrollable: false,
  );

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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? selectedColor : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ContratCard extends StatelessWidget {
  final ParticulierContrat contrat;
  final VoidCallback onTap;

  static final _dateFmt = DateFormat('dd/MM/yyyy');

  const _ContratCard({required this.contrat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final date = contrat.createdAt.isNotEmpty
        ? _dateFmt.format(DateTime.tryParse(contrat.createdAt) ?? DateTime.now())
        : '';
    final isSigne = contrat.estSigne;
    final statusColor = isSigne ? const Color(0xFF16A34A) : const Color(0xFFD97706);
    final statusBg    = isSigne ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB);

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                color: isSigne ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.description_outlined, color: statusColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contrat.numeroContrat, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF111827))),
                  const SizedBox(height: 2),
                  Text(contrat.typeLabel, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  if (contrat.generateurNom != null || contrat.generateurEntreprise != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      contrat.generateurEntreprise ?? contrat.generateurNom ?? '',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
                      child: Text(isSigne ? 'Signé' : 'En attente', style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
                    ),
                    if (contrat.peutSigner) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF93C5FD))),
                        child: const Text('À signer', style: TextStyle(fontSize: 11, color: Color(0xFF1D4ED8), fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(mainAxisSize: MainAxisSize.min, children: [
              if (date.isNotEmpty) Text(date, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
              const SizedBox(height: 4),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF), size: 20),
            ]),
          ],
        ),
      ),
    );
  }
}


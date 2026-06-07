import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/particulier_bloc.dart';
import '../bloc/particulier_event.dart';
import '../bloc/particulier_state.dart';
import '../../domain/entities/particulier_contrat.dart';
import 'detail_contrat_client_page.dart';

// Types de contrats disponibles pour le particulier
const _kContractTypes = [
  {'type': null,                     'label': 'Tous'},
  {'type': 'contrat-travail',        'label': 'Travail'},
  {'type': 'contrat-prestation',     'label': 'Prestation'},
  {'type': 'contrat-bail',           'label': 'Bail'},
  {'type': 'contrat-partenariat',    'label': 'Partenariat'},
  {'type': 'contrat-location',       'label': 'Location'},
  {'type': 'reconnaissance-dette',   'label': 'Reconnaissance dette'},
  {'type': 'procuration',            'label': 'Procuration'},
  {'type': 'contrat-caution',        'label': 'Caution'},
  {'type': 'contrat-confidentialite','label': 'Confidentialité'},
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
                return const Center(child: CircularProgressIndicator(color: Colors.black));
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

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Aucun contrat trouvé',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
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

  const _ContratCard({required this.contrat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final date = contrat.createdAt.isNotEmpty
        ? DateFormat('dd/MM/yyyy').format(DateTime.tryParse(contrat.createdAt) ?? DateTime.now())
        : '';
    final isSigne = contrat.estSigne;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            // Icône
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSigne ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.description_outlined,
                color: isSigne ? Colors.green.shade700 : Colors.orange.shade700,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contrat.numeroContrat,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    contrat.typeLabel,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  if (contrat.generateurNom != null || contrat.generateurEntreprise != null)
                    Text(
                      contrat.generateurEntreprise ?? contrat.generateurNom ?? '',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _StatusBadge(isSigne: isSigne),
                      if (contrat.peutSigner) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('À signer', style: TextStyle(fontSize: 10, color: Colors.blue.shade700)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(date, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isSigne;
  const _StatusBadge({required this.isSigne});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSigne ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isSigne ? 'Signé' : 'En attente',
        style: TextStyle(
          fontSize: 11,
          color: isSigne ? Colors.green.shade800 : Colors.orange.shade800,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

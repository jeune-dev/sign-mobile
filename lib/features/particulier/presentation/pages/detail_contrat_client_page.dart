import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sign_application/core/config/contrat_type.dart';
import '../bloc/particulier_bloc.dart';
import '../bloc/particulier_event.dart';
import '../bloc/particulier_state.dart';
import '../../domain/entities/particulier_contrat.dart';
import 'signer_contrat_page.dart';

class DetailContratClientPage extends StatelessWidget {
  final ParticulierContrat contrat;
  const DetailContratClientPage({super.key, required this.contrat});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          contrat.typeLabel,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocListener<ParticulierBloc, ParticulierState>(
        listener: (context, state) {
          if (state is ParticulierError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Statut ────────────────────────────────────────────
            _StatusHeader(contrat: contrat),
            const SizedBox(height: 16),

            // ── Informations générales ────────────────────────────
            _InfoSection(
              title: 'Informations générales',
              children: [
                _InfoRow(label: 'Numéro', value: contrat.numeroContrat),
                _InfoRow(label: 'Type', value: contrat.typeLabel),
                _InfoRow(
                  label: 'Date',
                  value: contrat.createdAt.isNotEmpty
                      ? DateFormat('dd/MM/yyyy').format(DateTime.tryParse(contrat.createdAt) ?? DateTime.now())
                      : '—',
                ),
                _InfoRow(
                  label: 'Statut',
                  value: contrat.estSigne ? 'Signé' : 'En attente de signature',
                  valueColor: contrat.estSigne ? Colors.green : Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Émetteur ─────────────────────────────────────────
            if (contrat.generateurNom != null || contrat.generateurEntreprise != null)
              _InfoSection(
                title: 'Émetteur',
                children: [
                  if (contrat.generateurNom != null)
                    _InfoRow(label: 'Nom', value: contrat.generateurNom!),
                  if (contrat.generateurEntreprise != null)
                    _InfoRow(label: 'Entreprise', value: contrat.generateurEntreprise!),
                  if (contrat.generateurEmail != null)
                    _InfoRow(label: 'Email', value: contrat.generateurEmail!),
                ],
              ),
            const SizedBox(height: 12),

            // ── Détails spécifiques ───────────────────────────────
            _buildSpecificDetails(),
            const SizedBox(height: 24),

            // ── Actions ───────────────────────────────────────────
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecificDetails() {
    final raw = contrat.rawData;
    final details = <Map<String, String>>[];

    // Selon le type, on extrait les champs pertinents
    if (contrat.type == 'contrat-travail') {
      _addIfNotNull(details, 'Poste',          raw['poste']);
      _addIfNotNull(details, 'Type de contrat', raw['type_contrat']);
      _addIfNotNull(details, 'Lieu de travail', raw['lieu_travail']);
      _addIfNotNull(details, 'Date de début',   raw['date_debut']);
      _addIfNotNull(details, 'Salaire brut',    raw['salaire_brut']?.toString());
    } else if (contrat.type == ContratType.prestation.apiValue) {
      _addIfNotNull(details, 'Titre',          raw['titre_contrat']);
      _addIfNotNull(details, 'Montant total',  raw['montant_total']?.toString());
      _addIfNotNull(details, 'Date de début',  raw['date_debut']);
      _addIfNotNull(details, 'Date de fin',    raw['date_fin']);
    } else if (contrat.type == 'contrat-bail') {
      _addIfNotNull(details, 'Adresse du bien', raw['adresse_bien']);
      _addIfNotNull(details, 'Loyer mensuel',  raw['loyer_mensuel']?.toString());
      _addIfNotNull(details, 'Date de début',  raw['date_debut_bail']);
      _addIfNotNull(details, 'Durée',          raw['duree']?.toString());
    } else if (contrat.type == ContratType.reconnaissanceDette.apiValue) {
      _addIfNotNull(details, 'Montant',        raw['montant']?.toString());
      _addIfNotNull(details, 'Date de remboursement', raw['date_remboursement']);
    } else {
      _addIfNotNull(details, 'Titre',          raw['titre_contrat'] ?? raw['objet']);
      _addIfNotNull(details, 'Montant',        raw['montant_total']?.toString() ?? raw['montant']?.toString());
      _addIfNotNull(details, 'Date de début',  raw['date_debut']);
      _addIfNotNull(details, 'Date de fin',    raw['date_fin']);
    }

    if (details.isEmpty) return const SizedBox.shrink();

    return _InfoSection(
      title: 'Détails du contrat',
      children: details.map((d) => _InfoRow(label: d['label']!, value: d['value']!)).toList(),
    );
  }

  void _addIfNotNull(List<Map<String, String>> list, String label, String? value) {
    if (value != null && value.isNotEmpty && value != 'null') {
      list.add({'label': label, 'value': value});
    }
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        // Bouton Voir le PDF (si disponible)
        if (contrat.rawData['contrat_pdf'] != null) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.visibility_outlined, color: Colors.black),
              label: const Text('Voir le contrat', style: TextStyle(color: Colors.black)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.black),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                // Affichage PDF — extension future
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Aperçu PDF disponible prochainement')),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Bouton Signer (si en attente)
        if (contrat.peutSigner)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.draw, color: Colors.white),
              label: const Text('Signer le contrat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _openSigner(context),
            ),
          ),
      ],
    );
  }

  void _openSigner(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ParticulierBloc>(),
          child: SignerContratPage(contrat: contrat),
        ),
      ),
    );
    if (!context.mounted) return;
    // Recharger le détail après retour
    context.read<ParticulierBloc>().add(
      LoadContratDetail(type: contrat.type, contratId: contrat.id),
    );
  }
}

// ── Composants réutilisables ──────────────────────────────────────────────────

class _StatusHeader extends StatelessWidget {
  final ParticulierContrat contrat;
  const _StatusHeader({required this.contrat});

  @override
  Widget build(BuildContext context) {
    final isSigne = contrat.estSigne;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: isSigne ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSigne ? Colors.green.shade200 : Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(
            isSigne ? Icons.check_circle : Icons.schedule,
            color: isSigne ? Colors.green.shade700 : Colors.orange.shade700,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSigne ? 'Contrat signé' : 'En attente de votre signature',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isSigne ? Colors.green.shade800 : Colors.orange.shade800,
                  ),
                ),
                Text(
                  isSigne
                      ? 'Ce contrat a été signé par les deux parties.'
                      : contrat.peutSigner
                          ? 'Votre signature est requise pour ce contrat.'
                          : 'Ce contrat est en cours de traitement.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isSigne ? Colors.green.shade700 : Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _InfoSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
          const Divider(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: valueColor ?? Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

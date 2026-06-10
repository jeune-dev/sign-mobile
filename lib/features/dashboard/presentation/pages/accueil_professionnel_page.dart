import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sign_application/features/auth/domain/entities/user.dart';
import 'package:sign_application/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:sign_application/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:sign_application/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:sign_application/features/facture/presentation/pages/historique_factures_page.dart';
import 'package:sign_application/features/facture/presentation/pages/cree_facture_page.dart';
import 'package:sign_application/features/facture/presentation/bloc/facture_bloc.dart';
import 'package:sign_application/features/contrat/presentation/widgets/contract_type_modal.dart';
import 'package:sign_application/core/widgets/pdf_viewer_page.dart';
import 'package:sign_application/injection_container.dart' as di;

class HomeProfessionnelPage extends StatefulWidget {
  final User? user;
  const HomeProfessionnelPage({super.key, this.user});

  @override
  State<HomeProfessionnelPage> createState() => _HomeProfessionnelPageState();
}

class _HomeProfessionnelPageState extends State<HomeProfessionnelPage>
    with SingleTickerProviderStateMixin {
  bool _localeReady = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;


  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    initializeDateFormatting('fr_FR', null).then((_) {
      if (mounted) setState(() => _localeReady = true);
    });

    context.read<DashboardBloc>().add(LoadDashboard());
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '—';
    try {
      final dt = DateTime.parse(dateString);
      return _localeReady
          ? DateFormat('dd MMM yyyy', 'fr_FR').format(dt)
          : DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return dateString;
    }
  }

  String _formatMontant(dynamic montant) {
    if (montant == null) return '—';
    try {
      final num val = num.parse(montant.toString());
      return NumberFormat('#,###', 'fr_FR').format(val).replaceAll(',', ' ') +
          ' FCFA';
    } catch (_) {
      return '$montant FCFA';
    }
  }

  Future<void> _ouvrirDocument(String documentId, String numeroFacture) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: _LoadingDialog()),
    );

    context.read<DashboardBloc>().add(OuvrirDocumentDashboardEvent(documentId, titre: numeroFacture));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DashboardBloc, DashboardState>(
      listener: (context, state) {
        if (state is DashboardLoaded) {
          _animController.forward();
        }
        if (state is DashboardDocumentBytes) {
          if (Navigator.canPop(context)) Navigator.pop(context);
          _saveAndOpenPdf(state.bytes, state.titre.isNotEmpty ? state.titre : state.documentId);
        }
        if (state is DashboardError) {
          if (Navigator.canPop(context)) Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red[400],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      child: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          return RefreshIndicator(
            color: Colors.black87,
            onRefresh: () async {
              _animController.reset();
              context.read<DashboardBloc>().add(LoadDashboard());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsSection(state),
                  const SizedBox(height: 32),
                  _buildRecentDocumentsSection(state),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveAndOpenPdf(List<int> bytes, String documentId) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/doc_$documentId.pdf');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      // ← await : on attend que l'utilisateur revienne du PDF
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerPage(filePath: file.path, titre: documentId),
        ),
      );
      // ← Retour du PDF viewer : recharger les données du dashboard
      if (mounted) {
        context.read<DashboardBloc>().add(LoadDashboard());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur ouverture: $e'), backgroundColor: Colors.red[400]),
        );
      }
    }
  }

  Widget _buildStatsSection(DashboardState state) {
    final effectiveState = state;

    if (effectiveState is DashboardLoading) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2.5),
              ),
              const SizedBox(height: 14),
              Text(
                'Chargement des statistiques…',
                style: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    if (effectiveState is DashboardError) {
      return _buildErrorCard(effectiveState.message, () => context.read<DashboardBloc>().add(LoadDashboard()));
    }

    if (effectiveState is DashboardLoaded) {
      final stats = effectiveState.stats;

      return FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Vue d\'ensemble'),
            const SizedBox(height: 14),
            // ── Cartes stats (compactes) ──────────────────────────────────
            Row(
              children: [
                Expanded(child: _buildMainStatCard(stats.nombreFactures, stats.creancesClients)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      _buildMiniStatCard(
                        title: 'Bail',
                        value: '${stats.nombreContratsImmobilier}',
                        icon: Icons.handshake_outlined,
                        color: const Color(0xFF6C63FF),
                        subtitle: 'Contrats',
                      ),
                      const SizedBox(height: 12),
                      _buildMiniStatCard(
                        title: 'Travail',
                        value: '${stats.nombreContratsTravail}',
                        icon: Icons.work_outline,
                        color: const Color(0xFF00C896),
                        subtitle: 'Contrats',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ── Boutons d'action rapide ───────────────────────────────────
            Row(
              children: [
                Expanded(child: _buildQuickActionBtn(
                  label: 'Créer une facture',
                  icon: Icons.receipt_long_outlined,
                  color: const Color(0xFF2563EB),
                  onTap: _ouvrirCreationFacture,
                )),
                const SizedBox(width: 12),
                Expanded(child: _buildQuickActionBtn(
                  label: 'Créer un contrat',
                  icon: Icons.description_outlined,
                  color: Colors.black,
                  onTap: _ouvrirModalContrat,
                )),
              ],
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ── Carte principale factures + KPI créances (compacte) ───────────────────
  Widget _buildMainStatCard(int nombreFactures, double creancesClients) {
    final creancesFormatted = NumberFormat('#,###', 'fr_FR')
        .format(creancesClients)
        .replaceAll(',', ' '); // espace fine insécable

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1a1a1a), Color(0xFF3a3a3a)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Badge Factures ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              '🧾  Factures',
              style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 10),
          // ── Nombre de factures ────────────────────────────────────────────
          Text(
            '$nombreFactures',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
              height: 1,
            ),
          ),
          Text(
            'enregistrées',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 10),
          ),
          // ── Séparateur ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(height: 0.5, color: Colors.white.withValues(alpha: 0.15)),
          ),
          // ── KPI Créances clients ──────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB347).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined,
                    color: Color(0xFFFFB347), size: 15),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Créances clients',
                      style: TextStyle(
                          color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '$creancesFormatted FCFA',
                      style: const TextStyle(
                        color: Color(0xFFFFB347),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Mini carte contrats (compacte) ──────────────────────────────────────────
  Widget _buildMiniStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: -0.8, height: 1)),
              const SizedBox(height: 1),
              Text('$subtitle $title',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bouton action rapide ────────────────────────────────────────────────────
  Widget _buildQuickActionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Actions boutons rapides ─────────────────────────────────────────────────
  void _ouvrirCreationFacture() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: di.sl<FactureBloc>(),
          child: const CreeFacture(),
        ),
      ),
    ).then((_) {
      if (mounted) context.read<DashboardBloc>().add(LoadDashboard());
    });
  }

  void _ouvrirModalContrat() {
    showContractTypeModal(context, user: widget.user);
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87, letterSpacing: -0.3),
        ),
      ],
    );
  }

  Widget _buildErrorCard(String error, VoidCallback onRetry) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
            child: Icon(Icons.error_outline, color: Colors.red[300], size: 26),
          ),
          const SizedBox(height: 12),
          const Text('Impossible de charger', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87, fontSize: 14)),
          const SizedBox(height: 4),
          Text(error, style: TextStyle(color: Colors.grey[400], fontSize: 12), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12)),
              child: const Text('Réessayer', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDocumentsSection(DashboardState state) {
    final docs = state is DashboardLoaded ? state.documentsRecents : [];
    final isLoading = state is DashboardLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Historique des factures'),
            GestureDetector(
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const HistoriqueFacturesPage())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                child: const Text('Voir tout →', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2.5),
            ),
          )
        else if (docs.isEmpty)
          _buildEmptyState()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _buildDocumentCard(docs[index], index),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 50),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
              child: Icon(Icons.inbox_outlined, size: 30, color: Colors.grey[400]),
            ),
            const SizedBox(height: 14),
            Text('Aucun document récent', style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Vos documents apparaîtront ici', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(dynamic doc, int index) {
    final client = doc['client'] ?? {};
    final clientName = '${client['prenom'] ?? ''} ${client['nom'] ?? ''}'.trim();
    final numeroFacture = doc['numero_facture'] ?? '—';
    final date = _formatDate(doc['date_execution']);
    final montant = _formatMontant(doc['montant']);
    final moyenPaiement = doc['moyen_paiement'] ?? '—';
    final lieuExecution = doc['lieu_execution'] ?? '—';

    final List<Color> iconColors = [
      const Color(0xFF6C63FF),
      const Color(0xFF00C896),
      const Color(0xFFFF6B6B),
      const Color(0xFFFFB347),
      const Color(0xFF4ECDC4),
    ];
    final iconColor = iconColors[index % iconColors.length];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.receipt_long_rounded, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(numeroFacture, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.black87)),
                      const SizedBox(height: 3),
                      Text(
                        clientName.isNotEmpty ? clientName : 'Client inconnu',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey[100], height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildInfoChip(Icons.monetization_on_outlined, 'Montant', montant, const Color(0xFF00C896))),
                    const SizedBox(width: 10),
                    Expanded(child: _buildInfoChip(Icons.calendar_today_outlined, 'Date', date, const Color(0xFF6C63FF))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildInfoChip(Icons.payment_outlined, 'Paiement', moyenPaiement, const Color(0xFFFFB347))),
                    const SizedBox(width: 10),
                    Expanded(child: _buildInfoChip(Icons.location_on_outlined, 'Lieu', lieuExecution, const Color(0xFFFF6B6B))),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: GestureDetector(
              onTap: () => _ouvrirDocument(doc['id'], doc['numero_facture'] ?? 'Document'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(14)),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.open_in_new_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text('Voir Facture', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[400], fontWeight: FontWeight.w500)),
                const SizedBox(height: 1),
                Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black87), overflow: TextOverflow.ellipsis, maxLines: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingDialog extends StatelessWidget {
  const _LoadingDialog();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 60),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.black87, strokeWidth: 2.5),
          SizedBox(height: 18),
          Text('Ouverture du document…', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
          SizedBox(height: 4),
          Text('Veuillez patienter', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

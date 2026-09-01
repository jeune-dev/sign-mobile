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
import 'package:sign_application/features/parcours/presentation/parcours_document.dart';
import 'package:sign_application/features/parcours/type_document_signs.dart';
import 'package:sign_application/features/facture/presentation/bloc/facture_bloc.dart';
import 'package:sign_application/features/contrat/presentation/widgets/contract_type_modal.dart';
import 'package:sign_application/core/widgets/pdf_viewer_page.dart';
import 'package:sign_application/core/widgets/pdf_loading_dialog.dart';
import 'package:sign_application/injection_container.dart' as di;
import 'package:toastification/toastification.dart';
import 'package:sign_application/core/widgets/toastNotif.dart';
import 'package:sign_application/core/theme/app_color.dart';

class HomeProfessionnelPage extends StatefulWidget {
  final User? user;

  /// Bascule vers l'onglet Contrats de la page hote.
  ///
  /// Fourni par le parent plutot que declenche ici : l'accueil est un onglet
  /// parmi d'autres, il n'a pas a empiler une page par-dessus lui-meme ni a
  /// connaitre l'index de ses voisins.
  final VoidCallback? onVoirContrats;

  const HomeProfessionnelPage({super.key, this.user, this.onVoirContrats});

  @override
  State<HomeProfessionnelPage> createState() => _HomeProfessionnelPageState();
}

class _HomeProfessionnelPageState extends State<HomeProfessionnelPage>
    with SingleTickerProviderStateMixin {
  bool _localeReady = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  static final _montantFmt = NumberFormat('#,###', 'fr_FR');
  static final _dateFmtFr  = DateFormat('dd MMM yyyy', 'fr_FR');
  static final _dateFmt    = DateFormat('dd/MM/yyyy');

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
      return _localeReady ? _dateFmtFr.format(dt) : _dateFmt.format(dt);
    } catch (_) {
      return dateString;
    }
  }

  String _formatMontant(dynamic montant) {
    if (montant == null) return '—';
    try {
      final num val = num.parse(montant.toString());
      return '${_montantFmt.format(val).replaceAll(',', ' ')} FCFA';
    } catch (_) {
      return '$montant FCFA';
    }
  }

  Future<void> _ouvrirDocument(String documentId, String numeroFacture) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PdfLoadingDialog(),
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
          showToast(context, 'Erreur', state.message, ToastificationType.error);
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
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
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
        showToast(context, 'Erreur', 'Erreur ouverture: $e', ToastificationType.error);
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
            // Ni salutation ni phrase d'introduction : l'ecran s'ouvre
            // directement sur les chiffres, qui se passent de presentation.
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
    final creancesFormatted = _montantFmt.format(creancesClients).replaceAll(',', ' ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColor.kTexte, Color(0xFF3a3a3a)],
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
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.receipt_long_outlined, size: 11, color: Colors.white70),
              SizedBox(width: 4),
              Text('Factures', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 10),
          // ── Nombre de factures ────────────────────────────────────────────
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '$nombreFactures',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.5,
                height: 1,
              ),
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
  /// Carte compacte d'un type de contrat.
  ///
  /// Le chevron dit que la carte mene quelque part : elle bascule sur
  /// l'onglet Contrats. Sans lui, rien ne laissait deviner qu'elle etait
  /// actionnable.
  Widget _buildMiniStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Material(
      color: AppColor.kSurface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: widget.onVoirContrats,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColor.kLine),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(value,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColor.kTexte, letterSpacing: -0.8, height: 1)),
                    ),
                    const SizedBox(height: 3),
                    // Deux lignes autorisees : sur une seule, « Contrats
                    // Travail » depassait la place disponible et se
                    // terminait par une ellipse.
                    Text('$subtitle $title',
                        style: const TextStyle(fontSize: 12, color: AppColor.kTexteMoyen, fontWeight: FontWeight.w600, height: 1.25),
                        maxLines: 2),
                  ],
                ),
              ),
              if (widget.onVoirContrats != null) ...[
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColor.kTexteFaible),
              ],
            ],
          ),
        ),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Actions boutons rapides ─────────────────────────────────────────────────
  /// Le raccourci de l'accueil poussait `CreeFacture` directement, sans passer
  /// par `ParcoursDocument.ouvrir`. Il contournait donc le contrôle de quota
  /// que la page Factures applique : un compte non vérifié pouvait continuer à
  /// créer des factures au-delà de sa limite en partant de l'accueil.
  ///
  /// Les deux entrées empruntent désormais la même garde — c'est elle qui
  /// vérifie le quota, réclame les informations manquantes et annonce les
  /// documents restants.
  Future<void> _ouvrirCreationFacture() async {
    await ParcoursDocument.ouvrir(
      context,
      typeDocument: TypeDocumentSigns.facture,
      page: (_) => BlocProvider.value(
        value: di.sl<FactureBloc>(),
        child: const CreeFacture(),
      ),
    );
    if (mounted) context.read<DashboardBloc>().add(LoadDashboard());
  }

  void _ouvrirModalContrat() {
    showContractTypeModal(context, user: widget.user);
  }

  /// Titre de section : texte seul.
  ///
  /// Le filet vertical qui le precedait ajoutait un element graphique sans
  /// rien distinguer — il etait identique devant chaque titre.
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: AppColor.kTexte,
        letterSpacing: -0.3,
      ),
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
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Text('Voir tout →',
                    style: TextStyle(
                        color: AppColor.kTexte,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 4)),
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
                  decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
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
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.12)),
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


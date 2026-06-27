import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:sign_application/core/config/env.dart';
import 'package:sign_application/core/utils/download_helper.dart';
import 'package:sign_application/features/facture/presentation/bloc/facture_bloc.dart';
import 'package:sign_application/features/facture/presentation/bloc/facture_event.dart';
import 'package:sign_application/features/facture/presentation/bloc/facture_state.dart';
import 'package:sign_application/injection_container.dart' as di;

class HistoriqueFacturesPage extends StatefulWidget {
  const HistoriqueFacturesPage({super.key});

  @override
  State<HistoriqueFacturesPage> createState() => _HistoriqueFacturesPageState();
}

class _HistoriqueFacturesPageState extends State<HistoriqueFacturesPage> {
  List<dynamic> _documents = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  bool _localeReady = false;
  final Set<String> _downloading = {};

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null).then((_) {
      if (mounted) setState(() => _localeReady = true);
    });
    context.read<FactureBloc>().add(LoadFactures(limit: 10));
  }

  void _fetchDocuments({int page = 1}) {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _currentPage = page;
    });
    context.read<FactureBloc>().add(LoadFactures(page: page, limit: 10));
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

  Future<void> _telechargerDocument(
    String documentId,
    String numeroFacture,
  ) async {
    if (_downloading.contains(documentId)) return;
    setState(() => _downloading.add(documentId));

    try {
      // 1. Télécharger les bytes depuis l'API
      final response = await di.sl<Dio>().get(
        '${Env.documentTelecharger}/$documentId',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur serveur (${response.statusCode})');
      }

      final Uint8List bytes = response.data is Uint8List
          ? response.data
          : Uint8List.fromList(List<int>.from(response.data));

      // 2. Nom propre du fichier
      final safeName = numeroFacture.replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '_');
      final fileName = '$safeName.pdf';

      // 3. Sauvegarder dans Téléchargements via le helper commun
      final savedPath = await savePdfToDownloads(bytes, fileName);

      if (!mounted) return;

      // 4. Snackbar succès avec bouton Ouvrir
      showDownloadSuccessSnackBar(context, fileName, savedPath);
    } catch (e) {
      if (!mounted) return;
      showDownloadErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _downloading.remove(documentId));
    }
  }

  // ───────────────────────────── BUILD ─────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocListener<FactureBloc, FactureState>(
      listener: (context, state) {
        if (state is FacturesLoaded) {
          setState(() {
            _documents = state.factures.map((f) => {
              'id': f.id,
              'numero_facture': f.numeroFacture,
              'date_execution': f.dateExecution,
              'lieu_execution': f.lieuExecution,
              'montant': f.montant,
              'avance': f.avance,
              'moyen_paiement': f.moyenPaiement,
              'tva': f.tva,
              'client': f.client,
            }).toList();
            // ← Pagination depuis le backend
            _totalPages = state.totalPages;
            _totalItems = state.total;
            _currentPage = state.currentPage;
            _isLoading = false;
            _errorMessage = '';
          });
        }
        if (state is FactureError) {
          setState(() {
            _errorMessage = state.message;
            _isLoading = false;
          });
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: _buildAppBar(),
        body: RefreshIndicator(
          color: Colors.black87,
          onRefresh: () async => _fetchDocuments(page: _currentPage),
          child: _buildBody(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1a1a1a),
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_rounded,
              color: Colors.white, size: 20),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historique des factures',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (_totalItems > 0)
            Text(
              '$_totalItems facture${_totalItems > 1 ? 's' : ''}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.black87, strokeWidth: 2.5),
            SizedBox(height: 14),
            Text(
              'Chargement…',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                    color: Colors.red[50], shape: BoxShape.circle),
                child: Icon(Icons.error_outline,
                    color: Colors.red[300], size: 28),
              ),
              const SizedBox(height: 14),
              const Text('Erreur de chargement',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 6),
              Text(_errorMessage,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _fetchDocuments(page: 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Réessayer',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: Colors.grey[200], shape: BoxShape.circle),
              child:
              Icon(Icons.inbox_outlined, size: 36, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            Text('Aucune facture trouvée',
                style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Vos factures apparaîtront ici',
                style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            itemCount: _documents.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _buildFactureCard(_documents[index], index),
          ),
        ),
        if (_totalPages > 1) _buildPagination(),
      ],
    );
  }

  Widget _buildFactureCard(dynamic doc, int index) {
    final client = doc['client'] ?? {};
    final clientName =
    '${client['prenom'] ?? ''} ${client['nom'] ?? ''}'.trim();
    final numeroFacture = doc['numero_facture'] ?? '—';
    final date = _formatDate(doc['date_execution']);
    final montant = _formatMontant(doc['montant']);
    final moyenPaiement = doc['moyen_paiement'] ?? '—';
    final lieuExecution = doc['lieu_execution'] ?? '—';
    final tva = doc['tva'] != null ? '${doc['tva']}%' : '—';
    final documentId = doc['id'] ?? '';
    final isDownloading = _downloading.contains(documentId);

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
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.receipt_long_rounded,
                      color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        numeroFacture,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Colors.black87,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        clientName.isNotEmpty ? clientName : 'Client inconnu',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                // Badge montant
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C896).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    montant,
                    style: const TextStyle(
                      color: Color(0xFF00C896),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(color: Colors.grey[100], height: 1),

          // ── Infos ──
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _buildInfoChip(
                            Icons.calendar_today_outlined,
                            'Date',
                            date,
                            const Color(0xFF6C63FF))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _buildInfoChip(
                            Icons.payment_outlined,
                            'Paiement',
                            moyenPaiement,
                            const Color(0xFFFFB347))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        child: _buildInfoChip(
                            Icons.location_on_outlined,
                            'Lieu',
                            lieuExecution,
                            const Color(0xFFFF6B6B))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _buildInfoChip(
                            Icons.percent_outlined,
                            'TVA',
                            tva,
                            const Color(0xFF4ECDC4))),
                  ],
                ),
              ],
            ),
          ),

          // ── Bouton télécharger ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: GestureDetector(
              onTap: isDownloading
                  ? null
                  : () => _telechargerDocument(documentId, numeroFacture),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: isDownloading
                      ? Colors.grey[300]
                      : Colors.black,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: isDownloading
                    ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        color: Colors.black54,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Téléchargement…',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.download_rounded,
                        color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Télécharger la facture',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
      IconData icon, String label, String value, Color color) {
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
                Text(label,
                    style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    final canPrev = _currentPage > 1;
    final canNext = _currentPage < _totalPages;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[100]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── Info total + page en cours ─────────────────────────────
            Text(
              '$_totalItems facture${_totalItems > 1 ? 's' : ''} · Page $_currentPage sur $_totalPages',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            // ── Boutons + numéros de pages ─────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ← Précédent
                _paginationBtn(
                  icon: Icons.chevron_left_rounded,
                  enabled: canPrev,
                  onTap: () => _fetchDocuments(page: _currentPage - 1),
                ),
                const SizedBox(width: 8),

                // Numéros de pages (fenêtre glissante)
                ..._buildPageNumbers(),

                const SizedBox(width: 8),
                // → Suivant
                _paginationBtn(
                  icon: Icons.chevron_right_rounded,
                  enabled: canNext,
                  onTap: () => _fetchDocuments(page: _currentPage + 1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Génère les numéros de pages visibles (fenêtre de 5 max)
  List<Widget> _buildPageNumbers() {
    if (_totalPages <= 1) return [];

    final List<Widget> items = [];
    int start = (_currentPage - 2).clamp(1, _totalPages);
    int end = (start + 4).clamp(1, _totalPages);
    if (end - start < 4) start = (end - 4).clamp(1, _totalPages);

    // "1 ..." si nécessaire
    if (start > 1) {
      items.add(_pageNumBtn(1));
      if (start > 2) items.add(_ellipsis());
    }

    for (int p = start; p <= end; p++) {
      items.add(_pageNumBtn(p));
    }

    // "... n" si nécessaire
    if (end < _totalPages) {
      if (end < _totalPages - 1) items.add(_ellipsis());
      items.add(_pageNumBtn(_totalPages));
    }

    return items;
  }

  Widget _pageNumBtn(int page) {
    final isActive = page == _currentPage;
    return GestureDetector(
      onTap: isActive ? null : () => _fetchDocuments(page: page),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: isActive ? null : Border.all(color: Colors.grey[200]!),
        ),
        child: Center(
          child: Text(
            '$page',
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black87,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _ellipsis() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: 28,
      alignment: Alignment.center,
      child: Text('…',
          style: TextStyle(color: Colors.grey[400], fontSize: 14)),
    );
  }

  Widget _paginationBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled ? Colors.black : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : Colors.grey[400],
          size: 22,
        ),
      ),
    );
  }
}
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sign_application/core/config/env.dart';
import 'package:sign_application/core/utils/download_helper.dart';
import 'package:sign_application/core/widgets/empty_state.dart';
import 'package:sign_application/core/widgets/shimmer_list.dart';
import 'package:sign_application/features/auth/domain/entities/user.dart';
import 'package:sign_application/features/facture/domain/entities/facture.dart';
import 'package:sign_application/features/facture/presentation/bloc/facture_bloc.dart';
import 'package:sign_application/features/facture/presentation/bloc/facture_event.dart';
import 'package:sign_application/features/facture/presentation/bloc/facture_state.dart';
import 'package:sign_application/injection_container.dart' as di;
import 'package:sign_application/features/facture/presentation/pages/cree_facture_page.dart';
import 'package:sign_application/core/widgets/pdf_viewer_page.dart';
import 'package:toastification/toastification.dart';
import 'package:sign_application/core/widgets/toastNotif.dart';

class FacturesPage extends StatefulWidget {
  final User? user;
  const FacturesPage({super.key, this.user});

  @override
  State<FacturesPage> createState() => _FacturesPageState();
}

class _FacturesPageState extends State<FacturesPage> {
  final Set<String> _downloading = {};
  static final _dateFmt   = DateFormat('dd/MM/yyyy');
  static final _montantFmt = NumberFormat('#,###', 'fr_FR');

  @override
  void initState() {
    super.initState();
    context.read<FactureBloc>().add(LoadFactures());
  }

  // ── Formatage ────────────────────────────────────────────────────────────
  String _formatDate(String? d) {
    if (d == null || d.isEmpty) return '—';
    try {
      return _dateFmt.format(DateTime.parse(d));
    } catch (_) {
      return d;
    }
  }

  String _formatMontant(dynamic v) {
    if (v == null) return '—';
    try {
      final num val = num.parse(v.toString());
      return '${_montantFmt.format(val).replaceAll(',', ' ')} FCFA';
    } catch (_) {
      return '$v FCFA';
    }
  }

  Color _statusColor(Facture doc) {
    switch (doc.statut) {
      case 'payee': return Colors.green;
      case 'partiel': return Colors.orange;
      default:
        if (doc.avance >= doc.montant) return Colors.green;
        if (doc.avance > 0) return Colors.orange;
        return Colors.red;
    }
  }

  String _statusText(Facture doc) {
    switch (doc.statut) {
      case 'payee': return 'Payée';
      case 'partiel': return 'Partiel';
      case 'en_attente': return 'En attente';
      default:
        if (doc.avance >= doc.montant) return 'Payée';
        if (doc.avance > 0) return 'Incomplet';
        return 'Non payée';
    }
  }

  // ── Ouvrir le document (même logique que l'accueil) ───────────────────────
  // ── Mise à jour de facture (UX fintech) ──────────────────────────────────
  void _ouvrirModalMiseAJour(Facture doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FactureMiseAJourSheet(
        doc: doc,
        formatMontant: _formatMontant,
        onConfirm: (avance, statut) {
          context.read<FactureBloc>().add(MettreAJourFactureEvent(
            documentId: doc.id,
            avance: avance,
            statut: statut,
          ));
        },
      ),
    );
  }

  Future<void> _confirmerRenvoyer(Facture doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renvoyer la facture'),
        content: Text('Voulez-vous renvoyer la facture ${doc.numeroFacture ?? ''} au client ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white),
            child: const Text('Renvoyer'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<FactureBloc>().add(RenvoyerFactureEvent(doc.id));
    }
  }

  void _ouvrirDocument(String documentId, String numeroFacture) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: _LoadingDialog()),
    );
    context.read<FactureBloc>().add(OuvrirDocumentEvent(documentId, titre: numeroFacture));
  }

  Future<void> _saveAndOpenPdf(List<int> bytes, String documentId) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/doc_$documentId.pdf');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerPage(
            filePath: file.path,
            titre: documentId,
          ),
        ),
      );
      // Recharger après retour du PDF
      if (mounted) context.read<FactureBloc>().add(LoadFactures());
    } catch (e) {
      if (mounted) {
        showToast(context, 'Erreur', 'Erreur ouverture: $e', ToastificationType.error);
      }
    }
  }

  // ── Télécharger le document (même logique que l'historique) ──────────────
  Future<void> _telechargerDocument(String documentId, String numeroFacture) async {
    if (_downloading.contains(documentId)) return;
    setState(() => _downloading.add(documentId));

    try {
      // 1. Télécharger les bytes
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

      final safeName = numeroFacture.replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '_');
      final fileName = '$safeName.pdf';

      // 2. Sauvegarder via le helper commun
      final savedPath = await savePdfToDownloads(bytes, fileName);

      if (!mounted) return;

      // 3. Snackbar succès avec bouton Ouvrir
      showDownloadSuccessSnackBar(context, fileName, savedPath);
    } catch (e) {
      if (!mounted) return;
      showDownloadErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _downloading.remove(documentId));
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocListener<FactureBloc, FactureState>(
      listener: (context, state) {
        if (state is DocumentBytes) {
          if (Navigator.canPop(context)) Navigator.pop(context);
          _saveAndOpenPdf(state.bytes, state.titre);
        }
        if (state is FactureMiseAJourSuccess) {
          showToast(context, 'Mise à jour', 'Facture mise à jour avec succès', ToastificationType.success);
          context.read<FactureBloc>().add(LoadFactures());
        }
        if (state is FactureRenvoyeeSuccess) {
          if (Navigator.canPop(context)) Navigator.pop(context);
          showToast(context, 'Email envoyé', 'La facture a été renvoyée avec succès', ToastificationType.success);
        }
        if (state is FactureError) {
          if (Navigator.canPop(context)) Navigator.pop(context);
          showToast(context, 'Erreur', state.message, ToastificationType.error);
        }
      },
      child: BlocBuilder<FactureBloc, FactureState>(
        builder: (context, state) {
          final isLoading = state is FactureLoading;
          final factures = state is FacturesLoaded ? state.factures : const <Facture>[];
          final totalPages = state is FacturesLoaded ? state.totalPages : 1;
          final currentPage = state is FacturesLoaded ? state.currentPage : 1;
          final total = state is FacturesLoaded ? state.total : 0;

          // Stats calculées
          double montantTotal = 0;
          int payees = 0, enAttente = 0;
          for (final f in factures) {
            montantTotal += f.montant;
            if (f.statut == 'payee') payees++; else enAttente++;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header stats ──────────────────────────────────────────
              _buildHeader(total, payees, enAttente, montantTotal, isLoading),

              // ── Bouton créer ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreeFacture()),
                      );
                      if (context.mounted) {
                        context.read<FactureBloc>().add(LoadFactures());
                      }
                    },
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Nouvelle facture',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),

              // ── Liste ────────────────────────────────────────────────
              Expanded(child: _buildBody(state, factures, isLoading)),

              // ── Pagination ───────────────────────────────────────────
              if (totalPages > 1) _buildPagination(currentPage, totalPages),
            ],
          );
        },
      ),
    );
  }

  // ── Header stats ──────────────────────────────────────────────────────────
  Widget _buildHeader(int total, int payees, int enAttente,
      double montantTotal, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        children: [
          // Carte principale
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1a1a1a), Color(0xFF3a3a3a)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.receipt_outlined, size: 12, color: Colors.white70),
                          SizedBox(width: 4),
                          Text('Mes factures', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                      const SizedBox(height: 12),
                      isLoading
                          ? Container(
                              width: 60,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            )
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '$total',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -2,
                                  height: 1,
                                ),
                              ),
                            ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: Colors.white38, size: 32),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Deux mini cartes
          Row(
            children: [
              Expanded(child: _miniStatCard('Payées', '$payees', const Color(0xFF00C896), Icons.check_circle_outline)),
              const SizedBox(width: 12),
              Expanded(child: _miniStatCard('En attente', '$enAttente', const Color(0xFFFFB347), Icons.hourglass_bottom_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                          height: 1)),
                ),
                Text(title,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Corps ─────────────────────────────────────────────────────────────────
  Widget _buildBody(
      FactureState state, List<Facture> factures, bool isLoading) {
    if (isLoading && factures.isEmpty) {
      return const ShimmerList();
    }

    if (state is FactureError && factures.isEmpty) {
      return _buildError(state.message);
    }

    if (factures.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      color: Colors.black87,
      onRefresh: () async => context.read<FactureBloc>().add(LoadFactures()),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: factures.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            _buildFactureCard(factures[index], index),
      ),
    );
  }

  // ── Carte facture (même design que l'historique) ───────────────────────────
  Widget _buildFactureCard(Facture doc, int index) {
    final List<Color> iconColors = [
      const Color(0xFF6C63FF),
      const Color(0xFF00C896),
      const Color(0xFFFF6B6B),
      const Color(0xFFFFB347),
      const Color(0xFF4ECDC4),
    ];
    final iconColor = iconColors[index % iconColors.length];
    final clientName =
        '${doc.client?['prenom'] ?? ''} ${doc.client?['nom'] ?? ''}'.trim();
    final numeroFacture = doc.numeroFacture ?? '—';
    final date = _formatDate(doc.dateExecution);
    final montant = _formatMontant(doc.montant);
    final moyenPaiement = doc.moyenPaiement ?? '—';
    final lieuExecution = doc.lieuExecution ?? '—';
    final isDownloading = _downloading.contains(doc.id);
    final statusColor = _statusColor(doc);
    final statusText = _statusText(doc);

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
          // ── Header ──────────────────────────────────────────────────
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
                      Text(numeroFacture,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: Colors.black87)),
                      const SizedBox(height: 3),
                      Text(
                          clientName.isNotEmpty ? clientName : 'Client inconnu',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                // Badge statut
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(statusText,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),

          Divider(color: Colors.grey[100], height: 1),

          // ── Infos chips ──────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _infoChip(Icons.monetization_on_outlined,
                            'Montant', montant, const Color(0xFF00C896))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _infoChip(Icons.calendar_today_outlined,
                            'Date', date, const Color(0xFF6C63FF))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        child: _infoChip(Icons.payment_outlined, 'Paiement',
                            moyenPaiement, const Color(0xFFFFB347))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _infoChip(Icons.location_on_outlined, 'Lieu',
                            lieuExecution, const Color(0xFFFF6B6B))),
                  ],
                ),
              ],
            ),
          ),

          Divider(color: Colors.grey[100], height: 1),

          // ── Actions ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Télécharger
                Expanded(
                  child: GestureDetector(
                    onTap: isDownloading
                        ? null
                        : () => _telechargerDocument(doc.id, numeroFacture),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isDownloading
                            ? Colors.grey[100]
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: isDownloading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      color: Colors.black54, strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('Téléchargement…',
                                    style: TextStyle(
                                        color: Colors.black45,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.download_rounded,
                                    size: 16, color: Colors.black54),
                                SizedBox(width: 6),
                                Text('Télécharger',
                                    style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Voir le document
                Expanded(
                  child: GestureDetector(
                    onTap: () => _ouvrirDocument(doc.id, numeroFacture),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.open_in_new_rounded,
                              color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text('Voir Facture',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Bouton action selon statut ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: doc.statut == 'payee'
                ? Column(
                    children: [
                      GestureDetector(
                        onTap: () => _ouvrirDocument(doc.id, doc.numeroFacture ?? ''),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C896).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF00C896).withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined, color: Color(0xFF00C896), size: 16),
                              SizedBox(width: 6),
                              Text('Voir la facture',
                                  style: TextStyle(
                                      color: Color(0xFF00C896),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => _confirmerRenvoyer(doc),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded, color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text('Renvoyer la facture',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: () => _ouvrirModalMiseAJour(doc),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_outlined, color: Colors.orange[700], size: 16),
                          const SizedBox(width: 6),
                          Text('Mettre à jour la facture',
                              style: TextStyle(
                                  color: Colors.orange[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, String value, Color color) {
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
                Text(value,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Pagination ────────────────────────────────────────────────────────────
  Widget _buildPagination(int currentPage, int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _pageBtn(
            label: 'Précédent',
            icon: Icons.chevron_left_rounded,
            enabled: currentPage > 1,
            iconLeft: true,
            onTap: () =>
                context.read<FactureBloc>().add(LoadFactures(page: currentPage - 1)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$currentPage / $totalPages',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Colors.black87),
            ),
          ),
          _pageBtn(
            label: 'Suivant',
            icon: Icons.chevron_right_rounded,
            enabled: currentPage < totalPages,
            iconLeft: false,
            onTap: () =>
                context.read<FactureBloc>().add(LoadFactures(page: currentPage + 1)),
          ),
        ],
      ),
    );
  }

  Widget _pageBtn({
    required String label,
    required IconData icon,
    required bool enabled,
    required bool iconLeft,
    required VoidCallback onTap,
  }) {
    final children = [
      if (iconLeft) Icon(icon, size: 18, color: enabled ? Colors.white : Colors.grey[400]),
      if (iconLeft) const SizedBox(width: 4),
      Text(label,
          style: TextStyle(
              color: enabled ? Colors.white : Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w600)),
      if (!iconLeft) const SizedBox(width: 4),
      if (!iconLeft) Icon(icon, size: 18, color: enabled ? Colors.white : Colors.grey[400]),
    ];

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: enabled ? Colors.black : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: children),
      ),
    );
  }

  // ── Vide ──────────────────────────────────────────────────────────────────
  Widget _buildEmpty() => const EmptyState(
    icon: Icons.receipt_outlined,
    title: 'Aucune facture',
    subtitle: 'Vos factures créées apparaîtront ici',
    scrollable: false,
  );

  // ── Erreur ────────────────────────────────────────────────────────────────
  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration:
                BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
            child: Icon(Icons.error_outline, color: Colors.red[300], size: 32),
          ),
          const SizedBox(height: 14),
          const Text('Erreur de chargement',
              style:
                  TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 6),
          Text(message,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => context.read<FactureBloc>().add(LoadFactures()),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Réessayer',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sheet de mise à jour de facture (UX fintech) ─────────────────────────────
class _FactureMiseAJourSheet extends StatefulWidget {
  final Facture doc;
  final String Function(dynamic) formatMontant;
  final void Function(double? avance, String? statut) onConfirm;

  const _FactureMiseAJourSheet({
    required this.doc,
    required this.formatMontant,
    required this.onConfirm,
  });

  @override
  State<_FactureMiseAJourSheet> createState() => _FactureMiseAJourSheetState();
}

class _FactureMiseAJourSheetState extends State<_FactureMiseAJourSheet> {
  late final TextEditingController _avanceCtrl;
  late String _statut;
  // 0 = totalité, 1 = moitié, 2 = personnalisé
  int _quickChip = 2;

  double get _montant => widget.doc.montant;
  double get _dejaPaye => widget.doc.avance;
  double get _reste => _montant - _dejaPaye;
  double get _pourcent => _montant > 0 ? (_dejaPaye / _montant).clamp(0.0, 1.0) : 0.0;

  Color get _progressColor {
    if (_pourcent >= 1.0) return const Color(0xFF22C55E);
    if (_pourcent > 0) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  @override
  void initState() {
    super.initState();
    _statut = widget.doc.statut ?? 'en_attente';
    _avanceCtrl = TextEditingController(
      text: _reste > 0 ? _reste.toStringAsFixed(0) : '0',
    );
  }

  @override
  void dispose() {
    _avanceCtrl.dispose();
    super.dispose();
  }

  void _setQuick(int chip) {
    setState(() {
      _quickChip = chip;
      if (chip == 0) {
        _avanceCtrl.text = _montant.toStringAsFixed(0);
        _statut = 'payee';
      } else if (chip == 1) {
        _avanceCtrl.text = (_montant / 2).toStringAsFixed(0);
      }
    });
  }

  String _formatNum(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '${buf.toString()} FCFA';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // ── Drag handle ─────────────────────────────────────────────────
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ── Header avec ring de progression ────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  // Ring
                  SizedBox(
                    width: 64, height: 64,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 64, height: 64,
                          child: CircularProgressIndicator(
                            value: _pourcent,
                            strokeWidth: 5,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation(_progressColor),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Text(
                          '${(_pourcent * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _progressColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.doc.numeroFacture ?? 'Facture',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _miniStat('Total', _formatNum(_montant), Colors.black87),
                            const SizedBox(width: 16),
                            _miniStat('Payé', _formatNum(_dejaPaye), const Color(0xFF22C55E)),
                            const SizedBox(width: 16),
                            _miniStat('Reste', _formatNum(_reste), const Color(0xFFF97316)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, size: 17, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),

            // ── Corps ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chips rapides
                  Text('Montant reçu',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey[700])),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _quickBtn(0, 'Totalité', Icons.check_circle_outline),
                      const SizedBox(width: 8),
                      _quickBtn(1, '50 %', Icons.percent_rounded),
                      const SizedBox(width: 8),
                      _quickBtn(2, 'Autre', Icons.edit_outlined),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Champ montant
                  TextField(
                    controller: _avanceCtrl,
                    keyboardType: TextInputType.number,
                    onTap: () => setState(() => _quickChip = 2),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: '0',
                      suffixText: 'FCFA',
                      suffixStyle: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[400]),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(Icons.payments_outlined, size: 20, color: Colors.grey[500]),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.black87, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Statut
                  Text('Statut',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey[700])),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _statutTile('en_attente', 'En attente', Icons.hourglass_empty_rounded, const Color(0xFFEF4444))),
                      const SizedBox(width: 8),
                      Expanded(child: _statutTile('partiel', 'Partiel', Icons.incomplete_circle_rounded, const Color(0xFFF97316))),
                      const SizedBox(width: 8),
                      Expanded(child: _statutTile('payee', 'Payée', Icons.check_circle_rounded, const Color(0xFF22C55E))),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Bouton confirmer
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      final v = double.tryParse(_avanceCtrl.text.trim());
                      widget.onConfirm(v, _statut);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('Enregistrer la mise à jour',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[500], fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }

  Widget _quickBtn(int chip, String label, IconData icon) {
    final selected = _quickChip == chip;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setQuick(chip),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.black87 : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : Colors.grey[500]),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : Colors.grey[500],
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statutTile(String value, String label, IconData icon, Color color) {
    final selected = _statut == value;
    final locked = _quickChip == 0;
    return GestureDetector(
      onTap: locked ? null : () => setState(() => _statut = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.10) : Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Colors.grey[200]!,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: selected ? color : Colors.grey[400]),
            const SizedBox(height: 5),
            Text(label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  color: selected ? color : Colors.grey[500],
                )),
          ],
        ),
      ),
    );
  }
}

class _LoadingDialog extends StatelessWidget {
  const _LoadingDialog();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80, height: 80,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: const Center(child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2.5)),
    );
  }
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
import 'package:toastification/toastification.dart';
import 'package:sign_application/core/widgets/toastNotif.dart';
import 'package:sign_application/core/widgets/pdf_viewer_page.dart';
import '../bloc/particulier_bloc.dart';
import '../bloc/particulier_event.dart';
import '../bloc/particulier_state.dart';
import '../../domain/entities/particulier_contrat.dart';

// ── Filtres par type ───────────────────────────────────────────────────────────
class _TypeFilter {
  final String? value;
  final String label;
  final IconData icon;
  const _TypeFilter({required this.value, required this.label, required this.icon});
}

const _kFilters = [
  _TypeFilter(value: null,                      label: 'Tous',          icon: Icons.grid_view_rounded),
  _TypeFilter(value: 'contrat-bail',            label: 'Bail',          icon: Icons.home_work_rounded),
  _TypeFilter(value: 'etat-des-lieux',          label: 'État des lieux',icon: Icons.checklist_rounded),
  _TypeFilter(value: 'contrat-travail',         label: 'Travail',       icon: Icons.work_rounded),
  _TypeFilter(value: 'contrat-prestation',      label: 'Prestation',    icon: Icons.handshake_rounded),
  _TypeFilter(value: 'contrat-partenariat',     label: 'Partenariat',   icon: Icons.people_rounded),
  _TypeFilter(value: 'contrat-location',        label: 'Location',      icon: Icons.directions_car_rounded),
  _TypeFilter(value: 'reconnaissance-dette',    label: 'Reconnaissance',icon: Icons.receipt_long_rounded),
  _TypeFilter(value: 'procuration',             label: 'Procuration',   icon: Icons.manage_accounts_rounded),
  _TypeFilter(value: 'contrat-caution',         label: 'Caution',       icon: Icons.security_rounded),
  _TypeFilter(value: 'contrat-confidentialite', label: 'Conf.',         icon: Icons.lock_rounded),
];

Color _colorForType(String type) {
  switch (type) {
    case 'contrat-bail':            return const Color(0xFF1565C0);
    case 'etat-des-lieux':          return const Color(0xFF2E7D32);
    case 'contrat-travail':         return const Color(0xFF6A1B9A);
    case 'contrat-prestation':      return const Color(0xFFE65100);
    case 'contrat-partenariat':     return const Color(0xFF00838F);
    case 'contrat-location':        return const Color(0xFF558B2F);
    case 'reconnaissance-dette':    return const Color(0xFFBF360C);
    case 'procuration':             return const Color(0xFF37474F);
    case 'contrat-caution':         return const Color(0xFF4527A0);
    case 'contrat-confidentialite': return const Color(0xFF283593);
    default:                        return Colors.black87;
  }
}

IconData _iconForType(String type) {
  switch (type) {
    case 'contrat-bail':            return Icons.home_work_rounded;
    case 'etat-des-lieux':          return Icons.checklist_rounded;
    case 'contrat-travail':         return Icons.work_rounded;
    case 'contrat-prestation':      return Icons.handshake_rounded;
    case 'contrat-partenariat':     return Icons.people_rounded;
    case 'contrat-location':        return Icons.directions_car_rounded;
    case 'reconnaissance-dette':    return Icons.receipt_long_rounded;
    case 'procuration':             return Icons.manage_accounts_rounded;
    case 'contrat-caution':         return Icons.security_rounded;
    case 'contrat-confidentialite': return Icons.lock_rounded;
    default:                        return Icons.description_rounded;
  }
}

// ── Page principale ────────────────────────────────────────────────────────────
class ContratsASignerPage extends StatefulWidget {
  const ContratsASignerPage({super.key});

  @override
  State<ContratsASignerPage> createState() => _ContratsASignerPageState();
}

class _ContratsASignerPageState extends State<ContratsASignerPage> {
  String? _downloadingPdfFor;
  List<ParticulierContrat>? _contrats;
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _loadContrats();
  }

  void _loadContrats() =>
      context.read<ParticulierBloc>().add(LoadContrats(type: _selectedType));

  void _onFilterChanged(String? type) {
    setState(() => _selectedType = type);
    context.read<ParticulierBloc>().add(LoadContrats(type: type));
  }

  Future<void> _openPdf(Uint8List bytes, String fileName) async {
    final dir  = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PdfViewerPage(filePath: file.path, titre: fileName),
    ));
  }

  void _downloadAndOpenPdf(ParticulierContrat contrat) {
    setState(() => _downloadingPdfFor = contrat.id);
    context.read<ParticulierBloc>().add(
      DownloadContratPdf(type: contrat.type, contratId: contrat.id),
    );
  }

  void _ouvrirModalSignature(ParticulierContrat contrat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<ParticulierBloc>(),
        child: _SignatureModal(contrat: contrat),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F8),
      body: BlocConsumer<ParticulierBloc, ParticulierState>(
        listener: (ctx, state) {
          if (state is ContratsLoaded) {
            setState(() => _contrats = state.contrats);
          }
          if (state is ContratPdfReady && _downloadingPdfFor != null) {
            setState(() => _downloadingPdfFor = null);
            _openPdf(state.pdfBytes, 'contrat_${state.contratId}.pdf');
          }
          if (state is ContratSigne) {
            Navigator.of(ctx).pop();
            showToast(ctx, 'Contrat signé', 'Votre signature a été enregistrée avec succès', ToastificationType.success);
            _loadContrats();
          }
          if (state is ParticulierError && _downloadingPdfFor != null) {
            setState(() => _downloadingPdfFor = null);
            showToast(ctx, 'Erreur', state.message, ToastificationType.error);
          }
        },
        builder: (ctx, state) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(state)),
              if (_contrats == null)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2.5)),
                )
              else if (_contrats!.isEmpty)
                SliverFillRemaining(child: _buildEmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _ContratCard(
                        contrat:             _contrats![i],
                        isDownloadingPdf:    _downloadingPdfFor == _contrats![i].id,
                        onVoirContrat:       () => _downloadAndOpenPdf(_contrats![i]),
                        onSigner:            () => _ouvrirModalSignature(_contrats![i]),
                        onVoirDocumentSigne: () => _downloadAndOpenPdf(_contrats![i]),
                      ),
                      childCount: _contrats!.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(ParticulierState state) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A0A0A), Color(0xFF2A2A2A)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: top + 14),

          // Titre + actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MES CONTRATS À SIGNER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _loadContrats,
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: state is ParticulierLoading
                        ? const Center(child: SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                        : const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stats
          if (_contrats != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _statChip('${_contrats!.where((c) => !c.estSigne).length}', 'En attente', Colors.orange),
                  const SizedBox(width: 10),
                  _statChip('${_contrats!.where((c) =>  c.estSigne).length}', 'Signés',    Colors.green),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Filtres
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _kFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f   = _kFilters[i];
                final sel = _selectedType == f.value;
                return GestureDetector(
                  onTap: () => _onFilterChanged(f.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? Colors.white : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel ? Colors.white : Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(f.icon, size: 13,
                            color: sel ? Colors.black87 : Colors.white.withValues(alpha: 0.85)),
                        const SizedBox(width: 5),
                        Text(f.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                            color: sel ? Colors.black87 : Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _statChip(String count, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(count, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 17)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12)),
      ],
    ),
  );

  Widget _buildEmptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 86, height: 86,
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(Icons.draw_outlined, size: 36, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 20),
          Text('Aucun contrat à signer',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          Text(
            _selectedType == null
                ? 'Vous n\'avez pas encore reçu de contrat.'
                : 'Aucun contrat de ce type pour l\'instant.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          if (_selectedType != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              icon: const Icon(Icons.grid_view_rounded, size: 15),
              label: const Text('Voir tous les types'),
              onPressed: () => _onFilterChanged(null),
            ),
          ],
        ],
      ),
    ),
  );
}

// ── Card ───────────────────────────────────────────────────────────────────────
class _ContratCard extends StatelessWidget {
  final ParticulierContrat contrat;
  final bool isDownloadingPdf;
  final VoidCallback onVoirContrat;
  final VoidCallback onSigner;
  final VoidCallback onVoirDocumentSigne;

  const _ContratCard({
    required this.contrat,
    required this.isDownloadingPdf,
    required this.onVoirContrat,
    required this.onSigner,
    required this.onVoirDocumentSigne,
  });

  @override
  Widget build(BuildContext context) {
    final color    = _colorForType(contrat.type);
    final icon     = _iconForType(contrat.type);
    final emetteur = contrat.generateurEntreprise ?? contrat.generateurNom ?? '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.07),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              border: Border(bottom: BorderSide(color: color.withValues(alpha: 0.12))),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(contrat.typeLabel,
                        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
                      Text(contrat.numeroContrat,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    ],
                  ),
                ),
                _StatutBadge(estSigne: contrat.estSigne),
              ],
            ),
          ),

          // Corps
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey.shade400),
                    const SizedBox(width: 6),
                    Text('Émetteur : ', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    Expanded(
                      child: Text(emetteur,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isDownloadingPdf ? null : onVoirContrat,
                        icon: isDownloadingPdf
                            ? SizedBox(width: 13, height: 13,
                                child: CircularProgressIndicator(strokeWidth: 2, color: color))
                            : Icon(Icons.visibility_outlined, size: 15, color: color),
                        label: Text('Voir', style: TextStyle(fontSize: 12, color: color)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: color.withValues(alpha: 0.35)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (!contrat.estSigne)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onSigner,
                          icon: const Icon(Icons.draw_outlined, size: 15),
                          label: const Text('Signer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isDownloadingPdf ? null : onVoirDocumentSigne,
                          icon: const Icon(Icons.verified_outlined, size: 15),
                          label: const Text('Doc. signé', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Badge statut ───────────────────────────────────────────────────────────────
class _StatutBadge extends StatelessWidget {
  final bool estSigne;
  const _StatutBadge({required this.estSigne});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: estSigne ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: estSigne ? Colors.green.shade200 : Colors.orange.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            estSigne ? Icons.check_circle_rounded : Icons.schedule_rounded,
            size: 11,
            color: estSigne ? Colors.green.shade600 : Colors.orange.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            estSigne ? 'Signé' : 'En attente',
            style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: estSigne ? Colors.green.shade700 : Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Modal de signature ─────────────────────────────────────────────────────────
class _SignatureModal extends StatefulWidget {
  final ParticulierContrat contrat;
  const _SignatureModal({required this.contrat});

  @override
  State<_SignatureModal> createState() => _SignatureModalState();
}

class _SignatureModalState extends State<_SignatureModal> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 2.5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  bool _consentAccepted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_consentAccepted) {
      showToast(context, 'Consentement requis', 'Veuillez accepter les conditions avant de signer.', ToastificationType.warning);
      return;
    }
    if (_controller.isEmpty) {
      showToast(context, 'Signature manquante', 'Veuillez tracer votre signature.', ToastificationType.warning);
      return;
    }
    final Uint8List? data = await _controller.toPngBytes();
    if (data == null || !mounted) return;
    final base64Sig = 'data:image/png;base64,${base64Encode(data)}';
    context.read<ParticulierBloc>().add(
      SignerContrat(type: widget.contrat.type, contratId: widget.contrat.id, signature: base64Sig),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(widget.contrat.type);
    return BlocBuilder<ParticulierBloc, ParticulierState>(
      builder: (ctx, state) {
        final isLoading = state is ContratSignatureEnCours;
        return Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 18),

                Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_iconForType(widget.contrat.type), color: color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Signer le document',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                          Text(widget.contrat.typeLabel,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Bannière
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.draw_rounded, color: color, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Votre signature requise',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
                            const SizedBox(height: 2),
                            const Text('Dessinez votre signature dans le cadre ci-dessous.',
                                style: TextStyle(fontSize: 11, color: Colors.black54)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Pad
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Signature(
                      controller: _controller,
                      height: 170,
                      backgroundColor: const Color(0xFFFAFAFA),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.clear, size: 14),
                    label: const Text('Effacer', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey),
                    onPressed: () => _controller.clear(),
                  ),
                ),

                // Consentement
                GestureDetector(
                  onTap: () => setState(() => _consentAccepted = !_consentAccepted),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color: _consentAccepted ? color : Colors.white,
                          border: Border.all(color: _consentAccepted ? color : Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: _consentAccepted
                            ? const Icon(Icons.check, color: Colors.white, size: 14)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'J\'accepte les conditions et je consens à signer électroniquement ce contrat.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF4B5563), height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                      elevation: 0,
                    ),
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.verified_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Confirmer et signer',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

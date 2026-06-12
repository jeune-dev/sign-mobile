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

class ContratsASignerPage extends StatefulWidget {
  const ContratsASignerPage({super.key});

  @override
  State<ContratsASignerPage> createState() => _ContratsASignerPageState();
}

class _ContratsASignerPageState extends State<ContratsASignerPage> {
  // Contrat en cours de téléchargement PDF (pour éviter doubles appels)
  String? _downloadingPdfFor;

  @override
  void initState() {
    super.initState();
    context.read<ParticulierBloc>().add(const LoadContrats());
  }

  Future<void> _openPdf(Uint8List bytes, String fileName) async {
    final dir = await getTemporaryDirectory();
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Mes contrats à signer',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocConsumer<ParticulierBloc, ParticulierState>(
        listener: (ctx, state) {
          if (state is ContratPdfReady && _downloadingPdfFor != null) {
            setState(() => _downloadingPdfFor = null);
            _openPdf(state.pdfBytes, 'contrat_${state.contratId}.pdf');
          }
          if (state is ContratSigne) {
            Navigator.of(ctx).pop(); // ferme le modal
            showToast(ctx, 'Contrat signé', 'Votre signature a été enregistrée avec succès', ToastificationType.success);
            // Recharge la liste
            ctx.read<ParticulierBloc>().add(const LoadContrats());
          }
          if (state is ParticulierError && _downloadingPdfFor != null) {
            setState(() => _downloadingPdfFor = null);
            showToast(ctx, 'Erreur', state.message, ToastificationType.error);
          }
        },
        builder: (ctx, state) {
          if (state is ParticulierLoading || state is ContratPdfLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }

          List<ParticulierContrat> contrats = [];
          if (state is ContratsLoaded) contrats = state.contrats;

          if (contrats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.draw_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun contrat à signer',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vous n\'avez pas encore reçu de contrat.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: Colors.black,
            onRefresh: () async {
              ctx.read<ParticulierBloc>().add(const LoadContrats());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: contrats.length,
              itemBuilder: (_, i) => _ContratCard(
                contrat:               contrats[i],
                isDownloadingPdf:      _downloadingPdfFor == contrats[i].id,
                onVoirContrat:         () => _downloadAndOpenPdf(contrats[i]),
                onSigner:              () => _ouvrirModalSignature(contrats[i]),
                onVoirDocumentSigne:   () => _downloadAndOpenPdf(contrats[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Card d'un contrat ─────────────────────────────────────────────────────────
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
    final emetteur = contrat.generateurEntreprise ?? contrat.generateurNom ?? '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête ───────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(contrat.typeLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(contrat.numeroContrat,
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ),
                _StatutBadge(estSigne: contrat.estSigne),
              ],
            ),
            const SizedBox(height: 8),
            Text('Émetteur : $emetteur',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 14),

            // ── Actions ───────────────────────────────────────────
            Row(
              children: [
                // Voir le contrat
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isDownloadingPdf ? null : onVoirContrat,
                    icon: isDownloadingPdf
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54))
                        : const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('Voir', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Signer OU Voir document signé
                if (contrat.peutSigner && !contrat.estSigne)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onSigner,
                      icon: const Icon(Icons.draw_outlined, size: 16),
                      label: const Text('Signer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  )
                else if (contrat.estSigne)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isDownloadingPdf ? null : onVoirDocumentSigne,
                      icon: const Icon(Icons.verified_outlined, size: 16),
                      label: const Text('Doc. signé', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
    );
  }
}

// ── Badge statut ──────────────────────────────────────────────────────────────
class _StatutBadge extends StatelessWidget {
  final bool estSigne;
  const _StatutBadge({required this.estSigne});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: estSigne ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: estSigne ? Colors.green.shade200 : Colors.orange.shade200),
      ),
      child: Text(
        estSigne ? 'Signé' : 'En attente',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: estSigne ? Colors.green.shade700 : Colors.orange.shade700,
        ),
      ),
    );
  }
}

// ── Modal de signature ────────────────────────────────────────────────────────
class _SignatureModal extends StatefulWidget {
  final ParticulierContrat contrat;
  const _SignatureModal({required this.contrat});

  @override
  State<_SignatureModal> createState() => _SignatureModalState();
}

class _SignatureModalState extends State<_SignatureModal> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 2,
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
      SignerContrat(
        type:      widget.contrat.type,
        contratId: widget.contrat.id,
        signature: base64Sig,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ParticulierBloc, ParticulierState>(
      builder: (ctx, state) {
        final isLoading = state is ContratSignatureEnCours;
        return Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Handle ──────────────────────────────────────
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Titre ────────────────────────────────────────
                Text('Signer le contrat',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(widget.contrat.typeLabel,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                const SizedBox(height: 20),

                // ── Canvas signature ─────────────────────────────
                const Text('Votre signature', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Signature(
                      controller: _controller,
                      height: 160,
                      backgroundColor: Colors.grey.shade50,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.clear, size: 14, color: Colors.grey),
                    label: const Text('Effacer', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    onPressed: () => _controller.clear(),
                  ),
                ),
                const SizedBox(height: 8),

                // ── Consentement ─────────────────────────────────
                GestureDetector(
                  onTap: () => setState(() => _consentAccepted = !_consentAccepted),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          color: _consentAccepted ? Colors.black : Colors.white,
                          border: Border.all(color: _consentAccepted ? Colors.black : Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: _consentAccepted
                            ? const Icon(Icons.check, color: Colors.white, size: 14)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'J\'accepte les conditions et je consens à signer électroniquement ce contrat.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Bouton ───────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Confirmer et signer',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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

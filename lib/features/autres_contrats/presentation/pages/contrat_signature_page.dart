import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';

import 'package:sign_application/core/config/env.dart';
import 'package:sign_application/injection_container.dart' as di;
import '../../domain/entities/autre_contrat.dart';
import '../bloc/autres_contrats_bloc.dart';
import '../bloc/autres_contrats_event.dart';
import '../bloc/autres_contrats_state.dart';

class ContratSignaturePage extends StatefulWidget {
  final AutreContrat contrat;
  final String type;

  const ContratSignaturePage({
    super.key,
    required this.contrat,
    required this.type,
  });

  @override
  State<ContratSignaturePage> createState() => _ContratSignaturePageState();
}

class _ContratSignaturePageState extends State<ContratSignaturePage> {
  // ── PDF ──────────────────────────────────────────────────────────────────
  String? _pdfPath;
  bool _pdfLoading = true;
  String? _pdfError;
  int _currentPage = 1;
  int _totalPages = 0;
  PDFViewController? _pdfController;

  // ── Signature ─────────────────────────────────────────────────────────────
  Uint8List? _signatureBytes;
  bool _accepted = false;
  bool _signing = false;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final url = '${Env.autresContratsBase(widget.type)}/${widget.contrat.id}/download';
      final resp = await di.sl<Dio>().get(url, options: Options(responseType: ResponseType.bytes));
      if (resp.statusCode != 200) throw Exception('Erreur ${resp.statusCode}');
      final bytes = resp.data is List<int> ? resp.data as List<int> : List<int>.from(resp.data);
      final dir = await getTemporaryDirectory();
      final num = (widget.contrat.numeroContrat ?? widget.contrat.id).replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '_');
      final file = File('${dir.path}/sign_${widget.type}_$num.pdf');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      setState(() {
        _pdfPath = file.path;
        _pdfLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _pdfLoading = false; _pdfError = e.toString(); });
    }
  }

  Future<void> _openSignaturePad() async {
    final controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );

    final bytes = await showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Votre signature', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity, height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8FA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Signature(controller: controller, width: double.infinity, height: 180),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Dessinez votre signature ci-dessus',
                style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => controller.clear(), child: const Text('Effacer')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.isEmpty) return;
              final data = await controller.toPngBytes();
              if (data == null) return;
              if (dialogContext.mounted) Navigator.pop(dialogContext, data);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Valider'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (bytes != null && mounted) {
      setState(() => _signatureBytes = bytes);
    }
  }

  Future<void> _submit() async {
    if (!_accepted) {
      _showError('Veuillez accepter les conditions du contrat');
      return;
    }
    if (_signatureBytes == null) {
      _showError('Veuillez apposer votre signature');
      return;
    }
    setState(() => _signing = true);
    final sigBase64 = base64Encode(_signatureBytes!);
    if (!mounted) return;
    context.read<AutresContratsBloc>().add(SignerContrat(widget.type, widget.contrat.id, sigBase64));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red[700]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titre = widget.contrat.numeroContrat ?? widget.contrat.id;

    return BlocListener<AutresContratsBloc, AutresContratsState>(
      listener: (ctx, state) {
        if (state is AutresContratsSuccess) {
          setState(() => _signing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contrat signé avec succès ! Les deux parties ont été notifiées.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.pop(context, true);
        } else if (state is AutresContratsError) {
          setState(() => _signing = false);
          _showError(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        body: Column(
          children: [
            // ── AppBar ────────────────────────────────────────────────────
            _buildAppBar(titre),

            // ── PDF ───────────────────────────────────────────────────────
            Expanded(child: _buildPdfSection()),

            // ── Section signature ─────────────────────────────────────────
            _buildSignatureSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(String titre) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: Colors.black,
      padding: EdgeInsets.fromLTRB(16, top + 12, 16, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Signature du contrat',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                Text(titre,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: const [
                Icon(Icons.draw_outlined, color: Colors.white, size: 14),
                SizedBox(width: 5),
                Text('Signer', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfSection() {
    if (_pdfLoading) {
      return Container(
        color: const Color(0xFFF2F2F7),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12)]),
              child: const Center(child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2.5)),
            ),
            const SizedBox(height: 14),
            const Text('Chargement du document…', style: TextStyle(color: Colors.black54, fontSize: 13)),
          ]),
        ),
      );
    }
    if (_pdfError != null || _pdfPath == null) {
      return Container(
        color: const Color(0xFFF2F2F7),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 40),
            const SizedBox(height: 12),
            const Text('Impossible de charger le document', style: TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 8),
            TextButton(onPressed: () { setState(() { _pdfLoading = true; _pdfError = null; }); _loadPdf(); },
                child: const Text('Réessayer')),
          ]),
        ),
      );
    }
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 14, offset: const Offset(0, 3))],
              ),
              child: PDFView(
                filePath: _pdfPath!,
                enableSwipe: true,
                swipeHorizontal: false,
                autoSpacing: false,
                pageFling: true,
                fitEachPage: true,
                fitPolicy: FitPolicy.WIDTH,
                backgroundColor: Colors.white,
                onRender: (pages) {
                  if (mounted) setState(() { _totalPages = pages ?? 0; _currentPage = 1; });
                },
                onViewCreated: (ctrl) => _pdfController = ctrl,
                onPageChanged: (page, total) {
                  if (mounted) setState(() { _currentPage = (page ?? 0) + 1; _totalPages = total ?? 0; });
                },
              ),
            ),
          ),
        ),
        if (_totalPages > 1)
          Positioned(
            bottom: 14, left: 0, right: 0,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _pdfNavBtn(Icons.chevron_left_rounded, _currentPage > 1, () => _pdfController?.setPage(_currentPage - 2)),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
                child: Text('$_currentPage / $_totalPages',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 16),
              _pdfNavBtn(Icons.chevron_right_rounded, _currentPage < _totalPages, () => _pdfController?.setPage(_currentPage)),
            ]),
          ),
      ],
    );
  }

  Widget _pdfNavBtn(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: enabled ? Colors.black : Colors.grey[300],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: enabled ? Colors.white : Colors.grey[400], size: 22),
      ),
    );
  }

  Widget _buildSignatureSection() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Color(0x12000000), blurRadius: 20, offset: Offset(0, -4))],
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Trait de drag ─────────────────────────────────────────────
          Center(
            child: Container(width: 36, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),

          // ── Conditions ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8FA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _accepted ? Colors.black : const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: Colors.black54),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'En signant ce document, vous reconnaissez avoir lu et accepté '
                        "l'intégralité des termes et conditions du présent contrat. "
                        'Votre signature électronique a valeur légale et vous engage '
                        'au même titre qu\'une signature manuscrite.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF4B5563), height: 1.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => setState(() => _accepted = !_accepted),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color: _accepted ? Colors.black : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _accepted ? Colors.black : Colors.grey[400]!),
                        ),
                        child: _accepted
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      const Text('J\'accepte les termes et conditions',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Label signature ───────────────────────────────────────────
          const Text('Votre signature *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87)),
          const SizedBox(height: 8),

          // ── Pad de signature ──────────────────────────────────────────
          GestureDetector(
            onTap: _openSignaturePad,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 90, width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8FA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _signatureBytes != null ? Colors.black : const Color(0xFFE5E7EB),
                  width: _signatureBytes != null ? 2 : 1,
                ),
              ),
              child: _signatureBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(_signatureBytes!, fit: BoxFit.contain),
                    )
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.draw_outlined, size: 24, color: Colors.black38),
                      const SizedBox(height: 4),
                      const Text('Touchez pour signer',
                          style: TextStyle(color: Colors.black38, fontWeight: FontWeight.w600, fontSize: 12)),
                    ]),
            ),
          ),
          const SizedBox(height: 14),

          // ── Bouton soumettre ──────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _signing ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.black38,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _signing
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Signer le contrat', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

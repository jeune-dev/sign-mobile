import 'dart:convert';
import 'dart:io';

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
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  bool _accepted = false;
  bool _signing = false;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
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


  Future<void> _submit() async {
    if (!_accepted) {
      _showError('Veuillez accepter les conditions du contrat');
      return;
    }
    if (_signatureController.isEmpty) {
      _showError('Veuillez apposer votre signature');
      return;
    }
    setState(() => _signing = true);
    final bytes = await _signatureController.toPngBytes();
    if (bytes == null || !mounted) return;
    final sigBase64 = 'data:image/png;base64,${base64Encode(bytes)}';
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
    const accent = Colors.black87;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, -4))],
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

          // ── Bannière ──────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.draw_rounded, color: Colors.black87, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Votre signature requise',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black87)),
                      SizedBox(height: 2),
                      Text('Dessinez votre signature ci-dessous pour valider ce contrat.',
                          style: TextStyle(fontSize: 11, color: Colors.black54), maxLines: 2),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Pad signature inline ──────────────────────────────────────
          Container(
            // La Column parente est en CrossAxisAlignment.start : sans largeur
            // explicite, le pad s'effondre à 0 px de large et reste invisible.
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black.withValues(alpha: 0.3), width: 2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Signature(
                controller: _signatureController,
                width: double.infinity,
                height: 180,
                backgroundColor: const Color(0xFFFAFAFA),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.clear, size: 15, color: Colors.black45),
              label: const Text('Effacer', style: TextStyle(color: Colors.black45, fontSize: 12)),
              onPressed: () => _signatureController.clear(),
            ),
          ),

          // ── Case à cocher consentement ────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _accepted = !_accepted),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: _accepted ? Colors.black87 : Colors.white,
                    border: Border.all(color: _accepted ? Colors.black87 : Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: _accepted
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'En signant, je reconnais avoir lu et accepté l\'intégralité des termes de ce contrat. '
                    'Ma signature électronique a valeur légale.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF4B5563), height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Bouton soumettre ──────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _signing ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.black26,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _signing
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Signer le contrat',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:open_file/open_file.dart';

class PdfViewerPage extends StatefulWidget {
  final String filePath;
  final String titre;

  const PdfViewerPage({
    super.key,
    required this.filePath,
    required this.titre,
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  int _totalPages = 0;
  int _currentPage = 1;
  bool _isReady = false;
  bool _hasError = false;
  String _errorMsg = '';
  PDFViewController? _controller;

  Future<void> _goToPrev() async {
    if (_currentPage > 1 && _controller != null) {
      await _controller!.setPage(_currentPage - 2);
    }
  }

  Future<void> _goToNext() async {
    if (_currentPage < _totalPages && _controller != null) {
      await _controller!.setPage(_currentPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: Colors.white, size: 20),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.titre,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_isReady && _totalPages > 0)
              Text(
                'Page $_currentPage sur $_totalPages',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 11,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded,
                color: Colors.white, size: 20),
            onPressed: () => OpenFile.open(widget.filePath),
            tooltip: 'Ouvrir dans une autre app',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── PDF ──────────────────────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                // Fond gris clair derrière le PDF
                Container(color: const Color(0xFFF2F2F7)),

                // PDF avec marges horizontales pour le rendu "page avec ombre"
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: PDFView(
                        filePath: widget.filePath,
                        enableSwipe: true,
                        swipeHorizontal: false,
                        autoSpacing: false,
                        pageFling: true,
                        pageSnap: true,
                        fitEachPage: true,
                        fitPolicy: FitPolicy.WIDTH,
                        defaultPage: 0,
                        backgroundColor: Colors.white,
                        onRender: (pages) {
                          if (mounted) {
                            setState(() {
                              _totalPages = pages ?? 0;
                              _isReady = true;
                              _currentPage = 1;
                            });
                          }
                        },
                        onViewCreated: (controller) {
                          _controller = controller;
                        },
                        onPageChanged: (page, total) {
                          if (mounted) {
                            setState(() {
                              _currentPage = (page ?? 0) + 1;
                              _totalPages = total ?? 0;
                            });
                          }
                        },
                        onError: (error) {
                          if (mounted) {
                            setState(() {
                              _hasError = true;
                              _errorMsg = error.toString();
                              _isReady = true;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),

                // ── Loading overlay ─────────────────────────────────────
                if (!_isReady) _buildLoading(),

                // ── Error overlay ───────────────────────────────────────
                if (_hasError) _buildError(),
              ],
            ),
          ),

          // ── Bottom bar navigation ─────────────────────────────────────
          if (_isReady && !_hasError && _totalPages > 1)
            _buildBottomNav(),
        ],
      ),
    );
  }

  // ── Bottom navigation bar ─────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ← Précédent
            _navBtn(
              icon: Icons.chevron_left_rounded,
              enabled: _currentPage > 1,
              onTap: _goToPrev,
            ),
            const SizedBox(width: 24),

            // Compteur de page
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                '$_currentPage / $_totalPages',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            const SizedBox(width: 24),
            // → Suivant
            _navBtn(
              icon: Icons.chevron_right_rounded,
              enabled: _currentPage < _totalPages,
              onTap: _goToNext,
            ),
          ],
        ),
      ),
    );
  }

  Widget _navBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: enabled ? Colors.black : Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : Colors.grey[400],
          size: 26,
        ),
      ),
    );
  }

  // ── Loading ───────────────────────────────────────────────────────────────
  Widget _buildLoading() {
    return Container(
      color: const Color(0xFFF2F2F7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.black87,
                  strokeWidth: 2.5,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Chargement du document…',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Erreur ────────────────────────────────────────────────────────────────
  Widget _buildError() {
    return Container(
      color: const Color(0xFFF2F2F7),
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(Icons.error_outline, color: Colors.red[400], size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'Impossible d\'ouvrir ce document',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              _errorMsg,
              style: const TextStyle(fontSize: 12, color: Colors.black38),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}

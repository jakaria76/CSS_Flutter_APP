import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class PdfViewerPage extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerPage({
    super.key,
    required this.pdfUrl,
    required this.title,
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  final PdfViewerController _pdfCtrl = PdfViewerController();

  bool    _isLoading       = true;
  bool    _hasError        = false;
  double  _downloadProgress = 0;
  int     _totalPages      = 0;
  int     _currentPage     = 1;
  File?   _localFile;

  @override
  void initState() {
    super.initState();
    _downloadPdf();
  }

  @override
  void dispose() {
    _pdfCtrl.dispose();
    super.dispose();
  }

  // ── Download PDF ───────────────────────────────────────────────
  Future<void> _downloadPdf() async {
    if (mounted) setState(() {
      _isLoading        = true;
      _hasError         = false;
      _downloadProgress = 0;
    });

    try {
      final request  = http.Request('GET', Uri.parse(widget.pdfUrl));
      request.headers.addAll({
        'Accept'    : 'application/pdf,application/octet-stream,*/*',
        'User-Agent': 'Mozilla/5.0 FlutterApp',
      });

      final streamed = await http.Client()
          .send(request)
          .timeout(const Duration(seconds: 60));

      if (streamed.statusCode != 200) {
        throw Exception('HTTP ${streamed.statusCode}');
      }

      final contentLength = streamed.contentLength ?? 0;
      final bytes = <int>[];

      await for (final chunk in streamed.stream) {
        bytes.addAll(chunk);
        if (contentLength > 0 && mounted) {
          setState(() =>
          _downloadProgress = bytes.length / contentLength);
        }
      }

      if (bytes.isEmpty) throw Exception('Empty file');

      // PDF magic bytes check (%PDF)
      if (bytes.length < 4 ||
          bytes[0] != 0x25 ||
          bytes[1] != 0x50 ||
          bytes[2] != 0x44 ||
          bytes[3] != 0x46) {
        throw Exception('Not a valid PDF file');
      }

      final dir  = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/pdf_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes, flush: true);

      if (mounted) setState(() {
        _localFile = file;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('PDF download error: $e');
      if (mounted) setState(() {
        _isLoading = false;
        _hasError  = true;
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (_, __, ___) => _buildPage(),
    );
  }

  Widget _buildPage() {
    final isDark    = SC.isDark;
    final accent    = isDark ? const Color(0xFF00FFFF) : SC.cyan;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final appBarBg  = isDark ? const Color(0xFF0C1525) : Colors.white;
    final bodyBg    = isDark ? const Color(0xFF0A0F1A) : const Color(0xFFF0F4FF);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bodyBg,

        // ── AppBar ────────────────────────────────────────────────
        appBar: AppBar(
          backgroundColor: appBarBg,
          elevation: 0,
          toolbarHeight: 54,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: textColor, size: 15),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (_totalPages > 0)
                Text(
                  '$_currentPage / $_totalPages পৃষ্ঠা',
                  style: TextStyle(
                    color: accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () => _pdfCtrl.zoomLevel =
                  (_pdfCtrl.zoomLevel - 0.25).clamp(0.75, 4.0),
              icon: Icon(Icons.zoom_out_rounded, color: accent, size: 22),
            ),
            IconButton(
              onPressed: () => _pdfCtrl.zoomLevel =
                  (_pdfCtrl.zoomLevel + 0.25).clamp(0.75, 4.0),
              icon: Icon(Icons.zoom_in_rounded, color: accent, size: 22),
            ),
            const SizedBox(width: 4),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.transparent,
                  accent,
                  const Color(0xFF7B61FF),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
        ),

        // ── Body ──────────────────────────────────────────────────
        body: _isLoading
            ? _buildLoading(isDark, accent, bodyBg)
            : _hasError || _localFile == null
            ? _buildError(isDark, accent, bodyBg)
            : SfPdfViewer.file(
          _localFile!,
          controller: _pdfCtrl,
          pageLayoutMode: PdfPageLayoutMode.continuous,
          scrollDirection: PdfScrollDirection.vertical,
          canShowScrollHead: true,
          canShowScrollStatus: true,
          canShowPaginationDialog: false,
          initialZoomLevel: 1.0,
          onDocumentLoaded: (details) {
            if (mounted) setState(() {
              _totalPages = details.document.pages.count;
            });
          },
          onPageChanged: (details) {
            if (mounted) setState(() {
              _currentPage = details.newPageNumber;
            });
          },
          onDocumentLoadFailed: (details) {
            if (mounted) setState(() => _hasError = true);
          },
        ),
      ),
    );
  }

  // ── Loading ────────────────────────────────────────────────────
  Widget _buildLoading(bool isDark, Color accent, Color bodyBg) {
    return Container(
      color: bodyBg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 60, height: 60,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _downloadProgress > 0 ? _downloadProgress : null,
                    color: accent,
                    backgroundColor: accent.withValues(alpha: 0.08),
                    strokeWidth: 3,
                  ),
                  if (_downloadProgress > 0)
                    Text(
                      '${(_downloadProgress * 100).toInt()}%',
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _downloadProgress > 0
                  ? 'ডাউনলোড হচ্ছে...'
                  : 'PDF লোড হচ্ছে...',
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.4),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error ──────────────────────────────────────────────────────
  Widget _buildError(bool isDark, Color accent, Color bodyBg) {
    return Container(
      color: bodyBg,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFFFF6B6B).withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFFF6B6B), size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'PDF লোড করতে সমস্যা হয়েছে',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1A2332),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ইন্টারনেট সংযোগ চেক করুন এবং আবার চেষ্টা করুন।',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.5),
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _downloadPdf,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 13),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [accent, SC.blue]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.refresh_rounded,
                      color: isDark ? Colors.black : Colors.white,
                      size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'আবার চেষ্টা করুন',
                    style: TextStyle(
                      color: isDark ? Colors.black : Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
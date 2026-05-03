import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

/// In-app PDF viewer.
///
/// - [pdfUrl]     : already-fixed URL (raw/upload for Cloudinary).
/// - [originalUrl]: original URL used for "Open in Browser" fallback.
///
/// If you only have one URL, pass it for both params.
class NoticePdfViewer extends StatefulWidget {
  final String pdfUrl;
  final String originalUrl;

  const NoticePdfViewer({
    super.key,
    required this.pdfUrl,
    required this.originalUrl,
  });

  @override
  State<NoticePdfViewer> createState() => _NoticePdfViewerState();
}

class _NoticePdfViewerState extends State<NoticePdfViewer> {
  bool _loading = true;
  String? _localPath;
  String? _error;
  int _currentPage = 0;
  int _totalPages = 0;
  PDFViewController? _pdfController;
  double _downloadProgress = 0;

  @override
  void initState() {
    super.initState();
    _downloadAndShowPdf();
  }

  Future<void> _downloadAndShowPdf() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
        _downloadProgress = 0;
      });
    }

    try {
      final request = http.Request('GET', Uri.parse(widget.pdfUrl));
      request.headers.addAll({
        'Accept': 'application/pdf,application/octet-stream,*/*',
        'User-Agent': 'Mozilla/5.0 FlutterApp',
      });

      final streamedResponse = await http.Client().send(request);

      if (streamedResponse.statusCode != 200) {
        throw Exception('HTTP ${streamedResponse.statusCode}');
      }

      final contentLength = streamedResponse.contentLength ?? 0;
      final bytes = <int>[];

      await for (final chunk in streamedResponse.stream) {
        bytes.addAll(chunk);
        if (contentLength > 0 && mounted) {
          setState(() => _downloadProgress = bytes.length / contentLength);
        }
      }

      if (bytes.isEmpty) throw Exception('Downloaded file is empty');

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/notice_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes, flush: true);

      if (await file.length() == 0) {
        throw Exception('Saved file is empty (size=0)');
      }

      // Validate PDF magic bytes (%PDF)
      final header = bytes.take(4).toList();
      final isPdf = header.length >= 4 &&
          header[0] == 0x25 &&
          header[1] == 0x50 &&
          header[2] == 0x44 &&
          header[3] == 0x46;

      if (!isPdf) {
        final preview = String.fromCharCodes(bytes.take(200));
        debugPrint('Not a PDF! Preview: $preview');
        throw Exception('সঠিক PDF পাওয়া যায়নি (content type mismatch)');
      }

      if (mounted) {
        setState(() {
          _localPath = file.path;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'PDF লোড করা যায়নি\n$e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _openInBrowser(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = SC.isDark;
    final bg = isDark ? const Color(0xFF070C16) : const Color(0xFFF0F4FF);
    const accent = Color(0xFF00FFFF);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor:
        isDark ? const Color(0xFF0C1525) : Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.07)
                  : Colors.black.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.10)
                    : Colors.black.withOpacity(0.08),
              ),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : const Color(0xFF1A2332),
              size: 16,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              SC.tr('noticePdfViewer'),
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1A2332),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (_totalPages > 0)
              Text(
                '${_currentPage + 1} / $_totalPages',
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withOpacity(0.4)
                      : Colors.black.withOpacity(0.4),
                  fontSize: 11,
                ),
              ),
          ],
        ),
        actions: [
          if (_localPath != null)
            GestureDetector(
              onTap: () => _openInBrowser(widget.originalUrl),
              child: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.07)
                      : Colors.black.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.10)
                        : Colors.black.withOpacity(0.08),
                  ),
                ),
                child: const Icon(
                  Icons.open_in_new_rounded,
                  color: accent,
                  size: 16,
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(
            height: 2,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFF00FFFF), Color(0xFF7B61FF)]),
            ),
          ),
        ),
      ),

      // ── Body ──
      body: _loading
          ? _buildLoading(accent, isDark)
          : _error != null
          ? _buildError(accent, isDark)
          : PDFView(
        filePath: _localPath!,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        fitPolicy: FitPolicy.BOTH,
        backgroundColor: isDark
            ? const Color(0xFF070C16)
            : const Color(0xFFF0F4FF),
        onRender: (pages) =>
            setState(() => _totalPages = pages ?? 0),
        onPageChanged: (page, _) =>
            setState(() => _currentPage = page ?? 0),
        onViewCreated: (ctrl) =>
            setState(() => _pdfController = ctrl),
        onError: (e) => setState(
                () => _error = 'PDF রেন্ডার করা যায়নি: $e'),
        onPageError: (page, e) =>
            debugPrint('Page $page error: $e'),
      ),

      // ── Page navigation bar ──
      bottomNavigationBar: _localPath != null && _totalPages > 1
          ? Container(
        color: isDark ? const Color(0xFF0C1525) : Colors.white,
        padding:
        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _navButton(
              icon: Icons.arrow_back_ios_new_rounded,
              enabled: _currentPage > 0,
              onTap: () =>
                  _pdfController?.setPage(_currentPage - 1),
              accent: accent,
            ),
            Text(
              '${_currentPage + 1} / $_totalPages',
              style: TextStyle(
                color:
                isDark ? Colors.white : const Color(0xFF1A2332),
                fontWeight: FontWeight.w700,
              ),
            ),
            _navButton(
              icon: Icons.arrow_forward_ios_rounded,
              enabled: _currentPage < _totalPages - 1,
              onTap: () =>
                  _pdfController?.setPage(_currentPage + 1),
              accent: accent,
            ),
          ],
        ),
      )
          : null,
    );
  }

  // ── Loading state ──────────────────────────────────────────────
  Widget _buildLoading(Color accent, bool isDark) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(
              value: _downloadProgress > 0 ? _downloadProgress : null,
              color: accent,
              backgroundColor: accent.withOpacity(0.1),
              strokeWidth: 3,
            ),
            if (_downloadProgress > 0)
              Text(
                '${(_downloadProgress * 100).toInt()}%',
                style: TextStyle(
                  color: accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ]),
        ),
        const SizedBox(height: 16),
        Text(
          _downloadProgress > 0
              ? 'ডাউনলোড হচ্ছে...'
              : SC.tr('noticePdfLoading'),
          style: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.4)
                : Colors.black.withOpacity(0.4),
            fontSize: 13,
          ),
        ),
      ]),
    );
  }

  // ── Error state ────────────────────────────────────────────────
  Widget _buildError(Color accent, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withOpacity(0.1),
              shape: BoxShape.circle,
              border:
              Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.3)),
            ),
            child: const Icon(Icons.error_outline_rounded,
                color: Color(0xFFFF6B6B), size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            'PDF খোলা যায়নি',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1A2332),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark
                  ? Colors.white.withOpacity(0.4)
                  : Colors.black.withOpacity(0.5),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            // Retry
            GestureDetector(
              onTap: _downloadAndShowPdf,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [accent, SC.blue]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.refresh_rounded,
                      color: isDark ? Colors.black : Colors.white,
                      size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'আবার চেষ্টা করুন',
                    style: TextStyle(
                      color: isDark ? Colors.black : Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(width: 12),
            // Open in browser
            GestureDetector(
              onTap: () => _openInBrowser(widget.originalUrl),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.07)
                      : Colors.black.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.12)
                        : Colors.black.withOpacity(0.10),
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.open_in_new_rounded,
                      color:
                      isDark ? Colors.white70 : Colors.black54,
                      size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Browser এ খুলুন',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  // ── Nav button helper ──────────────────────────────────────────
  Widget _navButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    required Color accent,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
        const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: enabled ? accent.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
            enabled ? accent.withOpacity(0.3) : Colors.transparent,
          ),
        ),
        child: Icon(icon,
            color: enabled ? accent : Colors.grey, size: 16),
      ),
    );
  }
}
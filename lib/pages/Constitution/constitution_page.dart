import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:css/pages/Constitution/pdf_viewer_page.dart';
import 'package:css/models/constitution_model.dart';
import 'package:css/services/constitution_service.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class ConstitutionPage extends StatefulWidget {
  const ConstitutionPage({super.key});

  @override
  State<ConstitutionPage> createState() => _ConstitutionPageState();
}

class _ConstitutionPageState extends State<ConstitutionPage>
    with TickerProviderStateMixin {
  final _service = ConstitutionService();

  bool _loading = true;
  List<ConstitutionFile> _files = [];
  String? _error;

  late AnimationController _listAnim;
  late AnimationController _pulseAnim;
  late AnimationController _headerAnim;

  // Track which card is being opened (for loading state)
  String? _openingId;

  @override
  void initState() {
    super.initState();
    _listAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _pulseAnim =
    AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _headerAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _fetch();
  }

  @override
  void dispose() {
    _listAnim.dispose();
    _pulseAnim.dispose();
    _headerAnim.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────
  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error   = null;
    });
    try {
      _files = await _service.fetchFiles();
      _listAnim.forward(from: 0);
    } catch (e) {
      _error = 'Constitution ফাইল লোড করতে সমস্যা হয়েছে';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openPdf(ConstitutionFile file) async {
    setState(() => _openingId = file.id);
    final url = _service.getViewUrl(file.pdfUrl);
    if (url.isEmpty) {
      if (mounted) SC.toast(context, 'ফাইলের URL পাওয়া যায়নি', SC.red);
      if (mounted) setState(() => _openingId = null);
      return;
    }
    if (mounted) setState(() => _openingId = null);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerPage(pdfUrl: url, title: file.name),
      ),
    );
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
    final isDark = SC.isDark;
    final bg     = isDark ? const Color(0xFF070C16) : const Color(0xFFF0F4FF);
    final accent = isDark ? const Color(0xFF00FFFF) : SC.cyan;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(children: [
          // Background orbs
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Stack(children: [
              Positioned(
                top: -100, right: -80,
                child: _orb(280, accent,
                    (isDark ? 0.06 : 0.03) + _pulseAnim.value * 0.02),
              ),
              Positioned(
                bottom: 200, left: -60,
                child: _orb(200, const Color(0xFF7B61FF),
                    (isDark ? 0.05 : 0.02) + _pulseAnim.value * 0.02),
              ),
            ]),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(isDark, accent),
              if (_loading)
                SliverFillRemaining(
                  child: Center(child: _buildLoader(isDark, accent)),
                )
              else if (_error != null)
                SliverFillRemaining(child: _buildError(isDark, accent))
              else if (_files.isEmpty)
                  SliverFillRemaining(child: _buildEmpty(isDark, accent))
                else
                  _buildList(isDark, accent),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _orb(double size, Color color, double opacity) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
          colors: [color.withOpacity(opacity), color.withOpacity(0)]),
    ),
  );

  // ── AppBar ─────────────────────────────────────────────────────
  Widget _buildAppBar(bool isDark, Color accent) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final bg        = isDark ? const Color(0xFF070C16) : const Color(0xFFF0F4FF);

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      elevation: 0,
      backgroundColor: bg,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : Colors.black.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.10)
                    : Colors.black.withOpacity(0.08)),
          ),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              color: textColor, size: 16),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: _fetch,
          child: Container(
            margin: const EdgeInsets.all(10),
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.07)
                  : Colors.black.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.10)
                      : Colors.black.withOpacity(0.08)),
            ),
            child: Icon(Icons.refresh_rounded, color: accent, size: 18),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(bottom: 16, left: 20),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'CSS OFFICIAL',
                style: TextStyle(
                    color: accent, fontSize: 8,
                    fontWeight: FontWeight.w800, letterSpacing: 2),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'গঠনতন্ত্র',
              style: TextStyle(
                  color: textColor, fontSize: 18,
                  fontWeight: FontWeight.w900, letterSpacing: -0.3),
            ),
          ],
        ),
        background: _buildHeaderBg(isDark, accent),
      ),
    );
  }

  Widget _buildHeaderBg(bool isDark, Color accent) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D1F3A), Color(0xFF070C16)])
            : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFDEEEFB), Color(0xFFF0F4FF)]),
      ),
      child: Stack(children: [
        // Decorative icon
        Positioned(
          right: 20, bottom: 60,
          child: Opacity(
            opacity: isDark ? 0.06 : 0.05,
            child: Icon(Icons.menu_book_rounded, size: 160, color: accent),
          ),
        ),
        // Stats row
        Positioned(
          bottom: 56, left: 20,
          child: Row(children: [
            _stat('${_files.length}', 'মোট ফাইল', accent, isDark),
          ]),
        ),
        // Top gradient line
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                const Color(0xFF7B61FF),
                accent,
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _stat(String value, String label, Color color, bool isDark) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 26,
                fontWeight: FontWeight.w900, letterSpacing: -1)),
        Text(label,
            style: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.4)
                    : Colors.black.withOpacity(0.4),
                fontSize: 10, fontWeight: FontWeight.w600)),
      ]);

  // ── List ───────────────────────────────────────────────────────
  Widget _buildList(bool isDark, Color accent) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (ctx, i) {
            final f     = _files[i];
            final delay = (i * 0.07).clamp(0.0, 0.5);
            return AnimatedBuilder(
              animation: _listAnim,
              builder: (_, child) {
                final p = Curves.easeOutCubic.transform(
                    ((_listAnim.value - delay) / (1 - delay)).clamp(0.0, 1.0));
                return Opacity(
                  opacity: p,
                  child: Transform.translate(
                      offset: Offset(0, 28 * (1 - p)), child: child),
                );
              },
              child: _buildFileCard(f, isDark, accent),
            );
          },
          childCount: _files.length,
        ),
      ),
    );
  }

  Widget _buildFileCard(ConstitutionFile file, bool isDark, Color accent) {
    final cardBg  = isDark ? const Color(0xFF0C1525) : Colors.white;
    final border  = isDark
        ? Colors.white.withOpacity(0.07)
        : Colors.black.withOpacity(0.07);
    final isOpening = _openingId == file.id;

    return GestureDetector(
      onTap: isOpening ? null : () => _openPdf(file),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isOpening ? accent.withOpacity(0.4) : border),
          boxShadow: !isDark
              ? [BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4))]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(children: [
                // PDF icon with pulse when opening
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: isOpening
                        ? accent.withOpacity(0.15)
                        : const Color(0xFFFF6B6B).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: isOpening
                            ? accent.withOpacity(0.4)
                            : const Color(0xFFFF6B6B).withOpacity(0.25)),
                  ),
                  child: isOpening
                      ? Center(
                    child: SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                        color: accent, strokeWidth: 2,
                      ),
                    ),
                  )
                      : const Icon(Icons.picture_as_pdf_rounded,
                      color: Color(0xFFFF6B6B), size: 26),
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF1A2332),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy').format(file.uploadedAt),
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withOpacity(0.35)
                              : Colors.black.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Open button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isOpening
                          ? [accent.withOpacity(0.5), SC.blue.withOpacity(0.5)]
                          : [accent, SC.blue],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(isOpening ? 0.1 : 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      isOpening ? Icons.hourglass_top_rounded : Icons.open_in_new_rounded,
                      color: isDark ? Colors.black : Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isOpening ? 'খোলা হচ্ছে' : 'দেখুন',
                      style: TextStyle(
                        color: isDark ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ── States ─────────────────────────────────────────────────────
  Widget _buildLoader(bool isDark, Color accent) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
          width: 48, height: 48,
          child: CircularProgressIndicator(
              color: accent,
              backgroundColor: accent.withOpacity(0.05),
              strokeWidth: 2.5)),
      const SizedBox(height: 14),
      Text('লোড হচ্ছে...',
          style: TextStyle(
              color: isDark
                  ? Colors.white.withOpacity(0.3)
                  : Colors.black.withOpacity(0.3),
              fontSize: 12, letterSpacing: 1.2)),
    ],
  );

  Widget _buildError(bool isDark, Color accent) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
            color: const Color(0xFFFF6B6B).withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
                color: const Color(0xFFFF6B6B).withOpacity(0.3))),
        child: const Icon(Icons.wifi_off_rounded,
            color: Color(0xFFFF6B6B), size: 36),
      ),
      const SizedBox(height: 16),
      Text(_error!,
          style: TextStyle(
              color: isDark
                  ? Colors.white.withOpacity(0.5)
                  : Colors.black.withOpacity(0.5),
              fontSize: 14)),
      const SizedBox(height: 20),
      GestureDetector(
        onTap: _fetch,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [accent, SC.blue]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: accent.withOpacity(0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 5))
              ]),
          child: Text('আবার চেষ্টা করুন',
              style: TextStyle(
                  color: isDark ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
        ),
      ),
    ]),
  );

  Widget _buildEmpty(bool isDark, Color accent) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Opacity(
        opacity: 0.12,
        child: Icon(Icons.menu_book_rounded,
            size: 90, color: isDark ? Colors.white : Colors.black),
      ),
      const SizedBox(height: 14),
      Text('কোনো Constitution ফাইল নেই',
          style: TextStyle(
              color: isDark
                  ? Colors.white.withOpacity(0.3)
                  : Colors.black.withOpacity(0.4),
              fontSize: 14)),
      const SizedBox(height: 6),
      Text('এখনো কোনো ফাইল আপলোড করা হয়নি',
          style: TextStyle(
              color: isDark
                  ? Colors.white.withOpacity(0.18)
                  : Colors.black.withOpacity(0.25),
              fontSize: 12)),
    ]),
  );
}
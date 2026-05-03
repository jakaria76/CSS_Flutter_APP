import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:css/models/notice_model.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

// Notice widgets
import 'package:css/widgets/notice/notice_card.dart';
import 'package:css/widgets/notice/notice_painters.dart';
import 'package:css/widgets/notice/notice_loaders.dart';
import 'package:css/widgets/notice/notice_image_viewer.dart';
import 'package:css/widgets/notice/notice_pdf_viewer.dart';
import 'package:url_launcher/url_launcher.dart';
class NoticePage extends StatefulWidget {
  const NoticePage({super.key});
  @override
  State<NoticePage> createState() => _NoticePageState();
}

class _NoticePageState extends State<NoticePage> with TickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  bool _loading = true;
  List<Notice> notices = [];
  String? _error;
  String _searchQuery = '';
  String _selectedFilter = 'all';

  late AnimationController _listAnim;
  late AnimationController _headerAnim;
  late AnimationController _pulseAnim;

  @override
  void initState() {
    super.initState();
    _listAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _headerAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _pulseAnim =
    AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _fetchNotices();
  }

  @override
  void dispose() {
    _listAnim.dispose();
    _headerAnim.dispose();
    _pulseAnim.dispose();
    super.dispose();
  }

  // ── Filtered list ──────────────────────────────────────────────
  List<Notice> get _filteredNotices {
    var list = notices;
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((n) =>
          n.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    if (_selectedFilter == 'new') {
      list = list
          .where((n) => DateTime.now().difference(n.publishDate).inDays < 3)
          .toList();
    } else if (_selectedFilter == 'file') {
      list = list
          .where((n) => n.pdfUrl != null && n.pdfUrl!.isNotEmpty)
          .toList();
    }
    return list;
  }

  // ── Data fetch ─────────────────────────────────────────────────
  Future<void> _fetchNotices() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _supabase
          .from('notices')
          .select()
          .order('publish_date', ascending: false);
      notices = (data as List).map((e) => Notice.fromMap(e)).toList();
      _listAnim.forward(from: 0);
    } catch (e) {
      _error = SC.tr('noticeLoadFail');
    }
    if (mounted) setState(() => _loading = false);
  }

  // ── File helpers ───────────────────────────────────────────────
  String _getExt(String? url) {
    if (url == null) return '';
    return url.split('.').last.split('?').first.toLowerCase();
  }

  IconData _getIcon(String ext) {
    switch (ext) {
      case 'pdf':  return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx': return Icons.description_rounded;
      case 'txt':  return Icons.text_snippet_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp': return Icons.image_rounded;
      default:     return Icons.insert_drive_file_rounded;
    }
  }

  Color _getExtColor(String ext) {
    switch (ext) {
      case 'pdf':  return const Color(0xFFFF6B6B);
      case 'doc':
      case 'docx': return const Color(0xFF4ECDC4);
      case 'txt':  return const Color(0xFF95E1D3);
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp': return const Color(0xFFFFBE0B);
      default:     return const Color(0xFF8B8FA8);
    }
  }

  /// Cloudinary image/upload → raw/upload (PDF fix)
  String _fixCloudinaryPdfUrl(String url) {
    if (!url.contains('cloudinary.com')) return url;
    String fixed = url.replaceAll('/upload/fl_attachment/', '/upload/');
    if (fixed.contains('/image/upload/')) {
      fixed = fixed.replaceFirst('/image/upload/', '/raw/upload/');
    }
    return fixed;
  }

  // ── File open routing ──────────────────────────────────────────
  Future<void> _openFile(String url) async {
    final ext = _getExt(url);
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
      _openImageViewer(url);
    } else if (ext == 'pdf') {
      _openPdfViewer(_fixCloudinaryPdfUrl(url), originalUrl: url);
    } else {
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {
        _showSnack(SC.tr('noticeOpenFail'), isError: true);
      }
    }
  }

  void _openImageViewer(String url) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => NoticeImageViewer(imageUrl: url),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _openPdfViewer(String url, {String? originalUrl}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoticePdfViewer(
          pdfUrl: url,
          originalUrl: originalUrl ?? url,
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
      isError ? const Color(0xFFFF6B6B) : const Color(0xFF00FFFF),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (context, __, ___) => _buildPage(),
      ),
    );
  }

  Widget _buildPage() {
    final isDark      = SC.isDark;
    final bgColor     = isDark ? const Color(0xFF070C16) : const Color(0xFFF0F4FF);
    final accentColor = isDark ? const Color(0xFF00FFFF) : SC.cyan;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(children: [
          // Background orbs
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Stack(children: [
              Positioned(
                top: -100, right: -80,
                child: _orb(280, accentColor,
                    (isDark ? 0.06 : 0.03) + _pulseAnim.value * 0.02),
              ),
              Positioned(
                top: 280, left: -70,
                child: _orb(200, const Color(0xFF7B61FF),
                    (isDark ? 0.05 : 0.02) + _pulseAnim.value * 0.02),
              ),
              Positioned(
                bottom: 180, right: -50,
                child: _orb(160, const Color(0xFF00E5A0),
                    (isDark ? 0.04 : 0.02) + _pulseAnim.value * 0.01),
              ),
            ]),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(isDark, accentColor),
              SliverToBoxAdapter(
                  child: _buildFilterChips(isDark, accentColor)),
              if (_loading)
                SliverFillRemaining(
                    child: Center(
                        child: NoticePulseLoader(
                            accentColor: accentColor, isDark: isDark)))
              else if (_error != null)
                SliverFillRemaining(child: _buildError(isDark, accentColor))
              else if (_filteredNotices.isEmpty)
                  SliverFillRemaining(child: _buildEmpty(isDark))
                else
                  _buildList(isDark, accentColor),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _orb(double size, Color color, double opacity) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
          colors: [color.withOpacity(opacity), color.withOpacity(0)]),
    ),
  );

  Widget _buildSliverAppBar(bool isDark, Color accentColor) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final bgColor   = isDark ? const Color(0xFF070C16) : const Color(0xFFF0F4FF);

    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      elevation: 0,
      backgroundColor: bgColor,
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
                  : Colors.black.withOpacity(0.08),
            ),
          ),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              color: textColor, size: 16),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: _fetchNotices,
          child: Container(
            margin: const EdgeInsets.all(10),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.07)
                  : Colors.black.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.10)
                    : Colors.black.withOpacity(0.08),
              ),
            ),
            child: Icon(Icons.refresh_rounded, color: accentColor, size: 18),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.blurBackground,
          StretchMode.zoomBackground,
        ],
        titlePadding: EdgeInsetsDirectional.only(
          start: 20,
          bottom: 16, // Padding ta adjustable kora hoyeche dynamic look er jonno
        ),
        centerTitle: false,
        title: AnimatedBuilder(
          animation: _headerAnim,
          builder: (context, child) {
            return Opacity(
              opacity: _headerAnim.value,
              child: Transform.translate(
                offset: Offset(0, 12 * (1 - _headerAnim.value)),
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modern Eyebrow Text with subtle glow effect logic
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  SC.tr('NoticePage....').toUpperCase(),
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Main Title with Neon/High-Contrast feel
              Text(
                SC.tr('noticePageTitle'),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 24, // Slightly larger for better hierarchy
                  color: textColor,
                  letterSpacing: -0.8,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Background with Gradient Overlay for readability
        background: Stack(
          fit: StackFit.expand,
          children: [
            _buildHeaderBg(isDark, accentColor),
            // Glassmorphism or Gradient Overlay layer
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    isDark ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.5),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.09)
                  : Colors.black.withOpacity(0.07),
            ),
            boxShadow: !isDark
                ? [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1A2332),
                    fontSize: 14),
                decoration: InputDecoration(
                  hintText: SC.tr('noticeSearch'),
                  hintStyle: TextStyle(
                    color: isDark
                        ? Colors.white.withOpacity(0.25)
                        : Colors.black.withOpacity(0.3),
                    fontSize: 14,
                  ),
                  prefixIcon:
                  Icon(Icons.search_rounded, color: accentColor, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBg(bool isDark, Color accentColor) {
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
        CustomPaint(
          painter: NoticeDiagonalPainter(isDark: isDark),
          size: const Size(double.infinity, 260),
        ),
        Positioned(
          right: 20,
          bottom: 100,
          child: AnimatedBuilder(
            animation: _headerAnim,
            builder: (_, __) => Transform.scale(
              scale: 0.7 + 0.3 * _headerAnim.value,
              child: Opacity(
                opacity: isDark ? 0.08 : 0.06,
                child: Icon(Icons.campaign_rounded,
                    size: 180, color: accentColor),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: 20,
          child: FadeTransition(
            opacity: _headerAnim,
            child: Row(children: [
              _headerStat('${notices.length}', SC.tr('noticeTotal'),
                  accentColor, isDark),
              const SizedBox(width: 20),
              _headerStat(
                '${notices.where((n) => DateTime.now().difference(n.publishDate).inDays < 3).length}',
                SC.tr('noticeNew'),
                const Color(0xFFFF6B6B),
                isDark,
              ),
            ]),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                accentColor,
                const Color(0xFF7B61FF),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _headerStat(String value, String label, Color color, bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value,
          style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -1)),
      Text(label,
          style: TextStyle(
              color: isDark
                  ? Colors.white.withOpacity(0.4)
                  : Colors.black.withOpacity(0.4),
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _buildFilterChips(bool isDark, Color accentColor) {
    final filters = [
      {
        'key': 'all',
        'label': SC.tr('noticeFilterAll'),
        'icon': Icons.all_inbox_rounded
      },
      {
        'key': 'new',
        'label': SC.tr('noticeFilterNew'),
        'icon': Icons.fiber_new_rounded
      },
      {
        'key': 'file',
        'label': SC.tr('noticeFilterFile'),
        'icon': Icons.attach_file_rounded
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: filters.map((f) {
            final active = _selectedFilter == f['key'];
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedFilter = f['key'] as String);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 10),
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: active
                      ? accentColor.withOpacity(0.15)
                      : (isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: active
                        ? accentColor.withOpacity(0.5)
                        : (isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.08)),
                    width: active ? 1.2 : 0.8,
                  ),
                  boxShadow: !isDark && !active
                      ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8)
                  ]
                      : [],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(f['icon'] as IconData,
                      color: active
                          ? accentColor
                          : (isDark
                          ? Colors.white.withOpacity(0.4)
                          : Colors.black.withOpacity(0.4)),
                      size: 14),
                  const SizedBox(width: 7),
                  Text(f['label'] as String,
                      style: TextStyle(
                          color: active
                              ? accentColor
                              : (isDark
                              ? Colors.white.withOpacity(0.5)
                              : Colors.black.withOpacity(0.5)),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildList(bool isDark, Color accentColor) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final notice = _filteredNotices[index];
            final delay  = (index * 0.07).clamp(0.0, 0.5);
            return AnimatedBuilder(
              animation: _listAnim,
              builder: (_, child) {
                final progress = Curves.easeOutCubic.transform(
                    ((_listAnim.value - delay) / (1 - delay))
                        .clamp(0.0, 1.0));
                return Opacity(
                  opacity: progress,
                  child: Transform.translate(
                      offset: Offset(0, 28 * (1 - progress)), child: child),
                );
              },
              child: NoticeCard(
                notice:      notice,
                index:       index,
                isDark:      isDark,
                onOpen:      _openFile,
                getExt:      _getExt,
                getIcon:     _getIcon,
                getExtColor: _getExtColor,
              ),
            );
          },
          childCount: _filteredNotices.length,
        ),
      ),
    );
  }

  Widget _buildError(bool isDark, Color accentColor) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B6B).withOpacity(0.1),
          shape: BoxShape.circle,
          border:
          Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.3)),
        ),
        child: const Icon(Icons.wifi_off_rounded,
            color: Color(0xFFFF6B6B), size: 38),
      ),
      const SizedBox(height: 18),
      Text(_error!,
          style: TextStyle(
              color: isDark
                  ? Colors.white.withOpacity(0.5)
                  : Colors.black.withOpacity(0.5),
              fontSize: 14)),
      const SizedBox(height: 22),
      GestureDetector(
        onTap: _fetchNotices,
        child: Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [accentColor, SC.blue]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: accentColor.withOpacity(0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 5))
            ],
          ),
          child: Text(SC.tr('noticeRetry'),
              style: TextStyle(
                  color: isDark ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
        ),
      ),
    ]),
  );

  Widget _buildEmpty(bool isDark) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Opacity(
        opacity: 0.12,
        child: Icon(Icons.inbox_rounded,
            size: 90, color: isDark ? Colors.white : Colors.black),
      ),
      const SizedBox(height: 14),
      Text(
        _searchQuery.isNotEmpty
            ? '"$_searchQuery" — ${SC.tr('noticeNoResult')}'
            : SC.tr('noticeEmpty'),
        style: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.3)
                : Colors.black.withOpacity(0.4),
            fontSize: 14),
      ),
    ]),
  );
}
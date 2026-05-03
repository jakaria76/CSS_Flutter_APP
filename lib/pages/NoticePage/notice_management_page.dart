import 'dart:ui';
import 'package:css/pages/SettingsPage/notification_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:css/models/notice_model.dart';
import 'package:css/services/notice_service.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

// Notice widgets
import 'package:css/widgets/notice/admin_notice_card.dart';
import 'package:css/widgets/notice/notice_painters.dart';
import 'package:css/widgets/notice/notice_image_viewer.dart';
import 'package:css/widgets/notice/notice_pdf_viewer.dart';

class NoticeManagementPage extends StatefulWidget {
  const NoticeManagementPage({super.key});
  @override
  State<NoticeManagementPage> createState() => _NoticeManagementPageState();
}

class _NoticeManagementPageState extends State<NoticeManagementPage>
    with TickerProviderStateMixin {
  final _noticeService = NoticeService();
  bool _loading = true;
  List<Notice> notices = [];
  String? _error;
  String _searchQuery = '';

  late AnimationController _listAnim;
  late AnimationController _fabAnim;
  late AnimationController _pulseAnim;

  @override
  void initState() {
    super.initState();
    _listAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fabAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400))
      ..forward();
    _pulseAnim =
    AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _fetchNotices();
  }

  @override
  void dispose() {
    _listAnim.dispose();
    _fabAnim.dispose();
    _pulseAnim.dispose();
    super.dispose();
  }

  List<Notice> get _filteredNotices {
    if (_searchQuery.isEmpty) return notices;
    return notices
        .where((n) =>
        n.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  // ── Data ───────────────────────────────────────────────────────
  Future<void> _fetchNotices() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      notices = await _noticeService.fetchNotices();
      _listAnim.forward(from: 0);
    } catch (e) {
      _error = SC.tr('noticeMgmtLoadFail');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _deleteNotice(Notice notice) async {
    final confirmed = await _showDeleteDialog(notice.title);
    if (!confirmed) return;
    _showProgress(SC.tr('noticeMgmtDeleting'));
    try {
      await _noticeService.deleteNotice(notice.id);
      if (mounted) {
        Navigator.pop(context);
        SC.toast(context, SC.tr('noticeMgmtDeleted'), SC.green);
      }
      _fetchNotices();
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        SC.toast(context, SC.tr('noticeMgmtDeleteFail'), SC.red);
      }
    }
  }

  Future<void> _openFile(String url) async {
    final ext = url.split('.').last.split('?').first.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
      Navigator.push(
        context,
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (_, __, ___) => NoticeImageViewer(imageUrl: url),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 280),
        ),
      );
    } else if (ext == 'pdf') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NoticePdfViewer(pdfUrl: url, originalUrl: url),
        ),
      );
    } else {
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {
        if (mounted) SC.toast(context, SC.tr('noticeOpenFail'), SC.red);
      }
    }
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
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Stack(children: [
              Positioned(
                top: -100, right: -80,
                child: _orb(280, accentColor,
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
              _buildAppBar(isDark, accentColor),
              if (_loading)
                SliverFillRemaining(
                    child: Center(child: _buildLoader(isDark, accentColor)))
              else if (_error != null)
                SliverFillRemaining(child: _buildError(isDark, accentColor))
              else if (_filteredNotices.isEmpty)
                  SliverFillRemaining(child: _buildEmpty(isDark))
                else
                  _buildList(isDark, accentColor),
            ],
          ),
        ]),
        floatingActionButton: AnimatedBuilder(
          animation: _fabAnim,
          builder: (_, child) => Transform.scale(
            scale: CurvedAnimation(
                parent: _fabAnim, curve: Curves.elasticOut)
                .value,
            child: child,
          ),
          child: GestureDetector(
            onTap: () => _showAddEditDialog(),
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF00FFFF), const Color(0xFF0077FF)]
                      : [SC.cyan, SC.blue],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_rounded,
                    color: isDark ? Colors.black : Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  SC.tr('noticeMgmtNew'),
                  style: TextStyle(
                    color: isDark ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ),
              ]),
            ),
          ),
        ),
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

  Widget _buildAppBar(bool isDark, Color accentColor) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final bgColor   = isDark ? const Color(0xFF070C16) : const Color(0xFFF0F4FF);

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      elevation: 0,
      backgroundColor: bgColor,
      systemOverlayStyle:
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
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
        titlePadding: const EdgeInsets.only(bottom: 90, left: 20),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ADMIN PANEL',
              style: TextStyle(
                  color: accentColor,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.5),
            ),
            Text(
              SC.tr('noticeMgmtTitle'),
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: textColor,
                  letterSpacing: -0.3),
            ),
          ],
        ),
        background: _buildHeaderBg(isDark, accentColor),
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
                  hintText: SC.tr('noticeMgmtSearch'),
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
          size: const Size(double.infinity, 240),
        ),
        Positioned(
          bottom: 100,
          left: 20,
          child: Row(children: [
            _headerStat('${notices.length}', SC.tr('noticeMgmtTotal'),
                accentColor, isDark),
            const SizedBox(width: 20),
            _headerStat(
              '${notices.where((n) => n.pdfUrl != null && n.pdfUrl!.isNotEmpty).length}',
              SC.tr('noticeMgmtWithFile'),
              const Color(0xFF00E5A0),
              isDark,
            ),
            const SizedBox(width: 20),
            _headerStat(
              '${notices.where((n) => DateTime.now().difference(n.publishDate).inDays < 3).length}',
              SC.tr('noticeNew'),
              const Color(0xFFFF6B6B),
              isDark,
            ),
          ]),
        ),
        Positioned(
          right: 20,
          bottom: 90,
          child: Opacity(
            opacity: isDark ? 0.06 : 0.05,
            child: Icon(Icons.admin_panel_settings_rounded,
                size: 160, color: accentColor),
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
                const Color(0xFF7B61FF),
                accentColor,
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
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -1)),
      Text(label,
          style: TextStyle(
              color: isDark
                  ? Colors.white.withOpacity(0.4)
                  : Colors.black.withOpacity(0.4),
              fontSize: 10,
              fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _buildList(bool isDark, Color accentColor) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final notice = _filteredNotices[index];
            final delay  = (index * 0.07).clamp(0.0, 0.5);
            return AnimatedBuilder(
              animation: _listAnim,
              builder: (_, child) {
                final p = Curves.easeOutCubic.transform(
                    ((_listAnim.value - delay) / (1 - delay))
                        .clamp(0.0, 1.0));
                return Opacity(
                  opacity: p,
                  child: Transform.translate(
                      offset: Offset(0, 28 * (1 - p)), child: child),
                );
              },
              child: AdminNoticeCard(
                notice:   notice,
                index:    index,
                isDark:   isDark,
                onEdit:   () => _showAddEditDialog(notice: notice),
                onDelete: () => _deleteNotice(notice),
                onOpen:   notice.pdfUrl != null
                    ? () => _openFile(notice.pdfUrl!)
                    : null,
              ),
            );
          },
          childCount: _filteredNotices.length,
        ),
      ),
    );
  }

  Widget _buildLoader(bool isDark, Color accentColor) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 52,
        height: 52,
        child: CircularProgressIndicator(
          color: accentColor,
          backgroundColor: accentColor.withOpacity(0.05),
          strokeWidth: 2.5,
        ),
      ),
      const SizedBox(height: 16),
      Text(SC.tr('noticeMgmtLoading'),
          style: TextStyle(
              color: isDark
                  ? Colors.white.withOpacity(0.3)
                  : Colors.black.withOpacity(0.3),
              fontSize: 12,
              letterSpacing: 1.5)),
    ],
  );

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
        child: const Icon(Icons.error_outline_rounded,
            color: Color(0xFFFF6B6B), size: 38),
      ),
      const SizedBox(height: 18),
      Text(_error!,
          style: TextStyle(
              color: isDark
                  ? Colors.white.withOpacity(0.5)
                  : Colors.black.withOpacity(0.5))),
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
          child: Text(SC.tr('noticeMgmtRetry'),
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
            ? SC.tr('noticeMgmtNoResult')
            : SC.tr('noticeMgmtEmpty'),
        style: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.3)
                : Colors.black.withOpacity(0.4),
            fontSize: 14),
      ),
      const SizedBox(height: 8),
      Text(SC.tr('noticeMgmtEmptyHint'),
          style: TextStyle(
              color: isDark
                  ? Colors.white.withOpacity(0.15)
                  : Colors.black.withOpacity(0.25),
              fontSize: 12)),
    ]),
  );

  // ── Add / Edit Dialog ──────────────────────────────────────────
  void _showAddEditDialog({Notice? notice}) {
    final isEditing   = notice != null;
    final isDark      = SC.isDark;
    final accentColor = isDark ? const Color(0xFF00FFFF) : SC.cyan;
    final titleCtrl   = TextEditingController(text: notice?.title ?? '');
    DateTime selectedDate = notice?.publishDate ?? DateTime.now();
    String? fileUrl   = notice?.pdfUrl;
    PlatformFile? selectedFile;
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0C1525) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.08),
                  ),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // Dialog header
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 22, 16, 22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isEditing
                            ? [
                          const Color(0xFF7B61FF),
                          isDark
                              ? const Color(0xFF0C1525)
                              : Colors.white
                        ]
                            : [
                          accentColor.withOpacity(0.7),
                          isDark
                              ? const Color(0xFF0C1525)
                              : Colors.white
                        ],
                        end: Alignment.centerRight,
                      ),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28)),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isEditing ? Icons.edit_rounded : Icons.add_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          isEditing
                              ? SC.tr('noticeMgmtEditTitle')
                              : SC.tr('noticeMgmtAddTitle'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white70, size: 18),
                        ),
                      ),
                    ]),
                  ),

                  // Form fields
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel(SC.tr('noticeMgmtFieldTitle'), isDark),
                          const SizedBox(height: 8),
                          TextField(
                            controller: titleCtrl,
                            maxLines: 3,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1A2332),
                              fontSize: 14,
                              height: 1.5,
                            ),
                            decoration: _fieldDecoration(
                              SC.tr('noticeMgmtFieldTitleHint'),
                              isDark,
                              accentColor,
                            ),
                          ),
                          const SizedBox(height: 22),
                          _fieldLabel(SC.tr('noticeMgmtFieldDate'), isDark),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                                builder: (ctx, child) => Theme(
                                  data: isDark
                                      ? ThemeData.dark().copyWith(
                                      colorScheme: ColorScheme.dark(
                                        primary: accentColor,
                                        surface: const Color(0xFF0C1525),
                                      ))
                                      : ThemeData.light().copyWith(
                                      colorScheme: ColorScheme.light(
                                          primary: accentColor)),
                                  child: child!,
                                ),
                              );
                              if (picked != null) {
                                setD(() => selectedDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.04)
                                    : Colors.black.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.08)
                                      : Colors.black.withOpacity(0.08),
                                ),
                              ),
                              child: Row(children: [
                                Icon(Icons.calendar_month_rounded,
                                    color: accentColor, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  DateFormat('dd MMMM yyyy')
                                      .format(selectedDate),
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1A2332),
                                    fontSize: 14,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: isDark
                                      ? Colors.white.withOpacity(0.3)
                                      : Colors.black.withOpacity(0.3),
                                  size: 20,
                                ),
                              ]),
                            ),
                          ),
                          const SizedBox(height: 22),
                          _fieldLabel(SC.tr('noticeMgmtFieldFile'), isDark),
                          const SizedBox(height: 8),
                          _filePickerSection(
                            selectedFile,
                            fileUrl,
                                (f) => setD(() {
                              selectedFile = f;
                              if (f == null) fileUrl = null;
                            }),
                            isDark,
                            accentColor,
                          ),
                          if (saving) ...[
                            const SizedBox(height: 20),
                            Column(children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  color: accentColor,
                                  backgroundColor:
                                  accentColor.withOpacity(0.1),
                                  minHeight: 4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                selectedFile != null
                                    ? SC.tr('noticeMgmtFileUploading')
                                    : SC.tr('noticeMgmtSaving'),
                                style: TextStyle(
                                    color: accentColor,
                                    fontSize: 12,
                                    letterSpacing: 0.5),
                              ),
                            ]),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Action buttons
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: saving ? null : () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : Colors.black.withOpacity(0.08),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                SC.tr('noticeMgmtCancel'),
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: saving
                              ? null
                              : () async {
                            if (titleCtrl.text.trim().isEmpty) {
                              SC.toast(
                                  context,
                                  SC.tr('noticeMgmtTitleEmpty'),
                                  SC.red);
                              return;
                            }
                            setD(() => saving = true);
                            try {
                              String? finalUrl = fileUrl;
                              if (selectedFile != null) {
                                finalUrl = await _noticeService
                                    .uploadNoticeFile(selectedFile!);
                                if (finalUrl == null) {
                                  SC.toast(
                                      context,
                                      SC.tr('noticeMgmtUploadFail'),
                                      SC.red);
                                  setD(() => saving = false);
                                  return;
                                }
                              }
                              if (isEditing) {
                                await _noticeService.updateNotice(
                                  id: notice.id,
                                  title: titleCtrl.text.trim(),
                                  publishDate: selectedDate,
                                  fileUrl: finalUrl,
                                );
                              } else {
                                await _noticeService.createNotice(
                                  title: titleCtrl.text.trim(),
                                  publishDate: selectedDate,
                                  fileUrl: finalUrl,
                                );
                                // ✅ নতুন notice create হলে সব user-কে notification পাঠাও
                                await NotificationHelper.sendToAll(
                                  titleKey: 'notice_new_title',
                                  bodyKey: 'notice_new_body',
                                  type: 'notice',
                                );
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                              _fetchNotices();
                              SC.toast(
                                  context,
                                  isEditing
                                      ? SC.tr('noticeMgmtSaved')
                                      : SC.tr('noticeMgmtAdded'),
                                  SC.green);
                            } catch (e) {
                              setD(() => saving = false);
                              SC.toast(context, 'Error: $e', SC.red);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isEditing
                                    ? [
                                  const Color(0xFF7B61FF),
                                  const Color(0xFF4ECDC4)
                                ]
                                    : [accentColor, SC.blue],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: (isEditing
                                      ? const Color(0xFF7B61FF)
                                      : accentColor)
                                      .withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Center(
                              child: saving
                                  ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: isDark
                                          ? Colors.black
                                          : Colors.white,
                                      strokeWidth: 2))
                                  : Text(
                                  isEditing
                                      ? SC.tr('noticeMgmtUpdate')
                                      : SC.tr('noticeMgmtAdd'),
                                  style: TextStyle(
                                      color: isDark
                                          ? Colors.black
                                          : Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14)),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Form helpers ───────────────────────────────────────────────
  Widget _fieldLabel(String text, bool isDark) => Text(
    text.toUpperCase(),
    style: TextStyle(
      color: isDark
          ? Colors.white.withOpacity(0.35)
          : Colors.black.withOpacity(0.4),
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.5,
    ),
  );

  InputDecoration _fieldDecoration(
      String hint, bool isDark, Color accentColor) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.2)
                : Colors.black.withOpacity(0.3),
            fontSize: 14),
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.04),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.08))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.08))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: accentColor, width: 1.5)),
        contentPadding: const EdgeInsets.all(16),
      );

  Widget _filePickerSection(PlatformFile? file, String? url,
      Function(PlatformFile?) onPick, bool isDark, Color accentColor) {
    final hasFile  = file != null || url != null;
    final fileName = file?.name ?? (url?.split('/').last ?? '');
    return Column(children: [
      if (hasFile) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF00E5A0).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00E5A0).withOpacity(0.25)),
          ),
          child: Row(children: [
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF00E5A0), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(fileName,
                  style: const TextStyle(
                      color: Color(0xFF00E5A0),
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            GestureDetector(
              onTap: () => onPick(null),
              child: const Icon(Icons.close_rounded,
                  color: Color(0xFFFF6B6B), size: 18),
            ),
          ]),
        ),
      ],
      GestureDetector(
        onTap: () async {
          final res = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: [
              'pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'
            ],
            withData: true,
          );
          if (res != null && res.files.isNotEmpty) onPick(res.files.first);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.03)
                : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accentColor.withOpacity(0.2)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.upload_file_rounded, color: accentColor, size: 20),
            const SizedBox(width: 10),
            Text(
              hasFile
                  ? SC.tr('noticeMgmtFileChange')
                  : SC.tr('noticeMgmtFileSelect'),
              style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'PDF • DOC • DOCX • TXT • JPG • PNG',
        style: TextStyle(
          color: isDark
              ? Colors.white.withOpacity(0.2)
              : Colors.black.withOpacity(0.25),
          fontSize: 10,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
      ),
    ]);
  }

  Future<bool> _showDeleteDialog(String title) async {
    final isDark = SC.isDark;
    return await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0C1525) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: const Color(0xFFFF6B6B).withOpacity(0.25)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFFFF6B6B).withOpacity(0.3)),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFFF6B6B), size: 30),
            ),
            const SizedBox(height: 18),
            Text(SC.tr('noticeMgmtDeleteQ'),
                style: TextStyle(
                    color:
                    isDark ? Colors.white : const Color(0xFF1A2332),
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(
              '"$title"\n${SC.tr('noticeMgmtDeleteHint')}',
              style: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.45)
                    : Colors.black.withOpacity(0.5),
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx, false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.08),
                      ),
                    ),
                    child: Center(
                      child: Text(SC.tr('noticeMgmtCancel'),
                          style: TextStyle(
                              color: isDark
                                  ? Colors.white60
                                  : Colors.black54,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFFF4444)]),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFFFF6B6B).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Center(
                      child: Text(SC.tr('noticeMgmtDeleteConfirm'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    ) ??
        false;
  }

  void _showProgress(String msg) => showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Center(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: SC.isDark ? const Color(0xFF0C1525) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: SC.isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.08)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
                color: SC.isDark ? const Color(0xFF00FFFF) : SC.cyan,
                strokeWidth: 2.5),
          ),
          const SizedBox(height: 14),
          Text(msg,
              style: TextStyle(
                  color: SC.isDark ? Colors.white70 : Colors.black54,
                  fontSize: 13)),
        ]),
      ),
    ),
  );
}
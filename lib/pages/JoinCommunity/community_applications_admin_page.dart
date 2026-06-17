import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';
import 'package:css/services/community_application_service.dart';
import 'package:css/models/community_application_model.dart';

class CommunityApplicationsAdminPage extends StatefulWidget {
  const CommunityApplicationsAdminPage({super.key});

  @override
  State<CommunityApplicationsAdminPage> createState() =>
      _CommunityApplicationsAdminPageState();
}

class _CommunityApplicationsAdminPageState
    extends State<CommunityApplicationsAdminPage>
    with TickerProviderStateMixin {
  final _service = CommunityApplicationService();

  List<CommunityApplicationModel> _applications = [];
  bool _isLoading    = true;
  bool _isExporting  = false;
  String _statusFilter = 'all';

  late AnimationController _listCtrl;

  // ─── Theme Helpers ───────────────────────────────────────────
  bool   get _isDark  => SC.isDark;
  Color  get _bg      => _isDark ? const Color(0xFF080E14) : const Color(0xFFF0F4FF);
  Color  get _card    => _isDark ? const Color(0xFF111923) : Colors.white;
  Color  get _text    => _isDark ? Colors.white : const Color(0xFF1A2332);
  Color  get _sub     => _isDark ? Colors.white38 : Colors.black38;
  Color  get _border  => (_isDark ? Colors.white : Colors.black).withOpacity(0.07);

  // Status meta
  static const _statusMeta = {
    'pending':  (color: Color(0xFFFFB300), icon: Icons.hourglass_top_rounded,   label: 'pending'),
    'approved': (color: Color(0xFF00E676), icon: Icons.check_circle_rounded,     label: 'approved'),
    'rejected': (color: Color(0xFFFF5252), icon: Icons.cancel_rounded,           label: 'rejected'),
  };

  @override
  void initState() {
    super.initState();
    _listCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _load();
  }

  @override
  void dispose() {
    _listCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    _listCtrl.reset();
    try {
      final data =
      await _service.fetchAllApplications(statusFilter: _statusFilter);
      if (mounted) {
        setState(() => _applications = data);
        _listCtrl.forward();
      }
    } catch (_) {
      if (mounted) SC.toast(context, SC.tr('adminLoadFail'), Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── CSV Export ──────────────────────────────────────────────
  Future<void> _exportCsv() async {
    if (_applications.isEmpty) {
      SC.toast(context, SC.tr('adminNothingToExport'), Colors.orange);
      return;
    }
    setState(() => _isExporting = true);
    try {
      final buffer = StringBuffer();
      buffer.writeln(
          CommunityApplicationModel.csvHeaders().map(_csvEscape).join(','));
      for (final app in _applications) {
        buffer.writeln(app.toCsvRow().map(_csvEscape).join(','));
      }
      final dir      = await getTemporaryDirectory();
      final fileName =
          'community_applications_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(
          [0xEF, 0xBB, 0xBF, ...buffer.toString().codeUnits]);
      if (mounted) {
        await Share.shareXFiles([XFile(file.path)],
            text: SC.tr('adminCsvShareText'));
      }
    } catch (_) {
      if (mounted) {
        SC.toast(context, SC.tr('adminExportFail'), Colors.redAccent);
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String _csvEscape(String value) {
    final v = value.replaceAll('"', '""');
    return (v.contains(',') || v.contains('\n') || v.contains('"'))
        ? '"$v"'
        : v;
  }

  // ─── Status Update & Delete ──────────────────────────────────
  Future<void> _updateStatus(
      CommunityApplicationModel app, String status) async {
    try {
      await _service.updateApplicationStatus(
          applicationId: app.id!, status: status);
      if (mounted) {
        SC.toast(
          context,
          status == 'approved'
              ? SC.tr('adminApproved')
              : SC.tr('adminRejected'),
          status == 'approved'
              ? const Color(0xFF00E676)
              : Colors.redAccent,
        );
      }
      _load();
    } catch (_) {
      if (mounted) {
        SC.toast(context, SC.tr('adminUpdateFail'), Colors.redAccent);
      }
    }
  }

  Future<void> _confirmDelete(CommunityApplicationModel app) async {
    HapticFeedback.heavyImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _isDark
                    ? const Color(0xFF111923).withOpacity(0.95)
                    : Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_rounded,
                        color: Colors.redAccent, size: 30),
                  ),
                  const SizedBox(height: 16),
                  Text(SC.tr('adminDeleteTitle'),
                      style: TextStyle(
                          color: _text,
                          fontWeight: FontWeight.bold,
                          fontSize: 17)),
                  const SizedBox(height: 8),
                  Text(app.fullName,
                      style: TextStyle(color: _sub, fontSize: 14),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: _border),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(SC.tr('cancel'),
                              style: TextStyle(
                                  color: _sub, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(SC.tr('bannerDeleteConfirm'),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteApplication(app.id!);
        _load();
        if (mounted) {
          SC.toast(context, SC.tr('adminDeleted'), const Color(0xFF00E676));
        }
      } catch (_) {
        if (mounted) {
          SC.toast(context, SC.tr('adminDeleteFail'), Colors.redAccent);
        }
      }
    }
  }

  // ─── Build ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (_, __, ___) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (_, __, ___) => _buildPage(),
      ),
    );
  }

  Widget _buildPage() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _bg,
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            // ডায়নামিক স্পেসিং: স্ট্যাটাস বার + অ্যাপ বারের উচ্চতা
            SizedBox(height: MediaQuery.of(context).padding.top + 74),
            _buildStatsBar(),
            _buildFilterBar(),
            Expanded(
              child: _isLoading
                  ? _buildLoader()
                  : _applications.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                onRefresh: _load,
                color: Colors.cyanAccent,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 48),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _applications.length,
                  itemBuilder: (ctx, i) {
                    final delay = i * 40;
                    return AnimatedBuilder(
                      animation: _listCtrl,
                      builder: (_, child) {
                        final t = Curves.easeOutCubic.transform(
                          (_listCtrl.value -
                              delay / 1000)
                              .clamp(0.0, 1.0) /
                              (1 - delay / 1000).clamp(0.01, 1.0),
                        );
                        return Opacity(
                          opacity: t.clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - t)),
                            child: child,
                          ),
                        );
                      },
                      child: _buildApplicationCard(_applications[i], i),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: AppBar(
            backgroundColor: _isDark
                ? Colors.black.withOpacity(0.4)
                : Colors.white.withOpacity(0.7),
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: _text, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(SC.tr('adminPageTitle'),
                    style: TextStyle(
                        color: _text,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
                Text(SC.tr('adminPageSubtitle'),
                    style: TextStyle(color: _sub, fontSize: 11)),
              ],
            ),
            actions: [
              // Refresh
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: _text, size: 22),
                onPressed: _load,
                tooltip: 'Refresh',
              ),
              // Export
              GestureDetector(
                onTap: _isExporting ? null : _exportCsv,
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: _isExporting
                        ? null
                        : const LinearGradient(
                        colors: [Color(0xFF00C9A7), Color(0xFF0091EA)]),
                    color: _isExporting ? _border : null,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _isExporting
                      ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                      : Row(
                    children: [
                      const Icon(Icons.download_rounded,
                          color: Colors.white, size: 15),
                      const SizedBox(width: 5),
                      Text(SC.tr('adminExportCsv'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Stats Bar ───────────────────────────────────────────────
  Widget _buildStatsBar() {
    final total    = _applications.length;
    final pending  = _applications.where((a) => a.status == 'pending').length;
    final approved = _applications.where((a) => a.status == 'approved').length;
    final rejected = _applications.where((a) => a.status == 'rejected').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _statChip(label: 'মোট',     value: total,    gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)])),
          const SizedBox(width: 8),
          _statChip(label: 'পেন্ডিং', value: pending,  gradient: const LinearGradient(colors: [Color(0xFFFFB300), Color(0xFFFF6F00)])),
          const SizedBox(width: 8),
          _statChip(label: 'অনুমোদিত', value: approved, gradient: const LinearGradient(colors: [Color(0xFF00C9A7), Color(0xFF00E676)])),
          const SizedBox(width: 8),
          _statChip(label: 'বাতিল',   value: rejected, gradient: const LinearGradient(colors: [Color(0xFFFF5252), Color(0xFFE91E63)])),
        ],
      ),
    );
  }

  Widget _statChip({
    required String label,
    required int value,
    required LinearGradient gradient,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              gradient.colors.first.withOpacity(_isDark ? 0.15 : 0.08),
              gradient.colors.last.withOpacity(_isDark ? 0.08 : 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: gradient.colors.first.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (b) => gradient.createShader(b),
              child: Text(
                '$value',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(color: _sub, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // ─── Filter Bar ──────────────────────────────────────────────
  Widget _buildFilterBar() {
    final filters = [
      ('all',      SC.tr('adminFilterAll'),      const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)])),
      ('pending',  SC.tr('adminFilterPending'),  const LinearGradient(colors: [Color(0xFFFFB300), Color(0xFFFF6F00)])),
      ('approved', SC.tr('adminFilterApproved'), const LinearGradient(colors: [Color(0xFF00C9A7), Color(0xFF00E676)])),
      ('rejected', SC.tr('adminFilterRejected'), const LinearGradient(colors: [Color(0xFFFF5252), Color(0xFFE91E63)])),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final (value, label, gradient) = filters[i];
          final selected = _statusFilter == value;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _statusFilter = value);
              _load();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: selected ? gradient : null,
                color: selected ? null : _card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: selected
                      ? Colors.transparent
                      : _border,
                ),
                boxShadow: selected
                    ? [
                  BoxShadow(
                      color: gradient.colors.first.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]
                    : [],
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                  color: selected ? Colors.white : _sub,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Application Card ─────────────────────────────────────────
  Widget _buildApplicationCard(CommunityApplicationModel app, int index) {
    final meta        = _statusMeta[app.status] ??
        (color: const Color(0xFFFFB300),
        icon: Icons.hourglass_top_rounded,
        label: app.status);
    final statusColor = meta.color;
    final isPending   = app.status == 'pending';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showDetailSheet(app);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isDark ? 0.25 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Left accent bar
              Positioned(
                left: 0, top: 0, bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [statusColor, statusColor.withOpacity(0.3)],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                child: Row(
                  children: [
                    // Photo
                    Hero(
                      tag: 'photo_${app.id}',
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: statusColor.withOpacity(0.3), width: 2),
                          image: DecorationImage(
                            image: NetworkImage(app.photoUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.fullName,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: _text),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              _miniTag(app.bloodGroup,
                                  const Color(0xFFFF5252), Icons.water_drop_rounded),
                              const SizedBox(width: 6),
                              Icon(Icons.location_on_rounded,
                                  size: 11, color: _sub),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  '${app.upazila}, ${app.district}',
                                  style:
                                  TextStyle(fontSize: 11, color: _sub),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(Icons.phone_rounded,
                                  size: 11, color: _sub),
                              const SizedBox(width: 4),
                              Text(app.mobileNumber,
                                  style:
                                  TextStyle(fontSize: 11, color: _sub)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Status badge
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border:
                            Border.all(color: statusColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isPending)
                                SizedBox(
                                  width: 8, height: 8,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 1.8,
                                      color: statusColor),
                                )
                              else
                                Icon(meta.icon,
                                    size: 10, color: statusColor),
                              const SizedBox(width: 5),
                              Text(
                                isPending
                                    ? SC.tr('joinStatusPending')
                                    : app.status.toUpperCase(),
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 12, color: _sub),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniTag(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: color),
          const SizedBox(width: 3),
          Text(text,
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ─── Loader & Empty ──────────────────────────────────────────
  Widget _buildLoader() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 42, height: 42,
          child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: _isDark ? Colors.cyanAccent : SC.cyan),
        ),
        const SizedBox(height: 14),
        Text(SC.tr('loading'),
            style: TextStyle(color: _sub, fontSize: 13)),
      ],
    ),
  );

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _isDark
                ? Colors.white.withOpacity(0.04)
                : Colors.black.withOpacity(0.04),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.inbox_rounded,
              size: 52,
              color: _isDark ? Colors.white24 : Colors.black26),
        ),
        const SizedBox(height: 20),
        Text(SC.tr('adminEmpty'),
            style: TextStyle(
                color: _text,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(SC.tr('adminEmptyHint'),
            style: TextStyle(color: _sub, fontSize: 13)),
      ],
    ),
  );

  // ─── Detail Bottom Sheet ─────────────────────────────────────
  void _showDetailSheet(CommunityApplicationModel app) {
    final meta        = _statusMeta[app.status] ??
        (color: const Color(0xFFFFB300),
        icon: Icons.hourglass_top_rounded,
        label: app.status);
    final statusColor = meta.color;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.97,
        expand: false,
        builder: (ctx, scrollCtrl) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              decoration: BoxDecoration(
                color: _isDark
                    ? const Color(0xFF0D1520).withOpacity(0.97)
                    : Colors.white.withOpacity(0.97),
              ),
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 44, height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                          color: _border.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  // ── Hero Header ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor.withOpacity(_isDark ? 0.15 : 0.08),
                          statusColor.withOpacity(_isDark ? 0.05 : 0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: statusColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Hero(
                          tag: 'photo_${app.id}',
                          child: Container(
                            width: 82, height: 82,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                  color: statusColor.withOpacity(0.4),
                                  width: 2.5),
                              image: DecorationImage(
                                image: NetworkImage(app.photoUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(app.fullName,
                                  style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      color: _text)),
                              const SizedBox(height: 6),
                              _infoChip(Icons.phone_rounded,
                                  app.mobileNumber, statusColor),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color:
                                      statusColor.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(meta.icon,
                                        size: 12, color: statusColor),
                                    const SizedBox(width: 5),
                                    Text(
                                      app.status.toUpperCase(),
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: statusColor),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Personal ──
                  _detailCard(
                    title: SC.tr('joinSectionPersonal'),
                    icon: Icons.person_rounded,
                    gradient: const LinearGradient(
                        colors: [Color(0xFF2575FC), Color(0xFF6A11CB)]),
                    rows: [
                      _row(SC.tr('joinFieldFatherName'), app.fatherName),
                      _row(SC.tr('joinFieldMotherName'), app.motherName),
                      _row(SC.tr('joinFieldBloodGroup'), app.bloodGroup,
                          accent: const Color(0xFFFF5252),
                          icon: Icons.water_drop_rounded),
                      _row(SC.tr('joinFieldReason'), app.reasonToJoin),
                    ],
                  ),

                  // ── Address ──
                  _detailCard(
                    title: SC.tr('joinSectionAddress'),
                    icon: Icons.location_on_rounded,
                    gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFFB347)]),
                    rows: [
                      _row(SC.tr('joinFieldVillage'), app.village),
                      _row(SC.tr('joinFieldUpazila'), app.upazila),
                      _row(SC.tr('joinFieldDistrict'), app.district),
                    ],
                  ),

                  // ── Education ──
                  if ([
                    app.eduPrimary,
                    app.eduSecondary,
                    app.eduHigherSecondary,
                    app.eduGraduate
                  ].any((e) => e != null))
                    _detailCard(
                      title: SC.tr('joinSectionEducation'),
                      icon: Icons.school_rounded,
                      gradient: const LinearGradient(
                          colors: [Color(0xFF6A11CB), Color(0xFF9C27B0)]),
                      rows: [
                        if (app.eduPrimary != null)
                          _row(SC.tr('joinFieldEduPrimary'), app.eduPrimary!),
                        if (app.eduSecondary != null)
                          _row(SC.tr('joinFieldEduSecondary'), app.eduSecondary!),
                        if (app.eduHigherSecondary != null)
                          _row(SC.tr('joinFieldEduHsc'), app.eduHigherSecondary!),
                        if (app.eduGraduate != null)
                          _row(SC.tr('joinFieldEduGrad'), app.eduGraduate!),
                      ],
                    ),

                  // ── Payment ──
                  _detailCard(
                    title: SC.tr('joinSectionPayment'),
                    icon: Icons.account_balance_wallet_rounded,
                    gradient: const LinearGradient(
                        colors: [Color(0xFFE91E63), Color(0xFFFF6B35)]),
                    rows: [
                      _row(SC.tr('joinFieldPaymentNumber'), app.paymentNumber),
                      _row(SC.tr('joinFieldTransactionId'), app.transactionId),
                      _row(SC.tr('adminAmount'), '${app.paymentAmount} ৳',
                          accent: const Color(0xFF00E676),
                          icon: Icons.monetization_on_rounded),
                    ],
                    extraChild: Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          app.paymentScreenshotUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Action Buttons ──
                  if (app.status == 'pending') ...[
                    Row(
                      children: [
                        Expanded(
                          child: _actionButton(
                            label: SC.tr('adminReject'),
                            icon: Icons.close_rounded,
                            gradient: const LinearGradient(
                                colors: [Color(0xFFFF5252), Color(0xFFE91E63)]),
                            onTap: () {
                              Navigator.pop(ctx);
                              _updateStatus(app, 'rejected');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _actionButton(
                            label: SC.tr('adminApprove'),
                            icon: Icons.check_rounded,
                            gradient: const LinearGradient(
                                colors: [Color(0xFF00C9A7), Color(0xFF00E676)]),
                            onTap: () {
                              Navigator.pop(ctx);
                              _updateStatus(app, 'approved');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Delete button
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _confirmDelete(app);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.redAccent.withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.delete_rounded,
                              color: Colors.redAccent, size: 18),
                          const SizedBox(width: 8),
                          Text(SC.tr('adminDeleteTitle'),
                              style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Detail Card ─────────────────────────────────────────────
  Widget _detailCard({
    required String title,
    required IconData icon,
    required LinearGradient gradient,
    required List<Widget> rows,
    Widget? extraChild,
  }) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  gradient.colors.first.withOpacity(_isDark ? 0.18 : 0.1),
                  Colors.transparent,
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 10),
                Text(title,
                    style: TextStyle(
                        color: gradient.colors.first,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
          ),
          Divider(height: 1, color: _border),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...rows,
                if (extraChild != null) extraChild,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value,
      {Color? accent, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(label,
                style: TextStyle(fontSize: 12, color: _sub)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 13, color: accent ?? _text),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(value,
                      style: TextStyle(
                          fontSize: 14,
                          color: accent ?? _text,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Text(text,
            style: TextStyle(
                fontSize: 12,
                color: _sub,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
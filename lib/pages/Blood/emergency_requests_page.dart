import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../SettingsPage/settings_constants.dart';
import 'donation_history_page.dart';
import 'emergency_request_detail_page.dart';

class EmergencyRequestsPage extends StatefulWidget {
  const EmergencyRequestsPage({super.key});

  @override
  State<EmergencyRequestsPage> createState() => _EmergencyRequestsPageState();
}

class _EmergencyRequestsPageState extends State<EmergencyRequestsPage>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _myRequests = [];
  List<Map<String, dynamic>> _otherRequests = [];

  bool _loading = true;
  String? _errorMessage;
  String? _currentUserId;
  final Set<String> _submittingIds = {};

  late final String _channelName;
  late RealtimeChannel _channel;

  late AnimationController _pulseController;
  late AnimationController _staggerController;
  late PageController _pageController;
  int _currentPage = 0;

  // ─── Theme ────────────────────────────────────────────────────────────────
  bool get _isDark => SC.isDark;
  Color get _bg => _isDark ? const Color(0xFF060810) : const Color(0xFFF0F4FF);
  Color get _card => _isDark ? const Color(0xFF0D1B2A) : Colors.white;
  Color get _text => _isDark ? Colors.white : const Color(0xFF1A2332);
  Color get _sub => _isDark ? const Color(0xFFB0BEC5) : const Color(0xFF4A5568);
  Color get _border =>
      (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.07);

  static const _red = Color(0xFFFF4B6E);
  static const _green = Color(0xFF00E676);
  static const _cyan = Color(0xFF00E5FF);

  @override
  void initState() {
    super.initState();
    _channelName =
    'emergency_requests_${DateTime.now().millisecondsSinceEpoch}';
    _currentUserId = supabase.auth.currentUser?.id;

    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
    _staggerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _pageController = PageController();

    _fetchRequests();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    supabase.removeChannel(_channel);
    _pulseController.dispose();
    _staggerController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ─── Data ────────────────────────────────────────────────────────────────
  void _subscribeRealtime() {
    _channel = supabase
        .channel(_channelName)
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'emergency_blood_requests',
      callback: (_) => _fetchRequests(),
    )
        .subscribe();
  }

  Future<void> _fetchRequests() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final uid = _currentUserId ?? '';
      final data = await supabase
          .from('emergency_blood_requests')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .range(0, 49);

      final all = List<Map<String, dynamic>>.from(data);
      all.sort((a, b) {
        final aT = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(0);
        final bT = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(0);
        return bT.compareTo(aT);
      });

      if (!mounted) return;
      setState(() {
        _myRequests =
            all.where((r) => r['requester_user_id'] == uid).toList();
        _otherRequests =
            all.where((r) => r['requester_user_id'] != uid).toList();
        _loading = false;
      });
      _staggerController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _markAsDonated(Map<String, dynamic> req) async {
    if (_currentUserId == null) {
      SC.toast(context, SC.tr('loginRequired'), const Color(0xFFFF2244));
      return;
    }
    final reqId = req['id'].toString();
    final donors = List<String>.from(req['donated_by'] ?? []);
    if (donors.contains(_currentUserId)) {
      SC.toast(context, SC.tr('alreadyDonated'), const Color(0xFFFFAB40));
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() => _submittingIds.add(reqId));
    try {
      final newDonors = [...donors, _currentUserId!];
      await supabase.from('emergency_blood_requests').update({
        'donated_by': newDonors,
        'donation_count': newDonors.length,
      }).eq('id', req['id']);

      await supabase.from('donations').upsert({
        'request_id': req['id'],
        'donor_id': _currentUserId,
        'donated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'request_id,donor_id');

      await supabase.from('profiles').update({
        'last_donated_at': DateTime.now().toIso8601String(),
      }).eq('id', _currentUserId!);

      if (!mounted) return;
      setState(() {
        final idx = _otherRequests.indexWhere((r) => r['id'] == req['id']);
        if (idx != -1) {
          _otherRequests[idx] = {
            ..._otherRequests[idx],
            'donated_by': newDonors,
            'donation_count': newDonors.length,
          };
        }
        _submittingIds.remove(reqId);
      });
      SC.toast(context, SC.tr('donatedSuccess'), _green);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submittingIds.remove(reqId));
      final dup = e.toString().contains('donations_unique') ||
          e.toString().contains('unique') ||
          e.toString().contains('23505');
      SC.toast(
        context,
        dup ? SC.tr('alreadyDonated') : SC.tr('submitFailed'),
        dup ? const Color(0xFFFFAB40) : const Color(0xFFFF2244),
      );
    }
  }

  bool _hasDonated(Map<String, dynamic> req) =>
      _currentUserId != null &&
          List<String>.from(req['donated_by'] ?? []).contains(_currentUserId);

  // ─── Helpers ─────────────────────────────────────────────────────────────
  Color _bloodColor(String? g) {
    const map = {
      'A+': Color(0xFFFF4B6E),
      'A-': Color(0xFFFF6B8A),
      'B+': Color(0xFFFF7043),
      'B-': Color(0xFFFFAB40),
      'O+': Color(0xFF00E5FF),
      'O-': Color(0xFF69F0AE),
      'AB+': Color(0xFFE040FB),
      'AB-': Color(0xFF7C4DFF),
    };
    return map[g] ?? _red;
  }

  String _timeAgo(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final d = DateTime.now().difference(dt.toLocal());
    if (d.inSeconds < 60) return SC.tr('justNow');
    if (d.inMinutes < 60) return '${d.inMinutes}${SC.tr('minutesAgo')}';
    if (d.inHours < 24) return '${d.inHours}${SC.tr('hoursAgo')}';
    return '${d.inDays}${SC.tr('daysAgo')}';
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _openDetail(Map<String, dynamic> req, bool isOwn) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) =>
            EmergencyRequestDetailPage(request: req, isOwn: isOwn),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity:
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (_, __, ___) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (_, __, ___) => _scaffold(),
      ),
    );
  }

  Widget _scaffold() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _bg,
        extendBodyBehindAppBar: true,
        appBar: _appBar(),
        body: Stack(children: [
          _background(),
          SafeArea(
            child: Column(children: [
              _tabBar(),
              Expanded(
                child: _loading
                    ? _loader()
                    : _errorMessage != null
                    ? _errorView()
                    : (_myRequests.isEmpty && _otherRequests.isEmpty)
                    ? _emptyAll()
                    : _pageView(),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  // ─── APP BAR ─────────────────────────────────────────────────────────────
  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle:
      _isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (_isDark ? Colors.white : Colors.black)
                .withValues(alpha: 0.06),
            border: Border.all(color: _border),
          ),
          child:
          Icon(Icons.arrow_back_ios_new_rounded, color: _text, size: 14),
        ),
      ),
      title: Row(mainAxisSize: MainAxisSize.min, children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (_, __) => Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFF2244)
                  .withValues(alpha: 0.12 + _pulseController.value * 0.08),
              border: Border.all(
                color: const Color(0xFFFF2244)
                    .withValues(alpha: 0.4 + _pulseController.value * 0.2),
              ),
            ),
            child: const Icon(Icons.bloodtype_rounded,
                color: Color(0xFFFF2244), size: 14),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          SC.tr('emergencyRequests').toUpperCase(),
          style: TextStyle(
            color: _text,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ]),
      centerTitle: true,
      actions: [
        GestureDetector(
          onTap: _fetchRequests,
          child: Container(
            margin: const EdgeInsets.only(right: 14),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (_isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.06),
              border: Border.all(color: _border),
            ),
            child:
            Icon(Icons.refresh_rounded, color: _text, size: 17),
          ),
        ),
      ],
    );
  }

  // ─── TAB BAR ─────────────────────────────────────────────────────────────
  Widget _tabBar() {
    final tabs = [
      (
      icon: Icons.person_pin_circle_rounded,
      label: SC.tr('myRequests'),
      count: _myRequests.length,
      activeColor: const Color(0xFFFF2244),
      ),
      (
      icon: Icons.people_alt_rounded,
      label: SC.tr('emergencyRequests'),
      count: _otherRequests.length,
      activeColor: _green,
      ),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final tab = tabs[i];
          final active = _currentPage == i;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _pageController.animateToPage(i,
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeInOutCubic);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: active
                      ? LinearGradient(colors: [
                    tab.activeColor.withValues(alpha: 0.18),
                    tab.activeColor.withValues(alpha: 0.07),
                  ])
                      : null,
                  border: active
                      ? Border.all(
                      color: tab.activeColor.withValues(alpha: 0.35),
                      width: 1.2)
                      : null,
                  boxShadow: active
                      ? [
                    BoxShadow(
                      color: tab.activeColor.withValues(alpha: 0.14),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    )
                  ]
                      : null,
                ),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tab.icon,
                        size: 14,
                        color: active
                            ? tab.activeColor
                            : _sub.withValues(alpha: 0.45),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          tab.label,
                          style: TextStyle(
                            color: active
                                ? tab.activeColor
                                : _sub.withValues(alpha: 0.45),
                            fontSize: 11,
                            fontWeight:
                            active ? FontWeight.w800 : FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (tab.count > 0) ...[
                        const SizedBox(width: 5),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: active
                                ? tab.activeColor
                                : _sub.withValues(alpha: 0.2),
                          ),
                          child: Text(
                            '${tab.count}',
                            style: TextStyle(
                              color: active ? Colors.white : _sub.withValues(alpha: 0.7),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ]),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── PAGE VIEW ───────────────────────────────────────────────────────────
  Widget _pageView() {
    return PageView(
      controller: _pageController,
      physics: const BouncingScrollPhysics(),
      onPageChanged: (i) {
        HapticFeedback.selectionClick();
        setState(() => _currentPage = i);
        _staggerController.forward(from: 0);
      },
      children: [
        _section(
          requests: _myRequests,
          isOwn: true,
          emptyIcon: Icons.person_off_rounded,
          emptyTitle: SC.tr('noMyRequests'),
          emptySubtitle: SC.tr('noMyRequestsSub'),
          accent: const Color(0xFFFF2244),
        ),
        _section(
          requests: _otherRequests,
          isOwn: false,
          emptyIcon: Icons.check_circle_outline,
          emptyTitle: SC.tr('noActiveRequests'),
          emptySubtitle: SC.tr('allResolved'),
          accent: _green,
        ),
      ],
    );
  }

  Widget _section({
    required List<Map<String, dynamic>> requests,
    required bool isOwn,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
    required Color accent,
  }) {
    if (requests.isEmpty) {
      return _sectionEmpty(
          icon: emptyIcon,
          title: emptyTitle,
          subtitle: emptySubtitle,
          color: accent);
    }
    return RefreshIndicator(
      onRefresh: _fetchRequests,
      color: accent,
      backgroundColor: _card,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
        physics: const BouncingScrollPhysics(),
        itemCount: requests.length,
        itemBuilder: (_, i) {
          final req = requests[i];
          final delay =
          requests.length <= 1 ? 0.0 : i / (requests.length - 1);
          final anim = Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: _staggerController,
              curve: Interval(
                (delay * 0.4).clamp(0.0, 0.6),
                (delay * 0.4 + 0.6).clamp(0.0, 1.0),
                curve: Curves.easeOutCubic,
              ),
            ),
          );
          return AnimatedBuilder(
            animation: anim,
            builder: (_, child) => Opacity(
              opacity: anim.value,
              child: Transform.translate(
                offset: Offset(0, 18 * (1 - anim.value)),
                child: child,
              ),
            ),
            child: _requestCard(req, isOwn: isOwn),
          );
        },
      ),
    );
  }

  Widget _sectionEmpty({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (_, __) => Transform.scale(
            scale: 1.0 + _pulseController.value * 0.05,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.08),
                border: Border.all(
                    color: color.withValues(alpha: 0.24)),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(
                        alpha: 0.07 + _pulseController.value * 0.06),
                    blurRadius: 20,
                    spreadRadius: 4,
                  )
                ],
              ),
              child: Icon(icon, color: color, size: 34),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(title,
            style: TextStyle(
                color: _text, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        Text(subtitle,
            style: TextStyle(
                color: _sub.withValues(alpha: 0.45), fontSize: 12)),
      ]),
    );
  }

  // ─── BACKGROUND ──────────────────────────────────────────────────────────
  Widget _background() {
    if (!_isDark) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF0F4FF),
              Color(0xFFE8EFFF),
              Color(0xFFEFF6FF),
            ],
          ),
        ),
      );
    }
    return Stack(children: [
      Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4),
            radius: 1.5,
            colors: [
              Color(0xFF1A0510),
              Color(0xFF060810),
              Color(0xFF030508),
            ],
          ),
        ),
      ),
      Positioned(
        top: 60,
        left: -100,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (_, __) => Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFFFF2244).withValues(
                    alpha: 0.06 + _pulseController.value * 0.03),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 100,
        right: -80,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              _green.withValues(alpha: 0.05),
              Colors.transparent,
            ]),
          ),
        ),
      ),
    ]);
  }

  // ─── LOADER / ERROR ──────────────────────────────────────────────────────
  Widget _loader() => Center(
    child: AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.scale(
              scale: 1.0 + _pulseController.value * 0.14,
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                  const Color(0xFFFF2244).withValues(alpha: 0.1),
                  border: Border.all(
                    color: const Color(0xFFFF2244).withValues(
                        alpha: 0.4 + _pulseController.value * 0.3),
                  ),
                ),
                child: const Icon(Icons.bloodtype_rounded,
                    color: Color(0xFFFF2244), size: 28),
              ),
            ),
            const SizedBox(height: 16),
            Text(SC.tr('loading'),
                style: TextStyle(
                    color: _sub.withValues(alpha: 0.6),
                    fontSize: 13)),
          ]),
    ),
  );

  Widget _errorView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child:
      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFF2244).withValues(alpha: 0.08),
            border: Border.all(
                color:
                const Color(0xFFFF2244).withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.wifi_off_rounded,
              color: Color(0xFFFF2244), size: 30),
        ),
        const SizedBox(height: 16),
        Text(SC.tr('submitFailed'),
            style: TextStyle(
                color: _text,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _fetchRequests,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                  colors: [Color(0xFFFF1744), Color(0xFFFF6B8A)]),
            ),
            child: Text(SC.tr('retry'),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
          ),
        ),
      ]),
    ),
  );

  Widget _emptyAll() => Center(
    child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _green.withValues(alpha: 0.08),
              border:
              Border.all(color: _green.withValues(alpha: 0.24)),
            ),
            child: const Icon(Icons.check_circle_outline,
                color: _green, size: 34),
          ),
          const SizedBox(height: 16),
          Text(SC.tr('noActiveRequests'),
              style: TextStyle(
                  color: _text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(SC.tr('allResolved'),
              style: TextStyle(
                  color: _sub.withValues(alpha: 0.45),
                  fontSize: 12)),
        ]),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // ─── NEW CARD DESIGN ─────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _requestCard(Map<String, dynamic> req, {required bool isOwn}) {
    final bloodGroup = req['blood_group'] as String?;
    final bColor = _bloodColor(bloodGroup);
    final name = req['requester_name'] ?? 'Anonymous';
    final phone = (req['phone'] ?? '') as String;
    final hospital = (req['hospital'] ?? '') as String;
    final address = (req['address'] ?? '') as String;
    final units = req['units_needed'] ?? 1;
    final notes = (req['notes'] ?? '') as String;
    final time = _timeAgo(req['created_at']);
    final donationCount =
        int.tryParse((req['donation_count'] ?? 0).toString()) ?? 0;
    final hasDonated = _hasDonated(req);
    final reqId = req['id'].toString();
    final isSubmitting = _submittingIds.contains(reqId);

    // Determine left bar color
    final barColor = isOwn
        ? const Color(0xFFFF1744)
        : hasDonated
        ? _green
        : bColor;

    // Card border color
    final borderColor = isOwn
        ? const Color(0xFFFF2244).withValues(alpha: 0.3)
        : hasDonated
        ? _green.withValues(alpha: 0.3)
        : bColor.withValues(alpha: 0.2);

    return GestureDetector(
      onTap: () => _openDetail(req, isOwn),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: _card,
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: barColor.withValues(alpha: _isDark ? 0.1 : 0.06),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(children: [
          // ── Left accent bar ─────────────────────────────────────────────
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(20)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isOwn
                      ? [const Color(0xFFFF1744), const Color(0xFFFF6B8A)]
                      : hasDonated
                      ? [const Color(0xFF00C853), const Color(0xFF69F0AE)]
                      : [bColor, bColor.withValues(alpha: 0.35)],
                ),
              ),
            ),
          ),

          // ── Card content ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: badge + info + units
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Blood group badge
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (_, __) => Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: bColor.withValues(alpha: 0.1),
                          border: Border.all(
                            color: bColor.withValues(
                                alpha: 0.35 + _pulseController.value * 0.1),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bloodtype_rounded,
                                  color: bColor.withValues(alpha: 0.7), size: 10),
                              const SizedBox(height: 2),
                              Text(
                                bloodGroup ?? '?',
                                style: TextStyle(
                                  color: bColor,
                                  fontSize: (bloodGroup?.length ?? 0) > 2 ? 11 : 17,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ]),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Name + time + hospital
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    color: _text,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isOwn) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    color: const Color(0xFFFF2244)
                                        .withValues(alpha: 0.1),
                                    border: Border.all(
                                        color: const Color(0xFFFF2244)
                                            .withValues(alpha: 0.3)),
                                  ),
                                  child: const Text(
                                    'আমার',
                                    style: TextStyle(
                                      color: Color(0xFFFF2244),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ]),

                            const SizedBox(height: 4),

                            // Time + hospital in one muted row
                            Row(children: [
                              Icon(Icons.access_time_rounded,
                                  size: 11,
                                  color: _sub.withValues(alpha: 0.4)),
                              const SizedBox(width: 3),
                              Text(time,
                                  style: TextStyle(
                                      color: _sub.withValues(alpha: 0.4),
                                      fontSize: 11)),
                              if (hospital.isNotEmpty) ...[
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 6),
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _sub.withValues(alpha: 0.25),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    hospital,
                                    style: TextStyle(
                                        color: _sub.withValues(alpha: 0.5),
                                        fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ]),

                            const SizedBox(height: 8),

                            // Tags row
                            Wrap(spacing: 6, runSpacing: 5, children: [
                              // Units pill
                              _tag(
                                icon: Icons.water_drop_rounded,
                                label:
                                '$units ${SC.tr('units')}',
                                color: bColor,
                              ),
                              if (address.isNotEmpty)
                                _tag(
                                  icon: Icons.location_on_rounded,
                                  label: address,
                                  color: _sub,
                                  maxWidth: 110,
                                ),
                              if (notes.isNotEmpty)
                                _tag(
                                  icon: Icons.notes_rounded,
                                  label: notes,
                                  color: const Color(0xFFFFAB40),
                                  maxWidth: 110,
                                ),
                            ]),
                          ]),
                    ),
                  ]),

                  // ── Donor strip (if any) ────────────────────────────────────
                  if (donationCount > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: _green.withValues(alpha: 0.07),
                        border: Border.all(
                            color: _green.withValues(alpha: 0.22)),
                      ),
                      child: Row(children: [
                        Icon(Icons.favorite_rounded,
                            color: _green, size: 13),
                        const SizedBox(width: 6),
                        Text(
                          '$donationCount ${SC.tr('donorCount')}',
                          style: const TextStyle(
                            color: _green,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          SC.tr('tapForDetails'),
                          style: TextStyle(
                              color: _sub.withValues(alpha: 0.35),
                              fontSize: 10),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.chevron_right_rounded,
                            color: _sub.withValues(alpha: 0.35), size: 14),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 12),
                  Divider(
                      color: _border, height: 1, thickness: 0.5),
                  const SizedBox(height: 12),

                  // ── Action buttons ──────────────────────────────────────────
                  if (isOwn)
                    _ownerActions(req, donationCount)
                  else
                    _donorActions(req, phone, bColor, hasDonated, isSubmitting),
                ]),
          ),
        ]),
      ),
    );
  }

  // ─── TAG CHIP ────────────────────────────────────────────────────────────
  Widget _tag({
    required IconData icon,
    required String label,
    required Color color,
    double? maxWidth,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth ?? 200),
          child: Text(
            label,
            style: TextStyle(
              color: _sub.withValues(alpha: 0.75),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }

  // ─── CARD ACTION BUTTONS ─────────────────────────────────────────────────
  Widget _donorActions(
      Map<String, dynamic> req,
      String phone,
      Color bColor,
      bool hasDonated,
      bool isSubmitting,
      ) {
    return Row(children: [
      if (phone.isNotEmpty) ...[
        Expanded(
          child: _actionBtn(
            onTap: () {
              HapticFeedback.mediumImpact();
              _callPhone(phone);
            },
            gradient:
            LinearGradient(colors: [bColor, bColor.withValues(alpha: 0.7)]),
            icon: Icons.phone_rounded,
            label: SC.tr('callNowToDonate'),
            textColor: Colors.white,
            shadow: bColor.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(width: 8),
      ],
      Expanded(
        child: hasDonated
            ? _actionBtn(
          onTap: null,
          gradient: const LinearGradient(
              colors: [Color(0xFF00C853), Color(0xFF69F0AE)]),
          icon: Icons.check_circle_rounded,
          label: SC.tr('donatedBadge'),
          textColor: Colors.white,
          shadow: _green.withValues(alpha: 0.3),
        )
            : _actionBtn(
          onTap: isSubmitting ? null : () => _markAsDonated(req),
          gradient: null,
          icon: Icons.volunteer_activism_rounded,
          label: SC.tr('iDonated'),
          textColor: _sub.withValues(alpha: 0.55),
          borderColor: _border,
          isLoading: isSubmitting,
        ),
      ),
    ]);
  }

  Widget _ownerActions(Map<String, dynamic> req, int donationCount) {
    return _actionBtn(
      onTap: donationCount > 0
          ? () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                DonationHistoryPage(requestId: req['id'])),
      )
          : null,
      gradient: donationCount > 0
          ? const LinearGradient(
          colors: [Color(0xFF00C853), Color(0xFF00E676)])
          : null,
      icon: Icons.people_alt_rounded,
      label: donationCount > 0
          ? '${SC.tr('viewDonors')} ($donationCount)'
          : SC.tr('noDonations'),
      textColor: donationCount > 0
          ? Colors.white
          : _sub.withValues(alpha: 0.35),
      shadow:
      donationCount > 0 ? _green.withValues(alpha: 0.28) : null,
      borderColor: donationCount > 0 ? null : _border,
    );
  }

  Widget _actionBtn({
    required VoidCallback? onTap,
    required LinearGradient? gradient,
    required IconData icon,
    required String label,
    required Color textColor,
    Color? shadow,
    Color? borderColor,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: gradient,
          color: gradient == null
              ? (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)
              : null,
          border:
          borderColor != null ? Border.all(color: borderColor) : null,
          boxShadow: shadow != null
              ? [BoxShadow(color: shadow, blurRadius: 12, offset: const Offset(0, 3))]
              : null,
        ),
        child: isLoading
            ? Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                color: _green, strokeWidth: 2),
          ),
        )
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: textColor, size: 14),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
      ),
    );
  }
}
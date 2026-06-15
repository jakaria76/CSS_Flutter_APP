import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../SettingsPage/settings_constants.dart';
import 'donation_history_page.dart';

class EmergencyRequestDetailPage extends StatefulWidget {
  final Map<String, dynamic> request;
  final bool isOwn;

  const EmergencyRequestDetailPage({
    super.key,
    required this.request,
    required this.isOwn,
  });

  @override
  State<EmergencyRequestDetailPage> createState() =>
      _EmergencyRequestDetailPageState();
}

class _EmergencyRequestDetailPageState
    extends State<EmergencyRequestDetailPage>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  late Map<String, dynamic> _req;
  bool _isSubmitting = false;
  String? _currentUserId;

  late AnimationController _pulseCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _entryCtrl;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _glowAnim;

  // ─── Theme helpers ────────────────────────────────────────────────────────
  bool get _isDark => SC.isDark;

  Color get _bg =>
      _isDark ? const Color(0xFF060810) : const Color(0xFFF0F4FF);

  Color get _card =>
      _isDark ? const Color(0xFF0D1B2A) : Colors.white;

  Color get _text =>
      _isDark ? Colors.white : const Color(0xFF1A2332);

  Color get _sub =>
      _isDark ? const Color(0xFFB0BEC5) : const Color(0xFF4A5568);

  Color get _border =>
      (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.07);

  Color get _accentRed => const Color(0xFFFF4B6E);
  Color get _accentGreen => const Color(0xFF00E676);
  Color get _accentCyan => const Color(0xFF00E5FF);
  Color get _accentAmber => const Color(0xFFFFAB40);

  @override
  void initState() {
    super.initState();
    _req = Map<String, dynamic>.from(widget.request);
    _currentUserId = supabase.auth.currentUser?.id;

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);

    _fadeAnim =
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.07), end: Offset.zero).animate(
            CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _glowCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
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
    return map[g] ?? const Color(0xFFFF4B6E);
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

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final l = dt.toLocal();
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final h = l.hour % 12 == 0 ? 12 : l.hour % 12;
    final m = l.minute.toString().padLeft(2, '0');
    final ap = l.hour < 12 ? 'AM' : 'PM';
    return '${l.day} ${months[l.month - 1]} ${l.year}, $h:$m $ap';
  }

  bool get _hasDonated =>
      _currentUserId != null &&
          List<String>.from(_req['donated_by'] ?? []).contains(_currentUserId);

  // ─── Actions ──────────────────────────────────────────────────────────────
  Future<void> _markAsDonated() async {
    if (_currentUserId == null) {
      _toast(SC.tr('loginRequired'), const Color(0xFFFF2244));
      return;
    }
    final donors = List<String>.from(_req['donated_by'] ?? []);
    if (donors.contains(_currentUserId)) {
      _toast(SC.tr('alreadyDonated'), _accentAmber);
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() => _isSubmitting = true);

    try {
      final newDonors = [...donors, _currentUserId!];
      await supabase.from('emergency_blood_requests').update({
        'donated_by': newDonors,
        'donation_count': newDonors.length,
      }).eq('id', _req['id']);

      await supabase.from('donations').upsert({
        'request_id': _req['id'],
        'donor_id': _currentUserId,
        'donated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'request_id,donor_id');

      await supabase.from('profiles').update({
        'last_donated_at': DateTime.now().toIso8601String(),
      }).eq('id', _currentUserId!);

      if (!mounted) return;
      setState(() {
        _req = {
          ..._req,
          'donated_by': newDonors,
          'donation_count': newDonors.length,
        };
        _isSubmitting = false;
      });
      _toast(SC.tr('donatedSuccess'), _accentGreen);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final dup = e.toString().contains('donations_unique') ||
          e.toString().contains('unique') ||
          e.toString().contains('23505');
      _toast(
        dup ? SC.tr('alreadyDonated') : SC.tr('submitFailed'),
        dup ? _accentAmber : const Color(0xFFFF2244),
      );
    }
  }

  void _toast(String msg, Color color) => SC.toast(context, msg, color);

  Future<void> _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openMap(String address) async {
    final uri = Uri.parse(
        'https://maps.google.com/?q=${Uri.encodeComponent(address)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _pushDonorHistory() => Navigator.push(
    context,
    MaterialPageRoute(
        builder: (_) => DonationHistoryPage(requestId: _req['id'])),
  );

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
    final bloodGroup = _req['blood_group'] as String?;
    final bColor = _bloodColor(bloodGroup);
    final isOwn = widget.isOwn;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _bg,
        extendBodyBehindAppBar: true,
        appBar: _appBar(bColor, isOwn),
        body: Stack(children: [
          _background(bColor),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: _body(bColor, isOwn),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ─── APP BAR ──────────────────────────────────────────────────────────────
  PreferredSizeWidget _appBar(Color bColor, bool isOwn) {
    final dotColor = isOwn ? const Color(0xFFFF2244) : bColor;
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
          child: Icon(Icons.arrow_back_ios_new_rounded,
              color: _text, size: 14),
        ),
      ),
      title: Row(mainAxisSize: MainAxisSize.min, children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor
                  .withValues(alpha: 0.12 + _pulseAnim.value * 0.1),
              border: Border.all(
                color: dotColor
                    .withValues(alpha: 0.4 + _pulseAnim.value * 0.25),
              ),
            ),
            child: Icon(Icons.bloodtype_rounded, color: dotColor, size: 13),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          SC.tr('emergencyRequests').toUpperCase(),
          style: TextStyle(
            color: _text,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
      ]),
      centerTitle: true,
    );
  }

  // ─── BACKGROUND ───────────────────────────────────────────────────────────
  Widget _background(Color accent) {
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
            center: Alignment(0, -0.5),
            radius: 1.4,
            colors: [Color(0xFF1A0510), Color(0xFF060810), Color(0xFF030508)],
          ),
        ),
      ),
      // Animated left glow
      Positioned(
        top: 50,
        left: -90,
        child: AnimatedBuilder(
          animation: _glowAnim,
          builder: (_, __) => Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                accent.withValues(alpha: 0.07 + _glowAnim.value * 0.05),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ),
      // Static bottom-right green glow
      Positioned(
        bottom: 100,
        right: -60,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              _accentGreen.withValues(alpha: 0.05),
              Colors.transparent,
            ]),
          ),
        ),
      ),
    ]);
  }

  // ─── BODY ─────────────────────────────────────────────────────────────────
  Widget _body(Color bColor, bool isOwn) {
    final bloodGroup = _req['blood_group'] as String?;
    final name = _req['requester_name'] ?? 'Anonymous';
    final phone = (_req['phone'] ?? '') as String;
    final hospital = (_req['hospital'] ?? '') as String;
    final address = (_req['address'] ?? '') as String;
    final units = _req['units_needed'] ?? 1;
    final notes = (_req['notes'] ?? '') as String;
    final donationCount =
        int.tryParse((_req['donation_count'] ?? 0).toString()) ?? 0;
    final createdAt = _req['created_at'] as String?;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 48),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _heroCard(
          bloodGroup: bloodGroup,
          bColor: bColor,
          name: name,
          phone: phone,
          units: units,
          createdAt: createdAt,
          isOwn: isOwn,
        ),

        const SizedBox(height: 12),

        if (address.isNotEmpty)
          _infoCard(
            icon: Icons.location_on_rounded,
            iconColor: _accentRed,
            title: SC.tr('address'),
            value: address,
            onTap: () => _openMap(address),
            trailing: Icons.open_in_new_rounded,
          ),

        if (hospital.isNotEmpty)
          _infoCard(
            icon: Icons.local_hospital_rounded,
            iconColor: _accentCyan,
            title: SC.tr('hospital'),
            value: hospital,
          ),

        if (notes.isNotEmpty)
          _infoCard(
            icon: Icons.notes_rounded,
            iconColor: _accentAmber,
            title: SC.tr('notes'),
            value: notes,
          ),

        if (createdAt != null)
          _infoCard(
            icon: Icons.schedule_rounded,
            iconColor: _sub.withValues(alpha: 0.5),
            title: SC.tr('postedAt'),
            value: _formatDate(createdAt),
          ),

        const SizedBox(height: 12),

        _donationStatus(donationCount),

        const SizedBox(height: 18),

        if (isOwn)
          _ownerActions(donationCount)
        else
          _donorActions(phone, bColor),
      ]),
    );
  }

  // ─── HERO CARD ────────────────────────────────────────────────────────────
  Widget _heroCard({
    required String? bloodGroup,
    required Color bColor,
    required String name,
    required String phone,
    required int units,
    required String? createdAt,
    required bool isOwn,
  }) {
    final topColor = isOwn ? const Color(0xFFFF1744) : bColor;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: _card,
        border: Border.all(
          color: topColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: topColor.withValues(alpha: _isDark ? 0.18 : 0.1),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Gradient top strip
        Container(
          height: 5,
          decoration: BoxDecoration(
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(22)),
            gradient: LinearGradient(
              colors: isOwn
                  ? [const Color(0xFFFF1744), const Color(0xFFFF6B8A)]
                  : [bColor, bColor.withValues(alpha: 0.4)],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Blood group badge
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: bColor.withValues(alpha: 0.1),
                    border: Border.all(
                      color: bColor.withValues(
                          alpha: 0.38 + _pulseAnim.value * 0.14),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: bColor.withValues(
                            alpha: 0.1 + _pulseAnim.value * 0.1),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bloodtype_rounded,
                          color: Color(0xFFFF2244), size: 14),
                      const SizedBox(height: 3),
                      Text(
                        bloodGroup ?? '?',
                        style: TextStyle(
                          color: bColor,
                          fontSize: (bloodGroup?.length ?? 0) > 2 ? 14 : 22,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + own label
                      Row(children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              color: _text,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (isOwn) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(7),
                              color: const Color(0xFFFF2244).withValues(alpha: 0.1),
                              border: Border.all(
                                color:
                                const Color(0xFFFF2244).withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Text(
                              'আমার',
                              style: TextStyle(
                                color: Color(0xFFFF2244),
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ]),

                      const SizedBox(height: 6),

                      // Time ago
                      Row(children: [
                        Icon(Icons.access_time_rounded,
                            size: 12,
                            color: _sub.withValues(alpha: 0.4)),
                        const SizedBox(width: 4),
                        Text(
                          _timeAgo(createdAt),
                          style: TextStyle(
                              color: _sub.withValues(alpha: 0.4), fontSize: 12),
                        ),
                      ]),

                      const SizedBox(height: 9),

                      // Units needed pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: bColor.withValues(alpha: 0.1),
                          border:
                          Border.all(color: bColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.water_drop_rounded, color: bColor, size: 13),
                          const SizedBox(width: 5),
                          Text(
                            '$units ${SC.tr('units')} ${SC.tr('needed')}',
                            style: TextStyle(
                              color: bColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ]),
                      ),
                    ]),
              ),
            ]),

            if (phone.isNotEmpty) ...[
              const SizedBox(height: 16),
              _phoneRow(phone, bColor),
            ],
          ]),
        ),
      ]),
    );
  }

  // ─── PHONE ROW ────────────────────────────────────────────────────────────
  Widget _phoneRow(String phone, Color bColor) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _callPhone(phone);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: _accentGreen.withValues(alpha: 0.07),
          border:
          Border.all(color: _accentGreen.withValues(alpha: 0.22)),
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accentGreen.withValues(alpha: 0.14),
              border:
              Border.all(color: _accentGreen.withValues(alpha: 0.3)),
            ),
            child: Icon(Icons.phone_rounded, color: _accentGreen, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                SC.tr('contactNumber'),
                style: TextStyle(
                  color: _sub.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                phone,
                style: TextStyle(
                  color: _text,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                  colors: [Color(0xFF00C853), Color(0xFF69F0AE)]),
              boxShadow: [
                BoxShadow(
                  color: _accentGreen.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.call_rounded, color: Colors.white, size: 13),
              SizedBox(width: 5),
              Text(
                'Call',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  // ─── INFO CARD ────────────────────────────────────────────────────────────
  Widget _infoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    VoidCallback? onTap,
    IconData? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: _card,
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: (_isDark ? Colors.black : Colors.grey)
                  .withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: iconColor.withValues(alpha: 0.1),
              border: Border.all(color: iconColor.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                title,
                style: TextStyle(
                  color: _sub.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  color: _text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ]),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Icon(trailing,
                color: iconColor.withValues(alpha: 0.5), size: 16),
          ],
        ]),
      ),
    );
  }

  // ─── DONATION STATUS ──────────────────────────────────────────────────────
  Widget _donationStatus(int count) {
    if (count == 0) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: _card,
          border: Border.all(color: _border),
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: _sub.withValues(alpha: 0.08),
              border: Border.all(color: _border),
            ),
            child: Icon(Icons.volunteer_activism_rounded,
                color: _sub.withValues(alpha: 0.35), size: 17),
          ),
          const SizedBox(width: 12),
          Text(
            SC.tr('noDonations'),
            style: TextStyle(
              color: _sub.withValues(alpha: 0.5),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ]),
      );
    }

    return GestureDetector(
      onTap: _pushDonorHistory,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: _card,
          border:
          Border.all(color: _accentGreen.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: _accentGreen.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: _accentGreen.withValues(alpha: 0.12),
              border:
              Border.all(color: _accentGreen.withValues(alpha: 0.28)),
            ),
            child:
            Icon(Icons.favorite_rounded, color: _accentGreen, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                SC.tr('totalDonors'),
                style: TextStyle(
                  color: _sub.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '$count ${SC.tr('donorCount')}',
                style: TextStyle(
                  color: _accentGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ]),
          ),
          Row(children: [
            Text(
              SC.tr('viewDonors'),
              style: TextStyle(
                color: _accentGreen.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.chevron_right_rounded,
                color: _accentGreen.withValues(alpha: 0.6), size: 17),
          ]),
        ]),
      ),
    );
  }

  // ─── ACTION BUTTONS ───────────────────────────────────────────────────────
  Widget _donorActions(String phone, Color bColor) {
    return Column(children: [
      if (phone.isNotEmpty) ...[
        _bigButton(
          onTap: () {
            HapticFeedback.mediumImpact();
            _callPhone(phone);
          },
          gradient: LinearGradient(
              colors: [bColor, bColor.withValues(alpha: 0.7)]),
          icon: Icons.phone_rounded,
          label: SC.tr('callNowToDonate'),
          shadowColor: bColor.withValues(alpha: 0.35),
        ),
        const SizedBox(height: 10),
      ],
      _hasDonated
          ? _bigButton(
        onTap: null,
        gradient: const LinearGradient(
            colors: [Color(0xFF00C853), Color(0xFF69F0AE)]),
        icon: Icons.check_circle_rounded,
        label: SC.tr('donatedBadge'),
        shadowColor:
        _accentGreen.withValues(alpha: 0.35),
      )
          : _bigButton(
        onTap: _isSubmitting ? null : _markAsDonated,
        gradient: null,
        icon: Icons.volunteer_activism_rounded,
        label: SC.tr('iDonated'),
        isLoading: _isSubmitting,
        textColor: _sub.withValues(alpha: 0.6),
        borderColor: _border,
      ),
    ]);
  }

  Widget _ownerActions(int count) {
    return _bigButton(
      onTap: count > 0 ? _pushDonorHistory : null,
      gradient: count > 0
          ? const LinearGradient(
          colors: [Color(0xFF00C853), Color(0xFF00E676)])
          : null,
      icon: Icons.people_alt_rounded,
      label: count > 0
          ? '${SC.tr('viewDonors')} ($count)'
          : SC.tr('noDonations'),
      textColor: count > 0 ? Colors.white : _sub.withValues(alpha: 0.4),
      shadowColor: count > 0
          ? _accentGreen.withValues(alpha: 0.3)
          : null,
      borderColor: count > 0 ? null : _border,
    );
  }

  Widget _bigButton({
    required VoidCallback? onTap,
    required LinearGradient? gradient,
    required IconData icon,
    required String label,
    Color textColor = Colors.white,
    Color? shadowColor,
    Color? borderColor,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: gradient,
          color: gradient == null
              ? (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)
              : null,
          border: borderColor != null ? Border.all(color: borderColor) : null,
          boxShadow: shadowColor != null
              ? [
            BoxShadow(
                color: shadowColor,
                blurRadius: 14,
                offset: const Offset(0, 4))
          ]
              : null,
        ),
        child: isLoading
            ? Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: _accentGreen,
              strokeWidth: 2.5,
            ),
          ),
        )
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 0.6,
            ),
          ),
        ]),
      ),
    );
  }
}
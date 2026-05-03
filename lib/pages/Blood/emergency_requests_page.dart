import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../SettingsPage/settings_constants.dart';
import 'donation_history_page.dart';

class EmergencyRequestsPage extends StatefulWidget {
  const EmergencyRequestsPage({super.key});

  @override
  State<EmergencyRequestsPage> createState() => _EmergencyRequestsPageState();
}

class _EmergencyRequestsPageState extends State<EmergencyRequestsPage>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _myRequests    = [];
  List<Map<String, dynamic>> _otherRequests = [];

  bool     _loading      = true;
  String?  _errorMessage;
  String?  _currentUserId;
  final Set<String> _submittingIds = {};

  late final String _channelName;
  late RealtimeChannel _channel;

  late AnimationController _pulseController;
  late AnimationController _staggerController;

  bool  get _isDark    => SC.isDark;
  Color get _bgColor   => _isDark ? const Color(0xFF060810) : const Color(0xFFF0F4FF);
  Color get _cardColor => _isDark ? const Color(0xFF0D1B2A) : Colors.white;
  Color get _textColor => _isDark ? Colors.white : const Color(0xFF1A2332);
  Color get _subColor  => _isDark ? const Color(0xFFB0BEC5) : const Color(0xFF4A5568);
  Color get _border    => (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.07);

  @override
  void initState() {
    super.initState();
    _channelName = 'emergency_requests_${DateTime.now().millisecondsSinceEpoch}';
    _currentUserId = supabase.auth.currentUser?.id;

    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _staggerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));

    _fetchRequests();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    supabase.removeChannel(_channel);
    _pulseController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

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
    setState(() { _loading = true; _errorMessage = null; });
    try {
      final currentUid = _currentUserId ?? '';

      final data = await supabase
          .from('emergency_blood_requests')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false)  // ← newest first
          .range(0, 49);

      final all = List<Map<String, dynamic>>.from(data);

      // Client-side sort নিশ্চিত করতে — created_at descending
      all.sort((a, b) {
        final aTime = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(0);
        final bTime = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(0);
        return bTime.compareTo(aTime);
      });

      if (!mounted) return;
      setState(() {
        _myRequests    = all.where((r) => r['requester_user_id'] == currentUid).toList();
        _otherRequests = all.where((r) => r['requester_user_id'] != currentUid).toList();
        _loading       = false;
      });
      _staggerController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading      = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _markAsDonated(Map<String, dynamic> req) async {
    if (_currentUserId == null) {
      SC.toast(context, SC.tr('loginRequired'), const Color(0xFFFF2244));
      return;
    }
    final reqId     = req['id'].toString();
    final donatedBy = List<String>.from(req['donated_by'] ?? []);
    if (donatedBy.contains(_currentUserId)) {
      SC.toast(context, SC.tr('alreadyDonated'), const Color(0xFFFFAB40));
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() => _submittingIds.add(reqId));

    try {
      final newDonors = [...donatedBy, _currentUserId!];

      await supabase.from('emergency_blood_requests').update({
        'donated_by':     newDonors,
        'donation_count': newDonors.length,
      }).eq('id', req['id']);

      await supabase.from('donations').upsert({
        'request_id': req['id'],
        'donor_id':   _currentUserId,
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
            'donated_by':     newDonors,
            'donation_count': newDonors.length,
          };
        }
        _submittingIds.remove(reqId);
      });
      SC.toast(context, SC.tr('donatedSuccess'), const Color(0xFF00E676));
    } catch (e) {
      if (!mounted) return;
      setState(() => _submittingIds.remove(reqId));
      final isAlreadyDonated = e.toString().contains('donations_unique') ||
          e.toString().contains('unique') ||
          e.toString().contains('23505');
      SC.toast(
        context,
        isAlreadyDonated ? SC.tr('alreadyDonated') : SC.tr('submitFailed'),
        isAlreadyDonated ? const Color(0xFFFFAB40) : const Color(0xFFFF2244),
      );
    }
  }

  bool _hasDonated(Map<String, dynamic> req) {
    if (_currentUserId == null) return false;
    return List<String>.from(req['donated_by'] ?? []).contains(_currentUserId);
  }

  Color _bloodGroupColor(String? g) {
    const map = {
      'A+': Color(0xFFFF4B6E), 'A-': Color(0xFFFF6B8A),
      'B+': Color(0xFFFF7043), 'B-': Color(0xFFFFAB40),
      'O+': Color(0xFF00E5FF), 'O-': Color(0xFF69F0AE),
      'AB+': Color(0xFFE040FB), 'AB-': Color(0xFF7C4DFF),
    };
    return map[g] ?? const Color(0xFFFF4B6E);
  }

  String _timeAgo(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inSeconds < 60)  return SC.tr('justNow');
    if (diff.inMinutes < 60) return '${diff.inMinutes}${SC.tr('minutesAgo')}';
    if (diff.inHours < 24)   return '${diff.inHours}${SC.tr('hoursAgo')}';
    return '${diff.inDays}${SC.tr('daysAgo')}';
  }

  Future<void> _callDonor(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (context, __, ___) => _buildScaffold(),
      ),
    );
  }

  Widget _buildScaffold() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _bgColor,
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(),
        body: Stack(children: [
          _buildBackground(),
          SafeArea(
            child: _loading
                ? _buildLoader()
                : _errorMessage != null
                ? _buildError()
                : (_myRequests.isEmpty && _otherRequests.isEmpty)
                ? _buildEmpty()
                : _buildList(),
          ),
        ]),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
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
            color: (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
            shape: BoxShape.circle,
            border: Border.all(color: _border),
          ),
          child: Icon(Icons.arrow_back_ios_new, color: _textColor, size: 15),
        ),
      ),
      title: Row(mainAxisSize: MainAxisSize.min, children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (_, __) => Container(
            width: 28, height: 28,
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
                color: Color(0xFFFF2244), size: 15),
          ),
        ),
        const SizedBox(width: 8),
        Text(SC.tr('emergencyRequests'),
            style: TextStyle(
                color: _textColor,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5)),
      ]),
      centerTitle: true,
      actions: [
        GestureDetector(
          onTap: _fetchRequests,
          child: Container(
            margin: const EdgeInsets.only(right: 14),
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
              border: Border.all(color: _border),
            ),
            child: Icon(Icons.refresh_rounded, color: _textColor, size: 17),
          ),
        ),
      ],
    );
  }

  Widget _buildBackground() {
    if (!_isDark) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFFF0F4FF), Color(0xFFE8EFFF),
              Color(0xFFEFF6FF), Color(0xFFF5F8FF)],
          ),
        ),
      );
    }
    return Stack(children: [
      Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4), radius: 1.5,
            colors: [Color(0xFF1A0510), Color(0xFF060810), Color(0xFF030508)],
          ),
        ),
      ),
      Positioned(
        top: 60, left: -100,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (_, __) => Container(
            width: 320, height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFFFF2244)
                    .withValues(alpha: 0.07 + _pulseController.value * 0.03),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 100, right: -80,
        child: Container(
          width: 200, height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              const Color(0xFFFF7043).withValues(alpha: 0.05),
              Colors.transparent,
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _buildLoader() => Center(
    child: AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.scale(
            scale: 1.0 + _pulseController.value * 0.15,
            child: Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF2244).withValues(alpha: 0.1),
                border: Border.all(
                    color: const Color(0xFFFF2244)
                        .withValues(alpha: 0.4 + _pulseController.value * 0.3)),
              ),
              child: const Icon(Icons.bloodtype_rounded,
                  color: Color(0xFFFF2244), size: 30),
            ),
          ),
          const SizedBox(height: 16),
          Text(SC.tr('loading'),
              style: TextStyle(
                  color: _subColor.withValues(alpha: 0.6), fontSize: 13)),
        ],
      ),
    ),
  );

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFF2244).withValues(alpha: 0.08),
            border: Border.all(
                color: const Color(0xFFFF2244).withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.wifi_off_rounded,
              color: Color(0xFFFF2244), size: 32),
        ),
        const SizedBox(height: 16),
        Text(SC.tr('submitFailed'),
            style: TextStyle(color: _textColor,
                fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _fetchRequests,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                  colors: [Color(0xFFFF1744), Color(0xFFFF6B8A)]),
            ),
            child: Text(SC.tr('retry'),
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        ),
      ]),
    ),
  );

  Widget _buildEmpty() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF00E676).withValues(alpha: 0.08),
          border: Border.all(
              color: const Color(0xFF00E676).withValues(alpha: 0.25)),
        ),
        child: const Icon(Icons.check_circle_outline,
            color: Color(0xFF00E676), size: 36),
      ),
      const SizedBox(height: 16),
      Text(SC.tr('noActiveRequests'),
          style: TextStyle(color: _textColor,
              fontSize: 17, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Text(SC.tr('allResolved'),
          style: TextStyle(
              color: _subColor.withValues(alpha: 0.45), fontSize: 12)),
    ]),
  );

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _fetchRequests,
      color: const Color(0xFFFF2244),
      backgroundColor: _cardColor,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        physics: const BouncingScrollPhysics(),
        children: [
          if (_myRequests.isNotEmpty) ...[
            _sectionHeader(
              icon: Icons.person_pin_circle_rounded,
              label: SC.tr('myRequests'),
              color: const Color(0xFFFF2244),
            ),
            ..._myRequests.map((req) => _buildRequestCard(req, isOwn: true)),
            const SizedBox(height: 8),
          ],
          if (_otherRequests.isNotEmpty) ...[
            _sectionHeader(
              icon: Icons.people_alt_rounded,
              label: SC.tr('emergencyRequests'),
              color: const Color(0xFF00E676),
            ),
            ..._otherRequests.asMap().entries.map((entry) {
              final index = entry.key;
              final req   = entry.value;
              final count = _otherRequests.length;
              final delay = count <= 1 ? 0.0 : index / (count - 1);
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
                      offset: Offset(0, 18 * (1 - anim.value)), child: child),
                ),
                child: _buildRequestCard(req, isOwn: false),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Row(children: [
        Container(
          width: 3, height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: color.withValues(alpha: 0.7), size: 14),
        const SizedBox(width: 6),
        Text(label.toUpperCase(),
            style: TextStyle(
                color: _subColor.withValues(alpha: 0.55),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2)),
      ]),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req, {required bool isOwn}) {
    final bloodGroup    = req['blood_group'] as String?;
    final color         = _bloodGroupColor(bloodGroup);
    final name          = req['requester_name'] ?? 'Anonymous';
    final phone         = req['phone'] ?? '';
    final hospital      = req['hospital'] ?? '';
    final address       = req['address'] ?? '';
    final units         = req['units_needed'] ?? 1;
    final notes         = req['notes'] ?? '';
    final time          = _timeAgo(req['created_at']);
    final donationCount = int.tryParse(
        (req['donation_count'] ?? 0).toString()) ?? 0;
    final hasDonated    = _hasDonated(req);
    final reqId         = req['id'].toString();
    final isSubmitting  = _submittingIds.contains(reqId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _cardColor,
        border: Border.all(
          color: isOwn
              ? const Color(0xFFFF2244).withValues(alpha: 0.35)
              : hasDonated
              ? const Color(0xFF00E676).withValues(alpha: 0.4)
              : color.withValues(alpha: 0.22),
          width: 1.5,
        ),
        boxShadow: [BoxShadow(
          color: (isOwn
              ? const Color(0xFFFF2244)
              : hasDonated ? const Color(0xFF00E676) : color)
              .withValues(alpha: _isDark ? 0.1 : 0.06),
          blurRadius: 16, offset: const Offset(0, 4),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Top accent strip
        Container(
          height: 3,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            gradient: LinearGradient(
              colors: isOwn
                  ? [const Color(0xFFFF1744), const Color(0xFFFF6B8A)]
                  : hasDonated
                  ? [const Color(0xFF00C853), const Color(0xFF69F0AE)]
                  : [color, color.withValues(alpha: 0.4)],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header row
            Row(children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  color: color.withValues(alpha: 0.1),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: Text(bloodGroup ?? '?',
                      style: TextStyle(
                          color: color,
                          fontSize: bloodGroup != null && bloodGroup.length > 2
                              ? 11 : 15,
                          fontWeight: FontWeight.w900,
                          height: 1)),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text(name,
                          style: TextStyle(color: _textColor,
                              fontSize: 14, fontWeight: FontWeight.w800),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    if (isOwn)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: const Color(0xFFFF2244).withValues(alpha: 0.1),
                          border: Border.all(
                              color: const Color(0xFFFF2244).withValues(alpha: 0.3)),
                        ),
                        child: const Text('আমার',
                            style: TextStyle(color: Color(0xFFFF2244),
                                fontSize: 9, fontWeight: FontWeight.w800)),
                      ),
                  ]),
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(Icons.access_time_rounded, size: 11,
                        color: _subColor.withValues(alpha: 0.4)),
                    const SizedBox(width: 3),
                    Text(time,
                        style: TextStyle(
                            color: _subColor.withValues(alpha: 0.4), fontSize: 11)),
                    if (hospital.isNotEmpty) ...[
                      Text('  ·  ',
                          style: TextStyle(
                              color: _subColor.withValues(alpha: 0.25), fontSize: 11)),
                      Expanded(
                        child: Text(hospital,
                            style: TextStyle(
                                color: _subColor.withValues(alpha: 0.5), fontSize: 11),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ]),
                ]),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: color.withValues(alpha: 0.1),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Column(children: [
                  Text('$units',
                      style: TextStyle(color: color, fontSize: 16,
                          fontWeight: FontWeight.w900, height: 1)),
                  Text(SC.tr('units'),
                      style: TextStyle(color: color.withValues(alpha: 0.7),
                          fontSize: 9, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),

            // Info chips
            if (address.isNotEmpty || notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: [
                if (address.isNotEmpty)
                  _infoChip(Icons.location_on_rounded, address, color),
                if (notes.isNotEmpty)
                  _infoChip(Icons.notes_rounded, notes, color),
              ]),
            ],

            // Donors strip
            if (donationCount > 0) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            DonationHistoryPage(requestId: req['id']))),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFF00E676).withValues(alpha: 0.07),
                    border: Border.all(
                        color: const Color(0xFF00E676).withValues(alpha: 0.25)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.favorite_rounded,
                        color: Color(0xFF00E676), size: 13),
                    const SizedBox(width: 6),
                    Text('$donationCount ${SC.tr('donorCount')}',
                        style: const TextStyle(color: Color(0xFF00E676),
                            fontSize: 11, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text(SC.tr('viewDonors'),
                        style: TextStyle(
                            color: const Color(0xFF00E676).withValues(alpha: 0.6),
                            fontSize: 10, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 3),
                    Icon(Icons.chevron_right_rounded,
                        color: const Color(0xFF00E676).withValues(alpha: 0.6),
                        size: 14),
                  ]),
                ),
              ),
            ],

            const SizedBox(height: 12),
            Divider(color: _border, height: 1),
            const SizedBox(height: 12),

            // Action buttons
            if (isOwn)
              _buildOwnerActions(req, donationCount)
            else
              Row(children: [
                if (phone.isNotEmpty) ...[
                  Expanded(
                    child: _actionButton(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _callDonor(phone);
                      },
                      gradient: LinearGradient(
                          colors: [color, color.withValues(alpha: 0.7)]),
                      icon: Icons.phone_rounded,
                      label: SC.tr('callNowToDonate'),
                      textColor: Colors.white,
                      shadowColor: color.withValues(alpha: 0.35),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: hasDonated
                      ? _actionButton(
                    onTap: null,
                    gradient: const LinearGradient(colors: [
                      Color(0xFF00C853), Color(0xFF69F0AE)]),
                    icon: Icons.check_circle_rounded,
                    label: SC.tr('donatedBadge'),
                    textColor: Colors.white,
                    shadowColor:
                    const Color(0xFF00E676).withValues(alpha: 0.35),
                  )
                      : _actionButton(
                    onTap: isSubmitting ? null : () => _markAsDonated(req),
                    gradient: null,
                    icon: Icons.volunteer_activism_rounded,
                    label: SC.tr('iDonated'),
                    textColor: _subColor.withValues(alpha: 0.55),
                    borderColor: _border,
                    isLoading: isSubmitting,
                  ),
                ),
              ]),
          ]),
        ),
      ]),
    );
  }

  Widget _buildOwnerActions(Map<String, dynamic> req, int donationCount) {
    return Row(children: [
      Expanded(
        child: _actionButton(
          onTap: donationCount > 0
              ? () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      DonationHistoryPage(requestId: req['id'])))
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
              : _subColor.withValues(alpha: 0.4),
          shadowColor: donationCount > 0
              ? const Color(0xFF00E676).withValues(alpha: 0.3)
              : null,
          borderColor: donationCount > 0 ? null : _border,
        ),
      ),
    ]);
  }

  Widget _infoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.06),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color.withValues(alpha: 0.6)),
        const SizedBox(width: 5),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: Text(text,
              style: TextStyle(color: _subColor.withValues(alpha: 0.7),
                  fontSize: 11, height: 1.3),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }

  Widget _actionButton({
    required VoidCallback? onTap,
    required LinearGradient? gradient,
    required IconData icon,
    required String label,
    required Color textColor,
    Color? shadowColor,
    Color? borderColor,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: gradient,
          color: gradient == null
              ? (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)
              : null,
          border: borderColor != null ? Border.all(color: borderColor) : null,
          boxShadow: shadowColor != null
              ? [BoxShadow(
              color: shadowColor,
              blurRadius: 12,
              offset: const Offset(0, 3))]
              : null,
        ),
        child: isLoading
            ? const Center(
          child: SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(
                  color: Color(0xFF00E676), strokeWidth: 2)),
        )
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: textColor, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.6)),
        ]),
      ),
    );
  }
}
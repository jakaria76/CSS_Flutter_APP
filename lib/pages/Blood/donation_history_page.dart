import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../SettingsPage/settings_constants.dart';

class DonationHistoryPage extends StatefulWidget {
  final dynamic requestId;
  const DonationHistoryPage({super.key, required this.requestId});

  @override
  State<DonationHistoryPage> createState() => _DonationHistoryPageState();
}

class _DonationHistoryPageState extends State<DonationHistoryPage>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _donors  = [];
  Map<String, dynamic>?      _request;
  bool                       _loading = true;
  String?                    _error;

  late AnimationController _pulseController;
  late AnimationController _staggerController;

  bool  get _isDark    => SC.isDark;
  Color get _bgColor   => _isDark ? const Color(0xFF060810) : const Color(0xFFF0F4FF);
  Color get _cardColor => _isDark ? const Color(0xFF0F1E2E) : Colors.white;
  Color get _textColor => _isDark ? Colors.white : const Color(0xFF1A2332);
  Color get _subColor  => _isDark ? Colors.white : const Color(0xFF4A5568);
  Color get _border    => (_isDark ? Colors.white : Colors.black)
      .withValues(alpha: 0.08);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _staggerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _fetchData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });

    try {
      // ── ১. Request details ──────────────────────────────────────
      final reqData = await supabase
          .from('emergency_blood_requests')
          .select()
          .eq('id', widget.requestId)
          .single();

      // ── ২. donations table থেকে এই request-এর সব record ─────────
      final donationsRaw = await supabase
          .from('donations')
          .select('donor_id, donated_at')
          .eq('request_id', widget.requestId)
          .order('donated_at', ascending: false);

      final donationsList = List<Map<String, dynamic>>.from(donationsRaw);
      List<Map<String, dynamic>> enriched = [];

      if (donationsList.isNotEmpty) {
        final donorIds = donationsList
            .map((d) => d['donor_id']?.toString())
            .whereType<String>()
            .toSet()
            .toList();

        if (donorIds.isNotEmpty) {
          final profilesRaw = await supabase
              .from('profiles')
              .select('id, full_name, blood_group, avatar_url')
              .inFilter('id', donorIds);

          final profileMap = <String, Map<String, dynamic>>{
            for (final p in List<Map<String, dynamic>>.from(profilesRaw))
              p['id'].toString(): p
          };

          for (final d in donationsList) {
            final pid     = d['donor_id']?.toString() ?? '';
            final profile = profileMap[pid] ?? {};
            enriched.add({
              'donor_id':    pid,
              'donated_at':  d['donated_at'],
              'full_name':   profile['full_name'] ?? 'Anonymous',
              'blood_group': profile['blood_group'],
              'avatar_url':  profile['avatar_url'],
            });
          }
        }
      }

      // ── ৩. donation_count mismatch হলে background-এ fix ──────────
      final actualCount = enriched.length;
      final storedCount = int.tryParse(
          (reqData['donation_count'] ?? 0).toString()) ?? 0;

      if (actualCount != storedCount) {
        supabase.from('emergency_blood_requests').update({
          'donation_count': actualCount,
        }).eq('id', widget.requestId).then((_) {
          debugPrint('✅ donation_count synced: $storedCount → $actualCount');
        }).catchError((e) {
          debugPrint('⚠️ donation_count sync failed: $e');
        });
      }

      if (!mounted) return;
      setState(() {
        _request = {
          ...Map<String, dynamic>.from(reqData),
          'donation_count': actualCount,
        };
        _donors  = enriched;
        _loading = false;
      });
      _staggerController.forward();
    } catch (e) {
      debugPrint('❌ DonationHistoryPage fetch error: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error   = e.toString();
      });
    }
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

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
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
    return Scaffold(
      backgroundColor: _bgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: _isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (_isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.07),
              shape: BoxShape.circle,
              border: Border.all(color: _border),
            ),
            child: Icon(Icons.arrow_back_ios_new,
                color: _textColor, size: 16),
          ),
        ),
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.favorite, color: Color(0xFF00E676), size: 18),
          const SizedBox(width: 8),
          Text(SC.tr('donationHistory'),
              style: TextStyle(color: _textColor, fontSize: 13,
                  fontWeight: FontWeight.w900, letterSpacing: 2)),
        ]),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: _fetchData,
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (_isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.06),
                border: Border.all(color: _border),
              ),
              child: Icon(Icons.refresh_rounded, color: _textColor, size: 17),
            ),
          ),
        ],
      ),
      body: Stack(children: [
        _buildBackground(),
        SafeArea(
          child: _loading
              ? _buildLoader()
              : _error != null
              ? _buildErrorView()
              : _buildContent(),
        ),
      ]),
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
            colors: [Color(0xFF051A10), Color(0xFF060810), Color(0xFF030508)],
          ),
        ),
      ),
      Positioned(
        top: 60, right: -80,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (_, __) => Container(
            width: 260, height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF00E676)
                    .withValues(alpha: 0.07 + _pulseController.value * 0.04),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildLoader() => Center(
    child: AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) => Transform.scale(
        scale: 1.0 + _pulseController.value * 0.2,
        child: const Icon(Icons.favorite,
            color: Color(0xFF00E676), size: 48),
      ),
    ),
  );

  Widget _buildErrorView() => Center(
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
          onTap: _fetchData,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                  colors: [Color(0xFF00C853), Color(0xFF69F0AE)]),
            ),
            child: Text(SC.tr('retry'),
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        ),
      ]),
    ),
  );

  Widget _buildContent() {
    final reqBloodGroup = _request?['blood_group'] as String?;
    final reqColor      = _bloodGroupColor(reqBloodGroup);
    final reqName       = _request?['requester_name'] as String? ?? '';
    final reqHospital   = _request?['hospital'] as String? ?? '';
    final donationCount = (_request?['donation_count'] as int?) ?? _donors.length;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Request summary card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: _cardColor,
                border: Border.all(
                    color: reqColor.withValues(alpha: 0.35), width: 1.5),
                boxShadow: [BoxShadow(
                    color: reqColor.withValues(alpha: _isDark ? 0.15 : 0.08),
                    blurRadius: 20, offset: const Offset(0, 6))],
              ),
              child: Row(children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: reqColor.withValues(alpha: 0.12),
                    border: Border.all(
                        color: reqColor.withValues(alpha: 0.6), width: 2),
                  ),
                  child: Center(
                    child: Text(reqBloodGroup ?? '?',
                        style: TextStyle(
                            color: reqColor,
                            fontSize: reqBloodGroup != null &&
                                reqBloodGroup.length > 2 ? 12 : 18,
                            fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reqName,
                            style: TextStyle(color: _textColor,
                                fontSize: 15, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(reqHospital,
                            style: TextStyle(
                                color: _subColor.withValues(alpha: 0.5),
                                fontSize: 12)),
                      ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF00E676).withValues(alpha: 0.1),
                    border: Border.all(
                        color: const Color(0xFF00E676).withValues(alpha: 0.4)),
                  ),
                  child: Column(children: [
                    Text('$donationCount',
                        style: const TextStyle(
                            color: Color(0xFF00E676), fontSize: 22,
                            fontWeight: FontWeight.w900, height: 1)),
                    Text(SC.tr('donorCount'),
                        style: TextStyle(
                            color: const Color(0xFF00E676).withValues(alpha: 0.7),
                            fontSize: 9, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
            ),
          ),
        ),

        // Section label
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
            child: Row(children: [
              Container(
                width: 3, height: 14,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E676), Color(0xFF00BCD4)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(SC.tr('donationHistory').toUpperCase(),
                  style: TextStyle(
                      color: _subColor.withValues(alpha: 0.5),
                      fontSize: 10, fontWeight: FontWeight.w800,
                      letterSpacing: 2)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF00E676).withValues(alpha: 0.08),
                  border: Border.all(
                      color: const Color(0xFF00E676).withValues(alpha: 0.25)),
                ),
                child: Text('${_donors.length} জন',
                    style: const TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ),

        // Donors list
        _donors.isEmpty
            ? SliverToBoxAdapter(child: _buildNoDonors())
            : SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                // ✅ FIX: Division by zero — single donor হলে delay 0
                final delay = _donors.length <= 1
                    ? 0.0
                    : index / (_donors.length - 1);
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
                        offset: Offset(0, 16 * (1 - anim.value)),
                        child: child),
                  ),
                  child: _buildDonorCard(_donors[index], index + 1),
                );
              },
              childCount: _donors.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoDonors() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _subColor.withValues(alpha: 0.06),
            border: Border.all(color: _border),
          ),
          child: Icon(Icons.volunteer_activism,
              color: _subColor.withValues(alpha: 0.25), size: 36),
        ),
        const SizedBox(height: 18),
        Text(SC.tr('noDonations'),
            style: TextStyle(color: _textColor, fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('এখনো কেউ donate করেনি',
            style: TextStyle(
                color: _subColor.withValues(alpha: 0.4), fontSize: 12)),
      ]),
    );
  }

  Widget _buildDonorCard(Map<String, dynamic> donor, int rank) {
    final name       = (donor['full_name'] as String?) ?? 'Anonymous';
    final bloodGroup = donor['blood_group'] as String?;
    final donatedAt  = _formatDate(donor['donated_at'] as String?);
    final color      = _bloodGroupColor(bloodGroup);
    final initials   = name.trim().isNotEmpty
        ? name.trim()[0].toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: _cardColor,
        border: Border.all(
            color: const Color(0xFF00E676).withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: _isDark ? 0.2 : 0.05),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Stack(children: [
          Container(
            width: 48, height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF00C853), Color(0xFF69F0AE)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(initials,
                  style: const TextStyle(color: Colors.white,
                      fontSize: 20, fontWeight: FontWeight.w900)),
            ),
          ),
          if (rank <= 3)
            Positioned(
              right: 0, bottom: 0,
              child: Container(
                width: 18, height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: rank == 1
                      ? const Color(0xFFFFD700)
                      : rank == 2
                      ? const Color(0xFFC0C0C0)
                      : const Color(0xFFCD7F32),
                  border: Border.all(color: _cardColor, width: 1.5),
                ),
                child: Center(
                  child: Text('$rank',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 8, fontWeight: FontWeight.w900)),
                ),
              ),
            ),
        ]),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(color: _textColor,
                        fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.access_time, size: 12,
                      color: _subColor.withValues(alpha: 0.35)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(donatedAt,
                        style: TextStyle(
                            color: _subColor.withValues(alpha: 0.4),
                            fontSize: 11),
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
              ]),
        ),
        if (bloodGroup != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: color.withValues(alpha: 0.12),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Text(bloodGroup,
                style: TextStyle(color: color, fontSize: 13,
                    fontWeight: FontWeight.w900)),
          ),
      ]),
    );
  }
}
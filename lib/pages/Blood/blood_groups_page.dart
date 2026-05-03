import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../SettingsPage/settings_constants.dart';
import 'find_donors_map_page.dart';
import 'emergency_blood_request_page.dart';
import 'emergency_requests_page.dart';

class BloodGroupsPage extends StatefulWidget {
  const BloodGroupsPage({super.key});

  @override
  State<BloodGroupsPage> createState() => _BloodGroupsPageState();
}

class _BloodGroupsPageState extends State<BloodGroupsPage>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  bool _loading = true;

  late AnimationController _heartbeatController;
  late AnimationController _staggerController;
  late AnimationController _rotateController;
  late AnimationController _pulseController;

  final List<Map<String, dynamic>> bloodGroups = [
    {'group': 'A+',  'color': Color(0xFFFF4B6E), 'gradient': [Color(0xFFFF4B6E), Color(0xFFFF1744)], 'rare': false},
    {'group': 'A-',  'color': Color(0xFFFF6B8A), 'gradient': [Color(0xFFFF6B8A), Color(0xFFFF4081)], 'rare': true},
    {'group': 'B+',  'color': Color(0xFFFF7043), 'gradient': [Color(0xFFFF7043), Color(0xFFFF3D00)], 'rare': false},
    {'group': 'B-',  'color': Color(0xFFFFAB40), 'gradient': [Color(0xFFFFAB40), Color(0xFFFF6D00)], 'rare': true},
    {'group': 'O+',  'color': Color(0xFF00E5FF), 'gradient': [Color(0xFF00E5FF), Color(0xFF0091EA)], 'rare': false},
    {'group': 'O-',  'color': Color(0xFF69F0AE), 'gradient': [Color(0xFF69F0AE), Color(0xFF00C853)], 'rare': true},
    {'group': 'AB+', 'color': Color(0xFFE040FB), 'gradient': [Color(0xFFE040FB), Color(0xFFAA00FF)], 'rare': false},
    {'group': 'AB-', 'color': Color(0xFF7C4DFF), 'gradient': [Color(0xFF7C4DFF), Color(0xFF6200EA)], 'rare': true},
  ];

  Map<String, Map<String, int>> stats = {};

  @override
  void initState() {
    super.initState();
    _heartbeatController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _staggerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _rotateController = AnimationController(
        vsync: this, duration: const Duration(seconds: 18))
      ..repeat();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _fetchStats();
  }

  @override
  void dispose() {
    _heartbeatController.dispose();
    _staggerController.dispose();
    _rotateController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchStats() async {
    // UI-te loader dekhano
    setState(() => _loading = true);

    try {
      // ✅ Merge Logic: Filtered data fetch kora
      final data = await supabase
          .from('profiles')
          .select('blood_group, donation_eligibility')
          .eq('visibility', 'public')      // Private users বাদ
          .eq('account_status', 'active'); // Inactive accounts বাদ

      // Initial map toiri kora
      Map<String, Map<String, int>> temp = {};
      for (var g in bloodGroups) {
        temp[g['group']] = {'total': 0, 'ready': 0};
      }

      // ✅ Data processing: Ekbarei counting kora
      for (var u in data) {
        final String? g = u['blood_group'];
        final String eligibility = (u['donation_eligibility'] ?? '').toString().toLowerCase();

        if (g != null && temp.containsKey(g)) {
          // Total count barano
          temp[g]!['total'] = (temp[g]!['total'] ?? 0) + 1;

          // Ready status-er count barano
          if (eligibility == 'eligible' || eligibility == 'ready') {
            temp[g]!['ready'] = (temp[g]!['ready'] ?? 0) + 1;
          }
        }
      }

      // ✅ State update (Context safe check soho)
      if (mounted) {
        setState(() {
          stats = temp;
          _loading = false;
        });
        // Card animation start kora
        _staggerController.forward(from: 0);
      }
    } catch (e) {
      debugPrint("Fetch Stats Error: $e");
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  bool  get _isDark       => SC.isDark;
  Color get _bgColor      => _isDark ? const Color(0xFF060810) : const Color(0xFFF0F4FF);
  Color get _cardColor    => _isDark ? const Color(0xFF0F1E2E) : Colors.white;
  Color get _textColor    => _isDark ? Colors.white : const Color(0xFF1A2332);
  Color get _subTextColor => _isDark ? Colors.white : const Color(0xFF4A5568);

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
        title: _buildAppBarTitle(),
        centerTitle: true,
      ),
      body: Stack(children: [
        _buildBackground(),
        SafeArea(child: _loading ? _buildLoader() : _buildContent()),
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
            colors: [Color(0xFF1A0520), Color(0xFF060810), Color(0xFF030508)],
          ),
        ),
      ),
      Positioned(
        top: -120, right: -120,
        child: AnimatedBuilder(
          animation: _rotateController,
          builder: (_, __) => Transform.rotate(
            angle: _rotateController.value * 2 * math.pi,
            child: Container(
              width: 500, height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFFFF2244).withValues(alpha: 0.07),
                    width: 1.5),
              ),
            ),
          ),
        ),
      ),
      Positioned(
        top: 60, left: -80,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (_, __) => Container(
            width: 280, height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFFFF2244)
                    .withValues(alpha: 0.08 + _pulseController.value * 0.04),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 150, right: -60,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (_, __) => Container(
            width: 220, height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF7C4DFF)
                    .withValues(alpha: 0.07 + _pulseController.value * 0.03),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildAppBarTitle() {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      AnimatedBuilder(
        animation: _heartbeatController,
        builder: (_, __) => Transform.scale(
          scale: 1.0 + _heartbeatController.value * 0.22,
          child: const Icon(Icons.favorite, color: Color(0xFFFF4B6E), size: 20),
        ),
      ),
      const SizedBox(width: 10),
      Text(SC.tr('cssBloodFinder'),
          style: TextStyle(color: _textColor,
              fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2)),
    ]);
  }

  Widget _buildLoader() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedBuilder(
          animation: _heartbeatController,
          builder: (_, __) => Transform.scale(
            scale: 1.0 + _heartbeatController.value * 0.28,
            child: Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFFFF2244).withValues(alpha: 0.2),
                  const Color(0xFFFF2244).withValues(alpha: 0.05),
                ]),
                border: Border.all(
                    color: const Color(0xFFFF2244).withValues(alpha: 0.5),
                    width: 2),
              ),
              child: const Icon(Icons.favorite, color: Color(0xFFFF2244), size: 40),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(SC.tr('loadingDonors'),
            style: TextStyle(color: _subTextColor, fontSize: 15,
                fontWeight: FontWeight.w600, letterSpacing: 1.5)),
      ]),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _fetchStats,
      color: const Color(0xFFFF2244),
      backgroundColor: _cardColor,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeroSection()),
          SliverToBoxAdapter(child: _buildStatsBanner()),
          SliverToBoxAdapter(child: _buildEmergencyBanner()),
          SliverToBoxAdapter(child: _buildSeeRequestsBanner()), // ← নতুন
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
              child: Row(children: [
                Container(
                  width: 3, height: 16,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF2244), Color(0xFF7C4DFF)],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(SC.tr('selectBloodGroup'),
                    style: TextStyle(
                        color: _subTextColor.withValues(alpha: 0.7),
                        fontSize: 11, fontWeight: FontWeight.w700,
                        letterSpacing: 2)),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 14,
                mainAxisSpacing: 14, childAspectRatio: 0.82,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildGroupCard(index),
                childCount: bloodGroups.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(colors: [
              const Color(0xFFFF2244).withValues(alpha: 0.15),
              const Color(0xFF7C4DFF).withValues(alpha: 0.1),
            ]),
            border: Border.all(color: const Color(0xFFFF2244).withValues(alpha: 0.4)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            AnimatedBuilder(
              animation: _heartbeatController,
              builder: (_, __) => Container(
                width: 7, height: 7,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF2244).withValues(
                      alpha: 0.6 + _heartbeatController.value * 0.4),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(SC.tr('liveDonorNetwork'),
                style: TextStyle(color: _textColor, fontSize: 10,
                    fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          ]),
        ),
        const SizedBox(height: 18),
        RichText(
          text: TextSpan(children: [
            TextSpan(
              text: '${SC.tr('find')}\n',
              style: TextStyle(fontSize: 50, fontWeight: FontWeight.w900,
                  color: _textColor, height: 1.0),
            ),
            TextSpan(
              text: '${SC.tr('blood')} ',
              style: const TextStyle(fontSize: 50, fontWeight: FontWeight.w900,
                  color: Color(0xFFFF2244), height: 1.0),
            ),
            TextSpan(
              text: SC.tr('donors'),
              style: TextStyle(fontSize: 50, fontWeight: FontWeight.w900,
                  color: _textColor, height: 1.0),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Text(SC.tr('connectInstantly'),
            style: TextStyle(color: _subTextColor.withValues(alpha: 0.55),
                fontSize: 14, height: 1.5)),
        const SizedBox(height: 28),
      ]),
    );
  }

  Widget _buildStatsBanner() {
    int totalDonors = 0, readyDonors = 0;
    stats.forEach((_, v) {
      totalDonors += v['total'] ?? 0;
      readyDonors += v['ready'] ?? 0;
    });
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: _cardColor,
          border: Border.all(
              color: (_isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.08)),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: _isDark ? 0.3 : 0.07),
              blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          _statItem(totalDonors.toString(), SC.tr('totalDonors'),
              Icons.people_alt_outlined, const Color(0xFF64B5F6)),
          _verticalDivider(),
          _statItem(readyDonors.toString(), SC.tr('readyNow'),
              Icons.volunteer_activism_outlined, const Color(0xFF69F0AE)),
          _verticalDivider(),
          _statItem('8', SC.tr('bloodTypes'),
              Icons.bloodtype_outlined, const Color(0xFFFF6B8A)),
        ]),
      ),
    );
  }

  Widget _verticalDivider() => Container(
    width: 1, height: 44,
    color: (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
  );

  Widget _statItem(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Column(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.12),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(color: _subTextColor.withValues(alpha: 0.5),
                fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      ]),
    );
  }

  Widget _buildEmergencyBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.heavyImpact();
          Navigator.push(context, MaterialPageRoute(
              builder: (_) => const EmergencyBloodRequestPage()));
        },
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (_, __) => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: _cardColor,
              border: Border.all(
                color: const Color(0xFFFF2244)
                    .withValues(alpha: 0.5 + _pulseController.value * 0.2),
                width: 1.5,
              ),
              boxShadow: [BoxShadow(
                color: const Color(0xFFFF2244)
                    .withValues(alpha: 0.15 + _pulseController.value * 0.08),
                blurRadius: 24, offset: const Offset(0, 6),
              )],
            ),
            child: Row(children: [
              Transform.scale(
                scale: 1.0 + _pulseController.value * 0.12,
                child: Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFF2244).withValues(alpha: 0.12),
                    border: Border.all(
                        color: const Color(0xFFFF2244).withValues(alpha: 0.6),
                        width: 2),
                  ),
                  child: const Icon(Icons.emergency,
                      color: Color(0xFFFF2244), size: 26),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(SC.tr('cantFindBlood'),
                          style: TextStyle(color: _textColor, fontSize: 16,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(SC.tr('emergencyDesc'),
                          style: TextStyle(
                              color: _subTextColor.withValues(alpha: 0.55),
                              fontSize: 12, height: 1.4)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                              colors: [Color(0xFFFF1744), Color(0xFFFF6B8A)]),
                        ),
                        child: Text(SC.tr('requestNow'),
                            style: const TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 11, letterSpacing: 1)),
                      ),
                    ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── নতুন banner ────────────────────────────────────────────────────────────
  Widget _buildSeeRequestsBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.push(context, MaterialPageRoute(
              builder: (_) => const EmergencyRequestsPage()));
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: _cardColor,
            border: Border.all(
                color: const Color(0xFF00E676).withValues(alpha: 0.4),
                width: 1.5),
            boxShadow: [BoxShadow(
                color: const Color(0xFF00E676)
                    .withValues(alpha: _isDark ? 0.12 : 0.07),
                blurRadius: 20, offset: const Offset(0, 6))],
          ),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00E676).withValues(alpha: 0.12),
                border: Border.all(
                    color: const Color(0xFF00E676).withValues(alpha: 0.5),
                    width: 2),
              ),
              child: const Icon(Icons.volunteer_activism,
                  color: Color(0xFF00E676), size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(SC.tr('seeRequests'),
                        style: TextStyle(color: _textColor, fontSize: 15,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(SC.tr('seeRequestsDesc'),
                        style: TextStyle(
                            color: _subTextColor.withValues(alpha: 0.55),
                            fontSize: 12, height: 1.4)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(
                            colors: [Color(0xFF00C853), Color(0xFF69F0AE)]),
                      ),
                      child: Text(SC.tr('respondNow'),
                          style: const TextStyle(color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 11, letterSpacing: 1)),
                    ),
                  ]),
            ),
            Icon(Icons.arrow_forward_ios,
                color: const Color(0xFF00E676).withValues(alpha: 0.5),
                size: 16),
          ]),
        ),
      ),
    );
  }

  Widget _buildGroupCard(int index) {
    final group         = bloodGroups[index];
    final g             = group['group'] as String;
    final color         = group['color'] as Color;
    final gradientColors = group['gradient'] as List<Color>;
    final isRare        = group['rare'] as bool;
    final s             = stats[g] ?? {'total': 0, 'ready': 0};
    final total         = s['total']!;
    final ready         = s['ready']!;
    final pct           = total > 0 ? ready / total : 0.0;
    final delay         = index / bloodGroups.length;
    final cardAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: Interval(delay * 0.5,
            (delay * 0.5 + 0.5).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic),
      ),
    );
    return AnimatedBuilder(
      animation: cardAnimation,
      builder: (_, __) => Opacity(
        opacity: cardAnimation.value,
        child: Transform.translate(
          offset: Offset(0, 30 * (1 - cardAnimation.value)),
          child: _CardContent(
            group: g, color: color, gradientColors: gradientColors,
            isRare: isRare, total: total, ready: ready, pct: pct,
            isDark: _isDark, cardColor: _cardColor,
            textColor: _textColor, subTextColor: _subTextColor,
            rareLabel: SC.tr('rare'),
            donorsLabel: SC.tr('donorsLabel'),
            readyLabel: SC.tr('readyLabel'),
            findDonorsLabel: SC.tr('findDonors'),
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => FindDonorsMapPage(bloodGroup: g)));
            },
          ),
        ),
      ),
    );
  }
}

// ── Card Widget (অপরিবর্তিত) ──────────────────────────────────────────────────
class _CardContent extends StatefulWidget {
  final String group;
  final Color color;
  final List<Color> gradientColors;
  final bool isRare;
  final int total, ready;
  final double pct;
  final bool isDark;
  final Color cardColor, textColor, subTextColor;
  final String rareLabel, donorsLabel, readyLabel, findDonorsLabel;
  final VoidCallback onTap;

  const _CardContent({
    required this.group, required this.color, required this.gradientColors,
    required this.isRare, required this.total, required this.ready,
    required this.pct, required this.isDark, required this.cardColor,
    required this.textColor, required this.subTextColor,
    required this.rareLabel, required this.donorsLabel,
    required this.readyLabel, required this.findDonorsLabel,
    required this.onTap,
  });

  @override
  State<_CardContent> createState() => _CardContentState();
}

class _CardContentState extends State<_CardContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.94).animate(
        CurvedAnimation(parent: _pressController, curve: Curves.easeOut));
  }

  @override
  void dispose() { _pressController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) { _pressController.reverse(); widget.onTap(); },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: widget.cardColor,
            border: Border.all(
                color: widget.color.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [BoxShadow(
                color: widget.color
                    .withValues(alpha: widget.isDark ? 0.2 : 0.12),
                blurRadius: 28, offset: const Offset(0, 8), spreadRadius: -2)],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 54, height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color.withValues(alpha: 0.12),
                      border: Border.all(
                          color: widget.color.withValues(alpha: 0.6), width: 2),
                    ),
                    child: Center(
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                            colors: widget.gradientColors).createShader(bounds),
                        child: Text(widget.group,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: widget.group.length > 2 ? 13 : 17,
                                fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (widget.isRare)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                        border: Border.all(
                            color: const Color(0xFFFFB300).withValues(alpha: 0.5)),
                      ),
                      child: Text(widget.rareLabel,
                          style: const TextStyle(color: Color(0xFFFFB300),
                              fontSize: 8, fontWeight: FontWeight.w900,
                              letterSpacing: 1)),
                    ),
                ]),
                const Spacer(),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min, children: [
                        Text(widget.total.toString(),
                            style: TextStyle(color: widget.textColor, fontSize: 26,
                                fontWeight: FontWeight.w900, height: 1)),
                        const SizedBox(height: 2),
                        Text(widget.donorsLabel,
                            style: TextStyle(
                                color: widget.subTextColor.withValues(alpha: 0.4),
                                fontSize: 11)),
                      ]),
                  const Spacer(),
                  Column(crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min, children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                              colors: widget.gradientColors).createShader(bounds),
                          child: Text(widget.ready.toString(),
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 20, fontWeight: FontWeight.w900,
                                  height: 1)),
                        ),
                        const SizedBox(height: 2),
                        Text(widget.readyLabel,
                            style: TextStyle(
                                color: widget.subTextColor.withValues(alpha: 0.4),
                                fontSize: 11)),
                      ]),
                ]),
                const SizedBox(height: 10),
                Stack(children: [
                  Container(
                      height: 4,
                      decoration: BoxDecoration(
                          color: (widget.isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4))),
                  FractionallySizedBox(
                    widthFactor: widget.pct.clamp(0.0, 1.0),
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: widget.gradientColors),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: widget.gradientColors,
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, color: Colors.white, size: 13),
                      const SizedBox(width: 5),
                      Text(widget.findDonorsLabel,
                          style: const TextStyle(color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 11, letterSpacing: 1)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
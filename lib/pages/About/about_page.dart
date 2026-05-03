import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:css/models/about_models.dart';
import 'package:css/services/about_service.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> with TickerProviderStateMixin {
  final AboutService _aboutService = AboutService();

  bool    _loading = true;
  String? _error;

  AboutOverview?     overview;
  List<MissionPoint> missions   = [];
  List<Activity>     activities = [];
  List<StoryEvent>   story      = [];
  ContactInfo?       contact;

  bool _showAllMission = false;
  bool _showAllStory   = false;

  late AnimationController _entryCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _shimmerCtrl;

  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _floatAnim;
  late Animation<double> _shimmerAnim;

  // ── Light mode fixed colors ──────────────────────────────────────────────
  static const _lightBg      = Color(0xFFF0F4FF);
  static const _lightCard    = Colors.white;
  static const _lightText    = Color(0xFF1A2332);
  static const _lightSubText = Color(0xFF4A5568);

  // ── Dark mode fixed colors ───────────────────────────────────────────────
  static const _gold   = Color(0xFFD4AF37);
  static const _goldLt = Color(0xFFF0D060);
  static const _accent = Color(0xFF4F8EF7);

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat();

    _fadeAnim   = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim  = Tween<double>(begin: 40, end: 0).animate(
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _floatAnim  = Tween<double>(begin: -6, end: 6).animate(
        CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _shimmerAnim = Tween<double>(begin: -2, end: 2).animate(
        CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

    _loadData();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _floatCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _aboutService.getAllAboutData();
      if (!mounted) return;
      setState(() {
        overview   = data['overview']       as AboutOverview?;
        missions   = (data['missionPoints'] as List<MissionPoint>?) ?? [];
        activities = (data['activities']    as List<Activity>?)     ?? [];
        story      = (data['story']         as List<StoryEvent>?)   ?? [];
        contact    = data['contact']        as ContactInfo?;
        _loading   = false;
      });
      _entryCtrl.forward();
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ════════════════════════════════════════════════════════════
  // BUILD — ValueListenableBuilder wrap
  // ════════════════════════════════════════════════════════════
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
    final isDark = SC.isDark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? SC.bgStart : _lightBg,
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(isDark),
        body: _loading
            ? _buildLoader(isDark)
            : _error != null
            ? _buildError(isDark)
            : _buildBody(isDark),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(bool isDark) {
    final textColor   = isDark ? Colors.white   : const Color(0xFF1A2332);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);
    final refreshBg = isDark
        ? _gold.withValues(alpha: 0.1)
        : _gold.withValues(alpha: 0.12);
    final refreshBorder = isDark
        ? _gold.withValues(alpha: 0.35)
        : _gold.withValues(alpha: 0.5);

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                color: textColor, size: 16),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14, top: 10, bottom: 10),
          child: GestureDetector(
            onTap: _loadData,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: refreshBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: refreshBorder),
              ),
              child: Row(children: [
                const Icon(Icons.refresh_rounded, color: _gold, size: 14),
                const SizedBox(width: 5),
                Text(SC.tr('aboutRefresh'),
                    style: const TextStyle(
                        color: _gold, fontSize: 11,
                        fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────
  Widget _buildBody(bool isDark) {
    return Stack(children: [
      _buildBackground(isDark),
      FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(child: _buildHeroSection(isDark)),
            if (overview != null)
              SliverToBoxAdapter(child: _buildAboutSection(isDark)),
            if (activities.isNotEmpty)
              SliverToBoxAdapter(child: _buildActivitiesSection(isDark)),
            if (missions.isNotEmpty)
              SliverToBoxAdapter(child: _buildMissionSection(isDark)),
            if (story.isNotEmpty)
              SliverToBoxAdapter(child: _buildTimelineSection(isDark)),
            if (contact != null)
              SliverToBoxAdapter(child: _buildContactSection(isDark)),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    ]);
  }

  // ── Background ────────────────────────────────────────────────────────────
  Widget _buildBackground(bool isDark) {
    return Positioned.fill(
      child: Stack(children: [
        Container(decoration: BoxDecoration(gradient: SC.currentGradient)),
        Positioned(
          top: -120, left: -60,
          child: Container(
            width: 380, height: 380,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _gold.withValues(alpha: isDark ? 0.09 : 0.06),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: 100, right: -80,
          child: Container(
            width: 300, height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _accent.withValues(alpha: isDark ? 0.07 : 0.05),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        Positioned.fill(child: CustomPaint(painter: _GridPainter(isDark))),
      ]),
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────────────
  Widget _buildHeroSection(bool isDark) {
    final textColor = isDark ? Colors.white : _lightText;
    final top = MediaQuery.of(context).padding.top + kToolbarHeight;

    return AnimatedBuilder(
      animation: _entryCtrl,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _slideAnim.value),
        child: Container(
          padding: EdgeInsets.fromLTRB(28, top + 32, 28, 56),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedBuilder(
                animation: _floatCtrl,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, _floatAnim.value * 0.4),
                  child: _buildEstPill(isDark),
                ),
              ),
              const SizedBox(height: 32),
              _buildHeroTitle(isDark),
              const SizedBox(height: 24),
              _buildTagline(isDark),
              const SizedBox(height: 40),
              _buildStatRow(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstPill(bool isDark) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      color: _gold.withValues(alpha: isDark ? 0.08 : 0.10),
      border: Border.all(color: _gold.withValues(alpha: 0.4)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 6, height: 6,
          decoration: const BoxDecoration(color: _gold, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(
        '${SC.tr('aboutEstablished')} ${overview?.foundedYear ?? 2015}',
        style: const TextStyle(
          color: _gold, fontSize: 10,
          fontWeight: FontWeight.w800, letterSpacing: 2.0,
        ),
      ),
    ]),
  );

  Widget _buildHeroTitle(bool isDark) {
    final textColor = isDark ? Colors.white : _lightText;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AnimatedBuilder(
        animation: _shimmerCtrl,
        builder: (_, __) => ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(_shimmerAnim.value - 1, 0),
            end: Alignment(_shimmerAnim.value + 1, 0),
            colors: [textColor, _goldLt, textColor, _goldLt, textColor],
            stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
          ).createShader(bounds),
          child: Text('CONSCIOUS',
              style: TextStyle(
                color: textColor, fontSize: 52,
                fontWeight: FontWeight.w900, height: 0.95, letterSpacing: -1.5,
              )),
        ),
      ),
      Text('STUDENT',
          style: TextStyle(
            color: textColor, fontSize: 52,
            fontWeight: FontWeight.w900, height: 0.95, letterSpacing: -1.5,
          )),
      Stack(children: [
        Text('SOCIETY',
            style: TextStyle(
              fontSize: 52, fontWeight: FontWeight.w900,
              height: 0.95, letterSpacing: -1.5,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.5
                ..color = _gold.withValues(alpha: 0.6),
            )),
        Text('SOCIETY',
            style: TextStyle(
              color: _gold.withValues(alpha: isDark ? 0.15 : 0.12),
              fontSize: 52, fontWeight: FontWeight.w900,
              height: 0.95, letterSpacing: -1.5,
            )),
      ]),
    ]);
  }

  Widget _buildTagline(bool isDark) {
    final subTextColor = isDark ? _lightSubText.withValues(alpha: 0.85) : _lightSubText;
    return Row(children: [
      Container(width: 32, height: 1.5, color: _gold.withValues(alpha: 0.6)),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          SC.tr('aboutTagline'),
          style: TextStyle(
            color: subTextColor, fontSize: 13,
            fontWeight: FontWeight.w500, letterSpacing: 0.5,
          ),
        ),
      ),
    ]);
  }

  Widget _buildStatRow(bool isDark) {
    final cardColor = isDark ? SC.cardBg : _lightCard;
    final textColor = isDark ? Colors.white : _lightText;
    final subColor  = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : _lightSubText.withValues(alpha: 0.7);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.08);

    final year        = overview?.foundedYear ?? 2022;
    final yearsActive = DateTime.now().year - year;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _statChip('${yearsActive}+', SC.tr('aboutYearsActive'),
            cardColor, textColor, subColor, borderColor),
        const SizedBox(width: 12),
        _statChip(
            overview?.focus?.split(',').length.toString() ?? '1',
            SC.tr('aboutFocusAreas'),
            cardColor, textColor, subColor, borderColor),
        const SizedBox(width: 12),
        _statChip('${missions.length}', SC.tr('aboutMissions'),
            cardColor, textColor, subColor, borderColor),
      ],
    );
  }

  Widget _statChip(String value, String label,
      Color cardColor, Color textColor, Color subColor, Color borderColor) =>
      Expanded(
        child: Container(
          constraints: const BoxConstraints(minHeight: 70),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                child: Text(value,
                    style: TextStyle(
                      color: textColor, fontSize: 22,
                      fontWeight: FontWeight.w800, height: 1,
                    )),
              ),
              const SizedBox(height: 6),
              Text(label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    color: subColor, fontSize: 9,
                    fontWeight: FontWeight.w600, letterSpacing: 0.8,
                  )),
            ],
          ),
        ),
      );

  // ── About Section ─────────────────────────────────────────────────────────
  Widget _buildAboutSection(bool isDark) {
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : _lightSubText;

    return _sectionWrapper(
      isDark: isDark,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel(SC.tr('aboutWhoWeAre'),
            Icons.info_outline_rounded, _accent),
        const SizedBox(height: 20),
        if ((overview?.focus ?? '').isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: _accent.withValues(alpha: 0.08),
              border: Border.all(color: _accent.withValues(alpha: 0.25)),
            ),
            child: Text(overview!.focus,
                style: const TextStyle(
                  color: _accent, fontSize: 13,
                  fontWeight: FontWeight.w700, letterSpacing: 0.3,
                )),
          ),
          const SizedBox(height: 18),
        ],
        Text(
          overview?.description ?? '',
          style: TextStyle(
            color: subColor, fontSize: 14, height: 1.85, letterSpacing: 0.2,
          ),
        ),
      ]),
    );
  }

  // ── Activities Section ────────────────────────────────────────────────────
  Widget _buildActivitiesSection(bool isDark) {
    final cardColor   = isDark ? SC.cardBg : _lightCard;
    final textColor   = isDark ? Colors.white : _lightText;
    final borderColor = isDark
        ? _gold.withValues(alpha: 0.15)
        : _gold.withValues(alpha: 0.2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: _sectionLabel(SC.tr('aboutWhatWeDo'),
              Icons.bolt_rounded, _gold),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const BouncingScrollPhysics(),
            itemCount: activities.length,
            itemBuilder: (_, i) {
              final icons = [
                Icons.groups_rounded, Icons.campaign_rounded,
                Icons.science_outlined, Icons.volunteer_activism_rounded,
                Icons.emoji_events_rounded, Icons.menu_book_rounded,
              ];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12, bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: _gold.withValues(alpha: isDark ? 0.06 : 0.04),
                      blurRadius: 12, offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: _gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(icons[i % icons.length],
                          color: _gold, size: 16),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: Text(activities[i].title,
                          style: TextStyle(
                            color: textColor, fontSize: 12,
                            fontWeight: FontWeight.w600, height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Mission Section ───────────────────────────────────────────────────────
  Widget _buildMissionSection(bool isDark) {
    const missionColor = Color(0xFF9B6DFF);
    final list = _showAllMission ? missions : missions.take(4).toList();
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : _lightSubText.withValues(alpha: 0.6);

    return _sectionWrapper(
      isDark: isDark,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel(SC.tr('aboutMissionVision'),
            Icons.rocket_launch_rounded, missionColor),
        const SizedBox(height: 20),
        ...list.asMap().entries.map((e) =>
            _missionRow(e.key, e.value.text, isDark)),
        if (missions.length > 4) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _showAllMission = !_showAllMission),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(children: [
                Text(
                  _showAllMission
                      ? SC.tr('aboutShowLess')
                      : '${SC.tr('aboutViewAllGoals')} ${missions.length}',
                  style: TextStyle(
                    color: subColor, fontSize: 13, fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  _showAllMission
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: subColor, size: 18,
                ),
              ]),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _missionRow(int index, String text, bool isDark) {
    const accent = Color(0xFF9B6DFF);
    final textColor = isDark
        ? Colors.white.withValues(alpha: 0.8)
        : _lightText.withValues(alpha: 0.85);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accent.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Text('${index + 1}',
                style: const TextStyle(
                  color: accent, fontSize: 11, fontWeight: FontWeight.w800,
                )),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(text,
                style: TextStyle(
                  color: textColor, fontSize: 14,
                  height: 1.6, fontWeight: FontWeight.w400,
                )),
          ),
        ),
      ]),
    );
  }

  // ── Timeline Section ──────────────────────────────────────────────────────
  Widget _buildTimelineSection(bool isDark) {
    final list = _showAllStory ? story : story.take(4).toList();
    final goldSub = _gold.withValues(alpha: 0.7);

    return _sectionWrapper(
      isDark: isDark,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel(SC.tr('aboutOurJourney'),
            Icons.timeline_rounded, _gold),
        const SizedBox(height: 24),
        ...list.asMap().entries.map((e) =>
            _timelineRow(e.value, e.key == list.length - 1, isDark)),
        if (story.length > 4) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => setState(() => _showAllStory = !_showAllStory),
            child: Padding(
              padding: const EdgeInsets.only(left: 48, top: 4),
              child: Row(children: [
                Text(
                  _showAllStory
                      ? SC.tr('aboutCollapse')
                      : SC.tr('aboutSeeFullHistory'),
                  style: TextStyle(
                    color: goldSub, fontSize: 13, fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 5),
                Icon(
                  _showAllStory
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: goldSub, size: 18,
                ),
              ]),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _timelineRow(StoryEvent e, bool isLast, bool isDark) {
    final textColor = isDark
        ? Colors.white.withValues(alpha: 0.75)
        : _lightSubText;
    final slateColor = isDark
        ? const Color(0xFF8896B3).withValues(alpha: 0.5)
        : _lightSubText.withValues(alpha: 0.5);

    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 56,
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const SizedBox(height: 2),
            Text(DateFormat('dd').format(e.eventDate),
                style: const TextStyle(
                  color: _gold, fontSize: 18,
                  fontWeight: FontWeight.w800, height: 1,
                )),
            Text(
              DateFormat('MMM').format(e.eventDate).toUpperCase(),
              style: TextStyle(
                color: _gold.withValues(alpha: 0.6), fontSize: 9,
                fontWeight: FontWeight.w700, letterSpacing: 1.2,
              ),
            ),
            Text(
              DateFormat('yyyy').format(e.eventDate),
              style: TextStyle(
                color: slateColor, fontSize: 9, fontWeight: FontWeight.w600,
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _gold,
                boxShadow: [
                  BoxShadow(color: _gold.withValues(alpha: 0.5),
                      blurRadius: 6, spreadRadius: 1),
                ],
              ),
            ),
            if (!isLast)
              Expanded(
                child: Container(
                  width: 1.5,
                  color: _gold.withValues(alpha: 0.15),
                ),
              ),
          ]),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: Text(e.description,
                style: TextStyle(
                  color: textColor, fontSize: 14, height: 1.6,
                )),
          ),
        ),
      ]),
    );
  }

  // ── Contact Section ───────────────────────────────────────────────────────
  Widget _buildContactSection(bool isDark) {
    return _sectionWrapper(
      isDark: isDark,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel(SC.tr('aboutGetInTouch'),
            Icons.alternate_email_rounded, const Color(0xFF34D399)),
        const SizedBox(height: 20),
        _contactRow(Icons.email_outlined,
            contact!.email, SC.tr('aboutEmail'), isDark),
        _contactRow(Icons.phone_outlined,
            contact!.phone, SC.tr('aboutPhone'), isDark),
        _contactRow(Icons.location_on_outlined,
            contact!.address, SC.tr('aboutAddress'), isDark),
        if ((contact!.facebook ?? '').isNotEmpty)
          _contactRow(Icons.link_rounded,
              contact!.facebook!, SC.tr('aboutFacebook'), isDark),
        if ((contact!.website ?? '').isNotEmpty)
          _contactRow(Icons.language_rounded,
              contact!.website!, SC.tr('aboutWebsite'), isDark),
      ]),
    );
  }

  Widget _contactRow(IconData icon, String value, String label,
      bool isDark) {
    final textColor    = isDark ? Colors.white : _lightText;
    final subColor     = isDark
        ? const Color(0xFF8896B3).withValues(alpha: 0.55)
        : _lightSubText.withValues(alpha: 0.6);
    final iconBgColor  = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);
    final iconBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.07);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: iconBorderColor),
          ),
          child: Icon(icon,
              color: isDark ? const Color(0xFF8896B3) : _lightSubText,
              size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                  color: subColor, fontSize: 9,
                  fontWeight: FontWeight.w700, letterSpacing: 1.2,
                )),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                  color: textColor, fontSize: 14, fontWeight: FontWeight.w500,
                )),
          ]),
        ),
      ]),
    );
  }

  // ── Section Wrapper ───────────────────────────────────────────────────────
  Widget _sectionWrapper({required bool isDark, required Widget child}) {
    final cardColor   = isDark ? SC.currentCardBg : _lightCard;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.07);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.034)
                  : _lightCard.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, IconData icon, Color color) =>
      Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 11),
        Text(text,
            style: TextStyle(
              color: color, fontSize: 11,
              fontWeight: FontWeight.w800, letterSpacing: 2.0,
            )),
      ]);

  // ── Loader ────────────────────────────────────────────────────────────────
  Widget _buildLoader(bool isDark) {
    final bgColor  = isDark ? SC.bgStart : _lightBg;
    final subColor = isDark
        ? const Color(0xFF8896B3).withValues(alpha: 0.5)
        : _lightSubText.withValues(alpha: 0.5);

    return Container(
      color: bgColor,
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(
            width: 48, height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: _gold.withValues(alpha: 0.8),
              backgroundColor: _gold.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(height: 20),
          Text(SC.tr('aboutLoading'),
              style: TextStyle(
                color: subColor, fontSize: 13,
                fontWeight: FontWeight.w500, letterSpacing: 0.5,
              )),
        ]),
      ),
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────
  Widget _buildError(bool isDark) {
    final bgColor = isDark ? SC.bgStart : _lightBg;

    return Container(
      color: bgColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.error_outline_rounded,
                color: Colors.redAccent.withValues(alpha: 0.7), size: 48),
            const SizedBox(height: 18),
            Text(_error ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.redAccent.withValues(alpha: 0.8),
                    fontSize: 14, height: 1.5)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _loadData,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: _gold.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(SC.tr('aboutTryAgain'),
                    style: const TextStyle(
                        color: _gold, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Grid Painter ──────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  final bool isDark;
  const _GridPainter(this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.022)
          : Colors.black.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;
    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.isDark != isDark;
}
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:css/pages/About/person_details_page.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';
import 'previous_president_model.dart';

// ════════════════════════════════════════════════════════════════
// DESIGN TOKENS
// ════════════════════════════════════════════════════════════════
class _P {
  static const bg0         = Color(0xFF06090F);
  static const bg1         = Color(0xFF0B1019);
  static const purple      = Color(0xFF9B59B6);
  static const purpleLight = Color(0xFFBB7FD4);
  static const purpleDim   = Color(0xFF6C3483);
  static const surface     = Color(0xFF0F1620);
  static const surface2    = Color(0xFF141C28);
  static const border      = Color(0xFF1A2535);
  static const text        = Color(0xFFEAEEF5);
  static const textMuted   = Color(0xFF4A5870);
  static const textDim     = Color(0xFF8899AA);
  static const accent      = Color(0xFF2A9D8F);
  static const rankGold    = Color(0xFFFFD700);
  static const rankSilver  = Color(0xFFB0BEC5);
  static const rankBronze  = Color(0xFFCD7F32);

  static const lBg         = Color(0xFFF0F4FF);
  static const lSurface    = Colors.white;
  static const lSurface2   = Color(0xFFF5F7FA);
  static const lBorder     = Color(0xFFE2E8F0);
  static const lText       = Color(0xFF1A2332);
  static const lTextMuted  = Color(0xFF64748B);
  static const lTextDim    = Color(0xFF94A3B8);
}

// ════════════════════════════════════════════════════════════════
// POSITION ORDER
// ════════════════════════════════════════════════════════════════
const List<String> _kPositionOrder = [
  "সভাপতি","সহ-সভাপতি","সাধারণ সম্পাদক","যুগ্ম-সাধারণ সম্পাদক",
  "সাংগঠনিক সম্পাদক","সহ-সাংগঠনিক সম্পাদক","দপ্তর সম্পাদক",
  "সিনিয়র সহ-দপ্তর সম্পাদক","সহ-দপ্তর সম্পাদক","অর্থ সম্পাদক",
  "সিনিয়র অর্থ সম্পাদক","সহ-অর্থ সম্পাদক","শিক্ষা সম্পাদক",
  "সহ-শিক্ষা সম্পাদক","পরিকল্পনা সম্পাদক","সহ-পরিকল্পনা সম্পাদক",
  "মানব সম্পদ সম্পাদক","সহ-মানব সম্পদ সম্পাদক","পরিবেশ সম্পাদক",
  "সহ-পরিবেশ সম্পাদক","ধর্ম সম্পাদক","সহ-ধর্ম সম্পাদক",
  "প্রচার সম্পাদক","সহ-প্রচার সম্পাদক","ব্র্যান্ড ও গণমাধ্যম সম্পাদক",
  "সিনিয়র ব্র্যান্ড ও গণমাধ্যম সম্পাদক","গ্রাফিক্স ডিজাইনার",
  "সহ-গ্রাফিক্স ডিজাইনার","ক্রিয়া সম্পাদক","সহ-ক্রিয়া সম্পাদক",
  "পাঠাগার সম্পাদক","সহ-পাঠাগার সম্পাদক","সাংস্কৃতিক সম্পাদক",
  "সহ-সাংস্কৃতিক সম্পাদক","বিজ্ঞান ও প্রযুক্তি সম্পাদক",
  "সহ-বিজ্ঞান ও প্রযুক্তি সম্পাদক","সমাজ কল্যাণ সম্পাদক",
  "সহ-সমাজ কল্যাণ সম্পাদক","স্বাস্থ্য সম্পাদক","সহ-স্বাস্থ্য সম্পাদক",
  "নারী সম্পাদক","সহ-নারী সম্পাদক","আন্তর্জাতিক সম্পাদক",
  "সহ-আন্তর্জাতিক সম্পাদক","ছাত্র কল্যাণ সম্পাদক",
  "সহ-ছাত্র কল্যাণ সম্পাদক","সাহিত্য সম্পাদক","সহ-সাহিত্য সম্পাদক",
  "তথ্য ও গবেষণা সম্পাদক","সহ-তথ্য ও গবেষণা সম্পাদক",
  "ত্রাণ ও দুর্যোগ সম্পাদক","সিনিয়র ত্রাণ ও দুর্যোগ সম্পাদক",
  "সহ-ত্রাণ ও দুর্যোগ সম্পাদক","কার্যকরী সদস্য",
];

int _positionRank(String? pos) {
  if (pos == null) return 9999;
  final idx = _kPositionOrder.indexOf(pos.trim());
  return idx == -1 ? 9998 : idx;
}

// ── Category filter — language-independent ─────────────────────
enum _PresidentFilter { all, byPosition }

// ════════════════════════════════════════════════════════════════
// PAGE
// ════════════════════════════════════════════════════════════════
class PreviousPresidentPage extends StatefulWidget {
  const PreviousPresidentPage({super.key});
  @override
  State<PreviousPresidentPage> createState() => _PreviousPresidentPageState();
}

class _PreviousPresidentPageState extends State<PreviousPresidentPage>
    with TickerProviderStateMixin {

  final _searchController = TextEditingController();
  final _supabase         = Supabase.instance.client;
  final _scrollController = ScrollController();
  final _searchFocus      = FocusNode();

  // Enum tracks which filter is active; _selectedPosition stores the actual
  // position string when byPosition is chosen.
  _PresidentFilter _selectedFilter   = _PresidentFilter.all;
  String?          _selectedPosition;     // non-null only when byPosition

  List<PreviousPresident> _allPresidents      = [];
  List<PreviousPresident> _filteredPresidents = [];
  bool   _isLoading     = true;
  double _scrollOffset  = 0.0;
  bool   _searchFocused = false;

  // Position list (excluding the "all" chip)
  List<String> _positions = [];

  final Map<String, Map<String, dynamic>> _rawDataMap = {};

  late final AnimationController _heroAnim;
  late final AnimationController _pulseAnim;
  late final AnimationController _shimmerAnim;
  late final AnimationController _listAnim;
  late final Animation<double>   _heroFade;
  late final Animation<Offset>   _heroSlide;

  static const _memberType = 'previous_committee';

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _scrollController.addListener(_onScroll);
    _searchFocus.addListener(
            () => setState(() => _searchFocused = _searchFocus.hasFocus));
    _fetchPresidents();
  }

  void _initAnimations() {
    _heroAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _pulseAnim = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _shimmerAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _listAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _heroFade  = CurvedAnimation(
        parent: _heroAnim, curve: const Interval(0.0, 0.7, curve: Curves.easeOut));
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: _heroAnim,
        curve: const Interval(0.1, 0.9, curve: Curves.easeOutCubic)));
  }

  void _onScroll() {
    if (mounted) setState(() => _scrollOffset = _scrollController.offset);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _heroAnim.dispose();
    _pulseAnim.dispose();
    _shimmerAnim.dispose();
    _listAnim.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────
  Color _surface(bool isDark)     => isDark ? _P.surface    : _P.lSurface;
  Color _surface2(bool isDark)    => isDark ? _P.surface2   : _P.lSurface2;
  Color _borderC(bool isDark)     => isDark ? _P.border     : _P.lBorder;
  Color _textC(bool isDark)       => isDark ? _P.text       : _P.lText;
  Color _textMutedC(bool isDark)  => isDark ? _P.textMuted  : _P.lTextMuted;
  Color _textDimC(bool isDark)    => isDark ? _P.textDim    : _P.lTextDim;
  Color _bgColor(bool isDark)     => isDark ? _P.bg0        : _P.lBg;

  // ── Data ──────────────────────────────────────────────────────
  Future<void> _fetchPresidents() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('profiles')
          .select(
        'id, full_name, full_name_bn, profile_image_url, '
            'tenure_from, tenure_to, previous_position, previous_committee_note, '
            'short_bio, blood_group, location_dms, '
            'school_name, school_group, school_passing_year, '
            'college_name, college_group, college_passing_year, '
            'university_name, department, current_year, current_semester',
      )
          .eq('member_type', _memberType)
          .order('tenure_from', ascending: false);

      final List<PreviousPresident> presidents = [];
      _rawDataMap.clear();
      final Set<String> positionSet = {};

      for (final item in response) {
        final id = item['id'];
        if (id == null) continue;
        final idStr = id.toString();
        _rawDataMap[idStr] = Map<String, dynamic>.from(item);
        final president = PreviousPresident(
          id:               idStr,
          fullName:         item['full_name']              as String? ?? 'Unknown',
          fullNameBn:       item['full_name_bn']            as String?,
          imagePath:        item['profile_image_url']       as String?,
          tenureFrom:       item['tenure_from']             as int?,
          tenureTo:         item['tenure_to']               as int?,
          previousPosition: item['previous_position']       as String?,
          note:             item['previous_committee_note'] as String?,
        );
        presidents.add(president);
        final pos = president.previousPosition?.trim();
        if (pos != null && pos.isNotEmpty) positionSet.add(pos);
      }

      presidents.sort((a, b) {
        final ra = _positionRank(a.previousPosition);
        final rb = _positionRank(b.previousPosition);
        if (ra != rb) return ra.compareTo(rb);
        return (b.tenureFrom ?? 0).compareTo(a.tenureFrom ?? 0);
      });

      final sortedPositions = positionSet.toList()
        ..sort((a, b) => _positionRank(a).compareTo(_positionRank(b)));

      setState(() {
        _allPresidents      = presidents;
        _filteredPresidents = List.from(presidents);
        _positions          = sortedPositions;
        // Reset filter on reload
        _selectedFilter   = _PresidentFilter.all;
        _selectedPosition = null;
        _isLoading        = false;
      });
      _listAnim.forward(from: 0);
      HapticFeedback.lightImpact();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) SC.toast(context, '${SC.tr('prevLoadFail')}: $e', SC.red);
    }
  }

  void _openPersonDetails(PreviousPresident president) {
    final raw = _rawDataMap[president.id] ?? {};
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => PersonDetailsPage(
          category:           SC.tr('prevFormerCommittee'),
          heroTag:            'president_${president.id}',
          name:               president.fullName,
          role:               president.previousPosition ?? SC.tr('prevFormerMember'),
          imageUrl:           president.imagePath,
          message:            president.note,
          bio:                raw['short_bio']            as String?,
          schoolName:         raw['school_name']          as String?,
          schoolGroup:        raw['school_group']         as String?,
          schoolPassingYear:  raw['school_passing_year']  as int?,
          collegeName:        raw['college_name']         as String?,
          collegeGroup:       raw['college_group']        as String?,
          collegePassingYear: raw['college_passing_year'] as int?,
          universityName:     raw['university_name']      as String?,
          department:         raw['department']           as String?,
          currentYear:        raw['current_year']         as int?,
          currentSemester:    raw['current_semester']     as int?,
          bloodGroup:         raw['blood_group']          as String?,
          locationDms:        raw['location_dms']         as String?,
          themeColor:         _P.purple,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04), end: Offset.zero,
                ).animate(CurvedAnimation(
                    parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              ),
            ),
        transitionDuration: const Duration(milliseconds: 380),
      ),
    );
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    List<PreviousPresident> result = _allPresidents.where((p) {
      final match = q.isEmpty ||
          p.fullName.toLowerCase().contains(q) ||
          (p.fullNameBn?.toLowerCase().contains(q) ?? false) ||
          (p.previousPosition?.toLowerCase().contains(q) ?? false) ||
          p.tenureLabel.contains(q);

      final cat = switch (_selectedFilter) {
        _PresidentFilter.all        => true,
        _PresidentFilter.byPosition =>
        p.previousPosition?.trim() == _selectedPosition,
      };

      return match && cat;
    }).toList();

    result.sort((a, b) {
      final ra = _positionRank(a.previousPosition);
      final rb = _positionRank(b.previousPosition);
      if (ra != rb) return ra.compareTo(rb);
      return (b.tenureFrom ?? 0).compareTo(a.tenureFrom ?? 0);
    });

    setState(() => _filteredPresidents = result);
    _listAnim.forward(from: 0);
    HapticFeedback.selectionClick();
  }

  void _clearSearch() {
    _searchController.clear();
    _selectedFilter   = _PresidentFilter.all;
    _selectedPosition = null;
    _applyFilter();
    _searchFocus.unfocus();
  }

  Color _rankAccent(String? pos) {
    final rank = _positionRank(pos);
    if (rank == 0) return _P.rankGold;
    if (rank == 1) return const Color(0xFF00BCD4);
    if (rank == 2) return const Color(0xFF4CAF50);
    if (rank <= 5) return const Color(0xFFFF9800);
    if (rank <= 10) return const Color(0xFF03A9F4);
    return _P.purple;
  }

  // ════════════════════════════════════════════════════════════
  // BUILD
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
        backgroundColor: _bgColor(isDark),
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            _buildBackground(isDark),
            RefreshIndicator(
              onRefresh: _fetchPresidents,
              color: _P.purple,
              backgroundColor: _surface(isDark),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(
                      child: SafeArea(bottom: false, child: _buildHero(isDark))),
                  SliverToBoxAdapter(child: _buildSearchBar(isDark)),
                  SliverToBoxAdapter(child: _buildCategoryChips(isDark)),
                  if (!_isLoading)
                    SliverToBoxAdapter(child: _buildStats(isDark)),
                  if (_isLoading)
                    SliverFillRemaining(
                        hasScrollBody: false, child: _buildLoadingState(isDark)),
                  if (!_isLoading && _filteredPresidents.isNotEmpty)
                    SliverToBoxAdapter(child: _buildSectionLabel(isDark)),
                  if (!_isLoading && _filteredPresidents.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      sliver: SliverGrid(
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:   2,
                          mainAxisSpacing:  14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.58,
                        ),
                        delegate: SliverChildBuilderDelegate(
                              (context, index) => _cardWrapper(index, isDark),
                          childCount: _filteredPresidents.length,
                        ),
                      ),
                    ),
                  if (!_isLoading && _filteredPresidents.isEmpty)
                    SliverFillRemaining(
                        hasScrollBody: false, child: _buildEmpty(isDark)),
                ],
              ),
            ),
            _buildTopBar(isDark),
          ],
        ),
      ),
    );
  }

  // ── Background ────────────────────────────────────────────────
  Widget _buildBackground(bool isDark) {
    return Stack(children: [
      Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
              colors: [_P.bg0, _P.bg0, _P.bg1],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.5, 1.0])
              : LinearGradient(
              colors: [_P.lBg, _P.lBg, const Color(0xFFE8EEFF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.5, 1.0]),
        ),
      ),
      Positioned(
        top: -120, left: -80,
        child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Container(
            width: 360, height: 360,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _P.purple.withOpacity(
                    (isDark ? 0.07 : 0.05) + _pulseAnim.value * 0.04),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 200, right: -100,
        child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Container(
            width: 280, height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF00BCD4).withOpacity(
                    (isDark ? 0.04 : 0.03) + _pulseAnim.value * 0.02),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ),
      CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _DotGridPainter(isDark: isDark)),
      Positioned(
        top: 0, left: 0, right: 0,
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.transparent,
              _P.purple.withOpacity(isDark ? 0.45 : 0.25),
              Colors.transparent,
            ]),
          ),
        ),
      ),
    ]);
  }

  // ── Top Bar ───────────────────────────────────────────────────
  Widget _buildTopBar(bool isDark) {
    final collapsed = _scrollOffset > 80;
    return Positioned(
      top: 0, left: 0, right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: collapsed
              ? _bgColor(isDark).withOpacity(0.92)
              : Colors.transparent,
          border: collapsed
              ? Border(bottom: BorderSide(
              color: _borderC(isDark).withOpacity(0.8), width: 0.5))
              : const Border(),
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: collapsed
                ? ImageFilter.blur(sigmaX: 16, sigmaY: 16)
                : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  _iconBtn(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.maybePop(context),
                    isDark: isDark,
                  ),
                  const Spacer(),
                  AnimatedOpacity(
                    opacity: collapsed ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(SC.tr('prevAppBarTitle'),
                        style: const TextStyle(
                            color: _P.purple,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3)),
                  ),
                  const Spacer(),
                  _iconBtn(
                    icon: Icons.refresh_rounded,
                    onTap: _fetchPresidents,
                    color: _P.purple,
                    isDark: isDark,
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    Color? color,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: _surface(isDark),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _borderC(isDark), width: 0.5),
          ),
          child: Icon(icon, color: color ?? _textMutedC(isDark), size: 17),
        ),
      );

  // ── Hero ──────────────────────────────────────────────────────
  Widget _buildHero(bool isDark) {
    return FadeTransition(
      opacity: _heroFade,
      child: SlideTransition(
        position: _heroSlide,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 80, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _eyebrow(),
              const SizedBox(height: 16),
              _purpleTitle(),
              const SizedBox(height: 10),
              Text(
                SC.tr('prevSubtitle'),
                style: TextStyle(
                    color: _textDimC(isDark),
                    fontSize: 13, height: 1.7, letterSpacing: 0.15),
              ),
              Container(
                height: 5,
                margin: const EdgeInsets.only(top: 7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    _P.purple.withOpacity(0.4),
                    _P.purple.withOpacity(0.05),
                    Colors.transparent,
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eyebrow() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              color: _P.purple,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                color: _P.purple.withOpacity(0.35 + _pulseAnim.value * 0.3),
                blurRadius: 10,
              )],
            ),
          ),
          const SizedBox(width: 10),
          Text(SC.tr('prevHistory'),
              style: TextStyle(
                  color: _P.purple.withOpacity(0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.2)),
        ],
      ),
    );
  }

  Widget _purpleTitle() {
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (_, __) => ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: const [
            _P.purpleLight, _P.purple, _P.purpleDim, _P.purple, _P.purpleLight,
          ],
          stops: [
            0.0,
            (_shimmerAnim.value * 0.5).clamp(0.0, 0.3),
            (_shimmerAnim.value * 0.5 + 0.25).clamp(0.1, 0.6),
            (_shimmerAnim.value * 0.5 + 0.45).clamp(0.35, 0.9),
            1.0,
          ],
        ).createShader(bounds),
        child: Text(SC.tr('prevTitle'),
            style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.08,
                letterSpacing: -1.5)),
      ),
    );
  }

  // ── Search Bar ────────────────────────────────────────────────
  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _surface(isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _searchFocused
                ? _P.purple.withOpacity(0.5)
                : _borderC(isDark),
            width: _searchFocused ? 1.5 : 0.5,
          ),
          boxShadow: _searchFocused
              ? [BoxShadow(
              color: _P.purple.withOpacity(0.12),
              blurRadius: 20, offset: const Offset(0, 4))]
              : [],
        ),
        child: Row(children: [
          const SizedBox(width: 14),
          Icon(Icons.search_rounded,
              color: _searchFocused ? _P.purple : _textMutedC(isDark), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              onChanged: (_) => _applyFilter(),
              style: TextStyle(
                  color: _textC(isDark), fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: SC.tr('prevSearchHint'),
                hintStyle: TextStyle(color: _textMutedC(isDark), fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: _clearSearch,
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                width: 22, height: 22,
                decoration: BoxDecoration(
                    color: _surface2(isDark), shape: BoxShape.circle),
                child: Icon(Icons.close_rounded,
                    color: _textMutedC(isDark), size: 13),
              ),
            )
          else
            const SizedBox(width: 14),
        ]),
      ),
    );
  }

  // ── Category Chips ────────────────────────────────────────────
  Widget _buildCategoryChips(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 0, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            // "All" chip
            _chip(
              label: SC.tr('prevCatAll'),
              active: _selectedFilter == _PresidentFilter.all,
              accentColor: _P.purple,
              isDark: isDark,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedFilter   = _PresidentFilter.all;
                  _selectedPosition = null;
                });
                _applyFilter();
              },
            ),
            // Position chips
            ..._positions.map((pos) {
              final accentColor = _rankAccent(pos);
              final active = _selectedFilter == _PresidentFilter.byPosition &&
                  _selectedPosition == pos;
              return _chip(
                label: pos,
                active: active,
                accentColor: accentColor,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedFilter   = _PresidentFilter.byPosition;
                    _selectedPosition = pos;
                  });
                  _applyFilter();
                },
              );
            }),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool active,
    required Color accentColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? accentColor.withOpacity(0.15) : _surface(isDark),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: active ? accentColor : _borderC(isDark),
              width: active ? 1.2 : 0.5),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? accentColor : _textDimC(isDark),
                fontSize: 12.5,
                fontWeight: FontWeight.w700)),
      ),
    );
  }

  // ── Stats ─────────────────────────────────────────────────────
  Widget _buildStats(bool isDark) {
    final total = _allPresidents.length;
    int? earliest, latest;
    for (final p in _allPresidents) {
      if (p.tenureFrom != null) {
        if (earliest == null || p.tenureFrom! < earliest) earliest = p.tenureFrom;
      }
      if (p.tenureTo != null) {
        if (latest == null || p.tenureTo! > latest) latest = p.tenureTo;
      }
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: _surface(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderC(isDark), width: 0.5),
        ),
        child: IntrinsicHeight(
          child: Row(children: [
            _statItem(SC.tr('prevStatTotal'),  total,         Icons.history_edu_rounded,  _P.purple,               isDark),
            _vDivider(isDark),
            _statItem(SC.tr('prevStatStart'),  earliest ?? 0, Icons.access_time_rounded,  const Color(0xFF00BCD4), isDark),
            _vDivider(isDark),
            _statItem(SC.tr('prevStatLatest'), latest ?? 0,   Icons.update_rounded,       const Color(0xFF4CAF50), isDark),
          ]),
        ),
      ),
    );
  }

  Widget _statItem(String label, int count, IconData icon,
      Color color, bool isDark) =>
      Expanded(
        child: TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: count),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (_, val, __) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: color.withOpacity(0.8), size: 18),
              const SizedBox(height: 6),
              Text(val == 0 ? '—' : '$val',
                  style: TextStyle(
                      color: _textC(isDark),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5)),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      color: _textMutedC(isDark),
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
      );

  Widget _vDivider(bool isDark) => Container(
      width: 0.5,
      color: _borderC(isDark),
      margin: const EdgeInsets.symmetric(vertical: 12));

  // ── Section Label ─────────────────────────────────────────────
  Widget _buildSectionLabel(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 14),
      child: Row(children: [
        Container(
          width: 2.5, height: 14,
          decoration: BoxDecoration(
              color: _P.purple, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 10),
        Text(SC.tr('prevSectionAll'),
            style: TextStyle(
                color: _textC(isDark), fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: _P.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: _P.purple.withOpacity(0.25), width: 0.5),
          ),
          child: Text('${_filteredPresidents.length}',
              style: const TextStyle(
                  color: _P.purple, fontSize: 11, fontWeight: FontWeight.w800)),
        ),
        const Spacer(),
        Row(children: [
          Icon(Icons.format_list_numbered_rounded,
              color: _textMutedC(isDark).withOpacity(0.6), size: 12),
          const SizedBox(width: 4),
          Text(SC.tr('prevSerial'),
              style: TextStyle(
                  color: _textMutedC(isDark).withOpacity(0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }

  // ── Card Wrapper ──────────────────────────────────────────────
  Widget _cardWrapper(int index, bool isDark) {
    final president = _filteredPresidents[index];
    final accent    = _rankAccent(president.previousPosition);
    return AnimatedBuilder(
      animation: _listAnim,
      builder: (_, child) {
        final delay = (index * 0.045).clamp(0.0, 0.5);
        final t = ((_listAnim.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
        final curve = Curves.easeOutCubic.transform(t);
        return Opacity(
          opacity: curve,
          child: Transform.translate(
              offset: Offset(0, 22 * (1 - curve)), child: child),
        );
      },
      child: GestureDetector(
        onTap: () => _openPersonDetails(president),
        child: AbsorbPointer(
          absorbing: true,
          child: _PresidentGridCard(
            president:   president,
            serialIndex: index,
            accentColor: accent,
            pulseAnim:   _pulseAnim,
            isDark:      isDark,
          ),
        ),
      ),
    );
  }

  // ── Loading ───────────────────────────────────────────────────
  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => SizedBox(
            width: 40, height: 40,
            child: CircularProgressIndicator(
              color: _P.purple.withOpacity(0.4 + _pulseAnim.value * 0.4),
              strokeWidth: 2,
              backgroundColor: _P.purple.withOpacity(0.08),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(SC.tr('prevLoading'),
            style: TextStyle(
                color: _textMutedC(isDark),
                fontSize: 13,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }

  // ── Empty ─────────────────────────────────────────────────────
  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: _surface(isDark),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _borderC(isDark), width: 0.5),
            ),
            child: Icon(Icons.search_off_rounded,
                size: 32, color: _textMutedC(isDark)),
          ),
          const SizedBox(height: 18),
          Text(SC.tr('prevEmpty'),
              style: TextStyle(
                  color: _textC(isDark), fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(SC.tr('prevEmptyHint'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _textMutedC(isDark), fontSize: 13, height: 1.5)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _clearSearch,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                  color: _P.purple, borderRadius: BorderRadius.circular(10)),
              child: Text(SC.tr('prevResetFilter'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// PRESIDENT GRID CARD
// ════════════════════════════════════════════════════════════════
class _PresidentGridCard extends StatelessWidget {
  final PreviousPresident president;
  final int               serialIndex;
  final Color             accentColor;
  final Animation<double> pulseAnim;
  final bool              isDark;

  const _PresidentGridCard({
    required this.president,
    required this.serialIndex,
    required this.accentColor,
    required this.pulseAnim,
    required this.isDark,
  });

  Color get _surfaceC   => isDark ? const Color(0xFF0F1620) : Colors.white;
  Color get _surface2C  => isDark ? const Color(0xFF141C28) : const Color(0xFFF5F7FA);
  Color get _borderC    => isDark ? const Color(0xFF1A2535) : const Color(0xFFE2E8F0);
  Color get _textC      => isDark ? const Color(0xFFEAEEF5) : const Color(0xFF1A2332);
  Color get _textDimC   => isDark ? const Color(0xFF8899AA) : const Color(0xFF94A3B8);
  Color get _textMutedC => isDark ? const Color(0xFF4A5870) : const Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final p      = president;
    final rank   = _positionRank(p.previousPosition);
    final isTop3 = rank <= 2;

    return Container(
      decoration: BoxDecoration(
        color: _surfaceC,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: accentColor.withOpacity(isTop3 ? 0.35 : 0.2),
            width: isTop3 ? 1.0 : 0.5),
        boxShadow: isTop3
            ? [BoxShadow(
            color: accentColor.withOpacity(isDark ? 0.12 : 0.08),
            blurRadius: 16, offset: const Offset(0, 4))]
            : [],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        if (isTop3)
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  accentColor.withOpacity(0.6),
                  accentColor,
                  accentColor.withOpacity(0.6),
                ]),
              ),
            ),
          ),
        Positioned(
          left: 0, top: isTop3 ? 3 : 0, bottom: 0,
          child: Container(
            width: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor, accentColor.withOpacity(0.3)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(clipBehavior: Clip.none, children: [
                Hero(
                  tag: 'president_${p.id}',
                  child: Container(
                    width: 150, height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: accentColor.withOpacity(0.4), width: 1.5),
                      color: _surface2C,
                      boxShadow: [BoxShadow(
                          color: accentColor.withOpacity(0.15),
                          blurRadius: 10, offset: const Offset(0, 3))],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: p.imagePath != null && p.imagePath!.isNotEmpty
                        ? Image.network(p.imagePath!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _placeholder(accentColor))
                        : _placeholder(accentColor),
                  ),
                ),
                Positioned(
                  top: -7, left: -7,
                  child: AnimatedBuilder(
                    animation: pulseAnim,
                    builder: (_, __) => Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: _surfaceC, width: 2),
                        boxShadow: [BoxShadow(
                          color: accentColor.withOpacity(
                              0.4 + pulseAnim.value * 0.2),
                          blurRadius: 8,
                        )],
                      ),
                      child: Center(
                        child: Text('${serialIndex + 1}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: accentColor.withOpacity(0.35), width: 0.5),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_positionIcon(rank), color: accentColor, size: 9),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      p.previousPosition ?? SC.tr('prevFormerMember'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: accentColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              Text(p.fullName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: _textC,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                      height: 1.2)),
              if (p.fullNameBn != null && p.fullNameBn!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(p.fullNameBn!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: _textDimC, fontSize: 10.5)),
              ],
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: _surface2C,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _borderC, width: 0.5),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.access_time_rounded, color: _textMutedC, size: 9),
                  const SizedBox(width: 4),
                  Text(p.tenureLabel,
                      style: TextStyle(
                          color: _textDimC,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    accentColor, accentColor.withOpacity(0.8),
                  ]),
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [BoxShadow(
                      color: accentColor.withOpacity(0.25),
                      blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(SC.tr('prevProfileBtn'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 11, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 10, right: 10,
          child: AnimatedBuilder(
            animation: pulseAnim,
            builder: (_, __) => Opacity(
              opacity: 0.06 + pulseAnim.value * 0.06,
              child: Text(_positionWatermark(rank),
                  style: TextStyle(
                      color: accentColor,
                      fontSize: 6.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0)),
            ),
          ),
        ),
      ]),
    );
  }

  IconData _positionIcon(int rank) {
    if (rank == 0) return Icons.star_rounded;
    if (rank == 1) return Icons.star_half_rounded;
    if (rank == 2) return Icons.history_edu_rounded;
    return Icons.person_pin_rounded;
  }

  String _positionWatermark(int rank) {
    if (rank == 0) return 'PRESIDENT';
    if (rank == 1) return 'VP';
    if (rank == 2) return 'GEN.SEC';
    return 'MEMBER';
  }

  Widget _placeholder(Color accent) => Container(
    color: _surface2C,
    child: Center(
        child: Icon(Icons.person_rounded,
            size: 32, color: accent.withOpacity(0.25))),
  );
}

// ════════════════════════════════════════════════════════════════
// DOT GRID PAINTER
// ════════════════════════════════════════════════════════════════
class _DotGridPainter extends CustomPainter {
  final bool isDark;
  const _DotGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark
          ? const Color(0xFF1E2D3F)
          : const Color(0xFFCBD5E1))
          .withOpacity(0.5)
      ..style = PaintingStyle.fill;
    const step = 32.0;
    for (double x = step; x < size.width; x += step) {
      for (double y = step; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => old.isDark != isDark;
}
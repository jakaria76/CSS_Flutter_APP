import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:css/pages/About/person_details_page.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';
import 'advisor_model.dart';

// ── Category filter — language-independent ────────────────────
enum _AdvisorFilter { all, byOccupation }

// ════════════════════════════════════════════════════════════════
// PAGE
// ════════════════════════════════════════════════════════════════
class AdvisorPage extends StatefulWidget {
  const AdvisorPage({super.key});

  @override
  State<AdvisorPage> createState() => _AdvisorPageState();
}

class _AdvisorPageState extends State<AdvisorPage>
    with TickerProviderStateMixin {

  final _searchController = TextEditingController();
  final _supabase         = Supabase.instance.client;
  final _scrollController = ScrollController();
  final _searchFocus      = FocusNode();

  // Enum tracks which category is active; _selectedOccupation holds the
  // actual occupation string when byOccupation is chosen.
  _AdvisorFilter _selectedFilter     = _AdvisorFilter.all;
  String?        _selectedOccupation;       // non-null only when byOccupation

  List<Advisor>  _allAdvisors       = [];
  List<Advisor>  _filteredAdvisors  = [];
  List<Advisor>  _chiefAdvisors     = [];
  bool   _isLoading     = true;
  double _scrollOffset  = 0.0;
  bool   _searchFocused = false;

  // Occupation list (excluding the "all" chip)
  List<String> _occupations = [];

  final Map<String, Map<String, dynamic>> _rawDataMap = {};

  late final AnimationController _heroAnim;
  late final AnimationController _pulseAnim;
  late final AnimationController _shimmerAnim;
  late final AnimationController _listAnim;
  late final Animation<double>   _heroFade;
  late final Animation<Offset>   _heroSlide;

  static const _memberType = 'advisor';

  // ── Card accent colors ────────────────────────────────────────
  static const List<Color> _cardAccents = [
    Color(0xFF00BCD4),
    Color(0xFF4CAF50),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF03A9F4),
    Color(0xFFFF5722),
    Color(0xFF009688),
    Color(0xFF673AB7),
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _scrollController.addListener(_onScroll);
    _searchFocus.addListener(
            () => setState(() => _searchFocused = _searchFocus.hasFocus));
    _fetchAdvisors();
  }

  void _initAnimations() {
    _heroAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    _pulseAnim = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _shimmerAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _listAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _heroFade = CurvedAnimation(
        parent: _heroAnim,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut));
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
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

  // ── Data ──────────────────────────────────────────────────────
  Future<void> _fetchAdvisors() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('profiles')
          .select(
        'id, full_name, full_name_bn, profile_image_url, '
            'occupation, institution, designation, expertise, advisor_note, '
            'advisor_type, '
            'short_bio, blood_group, location_dms, '
            'school_name, school_group, school_passing_year, '
            'college_name, college_group, college_passing_year, '
            'university_name, department, current_year, current_semester, '
            'visibility', // ← যোগ করো
      )
          .eq('member_type', _memberType)
          .order('full_name', ascending: true);

      final List<Advisor> chiefs  = [];
      final List<Advisor> regular = [];
      _rawDataMap.clear();
      final Set<String> occupationSet = {};

      for (final item in response) {
        final id = item['id'];
        if (id == null) continue;
        final idStr = id.toString();
        _rawDataMap[idStr] = Map<String, dynamic>.from(item);

        final advisor = Advisor(
          id:          idStr,
          fullName:    item['full_name']        as String? ?? 'Unknown',
          fullNameBn:  item['full_name_bn']      as String?,
          imagePath:   item['profile_image_url'] as String?,
          occupation:  item['occupation']        as String?,
          institution: item['institution']       as String?,
          designation: item['designation']       as String?,
          expertise:   item['expertise']         as String?,
          note:        item['advisor_note']      as String?,
        );

        final advisorType = item['advisor_type'] as String?;
        final des = (advisor.designation ?? '').toLowerCase();
        final isChief = advisorType == 'chief_advisor' ||
            des.contains('chief') ||
            des.contains('প্রধান');

        if (isChief) {
          chiefs.add(advisor);
        } else {
          regular.add(advisor);
          final occ = advisor.occupation?.trim();
          if (occ != null && occ.isNotEmpty) occupationSet.add(occ);
        }
      }

      if (chiefs.isEmpty && regular.isNotEmpty) {
        chiefs.add(regular.removeAt(0));
      }

      final sortedOccupations = occupationSet.toList()..sort();

      setState(() {
        _chiefAdvisors    = chiefs;
        _allAdvisors      = regular;
        _filteredAdvisors = List.from(regular);
        _occupations      = sortedOccupations;
        // Reset to "all" whenever data reloads
        _selectedFilter     = _AdvisorFilter.all;
        _selectedOccupation = null;
        _isLoading          = false;
      });
      _listAnim.forward(from: 0);
      HapticFeedback.lightImpact();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) SC.toast(context, '${SC.tr('advisorLoadFail')}: $e', SC.red);
    }
  }

  // ── Navigation ─────────────────────────────────────────────────
  void _openPersonDetails(Advisor advisor, {bool isChief = false}) {
    final raw = _rawDataMap[advisor.id] ?? {};
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PersonDetailsPage(
              category: SC.tr('advisorCategory'),
              heroTag: 'advisor_${advisor.id}',
              name: advisor.fullName,
              role: advisor.designation ??
                  advisor.occupation ??
                  SC.tr('advisorOccupationDefault'),
              imageUrl: advisor.imagePath,
              message: advisor.note,
              bio: raw['short_bio'] as String?,
              schoolName: raw['school_name'] as String?,
              schoolGroup: raw['school_group'] as String?,
              schoolPassingYear: raw['school_passing_year'] as int?,
              collegeName: raw['college_name'] as String?,
              collegeGroup: raw['college_group'] as String?,
              collegePassingYear: raw['college_passing_year'] as int?,
              universityName: raw['university_name'] as String?,
              department: raw['department'] as String?,
              currentYear: raw['current_year'] as int?,
              currentSemester: raw['current_semester'] as int?,
              bloodGroup: raw['blood_group'] as String?,
              locationDms: raw['location_dms'] as String?,
              themeColor: isChief ? const Color(0xFFFFD700) : SC.amber,
              visibility: raw['visibility'] as String? ?? 'public', // ← যোগ
              isOwner: currentUserId == advisor.id,                  // ← যোগ
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
    setState(() {
      _filteredAdvisors = _allAdvisors.where((a) {
        final match = q.isEmpty ||
            a.fullName.toLowerCase().contains(q) ||
            (a.fullNameBn?.toLowerCase().contains(q) ?? false) ||
            (a.designation?.toLowerCase().contains(q) ?? false) ||
            (a.occupation?.toLowerCase().contains(q) ?? false) ||
            (a.institution?.toLowerCase().contains(q) ?? false) ||
            (a.expertise?.toLowerCase().contains(q) ?? false);

        final cat = switch (_selectedFilter) {
          _AdvisorFilter.all          => true,
          _AdvisorFilter.byOccupation =>
          a.occupation?.trim() == _selectedOccupation,
        };

        return match && cat;
      }).toList();
    });
    _listAnim.forward(from: 0);
    HapticFeedback.selectionClick();
  }

  void _clearSearch() {
    _searchController.clear();
    _selectedFilter     = _AdvisorFilter.all;
    _selectedOccupation = null;
    _applyFilter();
    _searchFocus.unfocus();
  }

  bool get _showChiefs =>
      _chiefAdvisors.isNotEmpty &&
          _selectedFilter == _AdvisorFilter.all &&
          _searchController.text.isEmpty;

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
    final isDark        = SC.isDark;
    final bgColor       = isDark ? SC.bgStart : const Color(0xFFF0F4FF);
    final textColor     = isDark ? Colors.white : const Color(0xFF1A2332);
    final subTextColor  = isDark ? Colors.white70 : const Color(0xFF4A5568);
    final borderColor   = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.08);
    final surfaceColor  = isDark ? const Color(0xFF0F1620) : Colors.white;
    final surface2Color = isDark ? const Color(0xFF141C28) : const Color(0xFFF8FAFF);

    const amber      = Color(0xFFFFB300);
    const amberLight = Color(0xFFFFD54F);
    const gold       = Color(0xFFFFD700);
    const goldDim    = Color(0xFFFFA000);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            Container(decoration: BoxDecoration(gradient: SC.currentGradient)),
            Positioned(
              top: -120, left: -80,
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Container(
                  width: 380, height: 380,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      gold.withValues(alpha: 0.06 + _pulseAnim.value * 0.03),
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
                      amber.withValues(alpha: 0.04 + _pulseAnim.value * 0.02),
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
                    gold.withValues(alpha: 0.45),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),

            RefreshIndicator(
              onRefresh: _fetchAdvisors,
              color: amber,
              backgroundColor: surfaceColor,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(
                      child: SafeArea(
                          bottom: false,
                          child: _buildHero(textColor, subTextColor, gold,
                              amberLight, amber))),
                  SliverToBoxAdapter(
                      child: _buildSearchBar(
                          surfaceColor, borderColor, textColor, amber)),
                  SliverToBoxAdapter(
                      child: _buildCategoryChips(
                          surfaceColor, borderColor, textColor, amber)),
                  if (!_isLoading)
                    SliverToBoxAdapter(
                        child: _buildStats(
                            surfaceColor, borderColor, textColor, amber, gold)),
                  if (_isLoading)
                    SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildLoadingState(amber, gold)),

                  if (!_isLoading && _showChiefs) ...[
                    SliverToBoxAdapter(
                        child: _buildChiefSectionLabel(
                            surfaceColor, borderColor, gold)),
                    SliverToBoxAdapter(
                        child: _buildChiefAdvisorsList(
                            surfaceColor, surface2Color, borderColor,
                            textColor, subTextColor, gold, goldDim,
                            amberLight, amber)),
                  ],

                  if (!_isLoading && _filteredAdvisors.isNotEmpty) ...[
                    SliverToBoxAdapter(
                        child: _buildSectionLabel(
                            surfaceColor, borderColor, textColor, amber)),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      sliver: SliverGrid(
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:   2,
                          mainAxisSpacing:  14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.60,
                        ),
                        delegate: SliverChildBuilderDelegate(
                              (context, index) => _cardWrapper(
                              index, surfaceColor, surface2Color,
                              borderColor, textColor, isDark),
                          childCount: _filteredAdvisors.length,
                        ),
                      ),
                    ),
                  ],

                  if (!_isLoading &&
                      _filteredAdvisors.isEmpty &&
                      !_showChiefs)
                    SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmpty(
                            surfaceColor, borderColor, textColor,
                            subTextColor, amber, bgColor)),

                  if (!_isLoading &&
                      _filteredAdvisors.isEmpty &&
                      _showChiefs)
                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),

            _buildTopBar(surfaceColor, borderColor, textColor, gold, amber),
          ],
        ),
      ),
    );
  }

  // ── Top Bar ───────────────────────────────────────────────────
  Widget _buildTopBar(Color surfaceColor, Color borderColor,
      Color textColor, Color gold, Color amber) {
    final collapsed = _scrollOffset > 80;
    return Positioned(
      top: 0, left: 0, right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: collapsed
              ? surfaceColor.withValues(alpha: 0.92)
              : Colors.transparent,
          border: collapsed
              ? Border(bottom: BorderSide(
              color: borderColor.withValues(alpha: 0.8), width: 0.5))
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
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor, width: 0.5),
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            color: textColor, size: 17),
                      ),
                    ),
                    const Spacer(),
                    AnimatedOpacity(
                      opacity: collapsed ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Text(SC.tr('advisorPageCollapsedTitle'),
                          style: TextStyle(
                              color: gold,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3)),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _fetchAdvisors,
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor, width: 0.5),
                        ),
                        child: Icon(Icons.refresh_rounded, color: gold, size: 17),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Hero ──────────────────────────────────────────────────────
  Widget _buildHero(Color textColor, Color subTextColor, Color gold,
      Color amberLight, Color amber) {
    return FadeTransition(
      opacity: _heroFade,
      child: SlideTransition(
        position: _heroSlide,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 80, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        color: gold,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(
                          color: gold.withValues(
                              alpha: 0.4 + _pulseAnim.value * 0.3),
                          blurRadius: 10,
                        )],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(SC.tr('advisorPageEyebrow'),
                        style: TextStyle(
                            color: gold.withValues(alpha: 0.85),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.2)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: _shimmerAnim,
                builder: (_, __) => ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [amberLight, gold, amber, gold, amberLight],
                    stops: [
                      0.0,
                      (_shimmerAnim.value * 0.5).clamp(0.0, 0.3),
                      (_shimmerAnim.value * 0.5 + 0.25).clamp(0.1, 0.6),
                      (_shimmerAnim.value * 0.5 + 0.45).clamp(0.35, 0.9),
                      1.0,
                    ],
                  ).createShader(bounds),
                  child: Text(SC.tr('advisorPageTitle'),
                      style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.08,
                          letterSpacing: -1.5)),
                ),
              ),
              const SizedBox(height: 10),
              Text(SC.tr('advisorPageSubtitle'),
                  style: TextStyle(
                      color: subTextColor,
                      fontSize: 13,
                      height: 1.7,
                      letterSpacing: 0.15)),
              Container(
                height: 1,
                margin: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    gold.withValues(alpha: 0.5),
                    amber.withValues(alpha: 0.1),
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

  // ── Search Bar ────────────────────────────────────────────────
  Widget _buildSearchBar(Color surfaceColor, Color borderColor,
      Color textColor, Color amber) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _searchFocused ? amber.withValues(alpha: 0.5) : borderColor,
            width: _searchFocused ? 1.5 : 0.5,
          ),
          boxShadow: _searchFocused
              ? [BoxShadow(
              color: amber.withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, 4))]
              : [],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(Icons.search_rounded,
                color: _searchFocused ? amber : Colors.grey, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                onChanged: (_) => _applyFilter(),
                style: TextStyle(
                    color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: SC.tr('advisorSearchHint'),
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
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
                      color: Colors.grey.withValues(alpha: 0.15),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.grey, size: 13),
                ),
              )
            else
              const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }

  // ── Category Chips ────────────────────────────────────────────
  Widget _buildCategoryChips(Color surfaceColor, Color borderColor,
      Color textColor, Color amber) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 0, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            // "All" chip
            _chip(
              label: SC.tr('advisorFilterAll'),
              active: _selectedFilter == _AdvisorFilter.all,
              accentColor: amber,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedFilter     = _AdvisorFilter.all;
                  _selectedOccupation = null;
                });
                _applyFilter();
              },
            ),
            // Occupation chips
            ..._occupations.map((occ) {
              final active = _selectedFilter == _AdvisorFilter.byOccupation &&
                  _selectedOccupation == occ;
              return _chip(
                label: occ,
                active: active,
                accentColor: amber,
                surfaceColor: surfaceColor,
                borderColor: borderColor,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedFilter     = _AdvisorFilter.byOccupation;
                    _selectedOccupation = occ;
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
    required Color surfaceColor,
    required Color borderColor,
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
          color: active ? accentColor.withValues(alpha: 0.15) : surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: active ? accentColor : borderColor,
              width: active ? 1.2 : 0.5),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? accentColor : Colors.grey,
                fontSize: 12.5,
                fontWeight: FontWeight.w700)),
      ),
    );
  }

  // ── Stats ─────────────────────────────────────────────────────
  Widget _buildStats(Color surfaceColor, Color borderColor,
      Color textColor, Color amber, Color gold) {
    final total = _allAdvisors.length + _chiefAdvisors.length;
    final chiefCount = _chiefAdvisors.length;
    final occupationCount = <String>{};
    for (final a in _allAdvisors) {
      final occ = a.occupation?.trim();
      if (occ != null && occ.isNotEmpty) occupationCount.add(occ);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              _statItem(SC.tr('advisorStatTotal'), total,
                  Icons.people_alt_rounded, amber, textColor),
              _vDivider(borderColor),
              _statItem(SC.tr('advisorStatChief'), chiefCount,
                  Icons.workspace_premium_rounded, gold, textColor),
              _vDivider(borderColor),
              _statItem(SC.tr('advisorStatDept'), occupationCount.length,
                  Icons.category_rounded, const Color(0xFF00BCD4), textColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(String label, int count, IconData icon,
      Color color, Color textColor) =>
      Expanded(
        child: TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: count),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (_, val, __) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color.withValues(alpha: 0.8), size: 18),
                const SizedBox(height: 6),
                Text('$val',
                    style: TextStyle(
                        color: textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5)),
                const SizedBox(height: 2),
                Text(label,
                    style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      );

  Widget _vDivider(Color borderColor) => Container(
      width: 0.5,
      color: borderColor,
      margin: const EdgeInsets.symmetric(vertical: 12));

  // ── Chief Section Label ───────────────────────────────────────
  Widget _buildChiefSectionLabel(
      Color surfaceColor, Color borderColor, Color gold) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                gold.withValues(alpha: 0.2),
                gold.withValues(alpha: 0.08),
              ]),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: gold.withValues(alpha: 0.35), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('👑', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                Text(SC.tr('advisorChiefLabel'),
                    style: TextStyle(
                        color: gold,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('${_chiefAdvisors.length}',
                      style: TextStyle(
                          color: gold,
                          fontSize: 10,
                          fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Chief Advisors List ───────────────────────────────────────
  Widget _buildChiefAdvisorsList(
      Color surfaceColor, Color surface2Color, Color borderColor,
      Color textColor, Color subTextColor, Color gold, Color goldDim,
      Color amberLight, Color amber) {
    return Column(
      children: _chiefAdvisors
          .asMap()
          .entries
          .map((e) => _buildChiefAdvisorCard(e.value, e.key, surfaceColor,
          surface2Color, borderColor, textColor, subTextColor,
          gold, goldDim, amberLight, amber))
          .toList(),
    );
  }

  Widget _buildChiefAdvisorCard(
      Advisor a, int idx,
      Color surfaceColor, Color surface2Color, Color borderColor,
      Color textColor, Color subTextColor,
      Color gold, Color goldDim, Color amberLight, Color amber) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, idx == 0 ? 0 : 10, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openPersonDetails(a, isChief: true),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: gold.withValues(alpha: 0.4), width: 0.8),
              boxShadow: [
                BoxShadow(
                    color: gold.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4))
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    height: 2,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Color(0xFFFFD700),
                          Color(0xFFFFD54F),
                          Color(0xFFFFD700),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0, top: 2, bottom: 0,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [gold, goldDim],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          AnimatedBuilder(
                            animation: _pulseAnim,
                            builder: (_, __) => Container(
                              width: 94, height: 94,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: gold.withValues(
                                        alpha: 0.2 + _pulseAnim.value * 0.15),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  )
                                ],
                              ),
                            ),
                          ),
                          Hero(
                            tag: 'advisor_${a.id}',
                            child: Container(
                              width: 90, height: 90,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: gold.withValues(alpha: 0.5),
                                    width: 1.5),
                                color: surface2Color,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: a.imagePath != null &&
                                  a.imagePath!.isNotEmpty
                                  ? Image.network(a.imagePath!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _chiefPlaceholder(surface2Color, gold))
                                  : _chiefPlaceholder(surface2Color, gold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    gold.withValues(alpha: 0.2),
                                    amber.withValues(alpha: 0.1),
                                  ]),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                      color: gold.withValues(alpha: 0.5),
                                      width: 0.8),
                                ),
                                child: Text(
                                  a.designation ?? SC.tr('advisorDefaultTitle'),
                                  style: TextStyle(
                                      color: gold,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8),
                                ),
                              ),
                              const SizedBox(width: 6),
                              AnimatedBuilder(
                                animation: _pulseAnim,
                                builder: (_, __) => Icon(
                                  Icons.verified_rounded,
                                  color: gold.withValues(
                                      alpha: 0.7 + _pulseAnim.value * 0.3),
                                  size: 14,
                                ),
                              ),
                            ]),
                            const SizedBox(height: 8),
                            Text(a.fullName,
                                style: TextStyle(
                                    color: textColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                    height: 1.1),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            if (a.fullNameBn != null &&
                                a.fullNameBn!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(a.fullNameBn!,
                                  style: TextStyle(
                                      color: subTextColor, fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              [a.occupation, a.institution]
                                  .where((s) => s != null && s.isNotEmpty)
                                  .join(' · '),
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 11.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFD700), Color(0xFFFFB300)],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                      color: gold.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2))
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(SC.tr('advisorViewProfile'),
                                      style: const TextStyle(
                                          color: Color(0xFF06090F),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_rounded,
                                      size: 12, color: Color(0xFF06090F)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 14, right: 14,
                  child: AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => Opacity(
                      opacity: 0.12 + _pulseAnim.value * 0.1,
                      child: Text('CHIEF ADVISOR',
                          style: TextStyle(
                              color: gold,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.5)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chiefPlaceholder(Color surface2Color, Color gold) => Container(
    color: surface2Color,
    child: Center(
      child: Icon(Icons.person_rounded,
          size: 38, color: gold.withValues(alpha: 0.25)),
    ),
  );

  // ── Section Label ─────────────────────────────────────────────
  Widget _buildSectionLabel(Color surfaceColor, Color borderColor,
      Color textColor, Color amber) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 14),
      child: Row(
        children: [
          Container(
            width: 2.5, height: 14,
            decoration: BoxDecoration(
                color: amber, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 10),
          Text(SC.tr('advisorSectionAll'),
              style: TextStyle(
                  color: textColor, fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                  color: amber.withValues(alpha: 0.25), width: 0.5),
            ),
            child: Text('${_filteredAdvisors.length}',
                style: TextStyle(
                    color: amber, fontSize: 11, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  // ── Card Wrapper ──────────────────────────────────────────────
  Widget _cardWrapper(int index, Color surfaceColor, Color surface2Color,
      Color borderColor, Color textColor, bool isDark) {
    final advisor = _filteredAdvisors[index];
    final accent  = _cardAccents[index % _cardAccents.length];
    return AnimatedBuilder(
      animation: _listAnim,
      builder: (_, child) {
        final delay = (index * 0.045).clamp(0.0, 0.5);
        final t =
        ((_listAnim.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
        final curve = Curves.easeOutCubic.transform(t);
        return Opacity(
          opacity: curve,
          child: Transform.translate(
              offset: Offset(0, 22 * (1 - curve)), child: child),
        );
      },
      child: GestureDetector(
        onTap: () => _openPersonDetails(advisor),
        child: AbsorbPointer(
          absorbing: true,
          child: _AdvisorGridCard(
            advisor:      advisor,
            index:        index,
            accentColor:  accent,
            pulseAnim:    _pulseAnim,
            surfaceColor: surfaceColor,
            surface2Color: surface2Color,
            borderColor:  borderColor,
            textColor:    textColor,
            isDark:       isDark,
          ),
        ),
      ),
    );
  }

  // ── Loading ───────────────────────────────────────────────────
  Widget _buildLoadingState(Color amber, Color gold) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => SizedBox(
              width: 40, height: 40,
              child: CircularProgressIndicator(
                color: gold.withValues(alpha: 0.4 + _pulseAnim.value * 0.4),
                strokeWidth: 2,
                backgroundColor: gold.withValues(alpha: 0.08),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(SC.tr('advisorLoading'),
              style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── Empty ─────────────────────────────────────────────────────
  Widget _buildEmpty(Color surfaceColor, Color borderColor,
      Color textColor, Color subTextColor, Color amber, Color bgColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor, width: 0.5),
              ),
              child: const Icon(Icons.search_off_rounded,
                  size: 32, color: Colors.grey),
            ),
            const SizedBox(height: 18),
            Text(SC.tr('advisorNotFound'),
                style: TextStyle(
                    color: textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(SC.tr('advisorFilterHint'),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: subTextColor, fontSize: 13, height: 1.5)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _clearSearch,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 12),
                decoration: BoxDecoration(
                    color: amber, borderRadius: BorderRadius.circular(10)),
                child: Text(SC.tr('advisorResetFilter'),
                    style: TextStyle(
                        color: bgColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// ADVISOR GRID CARD
// ════════════════════════════════════════════════════════════════
class _AdvisorGridCard extends StatefulWidget {
  final Advisor advisor;
  final int index;
  final Color accentColor;
  final Animation<double> pulseAnim;
  final Color surfaceColor;
  final Color surface2Color;
  final Color borderColor;
  final Color textColor;
  final bool isDark;

  const _AdvisorGridCard({
    required this.advisor,
    required this.index,
    required this.accentColor,
    required this.pulseAnim,
    required this.surfaceColor,
    required this.surface2Color,
    required this.borderColor,
    required this.textColor,
    required this.isDark,
  });

  @override
  State<_AdvisorGridCard> createState() => _AdvisorGridCardState();
}

class _AdvisorGridCardState extends State<_AdvisorGridCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _pressAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _pressAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
        CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a      = widget.advisor;
    final accent = widget.accentColor;

    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) => _pressCtrl.reverse(),
      onTapCancel: () => _pressCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _pressAnim,
        builder: (_, child) =>
            Transform.scale(scale: _pressAnim.value, child: child),
        child: Container(
          decoration: BoxDecoration(
            color: widget.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.18), width: 1),
            boxShadow: [
              BoxShadow(
                  color: accent.withValues(alpha: 0.10),
                  blurRadius: 18,
                  spreadRadius: -2,
                  offset: const Offset(0, 6)),
              BoxShadow(
                  color: Colors.black.withValues(
                      alpha: widget.isDark ? 0.3 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                top: -30, left: -20,
                child: AnimatedBuilder(
                  animation: widget.pulseAnim,
                  builder: (_, __) => Container(
                    width: 160, height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        accent.withValues(
                            alpha: 0.06 + widget.pulseAnim.value * 0.04),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0, left: 0, right: 0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.transparent,
                      accent.withValues(alpha: 0.7),
                      accent,
                      accent.withValues(alpha: 0.7),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: widget.pulseAnim,
                          builder: (_, __) => Container(
                            width: 90, height: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(
                                      alpha: 0.18 + widget.pulseAnim.value * 0.12),
                                  blurRadius: 18,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Hero(
                          tag: 'advisor_${a.id}',
                          child: Container(
                            width: 170, height: 110,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: accent.withValues(alpha: 0.5), width: 2),
                              color: widget.surface2Color,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: a.imagePath != null && a.imagePath!.isNotEmpty
                                ? Image.network(a.imagePath!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _placeholder(accent))
                                : _placeholder(accent),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      a.fullName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: widget.textColor,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                          height: 1.25),
                    ),
                    if (a.fullNameBn != null && a.fullNameBn!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(a.fullNameBn!,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.grey.withValues(alpha: 0.75),
                              fontSize: 10.5,
                              height: 1.2)),
                    ],
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: accent.withValues(alpha: 0.3), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5, height: 5,
                            decoration: BoxDecoration(
                                color: accent, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              a.occupation ??
                                  a.designation ??
                                  SC.tr('advisorOccupationDefault'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: accent,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (a.institution != null && a.institution!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: widget.surface2Color,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: widget.borderColor.withValues(alpha: 0.7),
                              width: 0.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.account_balance_rounded,
                                color: Colors.grey, size: 9),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                a.institution!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 5),
                    Container(
                      height: 0.5,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.transparent,
                          accent.withValues(alpha: 0.2),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accent, accent.withValues(alpha: 0.8)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: accent.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 3))
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(SC.tr('advisorViewProfile'),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2)),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_forward_rounded,
                                size: 10, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8, right: 10,
                child: AnimatedBuilder(
                  animation: widget.pulseAnim,
                  builder: (_, __) => Opacity(
                    opacity: 0.05 + widget.pulseAnim.value * 0.05,
                    child: Text('ADVISOR',
                        style: TextStyle(
                            color: accent,
                            fontSize: 6.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.8)),
                  ),
                ),
              ),
              if (a.expertise != null && a.expertise!.isNotEmpty)
                Positioned(
                  top: 6, left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      a.expertise!.split(' ').first,
                      style: TextStyle(
                          color: accent.withValues(alpha: 0.8),
                          fontSize: 7,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(Color accent) => Container(
    color: widget.surface2Color,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_rounded,
              size: 30, color: accent.withValues(alpha: 0.3)),
          const SizedBox(height: 4),
          Text(SC.tr('advisorNoImage'),
              style: TextStyle(
                  color: accent.withValues(alpha: 0.2),
                  fontSize: 8,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    ),
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
      ..color = isDark
          ? const Color(0xFF1E2D3F).withValues(alpha: 0.5)
          : const Color(0xFF90A4AE).withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    const step = 32.0;
    const r    = 1.0;
    for (double x = step; x < size.width; x += step) {
      for (double y = step; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => old.isDark != isDark;
}
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:css/models/committee_member_model.dart';
import 'package:css/widgets/committee_card.dart';
import 'package:css/pages/About/person_details_page.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class _C {
  static const gold      = Color(0xFFE8B84B);
  static const goldLight = Color(0xFFF5D07A);
  static const goldDim   = Color(0xFFB8902D);
}

// Internal enum to track selected category — language-independent
enum _CategoryFilter { all, top, executive, members }

class CommitteePage extends StatefulWidget {
  const CommitteePage({super.key});
  @override
  State<CommitteePage> createState() => _CommitteePageState();
}

class _CommitteePageState extends State<CommitteePage> with TickerProviderStateMixin {

  final _searchController = TextEditingController();
  final _supabase         = Supabase.instance.client;
  final _scrollController = ScrollController();
  final _searchFocus      = FocusNode();

  // Use enum instead of translated string — never breaks on language change
  _CategoryFilter           _selectedFilter  = _CategoryFilter.all;
  List<CommitteeMember>     _allMembers      = [];
  List<CommitteeMember>     _filteredMembers = [];
  CommitteeMember?          _president;
  Map<String, Map<String, dynamic>> _rawDataMap = {};

  bool   _isLoading     = true;
  double _scrollOffset  = 0.0;
  bool   _searchFocused = false;

  late final AnimationController _heroAnim;
  late final AnimationController _pulseAnim;
  late final AnimationController _shimmerAnim;
  late final AnimationController _listAnim;
  late final Animation<double>   _heroFade;
  late final Animation<Offset>   _heroSlide;

  static const _memberType = 'present_committee';

  final _positionHierarchy = const [
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

  // Maps each filter enum to its translated label — always in sync
  List<MapEntry<_CategoryFilter, String>> get _categoryEntries => [
    MapEntry(_CategoryFilter.all,       SC.tr('all')),
    MapEntry(_CategoryFilter.top,       SC.tr('top')),
    MapEntry(_CategoryFilter.executive, SC.tr('executiveCat')),
    MapEntry(_CategoryFilter.members,   SC.tr('membersCat')),
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _scrollController.addListener(_onScroll);
    _searchFocus.addListener(() => setState(() => _searchFocused = _searchFocus.hasFocus));
    _fetchMembers();
    // _selectedFilter already defaults to _CategoryFilter.all — no extra work needed
  }

  void _initAnimations() {
    _heroAnim    = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _pulseAnim   = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _shimmerAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _listAnim    = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _heroFade    = CurvedAnimation(parent: _heroAnim, curve: const Interval(0.0, 0.7, curve: Curves.easeOut));
    _heroSlide   = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _heroAnim, curve: const Interval(0.1, 0.9, curve: Curves.easeOutCubic)));
  }

  void _onScroll() { if (mounted) setState(() => _scrollOffset = _scrollController.offset); }

  @override
  void dispose() {
    _searchController.dispose(); _searchFocus.dispose();
    _heroAnim.dispose(); _pulseAnim.dispose(); _shimmerAnim.dispose();
    _listAnim.dispose(); _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMembers() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase.from('profiles').select(
        'id, full_name, committee_position, profile_image_url, '
            'short_bio, present_committee_note, blood_group, location_dms, '
            'school_name, school_group, school_passing_year, '
            'college_name, college_group, college_passing_year, '
            'university_name, department, current_year, current_semester',
      ).eq('member_type', _memberType);

      final List<CommitteeMember> members = [];
      CommitteeMember? pres;
      final Map<String, Map<String, dynamic>> rawMap = {};

      for (final item in response) {
        final position = item['committee_position'] as String?;
        final id = item['id'];
        if (position == null || position.isEmpty || id == null) continue;

        final idStr = id.toString();
        rawMap[idStr] = Map<String, dynamic>.from(item);

        final member = CommitteeMember(
          id: idStr, fullName: item['full_name'] as String? ?? 'Unknown',
          position: position, imagePath: item['profile_image_url'] as String?,
          category: _categoryFor(position),
        );
        position == "সভাপতি" ? pres = member : members.add(member);
      }

      members.sort((a, b) {
        int ia = _positionHierarchy.indexOf(a.position);
        int ib = _positionHierarchy.indexOf(b.position);
        if (ia == -1) ia = 999;
        if (ib == -1) ib = 999;
        return ia.compareTo(ib);
      });

      setState(() {
        _president       = pres;
        _allMembers      = members;
        _filteredMembers = members; // show all by default
        _rawDataMap      = rawMap;
        _isLoading       = false;
      });
      _listAnim.forward(from: 0);
      HapticFeedback.lightImpact();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) _snack('${SC.tr('loadFailed')}: $e', error: true);
    }
  }

  String _categoryFor(String position) {
    if (position == 'সভাপতি' || position == 'সহ-সভাপতি' || position == 'সাধারণ সম্পাদক') return 'শীর্ষ';
    if (position.contains('সম্পাদক') || position.contains('সহ-') || position == 'কার্যকরী সদস্য') return 'নির্বাহী';
    return 'সদস্য';
  }

  void _openPersonDetails(CommitteeMember member) {
    final raw = _rawDataMap[member.id] ?? {};
    HapticFeedback.lightImpact();
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => PersonDetailsPage(
        category: SC.tr('allMembers'),
        heroTag: 'committee_${member.id}',
        name: member.fullName, role: member.position,
        imageUrl: member.imagePath,
        message: raw['present_committee_note'] as String?,
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
        themeColor: _C.gold,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      transitionDuration: const Duration(milliseconds: 380),
    ));
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredMembers = _allMembers.where((m) {
        // Text search
        final match = q.isEmpty ||
            m.fullName.toLowerCase().contains(q) ||
            m.position.toLowerCase().contains(q);

        // Category filter — compare against enum, never translated strings
        final cat = switch (_selectedFilter) {
          _CategoryFilter.all       => true,
          _CategoryFilter.top       => m.category == 'শীর্ষ',
          _CategoryFilter.executive => m.category == 'নির্বাহী',
          _CategoryFilter.members   => m.category == 'সদস্য',
        };

        return match && cat;
      }).toList();
    });
    _listAnim.forward(from: 0);
    HapticFeedback.selectionClick();
  }

  void _clearSearch() {
    _searchController.clear();
    _selectedFilter = _CategoryFilter.all;
    _applyFilter();
    _searchFocus.unfocus();
  }

  void _snack(String msg, {bool error = false}) => SC.toast(context, msg, error ? SC.red : SC.teal);

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
    final isDark       = SC.isDark;
    final bgColor      = isDark ? const Color(0xFF06090F) : const Color(0xFFF0F4FF);
    final textColor    = isDark ? Colors.white : const Color(0xFF1A2332);
    final subColor     = isDark ? const Color(0xFF8899AA) : const Color(0xFF4A5568);
    final borderColor  = isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.08);
    final surfaceColor = isDark ? const Color(0xFF0F1620) : Colors.white;
    final surface2     = isDark ? const Color(0xFF141C28) : const Color(0xFFEEF2FF);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            _buildBackground(isDark),
            RefreshIndicator(
              onRefresh: _fetchMembers, color: _C.gold, backgroundColor: surfaceColor,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(child: SafeArea(bottom: false, child: _buildHero(textColor, subColor))),
                  SliverToBoxAdapter(child: _buildSearchBar(textColor, subColor, surfaceColor, surface2, borderColor)),
                  SliverToBoxAdapter(child: _buildCategoryChips(textColor, subColor, surfaceColor, borderColor)),
                  if (!_isLoading) SliverToBoxAdapter(child: _buildStats(textColor, subColor, surfaceColor, borderColor)),
                  if (_isLoading) SliverFillRemaining(hasScrollBody: false, child: _buildLoadingState()),
                  // Show president card only when "all" filter is active and no search query
                  if (!_isLoading && _president != null &&
                      _selectedFilter == _CategoryFilter.all &&
                      _searchController.text.isEmpty)
                    SliverToBoxAdapter(child: _buildPresidentCard(textColor, subColor, surfaceColor, surface2, borderColor)),
                  if (!_isLoading && _filteredMembers.isNotEmpty)
                    SliverToBoxAdapter(child: _buildSectionLabel(textColor, subColor, surfaceColor, borderColor)),
                  if (!_isLoading && _filteredMembers.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.60),
                        delegate: SliverChildBuilderDelegate(
                              (context, index) => _cardWrapper(index),
                          childCount: _filteredMembers.length,
                        ),
                      ),
                    ),
                  if (!_isLoading && _filteredMembers.isEmpty && _president == null)
                    SliverFillRemaining(hasScrollBody: false, child: _buildEmpty(textColor, subColor, surfaceColor, borderColor)),
                ],
              ),
            ),
            _buildTopBar(isDark, textColor, subColor, surfaceColor, borderColor),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground(bool isDark) {
    return Stack(children: [
      Container(decoration: BoxDecoration(gradient: SC.currentGradient)),
      Positioned(top: -100, left: -80, child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, __) => Container(width: 340, height: 340,
            decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _C.gold.withValues(alpha: 0.05 + _pulseAnim.value * 0.025), Colors.transparent]))),
      )),
      CustomPaint(size: MediaQuery.of(context).size, painter: _DotGridPainter()),
      Positioned(top: 0, left: 0, right: 0, child: Container(
        height: 1,
        decoration: BoxDecoration(gradient: LinearGradient(colors: [
          Colors.transparent, _C.gold.withValues(alpha: 0.35), Colors.transparent])),
      )),
    ]);
  }

  Widget _buildTopBar(bool isDark, Color textColor, Color subColor, Color surfaceColor, Color borderColor) {
    final collapsed = _scrollOffset > 80;
    return Positioned(
      top: 0, left: 0, right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: collapsed
              ? (isDark ? const Color(0xFF06090F).withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.92))
              : Colors.transparent,
          border: collapsed ? Border(bottom: BorderSide(color: borderColor, width: 0.5)) : const Border(),
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
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(width: 38, height: 38,
                        decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor, width: 0.5)),
                        child: Icon(Icons.arrow_back_ios_new_rounded, color: subColor, size: 17)),
                  ),
                  const Spacer(),
                  AnimatedOpacity(
                    opacity: collapsed ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(SC.tr('committeeMembers'),
                        style: TextStyle(color: _C.gold, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _fetchMembers,
                    child: Container(width: 38, height: 38,
                        decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor, width: 0.5)),
                        child: Icon(Icons.refresh_rounded, color: _C.gold, size: 17)),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(Color textColor, Color subColor) {
    return FadeTransition(
      opacity: _heroFade,
      child: SlideTransition(
        position: _heroSlide,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 80, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6,
                    decoration: BoxDecoration(color: _C.gold, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: _C.gold.withValues(alpha: 0.35 + _pulseAnim.value * 0.3), blurRadius: 10)])),
                const SizedBox(width: 10),
                Text(SC.tr('leadershipTeam'),
                    style: TextStyle(color: _C.gold.withValues(alpha: 0.85), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2.2)),
              ]),
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _shimmerAnim,
              builder: (_, __) => ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: const [_C.goldLight, _C.gold, _C.goldDim, _C.gold, _C.goldLight],
                  stops: [
                    0.0,
                    (_shimmerAnim.value * 0.5).clamp(0.0, 0.3),
                    (_shimmerAnim.value * 0.5 + 0.25).clamp(0.1, 0.6),
                    (_shimmerAnim.value * 0.5 + 0.45).clamp(0.35, 0.9),
                    1.0,
                  ],
                ).createShader(bounds),
                child: Text(SC.tr('committeeMembersTitle'),
                    style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900,
                        color: Colors.white, height: 1.08, letterSpacing: -1.5)),
              ),
            ),
            const SizedBox(height: 10),
            Text(SC.tr('committeeSubtitle'),
                style: TextStyle(color: subColor, fontSize: 13, height: 1.7, letterSpacing: 0.15)),
            Container(height: 1, margin: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(gradient: LinearGradient(colors: [
                  _C.gold.withValues(alpha: 0.4), _C.gold.withValues(alpha: 0.05), Colors.transparent]))),
          ]),
        ),
      ),
    );
  }

  Widget _buildSearchBar(Color textColor, Color subColor, Color surfaceColor, Color surface2, Color borderColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: _searchFocused ? _C.gold.withValues(alpha: 0.5) : borderColor,
              width: _searchFocused ? 1.5 : 0.5),
          boxShadow: _searchFocused
              ? [BoxShadow(color: _C.gold.withValues(alpha: 0.10), blurRadius: 20, offset: const Offset(0, 4))]
              : [],
        ),
        child: Row(children: [
          const SizedBox(width: 14),
          Icon(Icons.search_rounded, color: _searchFocused ? _C.gold : subColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController, focusNode: _searchFocus, onChanged: (_) => _applyFilter(),
              style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: SC.tr('searchNameOrPosition'),
                hintStyle: TextStyle(color: subColor, fontSize: 14),
                border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: _clearSearch,
              child: Container(margin: const EdgeInsets.only(right: 10), width: 22, height: 22,
                  decoration: BoxDecoration(color: surface2, shape: BoxShape.circle),
                  child: Icon(Icons.close_rounded, color: subColor, size: 13)),
            )
          else
            const SizedBox(width: 14),
        ]),
      ),
    );
  }

  Widget _buildCategoryChips(Color textColor, Color subColor, Color surfaceColor, Color borderColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 0, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(children: [
          ..._categoryEntries.map((entry) {
            final active = _selectedFilter == entry.key;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedFilter = entry.key);
                _applyFilter();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220), curve: Curves.easeOut,
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? _C.gold : surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: active ? _C.gold : borderColor, width: 0.5),
                ),
                child: Text(entry.value, style: TextStyle(
                    color: active ? const Color(0xFF06090F) : subColor,
                    fontSize: 12.5, fontWeight: FontWeight.w700)),
              ),
            );
          }),
          const SizedBox(width: 16),
        ]),
      ),
    );
  }

  Widget _buildStats(Color textColor, Color subColor, Color surfaceColor, Color borderColor) {
    final total = _allMembers.length + (_president != null ? 1 : 0);
    final top   = _allMembers.where((m) => m.category == 'শীর্ষ').length + 1;
    final exec  = _allMembers.where((m) => m.category == 'নির্বাহী').length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Container(
        decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 0.5)),
        child: IntrinsicHeight(
          child: Row(children: [
            _statItem(SC.tr('total'), total, Icons.groups_rounded, textColor, subColor),
            Container(width: 0.5, color: borderColor, margin: const EdgeInsets.symmetric(vertical: 12)),
            _statItem(SC.tr('topStat'), top, Icons.military_tech_rounded, textColor, subColor),
            Container(width: 0.5, color: borderColor, margin: const EdgeInsets.symmetric(vertical: 12)),
            _statItem(SC.tr('executiveStat'), exec, Icons.workspace_premium_rounded, textColor, subColor),
          ]),
        ),
      ),
    );
  }

  Widget _statItem(String label, int count, IconData icon, Color textColor, Color subColor) {
    return Expanded(
      child: TweenAnimationBuilder<int>(
        tween: IntTween(begin: 0, end: count),
        duration: const Duration(milliseconds: 800), curve: Curves.easeOutCubic,
        builder: (_, val, __) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: _C.gold.withValues(alpha: 0.7), size: 18),
            const SizedBox(height: 6),
            Text('$val', style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: subColor, fontSize: 11, fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    );
  }

  Widget _buildPresidentCard(Color textColor, Color subColor, Color surfaceColor, Color surface2, Color borderColor) {
    final p = _president!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openPersonDetails(p),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _C.gold.withValues(alpha: 0.3), width: 0.5)),
            clipBehavior: Clip.antiAlias,
            child: Stack(children: [
              Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 3,
                  decoration: BoxDecoration(gradient: LinearGradient(
                      colors: [_C.goldLight, _C.goldDim],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter)))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Row(children: [
                  Hero(
                    tag: 'committee_${p.id}',
                    child: Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _C.gold.withValues(alpha: 0.3), width: 1), color: surface2),
                      clipBehavior: Clip.antiAlias,
                      child: p.imagePath != null
                          ? Image.network(p.imagePath!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(Icons.person_rounded, size: 40, color: _C.gold.withValues(alpha: 0.25)))
                          : Icon(Icons.person_rounded, size: 40, color: _C.gold.withValues(alpha: 0.25)),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: _C.gold.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: _C.gold.withValues(alpha: 0.35), width: 0.5)),
                        child: Text(SC.tr('president'),
                            style: TextStyle(color: _C.gold, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.verified_rounded, color: _C.gold, size: 13),
                    ]),
                    const SizedBox(height: 8),
                    Text(p.fullName, style: TextStyle(color: textColor, fontSize: 19, fontWeight: FontWeight.w900,
                        letterSpacing: -0.4, height: 1.1), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(p.position, style: TextStyle(color: subColor, fontSize: 12)),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(color: _C.gold, borderRadius: BorderRadius.circular(8)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(SC.tr('viewProfile'),
                            style: const TextStyle(color: Color(0xFF06090F), fontSize: 11, fontWeight: FontWeight.w800)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF06090F)),
                      ]),
                    ),
                  ])),
                ]),
              ),
              Positioned(top: 14, right: 16, child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Opacity(
                    opacity: 0.15 + _pulseAnim.value * 0.15,
                    child: Text('PRESIDENT',
                        style: TextStyle(color: _C.gold, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 2.5))),
              )),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(Color textColor, Color subColor, Color surfaceColor, Color borderColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 14),
      child: Row(children: [
        Container(width: 2.5, height: 14, decoration: BoxDecoration(color: _C.gold, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(SC.tr('allMembers'), style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(color: _C.gold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5),
              border: Border.all(color: _C.gold.withValues(alpha: 0.25), width: 0.5)),
          child: Text('${_filteredMembers.length}',
              style: TextStyle(color: _C.gold, fontSize: 11, fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }

  Widget _cardWrapper(int index) {
    final member = _filteredMembers[index];
    return AnimatedBuilder(
      animation: _listAnim,
      builder: (_, child) {
        final delay = (index * 0.045).clamp(0.0, 0.5);
        final t     = ((_listAnim.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
        final curve = Curves.easeOutCubic.transform(t);
        return Opacity(opacity: curve, child: Transform.translate(offset: Offset(0, 22 * (1 - curve)), child: child));
      },
      child: GestureDetector(
        onTap: () => _openPersonDetails(member),
        child: AbsorbPointer(absorbing: true, child: CommitteeCard(member: member)),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      AnimatedBuilder(animation: _pulseAnim,
          builder: (_, __) => SizedBox(width: 40, height: 40, child: CircularProgressIndicator(
              color: _C.gold.withValues(alpha: 0.4 + _pulseAnim.value * 0.4),
              strokeWidth: 2, backgroundColor: _C.gold.withValues(alpha: 0.08)))),
      const SizedBox(height: 16),
      Text(SC.tr('loading'),
          style: const TextStyle(color: Color(0xFF4A5870), fontSize: 13, fontWeight: FontWeight.w500)),
    ]));
  }

  Widget _buildEmpty(Color textColor, Color subColor, Color surfaceColor, Color borderColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 72, height: 72,
              decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor, width: 0.5)),
              child: Icon(Icons.search_off_rounded, size: 32, color: subColor)),
          const SizedBox(height: 18),
          Text(SC.tr('noMembersFound'),
              style: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(SC.tr('changeFilterOrSearch'), textAlign: TextAlign.center,
              style: TextStyle(color: subColor, fontSize: 13, height: 1.5)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _clearSearch,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(color: _C.gold, borderRadius: BorderRadius.circular(10)),
              child: Text(SC.tr('resetFilter'),
                  style: const TextStyle(color: Color(0xFF06090F), fontWeight: FontWeight.w800, fontSize: 13)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E2D3F).withValues(alpha: 0.5)
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
  bool shouldRepaint(_DotGridPainter _) => false;
}
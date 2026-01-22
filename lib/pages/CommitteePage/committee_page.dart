import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:css/models/committee_member_model.dart';
import 'package:css/widgets/committee_card.dart';
import 'package:css/pages/Profile/profile_page.dart';

class CommitteePage extends StatefulWidget {
  const CommitteePage({super.key});

  @override
  State<CommitteePage> createState() => _CommitteePageState();
}

class _CommitteePageState extends State<CommitteePage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  String selectedCategory = "All";
  List<CommitteeMember> allMembers = [];
  List<CommitteeMember> filteredMembers = [];
  CommitteeMember? president;
  bool _isLoading = true;
  double _scrollOffset = 0.0;
  bool _isSearchFocused = false;

  late AnimationController _animController;
  late AnimationController _particleController;
  late AnimationController _cardAnimController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final List<String> positionHierarchy = [
    "সভাপতি", "সহ-সভাপতি", "সাধারণ সম্পাদক", "যুগ্ম-সাধারণ সম্পাদক", "সাংগঠনিক সম্পাদক",
    "সহ-সাংগঠনিক সম্পাদক", "দপ্তর সম্পাদক", "সিনিয়র সহ-দপ্তর সম্পাদক", "সহ-দপ্তর সম্পাদক",
    "অর্থ সম্পাদক", "সিনিয়র অর্থ সম্পাদক", "সহ-অর্থ সম্পাদক", "শিক্ষা সম্পাদক", "সহ-শিক্ষা সম্পাদক",
    "পরিকল্পনা সম্পাদক", "সহ-পরিকল্পনা সম্পাদক", "মানব সম্পদ সম্পাদক", "সহ-মানব সম্পদ সম্পাদক",
    "পরিবেশ সম্পাদক", "সহ-পরিবেশ সম্পাদক", "ধর্ম সম্পাদক", "সহ-ধর্ম সম্পাদক", "প্রচার সম্পাদক",
    "সহ-প্রচার সম্পাদক", "ব্র্যান্ড ও গণমাধ্যম সম্পাদক", "সিনিয়র ব্র্যান্ড ও গণমাধ্যম সম্পাদক",
    "গ্রাফিক্স ডিজাইনার", "সহ-গ্রাফিক্স ডিজাইনার", "ক্রিয়া সম্পাদক", "সহ-ক্রিয়া সম্পাদক",
    "পাঠাগার সম্পাদক", "সহ-পাঠাগার সম্পাদক", "সাংস্কৃতিক সম্পাদক", "সহ-সাংস্কৃতিক সম্পাদক",
    "বিজ্ঞান ও প্রযুক্তি সম্পাদক", "সহ-বিজ্ঞান ও প্রযুক্তি সম্পাদক", "সমাজ কল্যাণ সম্পাদক",
    "সহ-সমাজ কল্যাণ সম্পাদক", "স্বাস্থ্য সম্পাদক", "সহ-স্বাস্থ্য সম্পাদক", "নারী সম্পাদক",
    "সহ-নারী সম্পাদক", "আন্তর্জাতিক সম্পাদক", "সহ-আন্তর্জাতিক সম্পাদক", "ছাত্র কল্যাণ সম্পাদক",
    "সহ-ছাত্র কল্যাণ সম্পাদক", "সাহিত্য সম্পাদক", "সহ-সাহিত্য সম্পাদক", "তথ্য ও গবেষণা সম্পাদক",
    "সহ-তথ্য ও গবেষণা সম্পাদক", "ত্রাণ ও দুর্যোগ সম্পাদক", "সিনিয়র ত্রাণ ও দুর্যোগ সম্পাদক",
    "সহ-ত্রাণ ও দুর্যোগ সম্পাদক", "কার্যকরী সদস্য"
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _scrollController.addListener(_onScroll);
    _searchFocusNode.addListener(_onSearchFocusChange);
    _fetchCommitteeMembers();
  }

  void _initAnimations() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();

    _cardAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.2, 1.0, curve: Curves.elasticOut)),
    );

    _animController.forward();
  }

  void _onScroll() {
    if (mounted) {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    }
  }

  void _onSearchFocusChange() {
    setState(() {
      _isSearchFocused = _searchFocusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animController.dispose();
    _particleController.dispose();
    _cardAnimController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchCommitteeMembers() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, full_name, committee_position, profile_image_url')
          .eq('member_type', 'Committee');

      final List<CommitteeMember> members = [];
      CommitteeMember? pres;

      for (var item in response) {
        final position = item['committee_position'] as String?;
        final id = item['id'];

        if (position != null && position.isNotEmpty && id != null) {
          final member = CommitteeMember(
            id: id.toString(),
            fullName: item['full_name'] as String? ?? 'Unknown',
            position: position,
            imagePath: item['profile_image_url'] as String?,
            category: _getCategoryFromPosition(position),
          );

          if (position == "সভাপতি") {
            pres = member;
          } else {
            members.add(member);
          }
        }
      }

      members.sort((a, b) {
        int indexA = positionHierarchy.indexOf(a.position);
        int indexB = positionHierarchy.indexOf(b.position);
        if (indexA == -1) indexA = 999;
        if (indexB == -1) indexB = 999;
        return indexA.compareTo(indexB);
      });

      setState(() {
        president = pres;
        allMembers = members;
        filteredMembers = members;
        _isLoading = false;
      });

      _cardAnimController.forward();
      HapticFeedback.lightImpact();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) _showMessage('Error loading members: $e', isError: true);
    }
  }

  String _getCategoryFromPosition(String position) {
    if (position == 'সভাপতি' || position == 'সহ-সভাপতি' || position == 'সাধারণ সম্পাদক') return 'Top';
    if (position.contains('সম্পাদক') || position.contains('সহ-') || position == 'কার্যকরী সদস্য') return 'Executive';
    return 'Members';
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      filteredMembers = allMembers.where((m) {
        final nameMatch = m.fullName.toLowerCase().contains(query);
        final positionMatch = m.position.toLowerCase().contains(query);
        final searchMatch = query.isEmpty || nameMatch || positionMatch;
        final categoryMatch = selectedCategory == "All" || m.category == selectedCategory;
        return searchMatch && categoryMatch;
      }).toList();
    });
    HapticFeedback.selectionClick();
  }

  void _clearSearch() {
    _searchController.clear();
    _applyFilter();
    _searchFocusNode.unfocus();
    HapticFeedback.lightImpact();
  }

  void _showMessage(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade900 : Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0E1A), Color(0xFF1A1F35), Color(0xFF0F1828)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) => Stack(
                children: List.generate(25, (index) => _buildAnimatedParticle(index)),
              ),
            ),
            RefreshIndicator(
              onRefresh: _fetchCommitteeMembers,
              color: Colors.amberAccent,
              backgroundColor: const Color(0xFF1A1F35),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: SafeArea(
                      bottom: false,
                      child: _buildHeroHeader(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      child: _buildSearchAndFilter(),
                    ),
                  ),
                  if (!_isLoading)
                    SliverToBoxAdapter(child: _buildStatsSection()),
                  if (_isLoading)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(color: Colors.amberAccent, strokeWidth: 3),
                            const SizedBox(height: 20),
                            Text(
                              'Loading Committee Members...',
                              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (!_isLoading && president != null && selectedCategory == "All" && _searchController.text.trim().isEmpty)
                    SliverToBoxAdapter(child: _buildPresidentSection()),
                  if (!_isLoading && filteredMembers.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 25, 20, 100),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.65,
                        ),
                        delegate: SliverChildBuilderDelegate(
                              (context, index) {
                            return FadeTransition(
                              opacity: _fadeAnimation,
                              child: CommitteeCard(member: filteredMembers[index]),
                            );
                          },
                          childCount: filteredMembers.length,
                        ),
                      ),
                    ),
                  if (!_isLoading && filteredMembers.isEmpty && president == null)
                    SliverFillRemaining(child: _buildEmptyState()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    double parallax = _scrollOffset * 0.3;
    return Transform.translate(
      offset: Offset(0, -parallax),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBadge('LEADERSHIP TEAM', Colors.amberAccent),
            const SizedBox(height: 28),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ).createShader(bounds),
              child: const Text(
                'Committee\nMembers',
                style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: Colors.white, height: 1.05, letterSpacing: -2.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Meet the visionary leaders driving our community forward',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: Colors.amberAccent, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: (_) => _applyFilter(),
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          decoration: InputDecoration(
                            hintText: "Search by name or position...",
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 15),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(onTap: _clearSearch, child: const Icon(Icons.close_rounded, color: Colors.white54, size: 18)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: ["All", "Top", "Executive", "Members"].map((cat) => _categoryChip(cat)).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(String cat) {
    bool isActive = selectedCategory == cat;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() { selectedCategory = cat; _applyFilter(); });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          gradient: isActive ? const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]) : null,
          color: isActive ? null : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: isActive ? Colors.transparent : Colors.white.withOpacity(0.1)),
        ),
        child: Text(
          cat,
          style: TextStyle(color: isActive ? Colors.black : Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildPresidentSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(id: president!.id))),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  colors: [Colors.amberAccent.withOpacity(0.2), Colors.orangeAccent.withOpacity(0.1)],
                ),
                border: Border.all(color: Colors.amberAccent.withOpacity(0.4), width: 2),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.amberAccent,
                    child: CircleAvatar(
                      radius: 45,
                      backgroundImage: president!.imagePath != null ? NetworkImage(president!.imagePath!) : null,
                      backgroundColor: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PRESIDENT', style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                        const SizedBox(height: 6),
                        Text(president!.fullName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                        Text(president!.position, style: TextStyle(color: Colors.amberAccent.shade100, fontSize: 15)),
                      ],
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

  Widget _buildStatsSection() {
    int total = allMembers.length + (president != null ? 1 : 0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statBox("Total", total.toString(), Icons.groups_rounded),
          _buildDivider(),
          _statBox("Leadership", allMembers.where((m) => m.category == 'Top').length.toString(), Icons.workspace_premium_rounded),
          _buildDivider(),
          _statBox("Executive", allMembers.where((m) => m.category == 'Executive').length.toString(), Icons.military_tech_rounded),
        ],
      ),
    );
  }

  Widget _statBox(String label, String count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.amberAccent, size: 28),
        const SizedBox(height: 10),
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 60,
      width: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withOpacity(0.2),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withOpacity(0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.8,
        ),
      ),
    );
  }

  Widget _buildAnimatedParticle(int index) {
    final random = (index * 37) % 100;
    final size = 2.0 + (random % 4);
    final speed = 150.0 + (random % 100);

    return Positioned(
      left: (index * 60.0) % MediaQuery.of(context).size.width,
      top: (index * 90.0 + (_particleController.value * speed)) % MediaQuery.of(context).size.height,
      child: Opacity(
        opacity: 0.08 + (random % 20) / 200,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: index % 3 == 0 ? Colors.amberAccent : Colors.orangeAccent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (index % 3 == 0 ? Colors.amberAccent : Colors.orangeAccent).withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 2),
            ),
            child: Icon(Icons.search_off_rounded, size: 64, color: Colors.white.withOpacity(0.3)),
          ),
          const SizedBox(height: 24),
          Text(
            "No Members Found",
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _clearSearch,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.amberAccent, Colors.orangeAccent]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text('RESET FILTERS', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';

import 'package:css/models/about_models.dart';
import 'package:css/services/about_service.dart';
import 'person_details_page.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> with TickerProviderStateMixin {
  final AboutService _aboutService = AboutService();
  final SupabaseClient supabase = Supabase.instance.client;

  bool _loading = true;
  String? _error;

  // Data Holders
  AboutOverview? overview;
  List<MissionPoint> missions = [];
  List<Activity> activities = [];
  List<Advisor> advisors = [];
  List<PreviousPresident> presidents = [];
  List<Leadership> leaders = [];
  List<StoryEvent> story = [];
  ContactInfo? contact;

  bool showAllMission = false;
  bool showAllStory = false;

  late AnimationController _mainFadeController;
  late AnimationController _heroController;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadData();
  }

  void _initAnimations() {
    _mainFadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _mainFadeController,
      curve: Curves.easeInOut,
    );

    _heroController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.easeOutBack),
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _mainFadeController.dispose();
    _heroController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final data = await _aboutService.getAllAboutData();
      if (mounted) {
        setState(() {
          overview = data['overview'] as AboutOverview?;
          missions = (data['missionPoints'] as List<MissionPoint>?) ?? [];
          activities = (data['activities'] as List<Activity>?) ?? [];
          advisors = (data['advisors'] as List<Advisor>?) ?? [];
          presidents = (data['previousPresidents'] as List<PreviousPresident>?) ?? [];
          leaders = (data['leadership'] as List<Leadership>?) ?? [];
          story = (data['story'] as List<StoryEvent>?) ?? [];
          contact = data['contact'] as ContactInfo?;
          _loading = false;
        });
        _mainFadeController.forward();
        _heroController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Failed to load data: $e";
          _loading = false;
        });
      }
    }
  }

  String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    return supabase.storage.from('about').getPublicUrl(path);
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.cyanAccent, size: 20),
            onPressed: _loadData,
            padding: const EdgeInsets.all(8),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.3, -0.5),
            radius: 1.8,
            colors: [
              Color(0xFF1A2332),
              Color(0xFF0F1419),
              Color(0xFF0A0E1A),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated Background Orbs
            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) => Stack(
                children: [
                  _positionedOrb(
                    top: -100,
                    left: -50,
                    size: 350,
                    color: Colors.cyanAccent.withOpacity(0.08),
                  ),
                  _positionedOrb(
                    bottom: 100,
                    right: -100,
                    size: 450,
                    color: Colors.purpleAccent.withOpacity(0.06),
                  ),
                  _positionedOrb(
                    top: MediaQuery.of(context).size.height * 0.4,
                    left: -80,
                    size: 280,
                    color: Colors.orangeAccent.withOpacity(0.05),
                  ),
                ],
              ),
            ),
            // Content
            _loading
                ? _buildPremiumLoader()
                : _error != null
                ? _buildErrorScreen()
                : FadeTransition(
              opacity: _fadeAnimation,
              child: _buildMainContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeroSection()),

        if (overview != null)
          SliverToBoxAdapter(child: _buildOverviewSection()),

        if (missions.isNotEmpty)
          SliverToBoxAdapter(child: _buildMissionSection()),

        if (activities.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildHorizontalListSection(
              'Core Activities',
              activities,
              Icons.auto_awesome_rounded,
              'activity',
              Colors.orangeAccent,
            ),
          ),

        if (advisors.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildHorizontalListSection(
              'Distinguished Advisors',
              advisors,
              Icons.workspace_premium_rounded,
              'advisor',
              Colors.amberAccent,
            ),
          ),

        if (presidents.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildHorizontalListSection(
              'Previous Presidents',
              presidents,
              Icons.history_edu_rounded,
              'president',
              Colors.purpleAccent,
            ),
          ),

        if (leaders.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildHorizontalListSection(
              'Current Board',
              leaders,
              Icons.military_tech_rounded,
              'leader',
              Colors.greenAccent,
            ),
          ),

        if (story.isNotEmpty)
          SliverToBoxAdapter(child: _buildStorySection()),

        if (contact != null)
          SliverToBoxAdapter(child: _buildContactSection()),



        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  // ================= HERO SECTION =================
  Widget _buildHeroSection() {
    return AnimatedBuilder(
      animation: _heroController,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _slideAnimation.value),
        child: Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.fromLTRB(28, 120, 28, 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _badge(
                  label: "ESTABLISHED ${overview?.foundedYear ?? 2022}",
                  icon: Icons.verified_rounded,
                ),
                const SizedBox(height: 28),
                const Text(
                  'Conscious\nStudent Society',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Building Leaders • Inspiring Change',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= OVERVIEW SECTION =================
  Widget _buildOverviewSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: _modernGlassCard(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _modernSectionHeader(
                title: "Our Focus Areas",
                icon: Icons.auto_stories_rounded,
                color: Colors.cyanAccent,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                ),
                child: Text(
                  overview?.focus ?? "",
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                overview?.description ?? "",
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.8,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= MISSION SECTION =================
  Widget _buildMissionSection() {
    final list = showAllMission ? missions : missions.take(3).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: _modernGlassCard(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(28),
              child: _modernSectionHeader(
                title: "Mission & Vision",
                icon: Icons.rocket_launch_rounded,
                color: Colors.purpleAccent,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  ...list.asMap().entries.map(
                        (e) => _modernMissionTile(e.value.text, e.key),
                  ),
                  if (missions.length > 3) ...[
                    const SizedBox(height: 8),
                    _modernToggleButton(
                      text: showAllMission ? "Show Less" : "View All Goals",
                      isExpanded: showAllMission,
                      onTap: () => setState(() => showAllMission = !showAllMission),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HORIZONTAL LIST SECTION =================
  Widget _buildHorizontalListSection(
      String title,
      List items,
      IconData icon,
      String type,
      Color color,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 16),
          child: _modernSectionHeader(
            title: title,
            icon: icon,
            color: color,
          ),
        ),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, i) => _buildCardItem(items[i], color, type),
          ),
        ),
      ],
    );
  }

  Widget _buildCardItem(dynamic item, Color color, String type) {
    String? name;
    String? subtitle;
    String? imageUrl;
    String? personMessage;
    String? personBio;

    if (item is Activity) {
      name = item.title;
      subtitle = "Activity";
    } else if (item is Advisor) {
      name = item.name;
      subtitle = item.role;
      imageUrl = getImageUrl(item.imageUrl);
      personMessage = item.message;
      personBio = item.bio;
    } else if (item is PreviousPresident) {
      name = item.name;
      subtitle = item.role;
      imageUrl = getImageUrl(item.imageUrl);
      personMessage = item.message;
      personBio = item.bio;
    } else if (item is Leadership) {
      name = item.name;
      subtitle = item.role;
      imageUrl = getImageUrl(item.imageUrl);
      personMessage = item.message;
      personBio = item.bio;
    }

    return GestureDetector(
      onTap: type == 'activity'
          ? null
          : () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PersonDetailsPage(
              name: name ?? "",
              role: subtitle ?? "",
              imageUrl: imageUrl,
              message: personMessage,
              bio: personBio,
              themeColor: color,
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        child: _modernGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withOpacity(0.5),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: color.withOpacity(0.1),
                    backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                        ? NetworkImage(imageUrl)
                        : null,
                    child: imageUrl == null || imageUrl.isEmpty
                        ? Icon(
                      type == 'activity' ? Icons.bolt : Icons.person,
                      color: color,
                      size: 32,
                    )
                        : null,
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    name ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle ?? '',
                  style: TextStyle(
                    color: color.withOpacity(0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= STORY SECTION =================
  Widget _buildStorySection() {
    final list = showAllStory ? story : story.take(3).toList();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: _modernGlassCard(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(28),
              child: _modernSectionHeader(
                title: "The Legacy Journey",
                icon: Icons.history,
                color: Colors.orangeAccent,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  ...list.asMap().entries.map(
                        (e) => _modernTimelineTile(
                      e.value,
                      e.key == list.length - 1,
                      e.key,
                    ),
                  ),
                  if (story.length > 3) ...[
                    const SizedBox(height: 8),
                    _modernToggleButton(
                      text: showAllStory ? "Show Less" : "Explore Journey",
                      isExpanded: showAllStory,
                      onTap: () => setState(() => showAllStory = !showAllStory),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= CONTACT SECTION =================
  Widget _buildContactSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: _modernGlassCard(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              _modernSectionHeader(
                title: "Get In Touch",
                icon: Icons.contact_mail,
                color: Colors.greenAccent,
              ),
              const SizedBox(height: 24),
              _modernContactTile(
                Icons.email_rounded,
                contact!.email,
                "EMAIL ADDRESS",
                Colors.cyanAccent,
              ),
              _modernContactTile(
                Icons.phone_rounded,
                contact!.phone,
                "CONTACT NUMBER",
                Colors.greenAccent,
              ),
              _modernContactTile(
                Icons.location_on_rounded,
                contact!.address,
                "HEAD OFFICE",
                Colors.orangeAccent,
              ),
              if (contact?.facebook != null && contact!.facebook!.isNotEmpty)
                _modernContactTile(
                  Icons.link_rounded,
                  contact!.facebook!,
                  "FACEBOOK PAGE",
                  Colors.blueAccent,
                ),
              if (contact?.website != null && contact!.website!.isNotEmpty)
                _modernContactTile(
                  Icons.language_rounded,
                  contact!.website!,
                  "WEBSITE",
                  Colors.purpleAccent,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= HELPER WIDGETS =================

  Widget _modernGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _modernSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _modernMissionTile(String text, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.purpleAccent.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.purpleAccent.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.check,
              color: Colors.purpleAccent,
              size: 14,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernTimelineTile(StoryEvent event, bool isLast, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.orangeAccent.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.orangeAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 50,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.orangeAccent.withOpacity(0.4),
                        Colors.orangeAccent.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orangeAccent.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    DateFormat('dd MMM yyyy').format(event.eventDate),
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  event.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernContactTile(
      IconData icon,
      String value,
      String label,
      Color color,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color.withOpacity(0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge({required String label, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.cyanAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.cyanAccent.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.cyanAccent),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernToggleButton({
    required String text,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        backgroundColor: Colors.cyanAccent.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.cyanAccent.withOpacity(0.3),
          ),
        ),
      ),
      icon: Icon(
        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
        size: 20,
        color: Colors.cyanAccent,
      ),
      label: Text(
        text,
        style: const TextStyle(
          color: Colors.cyanAccent,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPremiumLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.cyanAccent.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const CircularProgressIndicator(
              color: Colors.cyanAccent,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.redAccent.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _error ?? 'Something went wrong',
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: const Color(0xFF0A0E1A),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text(
                'Retry',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _positionedOrb({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: 100,
              spreadRadius: 20,
            ),
          ],
        ),
      ),
    );
  }
}
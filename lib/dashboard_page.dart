import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Services
import '../services/banner_service.dart';
import '../services/about_service.dart';
import '../services/gallery_service.dart';
import '../services/video_service.dart';
import '../services/feed_service.dart';
import '../services/profile_service.dart';

// Models
import '../models/banner_model.dart';
import '../models/notice_model.dart';
import '../models/about_models.dart';
import '../models/gallery_image_model.dart';
import '../models/video_model.dart';
import '../models/profile_model.dart';

// Shared / existing widgets
import '../widgets/banner_section.dart';
import '../widgets/notice_section.dart';
import '../widgets/gallery_preview_section.dart';
import '../widgets/video_preview_section.dart';
import '../widgets/events_section.dart';
import '../widgets/person_section.dart';
import '../widgets/footer_section.dart';
import '../widgets/background_orbs.dart';
import 'package:css/widgets/complaint_dashboard_card.dart';

// ── Dashboard-specific widgets ─────────────────────────────────────────────
import '../widgets/dashboard/offline_banner_widget.dart';
import '../widgets/dashboard/emergency_requests_banner_widget.dart';
import '../widgets/dashboard/blood_dashboard_section_widget.dart';
import '../widgets/dashboard/about_summary_section_widget.dart';

// ── AI Chat Popup ──────────────────────────────────────────────────────────
import 'package:css/widgets/ai_chat_popup.dart';

// Pages
import 'package:css/pages/NoticePage/notice_page.dart';
import 'package:css/pages/Events/events_list_page.dart';
import 'package:css/pages/Events/event_details_page.dart';
import 'package:css/pages/About/person_details_page.dart';
import 'package:css/pages/Gallery/gallery_page.dart';
import 'package:css/pages/videos/videos_page.dart';

// SC
import 'package:css/pages/SettingsPage/settings_constants.dart';

// ─── Cache Keys ───────────────────────────────────────────────────────────────
const _kCacheNotices    = 'cache_notices';
const _kCacheEvents     = 'cache_events';
const _kCacheBloodTotal = 'cache_blood_total';
const _kCacheBloodReady = 'cache_blood_ready';
const _kCacheEmergency  = 'cache_emergency';
const _kCacheOverview   = 'cache_overview';

// ─── Committee position serial order ─────────────────────────────────────────
const _kCommitteeOrder = [
  "সভাপতি", "সহ-সভাপতি", "সাধারণ সম্পাদক", "যুগ্ম-সাধারণ সম্পাদক",
  "সাংগঠনিক সম্পাদক", "সহ-সাংগঠনিক সম্পাদক", "দপ্তর সম্পাদক",
  "সিনিয়র সহ-দপ্তর সম্পাদক", "সহ-দপ্তর সম্পাদক", "অর্থ সম্পাদক",
  "সিনিয়র অর্থ সম্পাদক", "সহ-অর্থ সম্পাদক", "শিক্ষা সম্পাদক",
  "সহ-শিক্ষা সম্পাদক", "পরিকল্পনা সম্পাদক", "সহ-পরিকল্পনা সম্পাদক",
  "মানব সম্পদ সম্পাদক", "সহ-মানব সম্পদ সম্পাদক", "পরিবেশ সম্পাদক",
  "সহ-পরিবেশ সম্পাদক", "ধর্ম সম্পাদক", "সহ-ধর্ম সম্পাদক",
  "প্রচার সম্পাদক", "সহ-প্রচার সম্পাদক", "ব্র্যান্ড ও গণমাধ্যম সম্পাদক",
  "সিনিয়র ব্র্যান্ড ও গণমাধ্যম সম্পাদক", "গ্রাফিক্স ডিজাইনার",
  "সহ-গ্রাফিক্স ডিজাইনার", "ক্রিয়া সম্পাদক", "সহ-ক্রিয়া সম্পাদক",
  "পাঠাগার সম্পাদক", "সহ-পাঠাগার সম্পাদক", "সাংস্কৃতিক সম্পাদক",
  "সহ-সাংস্কৃতিক সম্পাদক", "বিজ্ঞান ও প্রযুক্তি সম্পাদক",
  "সহ-বিজ্ঞান ও প্রযুক্তি সম্পাদক", "সমাজ কল্যাণ সম্পাদক",
  "সহ-সমাজ কল্যাণ সম্পাদক", "স্বাস্থ্য সম্পাদক", "সহ-স্বাস্থ্য সম্পাদক",
  "নারী সম্পাদক", "সহ-নারী সম্পাদক", "আন্তর্জাতিক সম্পাদক",
  "সহ-আন্তর্জাতিক সম্পাদক", "ছাত্র কল্যাণ সম্পাদক",
  "সহ-ছাত্র কল্যাণ সম্পাদক", "সাহিত্য সম্পাদক", "সহ-সাহিত্য সম্পাদক",
  "তথ্য ও গবেষণা সম্পাদক", "সহ-তথ্য ও গবেষণা সম্পাদক",
  "ত্রাণ ও দুর্যোগ সম্পাদক", "সিনিয়র ত্রাণ ও দুর্যোগ সম্পাদক",
  "সহ-ত্রাণ ও দুর্যোগ সম্পাদক", "কার্যকরী সদস্য",
];

int _posIndex(String? pos) {
  if (pos == null) return _kCommitteeOrder.length;
  final i = _kCommitteeOrder.indexOf(pos);
  return i == -1 ? _kCommitteeOrder.length : i;
}

String? _advisorType(ProfileModel p) {
  try { return (p as dynamic).advisorType as String?; } catch (_) { return null; }
}

int _advisorPriority(ProfileModel p) {
  final t = _advisorType(p);
  if (t == 'chief_advisor') return 0;
  if (t == 'advisor') return 1;
  return 2;
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {

  // ─── Services ─────────────────────────────────────────────────────────────
  final _supabase       = Supabase.instance.client;
  final _bannerService  = BannerService();
  final _aboutService   = AboutService();
  final _galleryService = GalleryService();
  final _videoService   = VideoService();
  final _feedService    = FeedService();
  final _profileService = ProfileService();

  // ─── Data ─────────────────────────────────────────────────────────────────
  List<BannerModel>          _banners           = [];
  List<Notice>               _recentNotices     = [];
  List<Map<String, dynamic>> _upcomingEvents    = [];
  List<Map<String, dynamic>> _pastEvents        = [];
  List<ProfileModel>         _leaders           = [];
  List<ProfileModel>         _advisors          = [];
  List<ProfileModel>         _pastCommittee     = [];
  List<GalleryImage>         _recentImages      = [];
  List<Video>                _recentVideos      = [];
  ContactInfo?               _contactInfo;
  AboutOverview?             overview;
  int                        _totalDonors       = 0;
  int                        _readyDonors       = 0;
  List<Map<String, dynamic>> _emergencyRequests = [];

  // ─── Loading States ───────────────────────────────────────────────────────
  bool _initialLoadDone     = false;
  bool _isLoadingBanners    = true;
  bool _isLoadingNotices    = true;
  bool _isLoadingEvents     = true;
  bool _isLoadingAboutData  = true;
  bool _isLoadingGallery    = true;
  bool _isLoadingVideos     = true;
  bool _isLoadingMembers    = true;
  bool _isLoadingBloodStats = true;
  bool _isLoadingEmergency  = true;

  // ─── Connectivity ─────────────────────────────────────────────────────────
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  // ─── Animations ───────────────────────────────────────────────────────────
  late AnimationController _fadeController;
  late AnimationController _emergencyPulseController;
  late AnimationController _offlineBannerController;

  // ── AI button animation ────────────────────────────────────────────────────
  late AnimationController _aiGlowController;

  // ─── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 0,
    );

    _emergencyPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _offlineBannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // AI button glow animation
    _aiGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initConnectivity();
      await _loadCachedDataFirst();
      if (mounted) {
        setState(() => _initialLoadDone = true);
        _fadeController.forward(from: 0);
      }
      _loadDashboardData(showFadeAnimation: false);
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _fadeController.dispose();
    _emergencyPulseController.dispose();
    _offlineBannerController.dispose();
    _aiGlowController.dispose();
    super.dispose();
  }

  // ─── Connectivity ─────────────────────────────────────────────────────────
  Future<void> _initConnectivity() async {
    final connectivity = Connectivity();
    final results = await connectivity.checkConnectivity();
    _applyConnectivityResults(results, animate: false);
    _connectivitySub = connectivity.onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline;
      _applyConnectivityResults(results);
      if (!wasOnline && _isOnline) _onConnectionRestored();
    });
  }

  void _applyConnectivityResults(
      List<ConnectivityResult> results, {bool animate = true}) {
    final online = results.any((r) =>
    r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);
    if (!mounted) return;
    setState(() => _isOnline = online);
    if (animate) {
      if (!online) {
        _offlineBannerController.forward();
      } else {
        _offlineBannerController.reverse();
      }
    } else {
      _offlineBannerController.value = online ? 0.0 : 1.0;
    }
  }

  void _onConnectionRestored() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.wifi_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text(SC.tr('backOnline'),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ]),
        backgroundColor: const Color(0xFF00C853),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _loadDashboardData(showFadeAnimation: false);
    });
  }

  // ─── Cache ────────────────────────────────────────────────────────────────
  Future<void> _loadCachedDataFirst() async {
    final prefs = await SharedPreferences.getInstance();

    List<Notice>               notices    = [];
    List<Map<String, dynamic>> upcoming   = [];
    List<Map<String, dynamic>> past       = [];
    int                        total      = 0;
    int                        ready      = 0;
    List<Map<String, dynamic>> emergency  = [];
    AboutOverview?             ov;

    final cachedNotices = prefs.getString(_kCacheNotices);
    if (cachedNotices != null) {
      try {
        final List decoded = jsonDecode(cachedNotices);
        notices = decoded.map((e) => Notice.fromMap(e)).toList();
      } catch (_) {}
    }

    final cachedEvents = prefs.getString(_kCacheEvents);
    if (cachedEvents != null) {
      try {
        final Map decoded = jsonDecode(cachedEvents);
        final all = List<Map<String, dynamic>>.from(decoded['all'] ?? []);
        final now = DateTime.now();
        upcoming = all.where((e) => DateTime.parse(e['start_datetime']).isAfter(now)).toList();
        past = all.where((e) => DateTime.parse(e['start_datetime']).isBefore(now)).toList().reversed.toList();
      } catch (_) {}
    }

    total = prefs.getInt(_kCacheBloodTotal) ?? 0;
    ready = prefs.getInt(_kCacheBloodReady) ?? 0;

    final cachedEmergency = prefs.getString(_kCacheEmergency);
    if (cachedEmergency != null) {
      try {
        final List decoded = jsonDecode(cachedEmergency);
        emergency = List<Map<String, dynamic>>.from(decoded);
      } catch (_) {}
    }

    final cachedOverview = prefs.getString(_kCacheOverview);
    if (cachedOverview != null) {
      try {
        ov = AboutOverview.fromJson(jsonDecode(cachedOverview) as Map<String, dynamic>);
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _recentNotices     = notices;
        _upcomingEvents    = upcoming;
        _pastEvents        = past;
        _totalDonors       = total;
        _readyDonors       = ready;
        _emergencyRequests = emergency;
        overview           = ov;

        if (notices.isNotEmpty)  _isLoadingNotices    = false;
        if (upcoming.isNotEmpty || past.isNotEmpty) _isLoadingEvents = false;
        if (total > 0)           _isLoadingBloodStats = false;
        if (emergency.isNotEmpty) _isLoadingEmergency = false;
        if (ov != null)          _isLoadingAboutData  = false;
      });
    }
  }

  // ─── Main Data Loader ─────────────────────────────────────────────────────
  Future<void> _loadDashboardData({bool showFadeAnimation = true}) async {
    if (!_isOnline) return;

    await Future.wait([
      _loadBanners(),
      _loadRecentNotices(),
      _loadEvents(),
      _loadEmergencyRequests(),
      _loadBloodStats(),
    ]);

    await Future.wait([
      _loadAboutData(),
      _loadGallery(),
      _loadVideos(),
      _loadMembers(),
    ]);

    if (mounted && showFadeAnimation) {
      _fadeController.forward(from: 0);
    }
  }

  // ─── Individual Loaders ───────────────────────────────────────────────────
  Future<void> _loadEmergencyRequests() async {
    try {
      final data = await _supabase
          .from('emergency_blood_requests')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(5);
      final list  = List<Map<String, dynamic>>.from(data);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCacheEmergency, jsonEncode(list));
      if (mounted) setState(() {
        _emergencyRequests  = list;
        _isLoadingEmergency = false;
      });
    } catch (e) {
      debugPrint('Emergency requests error: $e');
      if (mounted) setState(() => _isLoadingEmergency = false);
    }
  }

  Future<void> _loadBloodStats() async {
    try {
      final data = await _supabase
          .from('profiles')
          .select('donation_eligibility')
          .eq('account_status', 'active');
      final total = data.length;
      final ready = data.where((u) {
        final e = (u['donation_eligibility'] ?? '').toString().toLowerCase();
        return e == 'eligible' || e == 'ready';
      }).length;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kCacheBloodTotal, total);
      await prefs.setInt(_kCacheBloodReady, ready);
      if (mounted) setState(() {
        _totalDonors         = total;
        _readyDonors         = ready;
        _isLoadingBloodStats = false;
      });
    } catch (e) {
      debugPrint('Blood stats error: $e');
      if (mounted) setState(() => _isLoadingBloodStats = false);
    }
  }

  Future<void> _loadMembers() async {
    try {
      final results = await Future.wait([
        _profileService.getPresentCommittee(),
        _profileService.getAdvisors(),
        _profileService.getPreviousCommittee(),
      ]);
      final leaders = List<ProfileModel>.from(results[0])
        ..sort((a, b) => _posIndex(a.committeePosition)
            .compareTo(_posIndex(b.committeePosition)));
      final advisors = List<ProfileModel>.from(results[1])
        ..sort((a, b) => _advisorPriority(a).compareTo(_advisorPriority(b)));
      final pastCommittee = List<ProfileModel>.from(results[2])
        ..sort((a, b) =>
            _posIndex(a.previousPosition ?? a.committeePosition)
                .compareTo(_posIndex(b.previousPosition ?? b.committeePosition)));
      if (mounted) setState(() {
        _leaders       = leaders;
        _advisors      = advisors;
        _pastCommittee = pastCommittee;
        _isLoadingMembers = false;
      });
    } catch (e) {
      debugPrint('Members load error: $e');
      if (mounted) setState(() => _isLoadingMembers = false);
    }
  }

  Future<void> _loadAboutData() async {
    try {
      final data            = await _aboutService.getAllAboutData();
      final fetchedOverview = data['overview'] as AboutOverview?;
      if (fetchedOverview != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kCacheOverview, jsonEncode(fetchedOverview.toJson()));
      }
      if (mounted) setState(() {
        overview            = fetchedOverview;
        _contactInfo        = data['contact'] as ContactInfo?;
        _isLoadingAboutData = false;
      });
    } catch (e) {
      debugPrint('About data error: $e');
      if (mounted) setState(() => _isLoadingAboutData = false);
    }
  }

  Future<void> _loadGallery() async {
    try {
      final images = await _galleryService.fetchGallery();
      if (mounted) setState(() {
        _recentImages    = images.take(6).toList();
        _isLoadingGallery = false;
      });
    } catch (e) {
      debugPrint('Gallery error: $e');
      if (mounted) setState(() => _isLoadingGallery = false);
    }
  }

  Future<void> _loadVideos() async {
    try {
      final fetchedVideos = await _videoService.fetchVideos();
      if (mounted) setState(() {
        _recentVideos    = fetchedVideos.take(4).toList();
        _isLoadingVideos = false;
      });
    } catch (e) {
      debugPrint('Video load error: $e');
      if (mounted) setState(() => _isLoadingVideos = false);
    }
  }

  Future<void> _loadBanners() async {
    try {
      final fetchedBanners = await _bannerService.fetchBanners();
      if (mounted) setState(() {
        _banners          = fetchedBanners;
        _isLoadingBanners = false;
      });
    } catch (e) {
      debugPrint('Banners error: $e');
      if (mounted) setState(() => _isLoadingBanners = false);
    }
  }

  Future<void> _loadRecentNotices() async {
    try {
      final data = await _supabase
          .from('notices')
          .select()
          .order('publish_date', ascending: false)
          .limit(3);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCacheNotices, jsonEncode(data));
      if (mounted) setState(() {
        _recentNotices    = (data as List).map((e) => Notice.fromMap(e)).toList();
        _isLoadingNotices = false;
      });
    } catch (e) {
      debugPrint('Notices error: $e');
      if (mounted) setState(() => _isLoadingNotices = false);
    }
  }

  Future<void> _loadEvents() async {
    try {
      final res = await _supabase
          .from('events')
          .select()
          .eq('is_published', true)
          .order('start_datetime', ascending: true);
      final all = List<Map<String, dynamic>>.from(res);
      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCacheEvents, jsonEncode({'all': all}));
      if (mounted) setState(() {
        _upcomingEvents  = all
            .where((e) => DateTime.parse(e['start_datetime']).isAfter(now))
            .toList();
        _pastEvents      = all
            .where((e) => DateTime.parse(e['start_datetime']).isBefore(now))
            .toList()
            .reversed
            .toList();
        _isLoadingEvents = false;
      });
    } catch (e) {
      debugPrint('Events error: $e');
      if (mounted) setState(() => _isLoadingEvents = false);
    }
  }

  // ─── Navigation ───────────────────────────────────────────────────────────
  void _navigateToEventDetails(int eventId) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => EventDetailsPage(eventId: eventId)));
  }

  void _navigateToPersonDetails(
      ProfileModel person, String? imageUrl, Color color) {
    String categoryName = "সদস্য";
    if (person.memberType == 'present_committee') {
      categoryName = "বর্তমান কমিটি সদস্য";
    } else if (person.memberType == 'advisor') {
      final aType = _advisorType(person);
      categoryName = aType == 'chief_advisor'
          ? "প্রধান উপদেষ্টা (Chief Advisor)"
          : "উপদেষ্টা (Advisor)";
    } else if (person.memberType == 'previous_committee') {
      categoryName = "প্রাক্তন কমিটি সদস্য";
    }

    final heroTag = person.memberType == 'present_committee'
        ? 'committee_${person.id}'
        : person.memberType == 'advisor'
        ? 'advisor_${person.id}'
        : 'previous_${person.id}';

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PersonDetailsPage(
          category: categoryName,
          heroTag: heroTag,
          name: person.fullName ?? 'Member',
          role: person.committeePosition ??
              person.previousPosition ??
              person.designation ?? 'Member',
          imageUrl: imageUrl,
          message: person.presentCommitteeNote ??
              person.advisorNote ?? person.previousCommitteeNote,
          bio: person.shortBio,
          presentAddress: person.presentAddress,
          bloodGroup: person.bloodGroup,
          locationDms: person.locationDms,
          schoolName: person.schoolName,
          schoolGroup: person.schoolGroup,
          schoolPassingYear: person.schoolPassingYear,
          collegeName: person.collegeName,
          collegeGroup: person.collegeGroup,
          collegePassingYear: person.collegePassingYear,
          universityName: person.universityName,
          department: person.department,
          currentYear: person.currentYear,
          currentSemester: person.currentSemester,
          themeColor: color,
          visibility: person.visibility ?? 'public',
          isOwner: currentUserId == person.id,
        ),
      ),
    );
  }

  // ─── Pull to Refresh ──────────────────────────────────────────────────────
  Future<void> _onRefresh() async {
    if (!_isOnline) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(SC.tr('offlineCache'),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ]),
          backgroundColor: const Color(0xFFE53935),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(12),
        ),
      );
      return;
    }
    await _loadDashboardData(showFadeAnimation: false);
  }

  // ─── Build ────────────────────────────────────────────────────────────────
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
    final isDark    = SC.isDark;
    final bgColor   = isDark ? SC.bgStart : const Color(0xFFF0F4FF);
    final accentCol = isDark ? Colors.cyanAccent : SC.blue;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,

        // ── AI Floating Button ─────────────────────────────────────────────
        floatingActionButton: _buildAiFloatingButton(isDark),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

        body: SafeArea(
          child: Stack(
            children: [
              if (isDark) const BackgroundOrbs(),

              Column(
                children: [
                  // ── Offline Banner ─────────────────────────────────────
                  OfflineBannerWidget(
                    controller: _offlineBannerController,
                    onRetry:    _loadDashboardData,
                  ),

                  Expanded(
                    child: RefreshIndicator(
                      onRefresh:       _onRefresh,
                      color:           accentCol,
                      backgroundColor: isDark
                          ? const Color(0xFF203A43)
                          : Colors.white,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        slivers: [
                          SliverToBoxAdapter(
                            child: FadeTransition(
                              opacity: _fadeController,
                              child: _initialLoadDone
                                  ? _buildContent(isDark, accentCol)
                                  : const SizedBox.shrink(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── AI Floating Button ─────────────────────────────────────────────────────
  Widget _buildAiFloatingButton(bool isDark) {
    return AnimatedBuilder(
      animation: _aiGlowController,
      builder: (context, child) {
        final glowOpacity = 0.3 + (_aiGlowController.value * 0.4);

        return GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            AiChatPopup.show(context);
          },
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0xFF0091EA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: SC.cyan.withValues(alpha: glowOpacity),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ── Circular image with fallback ──────────────────────────
                ClipOval(
                  child: Image.asset(
                    'assets/images/css_chat_icon.png',
                    width: 58,
                    height: 58,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),

                // ── Pulse ring ────────────────────────────────────────────
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                // ── Animated outer glow ring ──────────────────────────────
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _aiGlowController,
                    builder: (_, __) {
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.cyanAccent.withValues(
                              alpha: _aiGlowController.value * 0.5,
                            ),
                            width: 2,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Content ──────────────────────────────────────────────────────────────
  Widget _buildContent(bool isDark, Color accentCol) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_isLoadingBanners && _banners.isNotEmpty)
          BannerSection(
            isLoading: false,
            banners:   _banners,
          ),

        if (_recentNotices.isNotEmpty)
          NoticeSection(
            isLoading:   false,
            notices:     _recentNotices,
            onViewAll:   () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NoticePage())),
            onNoticeTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NoticePage())),
          ),

        if (_emergencyRequests.isNotEmpty)
          EmergencyRequestsBannerWidget(
            emergencyRequests: _emergencyRequests,
            pulseController:   _emergencyPulseController,
            isDark:            isDark,
          ),

        if (_totalDonors > 0)
          BloodDashboardSectionWidget(
            isDark:      isDark,
            isLoading:   false,
            totalDonors: _totalDonors,
            readyDonors: _readyDonors,
          ),

        if (_upcomingEvents.isNotEmpty)
          EventsSection(
            title:      SC.tr('upcomingEvents'),
            events:     _upcomingEvents,
            titleColor: accentCol,
            isLoading:  false,
            onViewAll:  () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const EventsListPage())),
            onEventTap: _navigateToEventDetails,
          ),

        if (_pastEvents.isNotEmpty)
          EventsSection(
            title:      SC.tr('pastEvents'),
            events:     _pastEvents,
            titleColor: isDark ? Colors.white38 : const Color(0xFF9AA5B4),
            isLoading:  false,
            onViewAll:  () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const EventsListPage())),
            onEventTap: _navigateToEventDetails,
          ),

        if (!_isLoadingAboutData && overview != null)
          AboutSummarySectionWidget(
            isDark:   isDark,
            overview: overview,
          ),

        if (!_isLoadingMembers) ...[
          if (_leaders.isNotEmpty)
            PersonSection(
              title:       SC.tr('currentLeadership'),
              items:       _leaders,
              themeColor:  Colors.greenAccent,
              sectionType: PersonSectionType.committee,
              onPersonTap: (p, img, col) =>
                  _navigateToPersonDetails(p as ProfileModel, img, col),
            ),
          if (_advisors.isNotEmpty)
            PersonSection(
              title:       SC.tr('ourAdvisors'),
              items:       _advisors,
              themeColor:  Colors.amberAccent,
              sectionType: PersonSectionType.advisor,
              onPersonTap: (p, img, col) =>
                  _navigateToPersonDetails(p as ProfileModel, img, col),
            ),
          if (_pastCommittee.isNotEmpty)
            PersonSection(
              title:       SC.tr('pastCommittee'),
              items:       _pastCommittee,
              themeColor:  Colors.purpleAccent,
              sectionType: PersonSectionType.previous,
              onPersonTap: (p, img, col) =>
                  _navigateToPersonDetails(p as ProfileModel, img, col),
            ),
        ],

        if (!_isLoadingGallery && _recentImages.isNotEmpty)
          GalleryPreviewSection(
            isLoading: false,
            images:    _recentImages,
            onViewAll: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const GalleryPage())),
          ),

        if (!_isLoadingVideos && _recentVideos.isNotEmpty)
          VideoPreviewSection(
            isLoading:  false,
            videos:     _recentVideos,
            onViewAll:  () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const VideosPage())),
            onVideoTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const VideosPage())),
          ),

        const SizedBox(height: 5),
        const ComplaintDashboardCard(),
        const SizedBox(height: 0),

        FooterSection(contactInfo: _contactInfo),
        // Extra padding so content not hidden behind FAB
        const SizedBox(height: 80),
      ],
    );
  }
}
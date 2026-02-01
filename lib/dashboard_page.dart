import 'package:css/widgets/dashboard_post_section.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Services
import '../services/banner_service.dart';
import '../services/about_service.dart';
import '../services/gallery_service.dart';
import '../services/video_service.dart';
import '../services/feed_service.dart';

import '../widgets/post_preview_section.dart';
import '../pages/feed/feed_page.dart';


// Models
import '../models/banner_model.dart';
import '../models/notice_model.dart';
import '../models/about_models.dart';
import '../models/gallery_image_model.dart';
import '../models/video_model.dart';
import '../models/post_model.dart';

// Widgets
import '../widgets/banner_section.dart';
import '../widgets/notice_section.dart';
import '../widgets/gallery_preview_section.dart';
import '../widgets/video_preview_section.dart';
import '../widgets/events_section.dart';
import '../widgets/person_section.dart';
import '../widgets/footer_section.dart';
import '../widgets/background_orbs.dart';
import 'package:css/widgets/complaint_dashboard_card.dart';

// Pages
import 'package:css/pages/NoticePage/notice_page.dart';
import 'package:css/pages/Events/events_list_page.dart';
import 'package:css/pages/Events/event_details_page.dart';
import 'package:css/pages/About/person_details_page.dart';
import 'package:css/pages/Gallery/gallery_page.dart';
import 'package:css/pages/videos/videos_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _bannerService = BannerService();
  final _aboutService = AboutService();
  final _galleryService = GalleryService();
  final _videoService = VideoService();
  final _feedService = FeedService();



  // Data Holders
  List<BannerModel> _banners = [];
  List<Notice> _recentNotices = [];
  List<Map<String, dynamic>> _upcomingEvents = [];
  List<Map<String, dynamic>> _pastEvents = [];
  List<Advisor> _advisors = [];
  List<PreviousPresident> _presidents = [];
  List<Leadership> _leaders = [];
  List<GalleryImage> _recentImages = [];
  List<Video> _recentVideos = [];
  List<Post> _recentPosts = [];
  ContactInfo? _contactInfo;

  bool _isLoadingBanners = true;
  bool _isLoadingNotices = true;
  bool _isLoadingEvents = true;
  bool _isLoadingAboutData = true;
  bool _isLoadingGallery = true;
  bool _isLoadingVideos = true;
  bool _isLoadingPosts = true;

  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _loadDashboardData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    await Future.wait([
      _loadBanners(),
      _loadRecentNotices(),
      _loadEvents(),
      _loadAboutData(),
      _loadGallery(),
      _loadVideos(),
      _loadRecentPosts(),
    ]);
    if (mounted) _fadeController.forward(from: 0);
  }

  Future<void> _loadAboutData() async {
    setState(() => _isLoadingAboutData = true);
    try {
      final data = await _aboutService.getAllAboutData();
      if (mounted) {
        setState(() {
          _advisors = (data['advisors'] as List<Advisor>?) ?? [];
          _presidents =
              (data['previousPresidents'] as List<PreviousPresident>?) ?? [];
          _leaders = (data['leadership'] as List<Leadership>?) ?? [];
          _contactInfo = data['contact'] as ContactInfo?;
        });
      }
    } catch (e) {
      debugPrint('About data error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingAboutData = false);
    }
  }

  Future<void> _loadGallery() async {
    setState(() => _isLoadingGallery = true);
    try {
      final images = await _galleryService.fetchGallery();
      if (mounted) {
        setState(() {
          _recentImages = images.take(6).toList();
        });
      }
    } catch (e) {
      debugPrint('Gallery error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingGallery = false);
    }
  }

  Future<void> _loadVideos() async {
    setState(() => _isLoadingVideos = true);
    try {
      final fetchedVideos = await _videoService.fetchVideos();
      if (mounted) {
        setState(() {
          _recentVideos = fetchedVideos.take(4).toList();
          _isLoadingVideos = false;
        });
      }
    } catch (e) {
      debugPrint('Video load error: $e');
      if (mounted) setState(() => _isLoadingVideos = false);
    }
  }

  Future<void> _loadBanners() async {
    setState(() => _isLoadingBanners = true);
    try {
      final fetchedBanners = await _bannerService.fetchBanners();
      if (mounted) setState(() => _banners = fetchedBanners);
    } catch (e) {
      debugPrint('Banners error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingBanners = false);
    }
  }

  Future<void> _loadRecentNotices() async {
    setState(() => _isLoadingNotices = true);
    try {
      final data = await _supabase
          .from('notices')
          .select()
          .order('publish_date', ascending: false)
          .limit(3);

      if (mounted) {
        setState(() {
          _recentNotices =
              (data as List).map((e) => Notice.fromMap(e)).toList();
        });
      }
    } catch (e) {
      debugPrint('Notices error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingNotices = false);
    }
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoadingEvents = true);
    try {
      final res = await _supabase
          .from('events')
          .select()
          .eq('is_published', true)
          .order('start_datetime', ascending: true);

      final List<Map<String, dynamic>> allEvents =
      List<Map<String, dynamic>>.from(res);
      final now = DateTime.now();

      if (mounted) {
        setState(() {
          _upcomingEvents = allEvents
              .where((e) => DateTime.parse(e['start_datetime']).isAfter(now))
              .toList();
          _pastEvents = allEvents
              .where((e) => DateTime.parse(e['start_datetime']).isBefore(now))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Events error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingEvents = false);
    }
  }

  Future<void> _loadRecentPosts() async {
    setState(() => _isLoadingPosts = true);
    try {
      final posts = await _feedService.fetchPosts(limit: 3, offset: 0);
      if (mounted) {
        setState(() {
          _recentPosts = posts;
        });
      }
    } catch (e) {
      debugPrint('Posts error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingPosts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: Stack(
        children: [
          const BackgroundOrbs(),
          RefreshIndicator(
            onRefresh: _loadDashboardData,
            color: Colors.cyanAccent,
            backgroundColor: const Color(0xFF203A43),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Banner Section
                        BannerSection(
                          isLoading: _isLoadingBanners,
                          banners: _banners,
                        ),

                        // Notice Section
                        NoticeSection(
                          isLoading: _isLoadingNotices,
                          notices: _recentNotices,
                          onViewAll: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NoticePage(),
                            ),
                          ),
                          onNoticeTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NoticePage(),
                            ),
                          ),
                        ),

                        // Gallery Preview
                        GalleryPreviewSection(
                          isLoading: _isLoadingGallery,
                          images: _recentImages,
                          onViewAll: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const GalleryPage(),
                            ),
                          ),
                        ),



                        // dashboard_page.dart এর build method এর EventsSection অংশ:

// Upcoming Events
                        EventsSection(
                          title: "UPCOMING EVENTS",
                          events: _upcomingEvents,
                          titleColor: Colors.cyanAccent,
                          isLoading: _isLoadingEvents,
                          onViewAll: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EventsListPage(),
                            ),
                          ),
                          onEventTap: (eventId) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EventDetailsPage(eventId: eventId),
                              ),
                            );
                          },
                        ),

// Past Events
                        EventsSection(
                          title: "PAST EVENTS",
                          events: _pastEvents,
                          titleColor: Colors.white38,
                          isLoading: _isLoadingEvents,
                          onViewAll: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EventsListPage(),
                            ),
                          ),
                          onEventTap: (eventId) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EventDetailsPage(eventId: eventId),
                              ),
                            );
                          },
                        ),

                        // Person Sections
                        if (!_isLoadingAboutData) ...[
                          PersonSection(
                            title: "CURRENT LEADERSHIP",
                            items: _leaders,
                            themeColor: Colors.greenAccent,
                            onPersonTap: (person, imageUrl, color) =>
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PersonDetailsPage(
                                      name: person.name,
                                      role: person.role,
                                      imageUrl: imageUrl,
                                      message: person.message,
                                      bio: person.bio,
                                      themeColor: color,
                                    ),
                                  ),
                                ),
                          ),
                          PersonSection(
                            title: "OUR ADVISORS",
                            items: _advisors,
                            themeColor: Colors.amberAccent,
                            onPersonTap: (person, imageUrl, color) =>
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PersonDetailsPage(
                                      name: person.name,
                                      role: person.role,
                                      imageUrl: imageUrl,
                                      message: person.message,
                                      bio: person.bio,
                                      themeColor: color,
                                    ),
                                  ),
                                ),
                          ),
                          PersonSection(
                            title: "PREVIOUS PRESIDENTS",
                            items: _presidents,
                            themeColor: Colors.purpleAccent,
                            onPersonTap: (person, imageUrl, color) =>
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PersonDetailsPage(
                                      name: person.name,
                                      role: person.role,
                                      imageUrl: imageUrl,
                                      message: person.message,
                                      bio: person.bio,
                                      themeColor: color,
                                    ),
                                  ),
                                ),
                          ),
                        ],

                        // Video Preview
                        VideoPreviewSection(
                          isLoading: _isLoadingVideos,
                          videos: _recentVideos,
                          onViewAll: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const VideosPage(),
                            ),
                          ),
                          onVideoTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const VideosPage(),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        const ComplaintDashboardCard(),
                        const SizedBox(height: 20),
                        // Footer
                        FooterSection(contactInfo: _contactInfo),

                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
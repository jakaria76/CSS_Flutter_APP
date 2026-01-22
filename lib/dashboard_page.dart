import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// সঠিক পাথগুলো নিশ্চিত করুন
import '../services/banner_service.dart';
import '../services/about_service.dart';
import '../services/gallery_service.dart';
import '../services/video_service.dart';
import '../models/banner_model.dart';
import '../models/notice_model.dart';
import '../models/about_models.dart';
import '../models/gallery_image_model.dart';
import '../models/video_model.dart';
import '../widgets/banner_slider.dart';
import '../widgets/event_card.dart';
import 'package:css/pages/NoticePage/notice_page.dart';
import 'package:css/pages/Events/events_list_page.dart';
import 'package:css/pages/Events/event_details_page.dart';
import 'package:css/pages/About/person_details_page.dart';
import 'package:css/pages/Gallery/gallery_page.dart';
import 'package:css/pages/videos/videos_page.dart';
import 'package:url_launcher/url_launcher.dart';



// সোসাইটির লোকেশন কোঅর্ডিনেটস
const LatLng cssLocation = LatLng(24.069222, 89.801083);

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with TickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _bannerService = BannerService();
  final _aboutService = AboutService();
  final _galleryService = GalleryService();
  final _videoService = VideoService();

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
  ContactInfo? _contactInfo;

  bool _isLoadingBanners = true;
  bool _isLoadingNotices = true;
  bool _isLoadingEvents = true;
  bool _isLoadingAboutData = true;
  bool _isLoadingGallery = true;
  bool _isLoadingVideos = true;

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
          _presidents = (data['previousPresidents'] as List<PreviousPresident>?) ?? [];
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
          _recentNotices = (data as List).map((e) => Notice.fromMap(e)).toList();
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

      final List<Map<String, dynamic>> allEvents = List<Map<String, dynamic>>.from(res);
      final now = DateTime.now();

      if (mounted) {
        setState(() {
          _upcomingEvents = allEvents.where((e) => DateTime.parse(e['start_datetime']).isAfter(now)).toList();
          _pastEvents = allEvents.where((e) => DateTime.parse(e['start_datetime']).isBefore(now)).toList();
        });
      }
    } catch (e) {
      debugPrint('Events error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingEvents = false);
    }
  }

  // গুগল ম্যাপ অ্যাপ খোলার জন্য
  Future<void> _launchMaps() async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${cssLocation.latitude},${cssLocation.longitude}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: Stack(
        children: [
          _buildBackgroundOrbs(),
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
                        _buildBannerSection(),
                        _buildNoticeSection(),
                        _buildGalleryPreview(),
                        _buildVideoPreview(),
                        _buildEventsSection("UPCOMING EVENTS", _upcomingEvents, Colors.cyanAccent),
                        _buildEventsSection("PAST EVENTS", _pastEvents, Colors.white38),

                        if (!_isLoadingAboutData) ...[
                          _buildHorizontalPersonSection("CURRENT LEADERSHIP", _leaders, Colors.greenAccent),
                          _buildHorizontalPersonSection("OUR ADVISORS", _advisors, Colors.amberAccent),
                          _buildHorizontalPersonSection("PREVIOUS PRESIDENTS", _presidents, Colors.purpleAccent),
                        ],

                        _buildFooterSection(),
                        const SizedBox(height: 100),
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

  // --- Background Design ---
  Widget _buildBackgroundOrbs() {
    return Stack(
      children: [
        Positioned(top: 200, left: -50, child: _orb(300, Colors.cyanAccent.withOpacity(0.05))),
        Positioned(bottom: 100, right: -50, child: _orb(400, Colors.purpleAccent.withOpacity(0.05))),
      ],
    );
  }

  Widget _orb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 50)]
    ),
  );

  // --- Banner Section ---
  Widget _buildBannerSection() {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 10))]
      ),
      child: _isLoadingBanners ? _buildGlassLoader() : _banners.isEmpty ? _buildEmptyBanner() : _buildPremiumSlider(),
    );
  }

  Widget _buildGlassLoader() => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 2));

  Widget _buildEmptyBanner() => Container(
      color: Colors.white.withOpacity(0.02),
      child: const Center(child: Text('কোনো আপডেট পাওয়া যায়নি', style: TextStyle(color: Colors.white24, letterSpacing: 1.2)))
  );

  Widget _buildPremiumSlider() => BannerSlider(
      banners: _banners,
      height: 280,
      autoPlay: true,
      autoPlayInterval: const Duration(seconds: 5),
      showIndicator: true
  );

  // --- Gallery Preview Section ---
  Widget _buildGalleryPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("স্মৃতির অ্যালবাম",
                  style: TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              if (_recentImages.isNotEmpty)
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GalleryPage())),
                  child: const Text("সব দেখুন", style: TextStyle(color: Colors.white38, fontSize: 11)),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 150,
          child: _isLoadingGallery
              ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 1))
              : ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: _recentImages.length,
            itemBuilder: (context, index) {
              final image = _recentImages[index];
              return Container(
                width: 140,
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8)],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CachedNetworkImage(
                    imageUrl: image.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.white10),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Video Preview Section ---
  Widget _buildVideoPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("ভিডিও গ্যালারি",
                  style: TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VideosPage())),
                child: const Text("সব দেখুন", style: TextStyle(color: Colors.white38, fontSize: 11)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: _isLoadingVideos
              ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 1))
              : ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: _recentVideos.length,
            itemBuilder: (context, index) {
              final video = _recentVideos[index];
              final videoId = YoutubePlayer.convertUrlToId(video.youtubeUrl);
              final thumbnailUrl = videoId != null ? 'https://img.youtube.com/vi/$videoId/mqdefault.jpg' : '';

              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VideosPage())),
                child: Container(
                  width: 200,
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8)],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(imageUrl: thumbnailUrl, fit: BoxFit.cover),
                        Container(color: Colors.black.withOpacity(0.4)),
                        const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.cyanAccent, size: 40)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Notice Section ---
  Widget _buildNoticeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("সর্বশেষ বিজ্ঞপ্তি",
                  style: TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              if (_recentNotices.isNotEmpty)
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NoticePage())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                    child: const Text("সব দেখুন", style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 190,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05))
            ),
            child: _isLoadingNotices
                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent)))
                : _recentNotices.isEmpty
                ? const Center(child: Text("কোনো বিজ্ঞপ্তি নেই", style: TextStyle(color: Colors.white24, fontSize: 12)))
                : ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: _recentNotices.length,
                itemBuilder: (context, index) {
                  final notice = _recentNotices[index];
                  return _ActivityTile(
                    icon: Icons.campaign_rounded,
                    title: notice.title,
                    subtitle: "${notice.publishDate.day}/${notice.publishDate.month}/${notice.publishDate.year}",
                    time: index == 0 ? "NEW" : "",
                    iconColor: index % 2 == 0 ? Colors.orangeAccent : Colors.cyanAccent,
                    hasPdf: notice.pdfUrl != null && notice.pdfUrl!.isNotEmpty,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NoticePage())),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Events Section ---
  Widget _buildEventsSection(String title, List<Map<String, dynamic>> eventList, Color titleColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(color: titleColor, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                if (eventList.isNotEmpty)
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EventsListPage())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                      child: const Text("সব দেখুন", style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
          if (_isLoadingEvents)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 1)))
          else if (eventList.isEmpty)
            _buildEmptyEventPlaceholder()
          else
            SizedBox(
              height: 320,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15, top: 5),
                itemCount: eventList.length,
                itemBuilder: (context, index) {
                  final event = eventList[index];
                  final bool past = _isPastEvent(event['start_datetime']);
                  return Container(
                    width: 280,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: _buildGlassEventWrapper(event, past),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGlassEventWrapper(Map<String, dynamic> event, bool past) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: EventCard(
            event: event,
            isPast: past,
            onTap: past ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailsPage(eventId: event['id']))),
          ),
        ),
      ),
    );
  }

  bool _isPastEvent(String? startDate) {
    if (startDate == null) return false;
    final start = DateTime.parse(startDate).toLocal();
    return start.isBefore(DateTime.now());
  }

  Widget _buildEmptyEventPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: const Center(child: Text("No events found", style: TextStyle(color: Colors.white10, fontSize: 12))),
      ),
    );
  }

  // --- Leadership/About Section ---
  Widget _buildHorizontalPersonSection(String title, List<dynamic> items, Color themeColor) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 25, 20, 12),
          child: Row(
            children: [
              Container(
                width: 4, height: 18,
                decoration: BoxDecoration(color: themeColor, borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: themeColor.withOpacity(0.5), blurRadius: 5)]),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length,
            itemBuilder: (context, index) => _buildModernRectangleCard(items[index], themeColor),
          ),
        ),
      ],
    );
  }

  Widget _buildModernRectangleCard(dynamic person, Color themeColor) {
    String? imageUrl;
    try {
      if (person.imageUrl != null && person.imageUrl!.isNotEmpty) {
        imageUrl = _supabase.storage.from('about').getPublicUrl(person.imageUrl!);
      }
    } catch (e) {
      debugPrint("Image URL error: $e");
    }

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => PersonDetailsPage(
          name: person.name, role: person.role, imageUrl: imageUrl,
          message: person.message, bio: person.bio, themeColor: themeColor,
        ),
      )),
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.09)),
        ),
        child: Column(
          children: [
            Hero(
              tag: person.name,
              child: Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: themeColor.withOpacity(0.2), width: 1.5),
                  boxShadow: [BoxShadow(color: themeColor.withOpacity(0.1), blurRadius: 10, spreadRadius: 1)],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: imageUrl != null
                      ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)
                      : Container(color: const Color(0xFF1A2332), child: Icon(Icons.person, color: themeColor.withOpacity(0.4), size: 35)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(person.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(person.role, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: themeColor.withOpacity(0.9), fontSize: 8, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // --- Footer Section (Contact Info with Premium Google Map) ---
  Widget _buildFooterSection() {
    if (_contactInfo == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 50, 20, 30),
      child: Column(
        children: [
          // ================= PREMIUM GOOGLE MAP CARD =================
          Container(
            height: 200,
            margin: const EdgeInsets.only(bottom: 30),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 35,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Stack(
                children: [
                  /// GOOGLE MAP PREVIEW
                  GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: cssLocation,
                      zoom: 16,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('css_main_loc'),
                        position: cssLocation,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueCyan,
                        ),
                      ),
                    },
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    compassEnabled: false,
                    mapToolbarEnabled: false,
                    tiltGesturesEnabled: false,
                    rotateGesturesEnabled: false,
                  ),

                  /// DARK GRADIENT OVERLAY
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),

                  /// VIEW ON GOOGLE MAPS BUTTON
                  Positioned(
                    bottom: 15,
                    left: 15,
                    child: GestureDetector(
                      onTap: _launchMaps,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F2027).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.cyanAccent.withOpacity(0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withOpacity(0.25),
                              blurRadius: 18,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.cyanAccent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.location_on,
                                size: 14,
                                color: Color(0xFF0F2027),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              "VIEW ON GOOGLE MAPS",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ================= GLASS CONTACT CARD =================
          ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.035),
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.07),
                  ),
                ),
                child: Column(
                  children: [
                    /// HEADER
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const CircleAvatar(
                            radius: 22,
                            backgroundImage:
                            AssetImage('assets/images/csslogo.jpg'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Conscious Student Society",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Building Leaders • Inspiring Change",
                                style: TextStyle(
                                  color: Colors.cyanAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 26),
                      child: Divider(color: Colors.white12),
                    ),

                    _footerItem(
                      Icons.map_outlined,
                      _contactInfo!.address,
                      "OUR LOCATION",
                      Colors.orangeAccent,
                    ),
                    _footerItem(
                      Icons.phone_iphone_rounded,
                      _contactInfo!.phone,
                      "CALL US",
                      Colors.greenAccent,
                    ),
                    _footerItem(
                      Icons.alternate_email_rounded,
                      _contactInfo!.email,
                      "EMAIL SUPPORT",
                      Colors.cyanAccent,
                    ),

                    const SizedBox(height: 28),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _socialIcon(Icons.facebook, Colors.blue),
                        _socialIcon(Icons.language, Colors.cyanAccent),
                        _socialIcon(
                            Icons.play_circle_fill, Colors.redAccent),
                      ],
                    ),

                    const SizedBox(height: 32),

                    const Text(
                      "© 2026 CONSCIOUS STUDENT SOCIETY",
                      style: TextStyle(
                        color: Colors.white12,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _footerItem(IconData icon, String text, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: color.withOpacity(0.55), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
                const SizedBox(height: 5),
                Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialIcon(IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

// --- Activity Tile Widget ---
class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle, time;
  final Color iconColor;
  final VoidCallback? onTap;
  final bool hasPdf;

  const _ActivityTile({
    super.key, required this.icon, required this.title, required this.subtitle,
    required this.time, required this.iconColor, this.onTap, this.hasPdf = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
              if (hasPdf)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent.withOpacity(0.8), size: 20),
                ),
              if (time.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                  child: Text(time, style: TextStyle(color: (time == "NEW") ? Colors.orangeAccent : Colors.white38, fontSize: 9, fontWeight: FontWeight.w900)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
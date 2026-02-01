import 'dart:ui';
import 'package:css/pages/feed/Posts%20Management%20Page.dart';
import 'package:css/pages/feed/create_post_page.dart';
import 'package:css/pages/feed/ManagePostPage.dart';// ✅ Updated import
import 'package:css/pages/feed/Posts Management Page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

// উইজেটস ইম্পোর্ট
import 'package:css/widgets/custom_app_bar.dart';
import 'package:css/widgets/custom_drawer.dart';
import 'package:css/widgets/custom_bottom_navigation.dart';

// সার্ভিস ও পেজ ইম্পোর্ট
import 'package:css/services/notification_service.dart';
import 'package:css/dashboard_page.dart';
import 'package:css/pages/Profile/profile_page.dart';
import 'package:css/pages/feed/feed_page.dart';

// অন্যান্য পেজ ইম্পোর্ট
import 'package:css/pages/Blood/blood_groups_page.dart';
import 'package:css/pages/events/events_list_page.dart';
import 'package:css/pages/NoticePage/notice_page.dart';
import 'package:css/pages/CommitteePage/committee_page.dart';
import 'package:css/pages/About/about_page.dart';
import 'package:css/pages/Gallery/gallery_page.dart';
import 'package:css/pages/videos/videos_page.dart';
import 'package:css/pages/complaints/my_complaints_page.dart';

// অ্যাডমিন পেজ ইম্পোর্ট
import 'package:css/pages/NoticePage/notice_management_page.dart';
import 'package:css/pages/CommitteePage/manage_committee_page.dart';
import 'package:css/pages/About/ManageAboutPage.dart';
import 'package:css/pages/events/admin_events_page.dart';
import 'package:css/pages/events/create_event_page.dart';
import 'package:css/pages/Gallery/gallery_management_page.dart';
import 'package:css/pages/videos/video_management_page.dart';
import 'package:css/pages/complaints/admin_complaints_page.dart';

class MemberHome extends StatefulWidget {
  final bool isGuest;
  const MemberHome({super.key, required this.isGuest});

  @override
  State<MemberHome> createState() => _MemberHomeState();
}

class _MemberHomeState extends State<MemberHome> with TickerProviderStateMixin {
  int selectedIndex = 0;
  int _page = 0;

  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey<CurvedNavigationBarState>();

  String? userName;
  String? userEmail;
  String? profileImageUrl;
  bool loadingProfile = true;
  bool isUserAdmin = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    if (!widget.isGuest) {
      await NotificationService.init();
      await NotificationService.initAndSaveToken();
      NotificationService.listenForeground();
      NotificationService.listenClick();
      await _loadProfile();
    } else {
      if (mounted) {
        setState(() {
          userName = 'Guest User';
          userEmail = 'Limited Access';
          loadingProfile = false;
          isUserAdmin = false;
        });
      }
    }
  }

  Future<void> _loadProfile() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    try {
      final data = await client
          .from('profiles')
          .select('full_name, profile_image_url, role')
          .eq('id', user.id)
          .maybeSingle();
      if (mounted) {
        setState(() {
          userName = data?['full_name'] ?? 'User';
          userEmail = user.email;
          profileImageUrl = data?['profile_image_url'];
          isUserAdmin = data?['role'] == 'admin';
          loadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loadingProfile = false);
    }
  }

  void _handleMenuTap(int index) {
    setState(() {
      selectedIndex = index;
    });

    HapticFeedback.lightImpact();

    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) Navigator.pop(context);

      if (index >= 0 && index <= 3) {
        setState(() {
          _page = index;
          _bottomNavigationKey.currentState?.setPage(index);
        });
      } else {
        Widget? nextRoute;
        switch (index) {
          case 4:
            nextRoute = const EventsListPage();
            break;
          case 5:
            nextRoute = const NoticePage();
            break;
          case 6:
            nextRoute = const CommitteePage();
            break;
          case 7:
            nextRoute = const AboutPage();
            break;
          case 18:
            nextRoute = const GalleryPage();
            break;
          case 20:
            nextRoute = const VideosPage();
            break;
          case 22:
            nextRoute = const MyComplaintsPage();
            break;
          case 8:
            nextRoute = const NoticeManagementPage();
            break;
          case 9:
            nextRoute = const ManageCommitteePage();
            break;
          case 10:
            nextRoute = const ManageAboutPage();
            break;
          case 11:
            nextRoute = const AdminEventsPage();
            break;
          case 12:
            nextRoute = const CreateEventPage();
            break;
          case 19:
            nextRoute = const GalleryManagementPage();
            break;
          case 21:
            nextRoute = const VideoManagementPage();
            break;
          case 23:
            nextRoute = const AdminComplaintsPage();
            break;
          case 24:
            nextRoute = const PostsManagementPage(); // ✅ Posts Management Page
            break;
          default:
            return;
        }

        if (nextRoute != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => nextRoute!),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0F2027),
      appBar: const CustomAppBar(),
      drawer: CustomDrawer(
        selectedIndex: selectedIndex,
        onMenuTap: _handleMenuTap,
        userName: userName,
        userEmail: userEmail,
        profileImageUrl: profileImageUrl,
        isAdmin: isUserAdmin,
      ),
      body: Stack(
        children: [
          Positioned(
            top: -50,
            left: -50,
            child: _blurOrb(250, Colors.cyanAccent.withOpacity(0.08)),
          ),
          Positioned(
            bottom: 100,
            right: -30,
            child: _blurOrb(200, Colors.purpleAccent.withOpacity(0.05)),
          ),
          IndexedStack(
            index: _page,
            children: const [
              DashboardPage(),
              FeedPage(),
              BloodGroupsPage(),
              ProfilePage()
            ],
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentPage: _page,
        navigationKey: _bottomNavigationKey,
        onPageChanged: (index) {
          setState(() {
            _page = index;
            selectedIndex = index;
          });
        },
      ),
    );
  }

  Widget _blurOrb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      boxShadow: [
        BoxShadow(
          color: color,
          blurRadius: 100,
          spreadRadius: 50,
        )
      ],
    ),
  );
}
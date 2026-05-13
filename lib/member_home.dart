import 'dart:ui';
import 'package:css/pages/MemberManage/MemberManagementPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

// সেটিংস ও ইউটিলিটি
import 'package:css/pages/SettingsPage/settings_constants.dart';

// উইজেটস ইম্পোর্ট
import 'package:css/widgets/custom_app_bar.dart';
import 'package:css/widgets/custom_drawer.dart';
import 'package:css/widgets/custom_bottom_navigation.dart';

// সার্ভিস ও পেজ ইম্পোর্ট
import 'package:css/dashboard_page.dart';
import 'package:css/pages/Profile/profile_page.dart';
import 'package:css/pages/feed/feed_page.dart';
import 'package:css/pages/feed/Posts%20Management%20Page.dart';

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

import 'package:css/pages/PreviousPresidentPage/PreviousPresidentPage.dart';
import 'package:css/pages/PreviousPresidentPage/ManagePreviousPresidentPage.dart';

import 'package:css/pages/AdvisorPage/advisor_page.dart';
import 'package:css/pages/AdvisorPage/manage_advisor_page.dart';
import 'package:css/pages/Banner/banner_management_page.dart';

import 'package:css/pages/SettingsPage/settings_page.dart';

import 'package:css/pages/Constitution/constitution_page.dart';
import 'package:css/pages/Constitution/manage_constitution_page.dart';
class MemberHome extends StatefulWidget {
  final bool isGuest;
  const MemberHome({super.key, required this.isGuest});

  @override
  State<MemberHome> createState() => _MemberHomeState();
}

class _MemberHomeState extends State<MemberHome> with TickerProviderStateMixin {
  int selectedIndex = 0;
  int _page = 0;

  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey =
  GlobalKey<CurvedNavigationBarState>();

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
      await _loadProfile();
    } else {
      if (mounted) {
        setState(() {
          userName = SC.tr('guest_user');
          userEmail = SC.tr('limited_access');
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
          userName = data?['full_name'] ?? SC.tr('user_default_name');
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
    setState(() => selectedIndex = index);
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
          case 4: nextRoute = const EventsListPage(); break;
          case 5: nextRoute = const NoticePage(); break;
          case 6: nextRoute = const CommitteePage(); break;
          case 7: nextRoute = const AboutPage(); break;
          case 8: nextRoute = const NoticeManagementPage(); break;
          case 9: nextRoute = const ManageCommitteePage(); break;
          case 10: nextRoute = const ManageAboutPage(); break;
          case 11: nextRoute = const AdminEventsPage(); break;
          case 12: nextRoute = const CreateEventPage(); break;
          case 18: nextRoute = const GalleryPage(); break;
          case 19: nextRoute = const GalleryManagementPage(); break;
          case 20: nextRoute = const VideosPage(); break;
          case 21: nextRoute = const VideoManagementPage(); break;
          case 22: nextRoute = const MyComplaintsPage(); break;
          case 23: nextRoute = const AdminComplaintsPage(); break;
          case 24: nextRoute = const PostsManagementPage(); break;
          case 25: nextRoute = const PreviousPresidentPage(); break;
          case 26: nextRoute = const ManagePreviousPresidentPage(); break;
          case 27: nextRoute = const AdvisorPage(); break;
          case 28: nextRoute = const ManageAdvisorPage(); break;
          case 29: nextRoute = const BannerManagementPage(); break;
          case 30: nextRoute = const SettingsPage(); break;
          case 31: nextRoute = const MemberManagementPage(); break;
          case 32: nextRoute = const ConstitutionPage(); break;
          case 33: nextRoute = const ManageConstitutionPage(); break;
          default: return;
        }

        if (nextRoute != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => nextRoute!));
        }
      }
    });
  }

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
    final bgColor = isDark ? SC.bgStart : const Color(0xFFF0F4FF);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: bgColor,
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
            // থিম অনুযায়ী ব্যাকগ্রাউন্ড গ্রেডিয়েন্ট
            Container(decoration: BoxDecoration(gradient: SC.currentGradient)),

            // অরবস (Orbs)
            Positioned(
              top: -50,
              left: -50,
              child: SC.blob(250, SC.cyan.withOpacity(isDark ? 0.08 : 0.04)),
            ),
            Positioned(
              bottom: 100,
              right: -30,
              child: SC.blob(200, SC.purple.withOpacity(isDark ? 0.05 : 0.03)),
            ),

            // কন্টেন্ট স্ট্যাক
            IndexedStack(
              index: _page,
              children: const [
                DashboardPage(),
                FeedPage(),
                BloodGroupsPage(),
                ProfilePage(),
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
      ),
    );
  }
}
import 'dart:ui';
import 'package:css/pages/About/ManageAboutPage.dart';
import 'package:css/pages/CommitteePage/manage_committee_page.dart';
import 'package:css/pages/videos/video_management_page.dart';
import 'package:css/pages/videos/videos_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:css/pages/Gallery/gallery_page.dart';
import 'package:css/pages/Gallery/gallery_management_page.dart';

// আপনার নতুন তৈরি করা Committee Page ইম্পোর্ট করুন (পাথ ঠিক করে নিন)
import 'package:css/pages/CommitteePage/committee_page.dart';

// Notice Pages Import
import 'package:css/pages/NoticePage/notice_page.dart';
import 'package:css/pages/NoticePage/notice_management_page.dart';

// সার্ভিস ও পেজ ইম্পোর্ট
import 'package:css/services/notification_service.dart';
import 'package:css/pages/About/about_page.dart';
import 'package:css/dashboard_page.dart';
import 'package:css/list_page.dart';
import 'package:css/pages/Profile/profile_page.dart';
import 'package:css/pages/Blood/blood_groups_page.dart';
import 'package:css/pages/events/events_list_page.dart';
import 'package:css/pages/events/admin_events_page.dart';
import 'package:css/pages/events/create_event_page.dart';

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
        });
      }
    }
  }

  Future<void> _loadProfile() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    try {
      final data = await client.from('profiles').select('full_name, profile_image_url').eq('id', user.id).maybeSingle();
      if (mounted) {
        setState(() {
          userName = data?['full_name'] ?? 'User';
          userEmail = user.email;
          profileImageUrl = data?['profile_image_url'];
          loadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loadingProfile = false);
    }
  }



  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          title: const Text('LOGOUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          content: const Text('Are you sure you want to end your session?', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.white38))),
            Container(
              decoration: BoxDecoration(
                boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.3), blurRadius: 15)],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
                },
                child: const Text('LOGOUT', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0F2027),
      appBar: _buildAppBar(),
      drawer: _buildModernDrawer(),
      body: Stack(
        children: [
          Positioned(top: -50, left: -50, child: _blurOrb(250, Colors.cyanAccent.withOpacity(0.08))),
          Positioned(bottom: 100, right: -30, child: _blurOrb(200, Colors.purpleAccent.withOpacity(0.05))),

          IndexedStack(
            index: _page,
            children: const [DashboardPage(), ListPage(), ProfilePage()],
          ),
        ],
      ),
      bottomNavigationBar: _buildCurvedBottomNav(),
    );
  }

  Widget _blurOrb(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 50)]),
  );

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF132D46),
      elevation: 0,
      centerTitle: true,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: const Icon(Icons.menu_rounded, color: Colors.cyanAccent, size: 22),
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(colors: [Colors.white, Colors.cyanAccent]).createShader(bounds),
        child: const Text('CSS MOBILE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 18,color: Colors.cyanAccent,)),
      ),
    );
  }

  Widget _buildModernDrawer() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Drawer(
        backgroundColor: const Color(0xFF0F2027).withOpacity(0.8),
        child: Container(
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05))),
          ),
          child: Column(
            children: [
              _buildDrawerHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _sectionLabel('GENERAL MENU'),
                      _drawerButton(0, Icons.dashboard_rounded, 'Dashboard', Colors.cyanAccent),
                      _drawerButton(3, Icons.water_drop_rounded, 'Blood Groups', Colors.redAccent),
                      _drawerButton(4, Icons.event_note_rounded, 'Public Events', Colors.orangeAccent),
                      _drawerButton(5, Icons.notifications_active_rounded, 'Notices', Colors.pinkAccent),
                      _drawerButton(6, Icons.people_alt_rounded, 'Committee Members', Colors.indigoAccent),
                      _drawerButton(7, Icons.info_outline_rounded, 'About CSS', Colors.blueAccent),
                      _drawerButton(18, Icons.photo_library_rounded, 'Gallery', Colors.purpleAccent),
                      _drawerButton(20, Icons.play_circle_rounded, 'Videos', Colors.redAccent),


                      const SizedBox(height: 25),
                      _sectionLabel('ADMIN PANEL'),
                      _drawerButton(8, Icons.manage_search_rounded, 'Manage Notices', Colors.deepOrangeAccent),
                      _drawerButton(9, Icons.manage_accounts_rounded, 'Manage Committee', Colors.deepPurpleAccent),
                      _drawerButton(10, Icons.edit_note_rounded, 'Manage About', Colors.amberAccent),
                      _drawerButton(11, Icons.settings_suggest_rounded, 'Manage Events', Colors.tealAccent),
                      _drawerButton(12, Icons.add_box_rounded, 'Create Event', Colors.lightGreenAccent),
                      _drawerButton(19, Icons.photo_album_rounded, 'Manage Gallery', Colors.pinkAccent),
                      _drawerButton(21, Icons.video_settings_rounded, 'Video Management', Colors.deepOrange),
                    ],
                  ),
                ),
              ),
              _buildDrawerFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 70, 25, 30),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.purpleAccent]),
              boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 15)],
            ),
            child: const CircleAvatar(radius: 32, backgroundImage: AssetImage('assets/images/csslogo.jpg')),
          ),
          const SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CSS PANEL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5)),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.cyanAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                child: const Text('ADMINISTRATOR', style: TextStyle(color: Colors.cyanAccent, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: Colors.white.withOpacity(0.05), thickness: 1)),
        ],
      ),
    );
  }

  Widget _drawerButton(int index, IconData icon, String title, Color color) {
    final bool isSel = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        splashColor: color.withOpacity(0.12),
        highlightColor: Colors.transparent,
        onTap: () => _handleMenuTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),

            // Subtle glass background
            color: isSel
                ? Colors.white.withOpacity(0.045)
                : Colors.white.withOpacity(0.02),

            // Very light gradient when selected
            gradient: isSel
                ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.14),
                color.withOpacity(0.035),
              ],
            )
                : null,

            border: Border.all(
              color: isSel
                  ? color.withOpacity(0.35)
                  : Colors.white.withOpacity(0.05),
              width: 0.6,
            ),

            boxShadow: isSel
                ? [
              BoxShadow(
                color: color.withOpacity(0.12),
                blurRadius: 12,
                spreadRadius: 0.5,
              ),
            ]
                : [],
          ),
          child: Row(
            children: [
              // Icon box (slimmer)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isSel
                      ? color.withOpacity(0.12)
                      : Colors.white.withOpacity(0.025),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AnimatedScale(
                  scale: isSel ? 1.04 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    icon,
                    size: 17,
                    color: isSel ? color : Colors.white54,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // Title text
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  style: TextStyle(
                    color: isSel ? Colors.white : Colors.white70,
                    fontSize: 13.5,
                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.4,
                  ),
                  child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),

              // Slim right indicator
              AnimatedSlide(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                offset: isSel ? Offset.zero : const Offset(0.25, 0),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isSel ? 1 : 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.22),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_right_rounded,
                      size: 13,
                      color: color,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  void _handleMenuTap(int index) {
    // ইনডেক্স আপডেট করা হচ্ছে যাতে বাটন মার্ক হয়ে থাকে
    setState(() {
      selectedIndex = index;
    });

    HapticFeedback.mediumImpact();

    // ড্রয়ার বন্ধ করার আগে সামান্য ডিলে দেওয়া যেতে পারে যাতে ইউজার সিলেকশন ইফেক্ট দেখতে পায়
    Future.delayed(const Duration(milliseconds: 150), () {
      Navigator.pop(context);

      // পেজ রাউটিং লজিক
      if (index >= 0 && index <= 2) {
        setState(() {
          _page = index;
          _bottomNavigationKey.currentState?.setPage(index);
        });
      } else {
        Widget? nextRoute;
        switch (index) {
          case 3: nextRoute = const BloodGroupsPage(); break;
          case 4: nextRoute = const EventsListPage(); break;
          case 5: nextRoute = const NoticePage(); break;
          case 6: nextRoute = const CommitteePage(); break;
          case 7: nextRoute = const AboutPage(); break;
        // Admin Panel
          case 8: nextRoute = const NoticeManagementPage(); break;
          case 9: nextRoute = const ManageCommitteePage(); break;
          case 10: nextRoute = const ManageAboutPage(); break;
          case 11: nextRoute = const AdminEventsPage(); break;
          case 12: nextRoute = const CreateEventPage(); break;
          case 18: nextRoute = const GalleryPage(); break;
          case 19: nextRoute = const GalleryManagementPage(); break;
          case 20: nextRoute = const VideosPage(); break;
          case 21: nextRoute = const VideoManagementPage(); break;
          default: return;
        }

        if (nextRoute != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => nextRoute!));
        }
      }
    });
  }

  Widget _buildDrawerFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20), // নিচের দিকে একটু গ্যাপ রাখা হয়েছে
      decoration: BoxDecoration(
        // গ্লাস ইফেক্ট এবং হালকা ব্যাকগ্রাউন্ড
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // প্রোফাইল ইমেজ উইথ নিওন গ্লো
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.cyanAccent.withOpacity(0.5), Colors.purpleAccent.withOpacity(0.5)],
                  ),
                ),
              ),
              CircleAvatar(
                radius: 23,
                backgroundColor: const Color(0xFF0F2027),
                child: CircleAvatar(
                  radius: 21,
                  backgroundColor: Colors.white10,
                  backgroundImage: profileImageUrl != null
                      ? NetworkImage(profileImageUrl!)
                      : null,
                  child: profileImageUrl == null
                      ? const Icon(Icons.person_rounded, size: 22, color: Colors.cyanAccent)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // ইউজার ইনফরমেশন
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName ?? 'CSS User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  userEmail ?? 'member@css.org',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // লগআউট বাটন উইথ নিওন ইফেক্ট
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showLogoutDialog,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.redAccent.withOpacity(0.2),
                  ),
                ),
                child: const Icon(
                  Icons.power_settings_new_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurvedBottomNav() {
    return CurvedNavigationBar(
      key: _bottomNavigationKey,
      backgroundColor: Colors.transparent,
      color: const Color(0xFF132D46),
      buttonBackgroundColor: Colors.cyanAccent,
      height: 60,
      index: _page,
      items: const [
        Icon(Icons.dashboard_rounded, size: 30, color: Colors.white),
        Icon(Icons.list_alt_rounded, size: 30, color: Colors.white),
        Icon(Icons.person_rounded, size: 30, color: Colors.white),
      ],
      onTap: (index) {
        setState(() {
          _page = index;
          selectedIndex = index;
        });
      },
    );
  }
}
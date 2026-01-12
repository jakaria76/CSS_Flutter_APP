import 'package:css/pages/events/create_event_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

// সার্ভিস ইম্পোর্ট
import 'package:css/services/notification_service.dart';

// পেজ ইম্পোর্টস
import 'welcome_page.dart';
import 'dashboard_page.dart';
import 'list_page.dart';
import 'pages/Profile/profile_page.dart';
import 'package:css/pages/Blood/blood_groups_page.dart';
import 'package:css/pages/events/events_list_page.dart';
import 'package:css/pages/events/admin_events_page.dart';

class MemberHome extends StatefulWidget {
  final bool isGuest;
  const MemberHome({super.key, required this.isGuest});

  @override
  State<MemberHome> createState() => _MemberHomeState();
}

class _MemberHomeState extends State<MemberHome> {
  int selectedIndex = 0; // Drawer selection tracking
  int _page = 0;         // Bottom navigation selection tracking

  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey =
  GlobalKey<CurvedNavigationBarState>();

  String? userName;
  String? userEmail;
  String? profileImageUrl;
  bool loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  // ================= NOTIFICATION & PROFILE INIT =================
  Future<void> _initNotifications() async {
    if (!widget.isGuest) {
      await NotificationService.init();
      await NotificationService.initAndSaveToken();
      NotificationService.listenForeground();
      NotificationService.listenClick();
      _loadProfile();
    } else {
      if (mounted) {
        setState(() {
          userName = 'Guest User';
          userEmail = 'Guest';
          profileImageUrl = null;
          loadingProfile = false;
        });
      }
    }
  }

  // ================= LOAD PROFILE FROM SUPABASE =================
  Future<void> _loadProfile() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          loadingProfile = false;
          userName = 'User';
          userEmail = '';
        });
      }
      return;
    }

    try {
      final data = await client
          .from('profiles')
          .select('full_name, profile_image_url')
          .eq('id', user.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          userName = data?['full_name'] ?? user.userMetadata?['full_name'] ?? 'User';
          userEmail = user.email;
          profileImageUrl = data?['profile_image_url'];
          loadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          userName = user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? 'User';
          userEmail = user.email;
          loadingProfile = false;
        });
      }
    }
  }

  // ================= LOGOUT CONFIRMATION DIALOG =================
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF162E38),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Logout Confirmation',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to logout from your account?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.cyanAccent)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context);
                _logout();
              },
              child: const Text('Logout', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // ================= LOGOUT FUNCTION =================
  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomePage()),
            (_) => false,
      );
    }
  }

  // ================= MAIN PAGES =================
  Widget _buildPage() {
    return IndexedStack(
      index: _page,
      children: const [
        DashboardPage(),
        ListPage(),
        ProfilePage(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'CSS',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // ================= DRAWER =================
      drawer: Drawer(
        width: 300,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F2027), Color(0xFF162E38), Color(0xFF203A43)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // ===== HEADER =====
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
                  child: Row(
                    children: [
                      Container(
                        height: 52,
                        width: 52,
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.cyanAccent.withOpacity(0.6), width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/csslogo.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.business, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CSS DASHBOARD',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'MEMBER PANEL',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Divider(color: Colors.white24, height: 1),
                ),
                const SizedBox(height: 16),

                // ===== MENU ITEMS =====
                // index 0 = Dashboard (Sync with Bottom Nav)
                _menuItem(0, Icons.grid_view_rounded, 'Dashboard'),

                // index 1 = Blood Donation (Not in Bottom Nav, so separate routing)
                _menuItem(1, Icons.water_drop_rounded, 'Blood Donation'),

                // index 2 = Profile (Sync with Bottom Nav)
                _menuItem(2, Icons.manage_accounts_rounded, 'Profile'),

                _menuItem(11, Icons.event_note_rounded, 'Public Event List'),
                _menuItem(5, Icons.contacts_outlined, 'Contacts'),

                const Padding(
                  padding: EdgeInsets.fromLTRB(28, 32, 24, 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'EVENT MANAGEMENT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.cyanAccent,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                _menuItem(10, Icons.admin_panel_settings_rounded, 'Manage Events (Admin)'),
                _menuItem(9, Icons.add_circle_outline_rounded, 'Create New Event'),

                const Spacer(),

                // ===== PROFILE FOOTER =====
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: loadingProfile
                        ? const Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.cyanAccent),
                      ),
                    )
                        : Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF1A2A3A),
                          backgroundImage: profileImageUrl != null
                              ? NetworkImage(profileImageUrl!)
                              : null,
                          child: profileImageUrl == null
                              ? Text((userName ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold))
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName ?? 'Unknown',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                              ),
                              Text(
                                (userEmail ?? '').toLowerCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout_rounded,
                              color: Colors.redAccent, size: 22),
                          onPressed: widget.isGuest ? null : _showLogoutDialog,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      body: _buildPage(),

      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        backgroundColor: const Color(0xFFF4F6FB),
        color: const Color(0xFF1E40AF),
        buttonBackgroundColor: const Color(0xFF2563EB),
        height: 60,
        index: _page,
        items: const [
          Icon(Icons.dashboard, size: 30, color: Colors.white),
          Icon(Icons.list, size: 30, color: Colors.white),
          Icon(Icons.person, size: 30, color: Colors.white),
        ],
        onTap: (index) {
          setState(() {
            _page = index;
            selectedIndex = index;
          });
        },
      ),
    );
  }

  Widget _menuItem(int index, IconData icon, String title) {
    // ড্যাশবোর্ড এবং প্রোফাইল বটম নেভিগেশনের সাথে সিঙ্ক করা
    // ListPage (index 1 in Bottom Nav) ড্রয়ারে সরাসরি রাখা হয়নি, তাই লজিক ফিক্স করা হয়েছে।
    final bool isBottomNavSync = (index == 0 || index == 2);
    final bool selected = selectedIndex == index;

    return InkWell(
      onTap: () {
        Navigator.pop(context); // Close Drawer

        if (isBottomNavSync) {
          // Dashboard (0) অথবা Profile (2) হলে বটম বার সিঙ্ক হবে
          setState(() {
            selectedIndex = index;
            _page = index;
            _bottomNavigationKey.currentState?.setPage(index);
          });
        } else {
          // আলাদা পেজে যাওয়ার জন্য রাউটিং লজিক
          Widget? targetPage;
          if (index == 1) targetPage = const BloodGroupsPage();
          if (index == 9) targetPage = const CreateEventPage();
          if (index == 10) targetPage = const AdminEventsPage();
          if (index == 11) targetPage = const EventsListPage();

          if (targetPage != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => targetPage!));
          } else {
            setState(() => selectedIndex = index);
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: selected ? Colors.cyanAccent : Colors.white70),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
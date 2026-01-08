import 'package:css/pages/Blood/blood_groups_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

import 'welcome_page.dart';
import 'dashboard_page.dart';
import 'list_page.dart';
import 'pages/Profile/profile_page.dart';
// Blood Donation পেজটি ইম্পোর্ট করা হলো


class MemberHome extends StatefulWidget {
  final bool isGuest;
  const MemberHome({super.key, required this.isGuest});

  @override
  State<MemberHome> createState() => _MemberHomeState();
}

class _MemberHomeState extends State<MemberHome> {
  int selectedIndex = 0; // drawer
  int _page = 0; // bottom nav

  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey =
  GlobalKey<CurvedNavigationBarState>();

  String? userName;
  String? userEmail;
  String? profileImageUrl;
  bool loadingProfile = true;

  @override
  void initState() {
    super.initState();
    if (!widget.isGuest) {
      _loadProfile();
    } else {
      userName = 'Guest User';
      userEmail = '';
      profileImageUrl = null;
      loadingProfile = false;
    }
  }

  // ================= LOAD PROFILE =================
  Future<void> _loadProfile() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      setState(() {
        loadingProfile = false;
        userName = 'User';
        userEmail = '';
      });
      return;
    }

    try {
      final data = await client
          .from('profiles')
          .select('full_name, profile_image_url')
          .eq('id', user.id)
          .maybeSingle();

      setState(() {
        userName = data?['full_name'] ?? user.userMetadata?['full_name'] ?? 'User';
        userEmail = user.email;
        profileImageUrl = data?['profile_image_url'];
        loadingProfile = false;
      });
    } catch (e) {
      setState(() {
        userName = user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? 'User';
        userEmail = user.email;
        loadingProfile = false;
      });
    }
  }

  // ================= LOGOUT =================
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

                // ===== MAIN MENU ITEMS =====
                _menuItem(0, Icons.grid_view_rounded, 'Dashboard'),

                // Blood Donation বাটনের index ১ রাখা হয়েছে
                _menuItem(1, Icons.water_drop_rounded, 'Blood Donation'),

                _menuItem(2, Icons.manage_accounts_rounded, 'Profile'),
                _menuItem(3, Icons.campaign_outlined, 'Campaigns'),
                _menuItem(4, Icons.calendar_month_outlined, 'Calendar'),
                _menuItem(5, Icons.contacts_outlined, 'Contacts'),

                // ===== ACCOUNT LABEL =====
                const Padding(
                  padding: EdgeInsets.fromLTRB(28, 32, 24, 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'ACCOUNT MANAGEMENT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),

                _menuItem(6, Icons.notifications_outlined, 'Notifications', badge: '3'),
                _menuItem(7, Icons.chat_outlined, 'Chat', badge: '1'),
                _menuItem(8, Icons.settings_outlined, 'Settings'),

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
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
                      ),
                    )
                        : Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(1.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFF1A2A3A),
                            backgroundImage: profileImageUrl != null
                                ? NetworkImage(profileImageUrl!)
                                : null,
                            child: profileImageUrl == null
                                ? Text(
                              (userName ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName ?? 'Unknown User',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  fontSize: 14,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                (userEmail ?? '').toLowerCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: widget.isGuest ? null : _logout,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                Icons.logout_rounded,
                                color: Colors.redAccent,
                                size: 24,
                              ),
                            ),
                          ),
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

  // ================= MENU ITEM =================
  Widget _menuItem(int index, IconData icon, String title, {String? badge}) {
    final bool selected = selectedIndex == index;

    return InkWell(
      onTap: () {
        // ১. ড্রয়ার বন্ধ করা
        Navigator.pop(context);

        // ২. Blood Donation বাটন (Index 1) এর জন্য নেভিগেশন
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BloodGroupsPage()),
          );
        } else {
          // অন্যান্য মেনু আইটেমের জন্য (যেমন ড্যাশবোর্ড বা প্রোফাইল)
          setState(() {
            selectedIndex = index;
            _page = index.clamp(0, 2); // বটম ন্যাভিগেশনের সাথে সিঙ্ক করার জন্য
          });
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
            Icon(
              icon,
              size: 20,
              color: selected ? Colors.cyanAccent : Colors.white70,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
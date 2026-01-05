import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

import 'welcome_page.dart';
import 'dashboard_page.dart';
import 'list_page.dart';
import 'profile_page.dart';

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
  bool loadingProfile = true;

  @override
  void initState() {
    super.initState();
    if (!widget.isGuest) {
      _loadProfile();
    } else {
      userName = 'Guest User';
      userEmail = '';
      loadingProfile = false;
    }
  }

  // ================= LOAD PROFILE =================
  Future<void> _loadProfile() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      setState(() => loadingProfile = false);
      return;
    }

    try {
      final data = await client
          .from('profiles')
          .select('name, email')
          .eq('user_id', user.id)
          .single();

      setState(() {
        userName = data['name'];
        userEmail = data['email'];
        loadingProfile = false;
      });
    } catch (_) {
      setState(() {
        userName =
            user.userMetadata?['full_name'] ??
                user.userMetadata?['name'] ??
                'User';
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

  // ================= PAGE SWITCH (FIXED NAV) =================
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

      // ================= APP BAR =================
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
        backgroundColor: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              // ===== HEADER =====
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  children: [
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/images/csslogo.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'CSS Dashboard',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Member Panel',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),
              const SizedBox(height: 8),

              // ===== MAIN MENU =====
              _menuItem(0, Icons.grid_view, 'Dashboard'),
              _menuItem(1, Icons.inventory_2_outlined, 'Products'),
              _menuItem(2, Icons.mail_outline, 'Mail'),
              _menuItem(3, Icons.campaign_outlined, 'Campaigns'),
              _menuItem(4, Icons.calendar_month_outlined, 'Calendar'),
              _menuItem(5, Icons.contacts_outlined, 'Contacts'),

              // ===== ACCOUNT LABEL =====
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ACCOUNT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

              _menuItem(
                6,
                Icons.notifications_outlined,
                'Notifications',
                badge: '3',
              ),
              _menuItem(
                7,
                Icons.chat_outlined,
                'Chat',
                badge: '1',
              ),
              _menuItem(
                8,
                Icons.settings_outlined,
                'Settings',
              ),

              const Spacer(),

              // ===== PROFILE FOOTER =====
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: loadingProfile
                      ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          (userName ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName ?? 'Unknown User',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userEmail ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, size: 20),
                        onPressed: widget.isGuest ? null : _logout,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // ================= BODY =================
      body: _buildPage(),

      // ================= BOTTOM NAV =================
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
  Widget _menuItem(
      int index,
      IconData icon,
      String title, {
        String? badge,
      }) {
    final bool selected = selectedIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          selectedIndex = index;
          _page = index.clamp(0, 2); // safe sync
        });
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE6F2FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? const Color(0xFF2563EB) : Colors.black54,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight:
                  selected ? FontWeight.w600 : FontWeight.w500,
                  color:
                  selected ? const Color(0xFF2563EB) : Colors.black87,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
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

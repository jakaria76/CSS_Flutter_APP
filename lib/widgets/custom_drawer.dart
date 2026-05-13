import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';
import 'package:css/services/auth_guard_service.dart'; // ✅ NEW

class CustomDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onMenuTap;
  final String? userName;
  final String? userEmail;
  final String? profileImageUrl;
  final bool isAdmin;

  const CustomDrawer({
    super.key,
    required this.selectedIndex,
    required this.onMenuTap,
    this.userName,
    this.userEmail,
    this.profileImageUrl,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (context, __, ___) => _buildDrawer(context),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final isDark = SC.isDark;
    final bgColor = isDark
        ? const Color(0xFF0F2027).withOpacity(0.8)
        : Colors.white.withOpacity(0.9);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.05);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Drawer(
        backgroundColor: bgColor,
        child: Container(
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: borderColor)),
          ),
          child: Column(
            children: [
              _buildDrawerHeader(isDark),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _sectionLabel(SC.tr('general_menu'), isDark),
                      _drawerButton(context, 0, Icons.dashboard_rounded,
                          SC.tr('dashboard'), Colors.cyanAccent, isDark),
                      _drawerButton(context, 1, Icons.feed_rounded,
                          SC.tr('css_updates'), Colors.greenAccent, isDark),
                      _drawerButton(context, 2, Icons.water_drop_rounded,
                          SC.tr('blood_groups'), Colors.redAccent, isDark),
                      _drawerButton(context, 3, Icons.person_rounded,
                          SC.tr('profile'), Colors.blueAccent, isDark),
                      const Divider(color: Colors.white10, height: 24),
                      _drawerButton(context, 4, Icons.event_note_rounded,
                          SC.tr('public_events'), Colors.orangeAccent, isDark),
                      _drawerButton(
                          context,
                          5,
                          Icons.notifications_active_rounded,
                          SC.tr('notices'),
                          Colors.pinkAccent,
                          isDark),
                      _drawerButton(context, 6, Icons.people_alt_rounded,
                          SC.tr('present_members'), Colors.indigoAccent, isDark),
                      _drawerButton(
                          context,
                          25,
                          Icons.history_edu_rounded,
                          SC.tr('previous_members'),
                          Colors.purpleAccent,
                          isDark),
                      _drawerButton(context, 27, Icons.history_edu_rounded,
                          SC.tr('advisors'), Colors.purpleAccent, isDark),
                      _drawerButton(context, 7, Icons.info_outline_rounded,
                          SC.tr('about_css'), Colors.blueAccent, isDark),
                      _drawerButton(context, 18, Icons.photo_library_rounded,
                          SC.tr('gallery'), Colors.purpleAccent, isDark),
                      _drawerButton(context, 20, Icons.play_circle_rounded,
                          SC.tr('videos'), Colors.redAccent, isDark),
                      _drawerButton(context, 22, Icons.feedback_rounded,
                          SC.tr('my_opinions'), Colors.purpleAccent, isDark),
                      _drawerButton(context, 30, Icons.settings,
                          SC.tr('settings'), Colors.orangeAccent, isDark),
                      _drawerButton(context, 32, Icons.book_online_rounded,
                          SC.tr('Constitution'), Colors.purpleAccent, isDark),
                      if (isAdmin) ...[
                        const SizedBox(height: 25),
                        _sectionLabel(SC.tr('admin_panel'), isDark),
                        _drawerButton(
                            context,
                            8,
                            Icons.manage_search_rounded,
                            SC.tr('manage_notices'),
                            Colors.deepOrangeAccent,
                            isDark),
                        _drawerButton(
                            context,
                            9,
                            Icons.manage_accounts_rounded,
                            SC.tr('manage_committee'),
                            Colors.deepPurpleAccent,
                            isDark),
                        _drawerButton(
                            context,
                            26,
                            Icons.manage_history_rounded,
                            SC.tr('manage_prev_members'),
                            Colors.purpleAccent,
                            isDark),
                        _drawerButton(
                            context,
                            28,
                            Icons.manage_accounts_rounded,
                            SC.tr('manage_advisors'),
                            Colors.amberAccent,
                            isDark),
                        _drawerButton(context, 10, Icons.edit_note_rounded,
                            SC.tr('manage_about'), Colors.amberAccent, isDark),
                        _drawerButton(
                            context,
                            11,
                            Icons.settings_suggest_rounded,
                            SC.tr('manage_events'),
                            Colors.tealAccent,
                            isDark),
                        _drawerButton(context, 12, Icons.add_box_rounded,
                            SC.tr('create_event'), Colors.lightGreenAccent, isDark),
                        _drawerButton(
                            context,
                            29,
                            Icons.view_carousel_rounded,
                            SC.tr('manage_banners'),
                            Colors.cyanAccent,
                            isDark),
                        _drawerButton(context, 19, Icons.photo_album_rounded,
                            SC.tr('manage_gallery'), Colors.pinkAccent, isDark),
                        _drawerButton(
                            context,
                            21,
                            Icons.video_settings_rounded,
                            SC.tr('video_management'),
                            Colors.deepOrange,
                            isDark),
                        _drawerButton(
                            context,
                            23,
                            Icons.admin_panel_settings_rounded,
                            SC.tr('manage_complaints'),
                            Colors.cyanAccent,
                            isDark),
                        _drawerButton(context, 24, Icons.post_add_rounded,
                            SC.tr('manage_post'), Colors.greenAccent, isDark),
                        _drawerButton(context, 31, Icons.post_add_rounded,
                            SC.tr('manage_all_member'), Colors.greenAccent, isDark),
                        _drawerButton(context, 33, Icons.book,
                            SC.tr('Manage_Constitution'), Colors.pinkAccent, isDark),
                      ],
                    ],
                  ),
                ),
              ),
              _buildDrawerFooter(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(bool isDark) {
    final textColor =
    isDark ? Colors.white : const Color(0xFF0F2027);
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 70, 25, 30),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                  colors: [Colors.cyanAccent, Colors.purpleAccent]),
              boxShadow: [
                BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.3),
                    blurRadius: 15)
              ],
            ),
            child: const CircleAvatar(
              radius: 32,
              backgroundImage: AssetImage('assets/images/csslogo.jpg'),
            ),
          ),
          const SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CSS PANEL',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isAdmin
                      ? Colors.cyanAccent.withOpacity(0.1)
                      : Colors.purpleAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  isAdmin ? SC.tr('administrator') : SC.tr('member'),
                  style: TextStyle(
                    color: isAdmin
                        ? Colors.cyanAccent
                        : Colors.purpleAccent,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, bool isDark) {
    final textColor = isDark
        ? Colors.white.withOpacity(0.2)
        : Colors.black.withOpacity(0.3);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerButton(BuildContext context, int index, IconData icon,
      String title, Color color, bool isDark) {
    final bool isSel = selectedIndex == index;
    final baseTextColor =
    isDark ? Colors.white70 : Colors.black87;
    final selTextColor = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        splashColor: color.withOpacity(0.12),
        onTap: () {
          HapticFeedback.mediumImpact();
          onMenuTap(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isSel
                ? (isDark
                ? Colors.white.withOpacity(0.045)
                : Colors.black.withOpacity(0.03))
                : (isDark
                ? Colors.white.withOpacity(0.02)
                : Colors.black.withOpacity(0.01)),
            gradient: isSel
                ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.14),
                  color.withOpacity(0.035)
                ])
                : null,
            border: Border.all(
              color: isSel
                  ? color.withOpacity(0.35)
                  : (isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05)),
              width: 0.6,
            ),
            boxShadow: isSel
                ? [
              BoxShadow(
                  color: color.withOpacity(0.12),
                  blurRadius: 12,
                  spreadRadius: 0.5)
            ]
                : [],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isSel
                      ? color.withOpacity(0.12)
                      : (isDark
                      ? Colors.white.withOpacity(0.025)
                      : Colors.black.withOpacity(0.025)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    size: 17,
                    color: isSel
                        ? color
                        : (isDark
                        ? Colors.white54
                        : Colors.black45)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSel ? selTextColor : baseTextColor,
                    fontSize: 13.5,
                    fontWeight: isSel
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSel)
                Icon(Icons.keyboard_arrow_right_rounded,
                    size: 13, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerFooter(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    final subColor = isDark
        ? Colors.white.withOpacity(0.4)
        : Colors.black.withOpacity(0.5);
    final cardBg = isDark
        ? Colors.white.withOpacity(0.04)
        : Colors.black.withOpacity(0.03);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: isDark
                ? Colors.cyanAccent.withOpacity(0.2)
                : Colors.cyanAccent.withOpacity(0.1),
            backgroundImage: profileImageUrl != null
                ? NetworkImage(profileImageUrl!)
                : null,
            child: profileImageUrl == null
                ? const Icon(Icons.person_rounded,
                size: 22, color: Colors.cyanAccent)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName ?? 'CSS User',
                    style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w900)),
                Text(userEmail ?? 'member@css.org',
                    style: TextStyle(color: subColor, fontSize: 10)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(Icons.power_settings_new_rounded,
                color: Colors.redAccent, size: 20),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final isDark = SC.isDark;
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: AlertDialog(
          backgroundColor: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1)),
          ),
          title: Text(SC.tr('logout_title'),
              style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w900)),
          content: Text(SC.tr('logout_confirm'),
              style: TextStyle(
                  color:
                  isDark ? Colors.white70 : Colors.black87)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(SC.tr('cancel'),
                  style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15))),
              onPressed: () async {
                // ✅ Guard আগে বন্ধ করো, তারপর logout
                AuthGuardService.dispose();
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/welcome', (route) => false);
                }
              },
              child: Text(SC.tr('logout_title'),
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
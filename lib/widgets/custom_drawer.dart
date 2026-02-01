import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
                      _drawerButton(context, 0, Icons.dashboard_rounded, 'Dashboard', Colors.cyanAccent),
                      _drawerButton(context, 1, Icons.feed_rounded, 'CSS Updates', Colors.greenAccent),
                      _drawerButton(context, 2, Icons.water_drop_rounded, 'Blood Groups', Colors.redAccent),
                      _drawerButton(context, 3, Icons.person_rounded, 'Profile', Colors.blueAccent),

                      const Divider(color: Colors.white10, height: 24),

                      _drawerButton(context, 4, Icons.event_note_rounded, 'Public Events', Colors.orangeAccent),
                      _drawerButton(context, 5, Icons.notifications_active_rounded, 'Notices', Colors.pinkAccent),
                      _drawerButton(context, 6, Icons.people_alt_rounded, 'Committee Members', Colors.indigoAccent),
                      _drawerButton(context, 7, Icons.info_outline_rounded, 'About CSS', Colors.blueAccent),
                      _drawerButton(context, 18, Icons.photo_library_rounded, 'Gallery', Colors.purpleAccent),
                      _drawerButton(context, 20, Icons.play_circle_rounded, 'Videos', Colors.redAccent),
                      _drawerButton(context, 22, Icons.feedback_rounded, 'My Opinions', Colors.purpleAccent),

                      if (isAdmin) ...[
                        const SizedBox(height: 25),
                        _sectionLabel('ADMIN PANEL'),
                        _drawerButton(context, 8, Icons.manage_search_rounded, 'Manage Notices', Colors.deepOrangeAccent),
                        _drawerButton(context, 9, Icons.manage_accounts_rounded, 'Manage Committee', Colors.deepPurpleAccent),
                        _drawerButton(context, 10, Icons.edit_note_rounded, 'Manage About', Colors.amberAccent),
                        _drawerButton(context, 11, Icons.settings_suggest_rounded, 'Manage Events', Colors.tealAccent),
                        _drawerButton(context, 12, Icons.add_box_rounded, 'Create Event', Colors.lightGreenAccent),
                        _drawerButton(context, 19, Icons.photo_album_rounded, 'Manage Gallery', Colors.pinkAccent),
                        _drawerButton(context, 21, Icons.video_settings_rounded, 'Video Management', Colors.deepOrange),
                        _drawerButton(context, 23, Icons.admin_panel_settings_rounded, 'Manage Complaints', Colors.cyanAccent),
                        _drawerButton(context, 24, Icons.post_add_rounded, 'ManagePost', Colors.greenAccent),
                      ],
                    ],
                  ),
                ),
              ),
              _buildDrawerFooter(context),
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
            child: const CircleAvatar(
              radius: 32,
              backgroundImage: AssetImage('assets/images/csslogo.jpg'),
            ),
          ),
          const SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CSS PANEL',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isAdmin
                      ? Colors.cyanAccent.withOpacity(0.1)
                      : Colors.purpleAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  isAdmin ? 'ADMINISTRATOR' : 'MEMBER',
                  style: TextStyle(
                    color: isAdmin ? Colors.cyanAccent : Colors.purpleAccent,
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

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(
              color: Colors.white.withOpacity(0.05),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerButton(BuildContext context, int index, IconData icon, String title, Color color) {
    final bool isSel = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        splashColor: color.withOpacity(0.12),
        highlightColor: Colors.transparent,
        onTap: () {
          HapticFeedback.mediumImpact();
          onMenuTap(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isSel
                ? Colors.white.withOpacity(0.045)
                : Colors.white.withOpacity(0.02),
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

  Widget _buildDrawerFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      decoration: BoxDecoration(
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
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.cyanAccent.withOpacity(0.5),
                      Colors.purpleAccent.withOpacity(0.5)
                    ],
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
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showLogoutDialog(context),
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

  void _showLogoutDialog(BuildContext context) {
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
          title: const Text(
            'LOGOUT',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          content: const Text(
            'Are you sure you want to end your session?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'CANCEL',
                style: TextStyle(color: Colors.white38),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withOpacity(0.3),
                    blurRadius: 15,
                  )
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/welcome',
                          (route) => false,
                    );
                  }
                },
                child: const Text(
                  'LOGOUT',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
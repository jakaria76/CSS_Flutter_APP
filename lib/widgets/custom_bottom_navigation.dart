import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentPage;
  final Function(int) onPageChanged;
  final GlobalKey<CurvedNavigationBarState> navigationKey;
  final List<int?> badgeCounts;

  const CustomBottomNavigation({
    super.key,
    required this.currentPage,
    required this.onPageChanged,
    required this.navigationKey,
    this.badgeCounts = const [null, null, null, null],
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (context, _, __) {
        final isDark = SC.isDark;

        // অ্যাপ বার কালার: Deep Navy
        final navBgColor = isDark ? const Color(0xFF132D46) : Colors.white;

        // আপনার পছন্দের গ্রিন কালার
        final greenColor = const Color(0xFF00FF7F);

        // আইকনের পিছনের গোল্লার ব্যাকগ্রাউন্ড ব্ল্যাক করা হয়েছে
        final buttonBgColor = isDark ? const Color(0xFF000000) : Colors.black87;

        // বডির ব্যাকগ্রাউন্ডের সাথে মিলাতে হবে কার্ভের পিছনের ফাঁকা অংশ
        final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

        final List<_NavItem> items = [
          _NavItem(Icons.grid_view_rounded, SC.tr('navDashboard')),
          _NavItem(Icons.feed_rounded, SC.tr('navFeed')),
          _NavItem(Icons.water_drop_rounded, SC.tr('navBlood')),
          _NavItem(Icons.person_rounded, SC.tr('navProfile')),
        ];

        return Container(
          // SafeArea ছাড়া সরাসরি Container ব্যবহার করা হয়েছে যাতে একদম নিচে লেগে থাকে
          color: navBgColor,
          child: CurvedNavigationBar(
            key: navigationKey,
            index: currentPage,
            height: 55, // স্ট্যান্ডার্ড স্লিম হাইট
            items: List.generate(items.length, (index) {
              final count = index < badgeCounts.length ? (badgeCounts[index] ?? 0) : 0;
              final isActive = index == currentPage;

              return _NavIcon(
                icon: items[index].icon,
                isActive: isActive,
                badgeCount: count,
                iconColor: greenColor,
                navBgColor: navBgColor,
              );
            }),
            color: navBgColor,
            buttonBackgroundColor: buttonBgColor, // এখানে এখন ব্ল্যাক ব্যাকগ্রাউন্ড কাজ করবে
            backgroundColor: Colors.white10, // আগে ছিল: scaffoldBg // কার্ভের বাইরের অংশ বডির সাথে মিশে যাবে
            animationCurve: Curves.easeInOutCubic,
            animationDuration: const Duration(milliseconds: 400),
            onTap: (index) {
              HapticFeedback.lightImpact();
              onPageChanged(index);
            },
          ),
        );
      },
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final int badgeCount;
  final Color iconColor;
  final Color navBgColor;

  const _NavIcon({
    required this.icon,
    required this.isActive,
    required this.badgeCount,
    required this.iconColor,
    required this.navBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Icon(
          icon,
          size: isActive ? 28 : 24,
          color: iconColor, // আইকন সবসময় গ্রিন থাকবে
        ),
        if (badgeCount > 0)
          Positioned(
            top: isActive ? -12 : -8,
            right: isActive ? -12 : -8,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3D00),
                shape: BoxShape.circle,
                border: Border.all(
                    color: navBgColor,
                    width: 1.2
                ),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Center(
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem(this.icon, this.label);
}
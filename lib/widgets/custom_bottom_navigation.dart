import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentPage;
  final Function(int) onPageChanged;
  final GlobalKey<CurvedNavigationBarState> navigationKey;

  const CustomBottomNavigation({
    super.key,
    required this.currentPage,
    required this.onPageChanged,
    required this.navigationKey,
  });

  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      key: navigationKey,
      backgroundColor: Colors.transparent,
      color: const Color(0xFF132D46),
      buttonBackgroundColor: Colors.cyanAccent,
      height: 60,
      index: currentPage,
      items: const [
        Icon(Icons.dashboard_rounded, size: 30, color: Colors.white),
        Icon(Icons.feed_rounded, size: 30, color: Colors.white),
        Icon(Icons.water_drop_rounded, size: 30, color: Colors.white),
        Icon(Icons.person_rounded, size: 30, color: Colors.white),
      ],
      onTap: onPageChanged,
    );
  }
}
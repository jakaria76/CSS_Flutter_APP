import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class BackgroundOrbs extends StatelessWidget {
  const BackgroundOrbs({super.key});

  @override
  Widget build(BuildContext context) {
    // থিম পরিবর্তনের জন্য লিসেনার ব্যবহার করা হয়েছে
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (context, _, __) => _buildOrbs(),
    );
  }

  Widget _buildOrbs() {
    final isDark = SC.isDark;

    // থিম অনুযায়ী অরবগুলোর অপাসিটি এবং কালার অ্যাডজাস্টমেন্ট
    // লাইট মোডে অরবগুলো আরও সূক্ষ্ম (Subtle) রাখা হয়েছে যাতে কন্টেন্ট পড়তে সমস্যা না হয়
    final Color cyanOrbColor = isDark
        ? SC.cyan.withValues(alpha: 0.08)
        : SC.cyan.withValues(alpha: 0.04);

    final Color purpleOrbColor = isDark
        ? SC.purple.withValues(alpha: 0.08)
        : SC.purple.withValues(alpha: 0.04);

    return Stack(
      children: [
        // উপরের বাম পাশের অরব
        Positioned(
          top: 200,
          left: -100,
          child: _orb(300, cyanOrbColor),
        ),

        // নিচের ডান পাশের অরব
        Positioned(
          bottom: 100,
          right: -150,
          child: _orb(400, purpleOrbColor),
        ),

        // অতিরিক্ত ডেপথের জন্য ছোট একটি অরব (ঐচ্ছিক)
        Positioned(
          top: -50,
          right: -20,
          child: _orb(200, isDark ? SC.blue.withValues(alpha: 0.05) : Colors.transparent),
        ),
      ],
    );
  }

  Widget _orb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 120, // ব্লার রেডিয়াস বাড়ানো হয়েছে সফট লুকের জন্য
            spreadRadius: 60,
          )
        ],
      ),
    );
  }
}
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double padding;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding = 20,
  });

  @override
  Widget build(BuildContext context) {
    // থিম এবং ভাষা পরিবর্তনের জন্য লিসেনার
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (context, __, ___) => _buildGlassCard(),
      ),
    );
  }

  Widget _buildGlassCard() {
    final isDark = SC.isDark;

    // থিম অনুযায়ী কালার সিলেকশন
    // ডার্ক মোডে গ্লাস ইফেক্ট ভালো দেখানোর জন্য স্লাইটলি ডার্ক অপাসিটি ব্যবহার করা হয়েছে
    final glassColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.35);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.white.withValues(alpha: 0.4);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        // ব্লাফ ইফেক্ট থিম অনুযায়ী অ্যাডজাস্ট করা যেতে পারে
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
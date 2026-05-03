import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool center;

  const SectionTitle({
    super.key,
    required this.icon,
    required this.title,
    this.center = false,
  });

  @override
  Widget build(BuildContext context) {
    // থিম এবং ভাষা পরিবর্তনের জন্য লিসেনার ব্যবহার করা হয়েছে
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (context, __, ___) => _buildTitle(context),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final isDark = SC.isDark;

    // থিম অনুযায়ী সঠিক কালার নির্ধারণ
    // ডার্ক মোডে নীল রঙের পরিবর্তে সায়ান (Cyan) ব্যবহার করা হয়েছে যাতে ভালো ফুটে ওঠে
    final accentColor = isDark ? SC.cyan : const Color(0xff003c8f);
    final textColor = isDark ? Colors.white : const Color(0xff003c8f);

    return Row(
      mainAxisAlignment:
      center ? MainAxisAlignment.center : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // আইকন সেকশন
        Icon(
            icon,
            color: accentColor,
            size: 26
        ),

        const SizedBox(width: 12),

        // টাইটেল টেক্সট
        Flexible(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 22, // মোবাইল স্ক্রিনের জন্য ২৬ থেকে কমিয়ে ২২ করা হয়েছে সামঞ্জস্যের জন্য
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
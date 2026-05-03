import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class ActivityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color iconColor;
  final VoidCallback? onTap;
  final bool hasPdf;

  const ActivityTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.iconColor,
    this.onTap,
    this.hasPdf = false,
  });

  @override
  Widget build(BuildContext context) {
    // থিম এবং ভাষা পরিবর্তনের জন্য লিসেনার
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (context, __, ___) => _buildTile(context),
      ),
    );
  }

  Widget _buildTile(BuildContext context) {
    final isDark = SC.isDark;

    // থিম অনুযায়ী টেক্সট এবং ব্যাকগ্রাউন্ড কালার নির্ধারণ
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subTextColor = isDark ? Colors.white38 : const Color(0xFF4A5568);
    final tileBgColor = isDark ? Colors.transparent : Colors.white;
    final timeBadgeBg = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05);

    return Material(
      color: tileBgColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // আইকন কন্টেইনার
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),

              const SizedBox(width: 15),

              // টেক্সট কন্টেন্ট
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // পিডিএফ আইকন
              if (hasPdf)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(
                    Icons.picture_as_pdf_rounded,
                    color: SC.red.withValues(alpha: 0.8),
                    size: 20,
                  ),
                ),

              // টাইম বা স্ট্যাটাস ব্যাজ
              if (time.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: timeBadgeBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    time,
                    style: TextStyle(
                      color: (time == "NEW" || time == SC.tr('new_badge_key'))
                          ? SC.orange
                          : subTextColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
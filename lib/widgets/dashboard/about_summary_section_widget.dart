import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:css/models/about_models.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';
import 'package:css/pages/About/about_page.dart';

class AboutSummarySectionWidget extends StatelessWidget {
  final bool isDark;
  final AboutOverview? overview;

  const AboutSummarySectionWidget({
    super.key,
    required this.isDark,
    required this.overview,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor   = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);
    final textColor   = isDark ? Colors.white : const Color(0xFF1A2332);
    final subColor    = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : const Color(0xFF4A5568);
    final accentCol   = isDark ? Colors.cyanAccent : SC.blue;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            SC.tr('whoWeAre'),
            style: TextStyle(
              color: accentCol,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentCol.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.auto_awesome_rounded,
                            color: accentCol, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          SC.tr('cssFullName'),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    Text(
                      overview?.description ?? SC.tr('cssTagline'),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: subColor, fontSize: 14, height: 1.6),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutPage()),
                      ),
                      child: Row(children: [
                        Text(
                          SC.tr('learnMore'),
                          style: TextStyle(
                            color: accentCol,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded,
                            color: accentCol, size: 16),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
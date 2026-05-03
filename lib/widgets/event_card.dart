import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final bool isPast;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.event,
    required this.isPast,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (context, __, ___) => _buildCard(context),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final isDark = SC.isDark;
    final cardColor = isDark ? SC.cardBg : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F1923);
    final subTextColor = isDark ? Colors.white60 : const Color(0xFF5A6478);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.09)
        : Colors.black.withValues(alpha: 0.07);

    final String? banner = event['banner_url']?.toString();
    final int price =
    event['price'] is num ? (event['price'] as num).toInt() : 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? cardColor.withValues(alpha: 0.45) : cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: isDark
                  ? []
                  : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Banner ──
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20)),
                      child: SizedBox(
                        height: 120,
                        width: double.infinity,
                        child: banner != null && banner.isNotEmpty
                            ? Image.network(
                          banner,
                          fit: BoxFit.cover,
                          loadingBuilder:
                              (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return _placeholder(isDark);
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              _placeholder(isDark),
                        )
                            : _placeholder(isDark),
                      ),
                    ),

                    // Gradient overlay at bottom of banner
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.45),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Price badge — top right
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _priceBadge(
                          price > 0 ? '৳$price' : SC.tr('free_text'),
                          price == 0),
                    ),

                    // Past badge — top left
                    if (isPast)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: _pastBadge(SC.tr('past_event'), isDark),
                      ),
                  ],
                ),

                // ── Content ──
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['title']?.toString() ?? SC.tr('no_title'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isPast
                              ? textColor.withValues(alpha: 0.4)
                              : textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 7),
                      _infoRow(
                        Icons.location_on_rounded,
                        event['venue']?.toString() ?? SC.tr('tbd_text'),
                        isPast,
                        subTextColor,
                      ),
                      const SizedBox(height: 5),
                      _infoRow(
                        Icons.access_time_rounded,
                        _formatDate(event['start_datetime']),
                        isPast,
                        subTextColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(bool isDark) {
    return Container(
      height: 130,
      width: double.infinity,
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.04),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        color: isDark ? Colors.white24 : Colors.black12,
        size: 36,
      ),
    );
  }

  Widget _priceBadge(String text, bool isFree) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        gradient: isFree
            ? LinearGradient(
          colors: [
            SC.cyan.withValues(alpha: 0.85),
            SC.cyan.withValues(alpha: 0.6),
          ],
        )
            : LinearGradient(
          colors: [
            const Color(0xFFFF6B35).withValues(alpha: 0.9),
            const Color(0xFFFF9500).withValues(alpha: 0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: (isFree ? SC.cyan : const Color(0xFFFF6B35))
                .withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _pastBadge(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white54,
          fontWeight: FontWeight.w600,
          fontSize: 10,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _infoRow(
      IconData icon, String text, bool isPast, Color subTextColor) {
    return Row(
      children: [
        Icon(
          icon,
          size: 12,
          color: isPast ? subTextColor.withValues(alpha: 0.3) : SC.cyan,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color:
              isPast ? subTextColor.withValues(alpha: 0.35) : subTextColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dt) {
    if (dt == null) return SC.tr('date_not_set');
    try {
      final d = DateTime.parse(dt).toLocal();
      return '${d.day}/${d.month}/${d.year} • ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return SC.tr('invalid_date');
    }
  }
}
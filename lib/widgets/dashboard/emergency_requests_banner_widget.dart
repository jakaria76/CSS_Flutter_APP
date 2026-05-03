import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';
import 'package:css/pages/Blood/emergency_blood_request_page.dart';
import 'package:css/pages/Blood/emergency_requests_page.dart';

class EmergencyRequestsBannerWidget extends StatelessWidget {
  final List<Map<String, dynamic>> emergencyRequests;
  final AnimationController pulseController;
  final bool isDark;

  const EmergencyRequestsBannerWidget({
    super.key,
    required this.emergencyRequests,
    required this.pulseController,
    required this.isDark,
  });

  _BloodColors _getThemeColors() {
    return const _BloodColors(
      accent:    Color(0xFFD32F2F),
      gradient: [Color(0xFFB71C1C), Color(0xFFEF5350)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final requests   = emergencyRequests.take(5).toList();
    final themeColors = _getThemeColors();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Row(
            children: [
              FadeTransition(
                opacity: Tween(begin: 0.5, end: 1.0).animate(pulseController),
                child: Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color:      themeColors.accent,
                    shape:      BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:      themeColors.accent.withValues(alpha: 0.4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                SC.tr('emergencyBlood').toUpperCase(),
                style: TextStyle(
                  color:       themeColors.accent,
                  fontSize:    11,
                  fontWeight:  FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const EmergencyRequestsPage()),
                ),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        SC.tr('viewAll'),
                        style: TextStyle(
                          color:      isDark ? Colors.cyanAccent : SC.cyan,
                          fontSize:   11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: isDark ? Colors.cyanAccent : SC.cyan,
                        size:  10,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Horizontal Cards ──
        SizedBox(
          height: 125,
          child: ListView.separated(
            padding:         const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics:         const BouncingScrollPhysics(),
            itemCount:       requests.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index == requests.length) {
                return _AddRequestCard(
                    isDark: isDark, themeColors: themeColors);
              }
              return _EmergencyCard(
                req:    requests[index],
                isDark: isDark,
                colors: themeColors,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Emergency Card ────────────────────────────────────────────────────────────
class _EmergencyCard extends StatelessWidget {
  final Map<String, dynamic> req;
  final bool isDark;
  final _BloodColors colors;

  const _EmergencyCard({
    required this.req,
    required this.isDark,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const EmergencyRequestsPage(),
          ),
        );
      },
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: isDark
              ? colors.accent.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: colors.accent.withValues(alpha: 0.25), width: 1.2),
          boxShadow: [
            BoxShadow(
              color:      colors.accent.withValues(alpha: 0.08),
              blurRadius: 6,
              offset:     const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Blood Group & Units ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      gradient:     LinearGradient(colors: colors.gradient),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      req['blood_group'] ?? '?',
                      style: const TextStyle(
                        color:      Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize:   14,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${req['units_needed'] ?? 1} Bag',
                    style: TextStyle(
                      color:      colors.accent,
                      fontSize:   11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // ── Requester Name ──
              Text(
                req['requester_name'] ?? 'Unknown',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:      isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize:   13,
                ),
              ),
              const SizedBox(height: 2),

              // ── Hospital ──
              Row(
                children: [
                  Icon(
                    Icons.local_hospital_rounded,
                    size:  12,
                    color: colors.accent.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      req['hospital'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color:      Colors.grey,
                        fontSize:   10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Respond Button ──
              Container(
                width:   double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color:        colors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      SC.tr('respond').toUpperCase(),
                      style: TextStyle(
                        color:         colors.accent,
                        fontSize:      10,
                        fontWeight:    FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size:  9,
                      color: colors.accent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Add Request Card ──────────────────────────────────────────────────────────
class _AddRequestCard extends StatelessWidget {
  final bool isDark;
  final _BloodColors themeColors;

  const _AddRequestCard({
    required this.isDark,
    required this.themeColors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const EmergencyBloodRequestPage()),
        );
      },
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: themeColors.accent.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_rounded,
              color: themeColors.accent.withValues(alpha: 0.6),
              size:  32,
            ),
            const SizedBox(height: 6),
            Text(
              SC.tr('requestNow'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color:      themeColors.accent,
                fontWeight: FontWeight.bold,
                fontSize:   10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Blood Colors Model ────────────────────────────────────────────────────────
class _BloodColors {
  final Color       accent;
  final List<Color> gradient;

  const _BloodColors({
    required this.accent,
    required this.gradient,
  });
}
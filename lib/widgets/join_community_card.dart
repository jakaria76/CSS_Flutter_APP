import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';
import 'package:css/pages/JoinCommunity/join_community_form_page.dart';

/// স্লাইডারের নিচে দেখানো হবে — Premium Green, Animated Card.
/// Tap করলে JoinCommunityFormPage খুলবে।
class JoinCommunityCard extends StatefulWidget {
  const JoinCommunityCard({super.key});

  @override
  State<JoinCommunityCard> createState() => _JoinCommunityCardState();
}

class _JoinCommunityCardState extends State<JoinCommunityCard>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    // শিমার অ্যানিমেশনের জন্য (যেটি কার্ডের ওপর দিয়ে সুইপ করবে)
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    // আইকনের পালস/ব্রিথিং অ্যানিমেশনের জন্য
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _openForm() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const JoinCommunityFormPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = SC.isDark;

    // প্রিমিয়াম গ্রিন গ্রেডিয়েন্ট প্যালট
    const greenGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF00BFA5), // Teal/Emerald Green
        Color(0xFF00E676), // Bright Green
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            // দারুণ একটি গ্রিন গ্লো (Glow) ইফেক্ট
            BoxShadow(
              color: const Color(0xFF00E676).withValues(alpha: 0.35),
              blurRadius: 20,
              spreadRadius: -2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openForm,
              splashColor: Colors.white.withValues(alpha: 0.2),
              highlightColor: Colors.transparent,
              child: Container(
                height: 64, // একটু চওড়া করা হয়েছে যাতে দেখতে প্রিমিয়াম লাগে
                decoration: BoxDecoration(
                  gradient: greenGradient,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.2 : 0.1),
                    width: 1.5,
                  ),
                ),
                child: Stack(
                  children: [
                    // ── Shimmer Sweep Effect ──
                    AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, child) {
                        return Positioned.fill(
                          child: Align(
                            alignment: Alignment(
                              -1.5 + (_shimmerController.value * 3),
                              0,
                            ),
                            child: Transform.rotate(
                              angle: 0.3,
                              child: Container(
                                width: 70,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.0),
                                      Colors.white.withValues(alpha: 0.3),
                                      Colors.white.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // ── Main Content ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        children: [
                          // ── Pulsing Icon ──
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 + (_pulseController.value * 0.15),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.25),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.group_add_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 16),

                          // ── Text ──
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  SC.tr('joinCommunityCardTitle'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  SC.tr('joinFormPageSubtitle') ?? 'Be a part of us',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // ── Trailing Arrow Box ──
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
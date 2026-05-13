import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Full-screen loading screen — dashboard data load হওয়া পর্যন্ত দেখায়।
/// ব্যবহার: _initialLoadDone false থাকলে এটা show করো।
class CssLoadingScreen extends StatefulWidget {
  const CssLoadingScreen({super.key});

  @override
  State<CssLoadingScreen> createState() => _CssLoadingScreenState();
}

class _CssLoadingScreenState extends State<CssLoadingScreen>
    with TickerProviderStateMixin {

  // ── Dot bounce animation ───────────────────────────────────────────────────
  late AnimationController _dotController;

  // ── Logo scale-in animation (একবার) ──────────────────────────────────────
  late AnimationController _logoController;
  late Animation<double>   _logoScale;
  late Animation<double>   _logoOpacity;

  @override
  void initState() {
    super.initState();

    // Dot bounce — repeat করে
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Logo scale-in — একবার
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    _logoController.forward();
  }

  @override
  void dispose() {
    _dotController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background image (full screen) ──────────────────────────────
          Image.asset(
            'assets/images/css_loading_screen.png',
            fit: BoxFit.cover,
          ),

          // ── Dark overlay — হালকা করে দিলে image ভালো দেখায় ────────────
          Container(
            color: Colors.black.withValues(alpha: 0.08),
          ),

          // ── Logo scale-in + animated dots at bottom ───────────────────
          Column(
            children: [
              const Spacer(),

              // ── Animated dots ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: _buildAnimatedDots(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 3 bouncing dots ────────────────────────────────────────────────────────
  Widget _buildAnimatedDots() {
    return AnimatedBuilder(
      animation: _dotController,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // প্রতিটা dot-এর জন্য আলাদা delay
            final delay = i * 0.28;
            final raw   = (_dotController.value - delay) % 1.0;
            final t     = raw.clamp(0.0, 1.0);
            final bounce = math.sin(t * math.pi); // 0→1→0

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Transform.translate(
                offset: Offset(0, -bounce * 10), // উপরে উঠবে
                child: Container(
                  width:  10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.55 + bounce * 0.45),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: bounce * 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
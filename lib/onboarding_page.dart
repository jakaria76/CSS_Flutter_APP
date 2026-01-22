import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int index = 0;

  final pages = [
    {
      'title': 'Welcome to CSS',
      'subtitle':
      'A premium platform designed for the conscious students of tomorrow.',
      'icon': Icons.auto_awesome_rounded,
      'accent': Colors.cyanAccent,
    },
    {
      'title': 'Empower Others',
      'subtitle':
      'Directly contribute to education support and social welfare initiatives.',
      'icon': Icons.auto_graph_rounded,
      'accent': Colors.purpleAccent,
    },
    {
      'title': 'Make an Impact',
      'subtitle':
      'Join a community where every action creates a ripple of positive change.',
      'icon': Icons.language_rounded,
      'accent': Colors.orangeAccent,
    },
  ];

  // ================= FINISH ONBOARDING =================
  Future<void> finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);

    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    // 🔐 Facebook-style decision
    if (session != null) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
            (_) => false,
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/welcome',
            (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -50,
              child: _blurCircle(
                250,
                (pages[index]['accent'] as Color).withOpacity(0.15),
              ),
            ),
            Positioned(
              bottom: 50,
              left: -30,
              child: _blurCircle(
                200,
                Colors.white.withOpacity(0.05),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  // TOP BAR
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'CSS',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            letterSpacing: 2,
                          ),
                        ),
                        TextButton(
                          onPressed: finish,
                          child: const Text(
                            'SKIP',
                            style: TextStyle(
                              color: Colors.white38,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // PAGES
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: pages.length,
                      onPageChanged: (i) {
                        HapticFeedback.lightImpact();
                        setState(() => index = i);
                      },
                      itemBuilder: (_, i) =>
                          _pageContent(pages[i]),
                    ),
                  ),

                  // BOTTOM ACTION
                  Padding(
                    padding:
                    const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                            sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color:
                            Colors.white.withOpacity(0.05),
                            borderRadius:
                            BorderRadius.circular(30),
                            border: Border.all(
                                color: Colors.white
                                    .withOpacity(0.1)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: List.generate(
                                  pages.length,
                                      (i) =>
                                      _indicator(i == index),
                                ),
                              ),
                              const SizedBox(height: 32),
                              _actionButton(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= UI HELPERS =================

  Widget _pageContent(Map<String, dynamic> page) {
    final accent = page['accent'] as Color;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
              border: Border.all(
                  color: Colors.white.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.1),
                  blurRadius: 40,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Icon(
              page['icon'],
              size: 80,
              color: accent,
            ),
          ),
          const SizedBox(height: 50),
          Text(
            page['title'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page['subtitle'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _indicator(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 6,
      width: active ? 24 : 8,
      decoration: BoxDecoration(
        color: active
            ? (pages[index]['accent'] as Color)
            : Colors.white10,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _actionButton() {
    final isLast = index == pages.length - 1;
    final accent = pages[index]['accent'] as Color;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLast
            ? finish
            : () => _controller.nextPage(
          duration:
          const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: const Color(0xFF0F2027),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          isLast ? 'GET STARTED' : 'NEXT STEP',
          style: const TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5),
        ),
      ),
    );
  }

  Widget _blurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration:
      BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

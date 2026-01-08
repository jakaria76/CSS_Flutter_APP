import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: Stack(
          children: [
            // --- Decorative Background Elements ---
            Positioned(
              top: -50,
              left: -50,
              child: _buildBlurCircle(200, Colors.cyanAccent.withOpacity(0.1)),
            ),
            Positioned(
              bottom: 100,
              right: -30,
              child: _buildBlurCircle(150, Colors.redAccent.withOpacity(0.05)),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    /// --- LOGO SECTION ---
                    _buildAnimatedLogo(),

                    const SizedBox(height: 40),

                    /// --- TEXT SECTION ---
                    const Text(
                      'CONSCIOUS\nSTUDENT SOCIETY',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Education • Humanity • Responsibility',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 60),

                    /// --- GLASS CARD CONTAINER ---
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Column(
                            children: [
                              /// LOGIN BUTTON
                              _buildPrimaryButton(
                                context,
                                'LOG IN',
                                    () => Navigator.pushNamed(context, '/login'),
                              ),

                              const SizedBox(height: 16),

                              /// SIGN UP BUTTON
                              _buildSecondaryButton(
                                context,
                                'CREATE ACCOUNT',
                                    () => Navigator.pushNamed(context, '/signup'),
                              ),

                              const SizedBox(height: 25),

                              /// GUEST MODE
                              GestureDetector(
                                onTap: () => Navigator.pushNamedAndRemoveUntil(
                                    context, '/home', (_) => false),
                                child: const Text(
                                  'Continue as Guest',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white54,
                                    letterSpacing: 1,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI Helper Widgets ---

  Widget _buildBlurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildAnimatedLogo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withOpacity(0.1),
            blurRadius: 40,
            spreadRadius: 10,
          )
        ],
      ),
      child: const Icon(
        Icons.volunteer_activism_rounded,
        size: 80,
        color: Colors.cyanAccent,
      ),
    );
  }

  Widget _buildPrimaryButton(BuildContext context, String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyanAccent,
          foregroundColor: const Color(0xFF0F2027),
          elevation: 10,
          shadowColor: Colors.cyanAccent.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onTap,
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(BuildContext context, String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white24, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onTap,
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
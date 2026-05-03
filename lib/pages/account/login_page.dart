import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'otp_verify_page.dart';
import 'forgot_password_page.dart';
import 'package:css/pages/SettingsPage/mfa_login_verify_page.dart';
import 'package:css/pages/SettingsPage/mfa_setup_page.dart';
import 'package:css/services/activity_logger.dart';
import 'dart:io' show Platform;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;

  bool loading = false;
  bool obscure = true;

  Future<void> login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter both email and password');
      return;
    }

    try {
      setState(() => loading = true);
      HapticFeedback.mediumImpact();

      // Step 1: Password দিয়ে sign in করো
      final authRes = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (authRes.user == null) throw const AuthException('Login failed');

// ✅ Login success log
      await ActivityLogger.log(
        activityType: 'login_success',
        device: Platform.isAndroid ? 'Android' : Platform.isIOS ? 'iOS' : 'Unknown',
      );

      // Step 2: Sign in সফল — এখন MFA check করো (session থাকা অবস্থায়)
      final factors = await supabase.auth.mfa.listFactors();
      final hasMfa =
      factors.all.any((f) => f.status == FactorStatus.verified);

      // Step 3: Sign out করো (verify না হওয়া পর্যন্ত access দেবো না)
      await supabase.auth.signOut();

      if (!mounted) return;

      if (hasMfa) {
        // ── MFA চালু আছে → Authenticator code চাও ──────────────────────────
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MFALoginVerifyPage(
              email: email,
              password: password,
            ),
          ),
        );
      } else {
        // ── MFA নেই → Email OTP পাঠাও ────────────────────────────────────────
        await supabase.auth.signInWithOtp(
          email: email,
          shouldCreateUser: false,
        );
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerifyPage(email: email),
          ),
        );
      }
    } on AuthException catch (e) {
      // ✅ Login failed log
      await ActivityLogger.log(
        activityType: 'login_failed',
        detail: 'wrong_pass',
        device: Platform.isAndroid ? 'Android' : Platform.isIOS ? 'iOS' : 'Unknown',
      );
      _showMessage(e.message);
    } catch (_) {
      await ActivityLogger.log(
        activityType: 'login_failed',
        detail: 'wrong_pass',
      );
      _showMessage('Invalid credentials or network error');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
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
              child: _buildBlurCircle(
                  180, Colors.cyanAccent.withOpacity(0.1)),
            ),
            Positioned(
              bottom: 100,
              left: -30,
              child: _buildBlurCircle(
                  150, Colors.purpleAccent.withOpacity(0.05)),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: const Icon(
                          Icons.lock_person_rounded,
                          size: 60,
                          color: Colors.cyanAccent,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Enter credentials to continue',
                        style: TextStyle(color: Colors.white54),
                      ),
                      const SizedBox(height: 48),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter:
                          ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Column(
                              children: [
                                _buildTextField(
                                  controller: _emailController,
                                  label: 'Email Address',
                                  icon: Icons.email_outlined,
                                  type: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 20),
                                _buildTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                          const ForgotPasswordPage(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: Colors.cyanAccent,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: loading ? null : login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.cyanAccent,
                                      foregroundColor:
                                      const Color(0xFF0F2027),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: loading
                                        ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF0F2027),
                                      ),
                                    )
                                        : const Text(
                                      'LOG IN',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        'Conscious Student Society © 2026',
                        style:
                        TextStyle(color: Colors.white24, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType type = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword ? obscure : false,
          keyboardType: type,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon:
            Icon(icon, color: Colors.cyanAccent.withOpacity(0.6)),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white38,
              ),
              onPressed: () => setState(() => obscure = !obscure),
            )
                : null,
            filled: true,
            fillColor: Colors.black.withOpacity(0.2),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
              BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                  color: Colors.cyanAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
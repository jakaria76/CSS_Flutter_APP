import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'otp_verify_page.dart';
import 'forgot_password_page.dart';
import 'package:css/pages/account/mfa_login_verify_page.dart';
import 'package:css/services/activity_logger.dart';

import 'package:css/services/session_service.dart';
import 'package:css/services/auth_guard_service.dart';
import 'dart:io' show Platform;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;

  bool _loading = false;
  bool _obscure = true;

  late AnimationController _animCtrl;
  late Animation<double>    _fadeAnim;
  late Animation<Offset>    _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
        begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String get _device {
    try {
      return Platform.isAndroid
          ? 'Android'
          : Platform.isIOS
          ? 'iOS'
          : 'Unknown';
    } catch (_) {
      return 'Unknown';
    }
  }

  /// Check blocked_emails table via RPC
  Future<bool> _isEmailBlocked(String email) async {
    try {
      final result = await supabase.rpc(
        'is_email_blocked',
        params: {'check_email': email.toLowerCase().trim()},
      );
      return result == true;
    } catch (_) {
      return false;
    }
  }

  /// Check if a profile exists for this email
  Future<bool> _hasAccount(String email) async {
    try {
      final res = await supabase
          .from('profiles')
          .select('id')
          .eq('email', email.toLowerCase().trim())
          .maybeSingle();
      return res != null;
    } catch (_) {
      return false;
    }
  }

  // ── Login logic ────────────────────────────────────────────────────────────

  Future<void> _login() async {
    final email    = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter both email and password');
      return;
    }

    setState(() => _loading = true);
    HapticFeedback.mediumImpact();

    try {
      // ── 1. Blocked check ─────────────────────────────────────────────────
      final blocked = await _isEmailBlocked(email);
      if (blocked) {
        _showBanner(
          icon:    Icons.block_rounded,
          color:   const Color(0xFFFF5722),
          title:   'Account Restricted',
          message: 'You cannot login or create a new account with this email address.',
        );
        return;
      }

      // ── 2. Account existence check ───────────────────────────────────────
      final hasAccount = await _hasAccount(email);
      if (!hasAccount) {
        _showBanner(
          icon:    Icons.person_off_rounded,
          color:   const Color(0xFF9C27B0),
          title:   'No Account Found',
          message: 'You have no account with this email. Please create a new account.',
          actionLabel: 'Create Account',
          onAction: () => Navigator.pop(context), // back to landing/signup
        );
        return;
      }

      // ── 3. Sign in ───────────────────────────────────────────────────────
      final authRes = await supabase.auth.signInWithPassword(
        email:    email,
        password: password,
      );
      if (authRes.user == null) throw const AuthException('Login failed');

      await ActivityLogger.log(
        activityType: 'login_success',
        device: _device,
      );

      // ── 4. MFA check ─────────────────────────────────────────────────────
      final factors  = await supabase.auth.mfa.listFactors();
      final hasMfa   = factors.all.any((f) => f.status == FactorStatus.verified);

      // ── TEST ACCOUNT: OTP bypass for Google Play reviewer ────────────────
      const testEmails = ['googlereview@myapp.com'];
      if (testEmails.contains(email)) {
        if (!mounted) return;
        AuthGuardService.init(context);
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
        return;
      }

      await supabase.auth.signOut();

      if (!mounted) return;

      if (hasMfa) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MFALoginVerifyPage(email: email, password: password),
          ),
        );
      } else {
        await supabase.auth.signInWithOtp(
          email: email,
          shouldCreateUser: false,
        );
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OtpVerifyPage(email: email)),
        );
      }
    } on AuthException catch (e) {
      await ActivityLogger.log(
        activityType: 'login_failed',
        detail: 'wrong_pass',
        device: _device,
      );

      final msg = e.message.toLowerCase();
      if (msg.contains('invalid') || msg.contains('credentials') || msg.contains('password')) {
        _showBanner(
          icon:    Icons.lock_outline_rounded,
          color:   const Color(0xFFEF5350),
          title:   'Incorrect Password',
          message: 'The password you entered is incorrect. Please try again or reset your password.',
          actionLabel: 'Forgot Password?',
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
          ),
        );
      } else {
        _showError(e.message);
      }
    } catch (e) {
      await ActivityLogger.log(
        activityType: 'login_failed',
        detail: 'unknown_error',
        device: _device,
      );
      _showError('Network error. Please check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  // ── Error / Banner UI ──────────────────────────────────────────────────────

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Text(msg,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
      backgroundColor: const Color(0xFFEF5350),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    ));
  }

  void _showBanner({
    required IconData icon,
    required Color    color,
    required String   title,
    required String   message,
    String?           actionLabel,
    VoidCallback?     onAction,
  }) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1E2E).withOpacity(0.97),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color: color.withOpacity(0.4), width: 1.2),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.12),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Icon(icon, color: color, size: 36),
                ),
                const SizedBox(height: 20),
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20)),
                const SizedBox(height: 12),
                Text(message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                        height: 1.6)),
                const SizedBox(height: 28),
                // Action buttons
                if (actionLabel != null && onAction != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onAction();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(actionLabel,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: Colors.white.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('OK',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 14)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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
        child: Stack(children: [
          // Background blobs
          Positioned(
              top: -50,
              right: -50,
              child: _blurOrb(180, Colors.cyanAccent.withOpacity(0.08))),
          Positioned(
              bottom: 100,
              left: -30,
              child: _blurOrb(150, Colors.purpleAccent.withOpacity(0.05))),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(children: [
                      // ── Logo ─────────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: const Icon(Icons.lock_person_rounded,
                            size: 60, color: Colors.cyanAccent),
                      ),
                      const SizedBox(height: 24),
                      const Text('Welcome Back',
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                      const SizedBox(height: 6),
                      const Text('Enter credentials to continue',
                          style: TextStyle(color: Colors.white54)),
                      const SizedBox(height: 48),

                      // ── Form card ─────────────────────────────────────────
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
                                  color:
                                  Colors.white.withOpacity(0.1)),
                            ),
                            child: Column(children: [
                              // Email field
                              _buildTextField(
                                controller: _emailController,
                                label: 'Email Address',
                                icon: Icons.email_outlined,
                                type: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 20),

                              // Password field
                              _buildTextField(
                                controller: _passwordController,
                                label: 'Password',
                                icon: Icons.lock_outline,
                                isPassword: true,
                              ),
                              const SizedBox(height: 12),

                              // Forgot password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                        const ForgotPasswordPage()),
                                  ),
                                  child: const Text('Forgot Password?',
                                      style: TextStyle(
                                          color: Colors.cyanAccent,
                                          fontSize: 13)),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Login button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.cyanAccent,
                                    foregroundColor:
                                    const Color(0xFF0F2027),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(16)),
                                    elevation: 0,
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child:
                                      CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF0F2027),
                                      ))
                                      : const Text('LOG IN',
                                      style: TextStyle(
                                          fontWeight:
                                          FontWeight.bold,
                                          fontSize: 15,
                                          letterSpacing: 1)),
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                      const Text(
                        'Conscious Student Society © 2026',
                        style: TextStyle(
                            color: Colors.white24, fontSize: 12),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _blurOrb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration:
    BoxDecoration(shape: BoxShape.circle, color: color),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String                label,
    required IconData              icon,
    bool isPassword             = false,
    TextInputType type          = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword ? _obscure : false,
          keyboardType: type,
          style: const TextStyle(color: Colors.white),
          onSubmitted: (_) {
            if (!isPassword) FocusScope.of(context).nextFocus();
            else if (!_loading) _login();
          },
          decoration: InputDecoration(
            prefixIcon: Icon(icon,
                color: Colors.cyanAccent.withOpacity(0.6)),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white38,
              ),
              onPressed: () =>
                  setState(() => _obscure = !_obscure),
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
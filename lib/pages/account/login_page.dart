import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'otp_verify_page.dart';
import 'forgot_password_page.dart';
import 'package:css/pages/account/mfa_login_verify_page.dart';
import 'package:css/services/activity_logger.dart';
import 'package:css/services/auth_guard_service.dart';
import 'package:css/services/biometric_auth_service.dart';
import 'dart:io' show Platform;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;

  bool _loading             = false;
  bool _obscure             = true;
  bool _fingerprintEnabled  = false;
  bool _fingerprintLoading  = false;

  // FIX: auto-trigger একবারের বেশি না হওয়ার জন্য flag
  bool _autoTriggered       = false;

  late AnimationController _animCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _glowCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;
  late Animation<double>   _pulseAnim;
  late Animation<double>   _glowAnim;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
        begin: const Offset(0, 0.10), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 0.7)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _animCtrl.forward();
    _checkBiometric();
  }

  /// enabled + stored token দুটোই check করি।
  /// শুধু enabled থাকলেই auto-trigger হবে না —
  /// token আসলেই আছে কিনা verify করে তবেই auto চেষ্টা করব।
  Future<void> _checkBiometric() async {
    final enabled      = await BiometricAuthService.isFingerprintEnabled();
    final hasToken     = await BiometricAuthService.hasStoredToken();

    if (!mounted) return;

    // enabled এবং token দুটোই থাকলে UI তে active দেখাবে
    final isReady = enabled && hasToken;
    setState(() => _fingerprintEnabled = isReady);

    // auto-trigger: শুধু একবার, এবং শুধু token থাকলে
    if (isReady && !_autoTriggered) {
      _autoTriggered = true;
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) {
        _loginWithFingerprint(auto: true);
      }
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _pulseCtrl.dispose();
    _glowCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _device {
    try {
      return Platform.isAndroid ? 'Android' : Platform.isIOS ? 'iOS' : 'Unknown';
    } catch (_) { return 'Unknown'; }
  }

  Future<bool> _isEmailBlocked(String email) async {
    try {
      final result = await supabase.rpc(
        'is_email_blocked',
        params: {'check_email': email.toLowerCase().trim()},
      );
      return result == true;
    } catch (_) { return false; }
  }

  Future<bool> _hasAccount(String email) async {
    try {
      final res = await supabase
          .from('profiles')
          .select('id')
          .eq('email', email.toLowerCase().trim())
          .maybeSingle();
      return res != null;
    } catch (_) { return false; }
  }

  // ── Fingerprint login ──────────────────────────────────────────────────────

  Future<void> _loginWithFingerprint({bool auto = false}) async {
    if (_fingerprintLoading) return;

    // Enabled না থাকলে — Settings এ যাওয়ার dialog দেখাও
    if (!_fingerprintEnabled) {
      if (!auto) _showFingerprintDisabledDialog();
      return;
    }

    setState(() => _fingerprintLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final response = await BiometricAuthService.loginWithFingerprint();

      if (!mounted) return;

      if (response == null) {
        // login fail হলে enabled state আবার check করি
        final stillEnabled  = await BiometricAuthService.isFingerprintEnabled();
        final stillHasToken = await BiometricAuthService.hasStoredToken();
        final stillReady    = stillEnabled && stillHasToken;

        if (mounted) {
          setState(() => _fingerprintEnabled = stillReady);
        }

        // auto-attempt ব্যর্থ হলে popup দেখানো হবে না।
        if (!auto && mounted) {
          if (!stillReady) {
            _showBanner(
              icon: Icons.fingerprint_rounded,
              color: Colors.orangeAccent,
              title: 'Fingerprint Session Expired',
              message: 'Your fingerprint session has expired. Please login with email and re-enable fingerprint in Settings.',
            );
          } else {
            _showError('Fingerprint login failed. Please try again, or use email login.');
          }
        }
        return;
      }

      // সফল login এর পরে নিশ্চিত করি refresh token সেভ আছে
      await BiometricAuthService.refreshStoredToken();

      await ActivityLogger.log(activityType: 'login_success', device: _device);
      if (!mounted) return;
      AuthGuardService.init(context);
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);

    } catch (_) {
      if (mounted && !auto) _showError('Fingerprint login failed. Use email login.');
    } finally {
      if (mounted) setState(() => _fingerprintLoading = false);
    }
  }

  // ── Email login ────────────────────────────────────────────────────────────

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
      final blocked = await _isEmailBlocked(email);
      if (blocked) {
        _showBanner(
          icon: Icons.block_rounded, color: const Color(0xFFFF5722),
          title: 'Account Restricted',
          message: 'You cannot login or create a new account with this email address.',
        );
        return;
      }

      final hasAccount = await _hasAccount(email);
      if (!hasAccount) {
        _showBanner(
          icon: Icons.person_off_rounded, color: const Color(0xFF9C27B0),
          title: 'No Account Found',
          message: 'You have no account with this email. Please create a new account.',
          actionLabel: 'Create Account',
          onAction: () => Navigator.pop(context),
        );
        return;
      }

      final authRes = await supabase.auth.signInWithPassword(
        email: email, password: password,
      );
      if (authRes.user == null) throw const AuthException('Login failed');

      // Email login সফল হলে fingerprint এর stored token refresh করি
      await BiometricAuthService.refreshStoredToken();

      final factors = await supabase.auth.mfa.listFactors();
      final hasMfa  = factors.all.any((f) => f.status == FactorStatus.verified);

      const testEmails = ['googlereview@myapp.com'];
      if (testEmails.contains(email)) {
        if (!mounted) return;
        await ActivityLogger.log(activityType: 'login_success', device: _device);
        AuthGuardService.init(context);
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
        return;
      }

      await supabase.auth.signOut();
      if (!mounted) return;

      if (hasMfa) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => MFALoginVerifyPage(email: email, password: password),
        ));
      } else {
        await supabase.auth.signInWithOtp(email: email, shouldCreateUser: false);
        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => OtpVerifyPage(email: email),
        ));
      }
    } on AuthException catch (e) {
      await ActivityLogger.log(
          activityType: 'login_failed', detail: 'wrong_pass', device: _device);
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid') || msg.contains('credentials') || msg.contains('password')) {
        _showBanner(
          icon: Icons.lock_outline_rounded, color: const Color(0xFFEF5350),
          title: 'Incorrect Password',
          message: 'The password you entered is incorrect. Please try again or reset your password.',
          actionLabel: 'Forgot Password?',
          onAction: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ForgotPasswordPage())),
        );
      } else {
        _showError(e.message);
      }
    } catch (e) {
      await ActivityLogger.log(
          activityType: 'login_failed', detail: 'unknown_error', device: _device);
      _showError('Network error. Please check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Error / Dialog UI ──────────────────────────────────────────────────────

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
      backgroundColor: const Color(0xFFEF5350),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    ));
  }

  void _showFingerprintDisabledDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
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
                color: const Color(0xFF0F1E2E).withValues(alpha: 0.97),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color: Colors.cyanAccent.withValues(alpha: 0.35), width: 1.2),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.cyanAccent.withValues(alpha: 0.10),
                    border: Border.all(
                        color: Colors.cyanAccent.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.fingerprint_rounded,
                      color: Colors.cyanAccent, size: 36),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Fingerprint Not Enabled',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 20),
                ),
                const SizedBox(height: 12),
                Text(
                  'Go to Settings → Security to enable fingerprint login.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 14,
                      height: 1.6),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: const Color(0xFF0A1628),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('OK',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  void _showBanner({
    required IconData icon, required Color color,
    required String title, required String message,
    String? actionLabel, VoidCallback? onAction,
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
                color: const Color(0xFF0F1E2E).withValues(alpha: 0.97),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color: color.withValues(alpha: 0.4), width: 1.2),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.12),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Icon(icon, color: color, size: 36),
                ),
                const SizedBox(height: 20),
                Text(title, textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w800, fontSize: 20)),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14, height: 1.6)),
                const SizedBox(height: 28),
                if (actionLabel != null && onAction != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () { Navigator.pop(ctx); onAction(); },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(actionLabel,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
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
                          color: Colors.white.withValues(alpha: 0.2)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF060D14),
                Color(0xFF0D1F2D),
                Color(0xFF0A2540),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(children: [
            _AnimatedOrb(glowAnim: _glowAnim, top: -80, right: -60,
                size: 260, color: Colors.cyanAccent, opacity: 0.06),
            _AnimatedOrb(glowAnim: _glowAnim, bottom: 60, left: -60,
                size: 200, color: const Color(0xFF00E5FF), opacity: 0.04),
            _AnimatedOrb(glowAnim: _glowAnim, top: 200, left: 20,
                size: 120, color: Colors.tealAccent, opacity: 0.03),

            CustomPaint(
              size: Size(MediaQuery.of(context).size.width,
                  MediaQuery.of(context).size.height),
              painter: _GridPainter(),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(children: [
                        const SizedBox(height: 16),
                        _buildLogoSection(),
                        const SizedBox(height: 40),
                        _buildFormCard(),
                        const SizedBox(height: 32),
                        Text(
                          'Conscious Student Society © 2026',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.2),
                              fontSize: 11, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 16),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Logo section ───────────────────────────────────────────────────────────

  Widget _buildLogoSection() {
    return Column(children: [
      AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, __) => Stack(alignment: Alignment.center, children: [
          Container(
            width: 110, height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent
                      .withValues(alpha: _glowAnim.value * 0.3),
                  blurRadius: 40, spreadRadius: 10,
                ),
              ],
            ),
          ),
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.cyanAccent.withValues(alpha: 0.3),
                  width: 1.5),
              color: Colors.cyanAccent.withValues(alpha: 0.05),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 74, height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.cyanAccent.withValues(alpha: 0.08),
                  border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.2),
                      width: 1),
                ),
                child: const Icon(Icons.lock_person_rounded,
                    size: 34, color: Colors.cyanAccent),
              ),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 22),
      const Text('Welcome Back',
          style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5)),
      const SizedBox(height: 6),
      Text('Sign in to your account',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 14,
              letterSpacing: 0.2)),
    ]);
  }

  // ── Form card ──────────────────────────────────────────────────────────────

  Widget _buildFormCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.08)),
          ),
          child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Section label
            Row(children: [
              Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.cyanAccent,
                  )),
              const SizedBox(width: 10),
              Text('Email Login',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2)),
            ]),
            const SizedBox(height: 24),

            _buildTextField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email_outlined,
              type: TextInputType.emailAddress,
            ),
            const SizedBox(height: 18),

            _buildTextField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock_outline,
              isPassword: true,
            ),
            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ForgotPasswordPage())),
                style: TextButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('Forgot Password?',
                    style: TextStyle(
                        color: Colors.cyanAccent.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 20),

            // ── SIGN IN button + Fingerprint button ────────────────────────
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: _loading
                              ? LinearGradient(colors: [
                            Colors.cyanAccent.withValues(alpha: 0.3),
                            Colors.tealAccent.withValues(alpha: 0.3),
                          ])
                              : const LinearGradient(
                            colors: [
                              Colors.cyanAccent,
                              Color(0xFF00BFA5)
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: _loading
                              ? []
                              : [
                            BoxShadow(
                              color: Colors.cyanAccent
                                  .withValues(alpha: 0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: _loading
                              ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF0F2027)))
                              : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('SIGN IN',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: Color(0xFF0A1628),
                                      letterSpacing: 1.5)),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded,
                                  color: Color(0xFF0A1628), size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Fingerprint button ─────────────────────────────────────
                const SizedBox(width: 12),
                _buildFingerprintButton(),
              ],
            ),

            // Enable না থাকলে hint text
            if (!_fingerprintEnabled) ...[
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/settings'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 12,
                        color: Colors.cyanAccent.withValues(alpha: 0.5)),
                    const SizedBox(width: 6),
                    Text(
                      'Tap fingerprint icon or go to Settings to enable',
                      style: TextStyle(
                          color: Colors.cyanAccent.withValues(alpha: 0.5),
                          fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  // ── Fingerprint button ─────────────────────────────────────────────────────

  Widget _buildFingerprintButton() {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => GestureDetector(
        onTap: _fingerprintLoading ? null : () => _loginWithFingerprint(),
        child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, child) => Transform.scale(
            scale: _fingerprintLoading ? _pulseAnim.value : 1.0,
            child: child,
          ),
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: _fingerprintEnabled
                  ? [
                BoxShadow(
                  color: Colors.cyanAccent
                      .withValues(alpha: _glowAnim.value * 0.35),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
                  : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: _fingerprintEnabled
                          ? [
                        Colors.cyanAccent.withValues(alpha: 0.18),
                        Colors.tealAccent.withValues(alpha: 0.08),
                      ]
                          : [
                        Colors.white.withValues(alpha: 0.05),
                        Colors.white.withValues(alpha: 0.02),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: _fingerprintEnabled
                          ? Colors.cyanAccent.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                  child: _fingerprintLoading
                      ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.cyanAccent, strokeWidth: 2),
                    ),
                  )
                      : Icon(
                    Icons.fingerprint_rounded,
                    size: 28,
                    color: _fingerprintEnabled
                        ? Colors.cyanAccent
                        : Colors.white.withValues(alpha: 0.30),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Text field ─────────────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType type = TextInputType.text,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(),
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2)),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        obscureText: isPassword ? _obscure : false,
        keyboardType: type,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        onSubmitted: (_) {
          if (!isPassword) FocusScope.of(context).nextFocus();
          else if (!_loading) _login();
        },
        decoration: InputDecoration(
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(icon,
                color: Colors.cyanAccent.withValues(alpha: 0.5), size: 20),
          ),
          prefixIconConstraints:
          const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              _obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.white.withValues(alpha: 0.3),
              size: 20,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          )
              : null,
          filled: true,
          fillColor: Colors.black.withValues(alpha: 0.25),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
            BorderSide(color: Colors.white.withValues(alpha: 0.07)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
            const BorderSide(color: Colors.cyanAccent, width: 1.2),
          ),
        ),
      ),
    ]);
  }
}

// ── Animated background orb ────────────────────────────────────────────────

class _AnimatedOrb extends StatelessWidget {
  final Animation<double> glowAnim;
  final double? top, bottom, left, right;
  final double size;
  final Color color;
  final double opacity;

  const _AnimatedOrb({
    required this.glowAnim,
    this.top, this.bottom, this.left, this.right,
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: AnimatedBuilder(
        animation: glowAnim,
        builder: (_, __) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: opacity * glowAnim.value),
          ),
        ),
      ),
    );
  }
}

// ── Grid background painter ────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.025)
      ..strokeWidth = 0.5;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
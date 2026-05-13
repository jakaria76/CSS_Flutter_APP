import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'otp_verify_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>
    with SingleTickerProviderStateMixin {
  final _nameController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;

  bool _loading = false;
  bool _obscure = true;

  late AnimationController _animCtrl;
  late Animation<double>    _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Blocked email check ────────────────────────────────────────────────────

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

  // ── Signup logic ───────────────────────────────────────────────────────────

  Future<void> _signup() async {
    if (_loading) return;

    final name     = _nameController.text.trim();
    final email    = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.length < 6) {
      _showError('Please fill all fields (min 6 character password)');
      return;
    }

    setState(() => _loading = true);
    HapticFeedback.heavyImpact();

    try {
      // ── 1. Blocked check ─────────────────────────────────────────────────
      final blocked = await _isEmailBlocked(email);
      if (blocked) {
        _showBanner(
          icon:    Icons.block_rounded,
          color:   const Color(0xFFFF5722),
          title:   'Registration Blocked',
          message:
          'You cannot create an account or login with this email address. '
              'It has been permanently restricted.',
        );
        return;
      }

      // ── 2. Supabase signup ───────────────────────────────────────────────
      final res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      if (res.user == null) {
        _showError('Signup failed. Please try again.');
        return;
      }

      // ── 3. Create profile ────────────────────────────────────────────────
      await _createProfile(res.user!.id, email, name);

      // ── 4. Sign out — OTP verify ছাড়া access নেই ─────────────────────────
      await supabase.auth.signOut();

      if (!mounted) return;

      // ── 5. Send OTP ──────────────────────────────────────────────────────
      await supabase.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => OtpVerifyPage(email: email)),
            (route) => false,
      );
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('already registered') || msg.contains('already exists')) {
        _showBanner(
          icon:    Icons.person_rounded,
          color:   const Color(0xFF4A90E2),
          title:   'Already Registered',
          message: 'An account already exists with this email. Please login instead.',
        );
      } else {
        _showError(e.message);
      }
    } catch (e) {
      _showError('Signup failed. Please check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createProfile(
      String id, String email, String name) async {
    try {
      await supabase.from('profiles').upsert({
        'id':                   id,
        'full_name':            name,
        'email':                email,
        'role':                 'member',
        'donation_eligibility': 'Eligible',
        'created_at':           DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Profile error: $e');
    }
  }

  // ── Error / Banner UI ──────────────────────────────────────────────────────

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline_rounded,
            color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Text(msg,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    ));
  }

  void _showBanner({
    required IconData icon,
    required Color    color,
    required String   title,
    required String   message,
  }) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding:
        const EdgeInsets.symmetric(horizontal: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color:
                const Color(0xFF0F1E2E).withOpacity(0.97),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color: color.withOpacity(0.4), width: 1.2),
              ),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(0.12),
                        border: Border.all(
                            color: color.withOpacity(0.3)),
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
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color:
                              Colors.white.withOpacity(0.2)),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                        ),
                        child: const Text('OK',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14)),
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
              color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
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
        child: Stack(children: [
          Positioned(
              top: -50,
              left: -50,
              child: _blurOrb(200, Colors.cyanAccent.withOpacity(0.1))),
          Positioned(
              bottom: 100,
              right: -30,
              child:
              _blurOrb(150, Colors.purpleAccent.withOpacity(0.05))),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _badgeText('START YOUR JOURNEY'),
                    const SizedBox(height: 12),
                    const Text(
                      'Create\nAccount',
                      style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1),
                    ),
                    const SizedBox(height: 35),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(35),
                      child: BackdropFilter(
                        filter:
                        ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color:
                            Colors.white.withOpacity(0.04),
                            borderRadius:
                            BorderRadius.circular(35),
                            border: Border.all(
                                color: Colors.white
                                    .withOpacity(0.08)),
                          ),
                          child: Column(children: [
                            _customField(_nameController,
                                'FULL NAME', Icons.person_outline),
                            const SizedBox(height: 20),
                            _customField(
                                _emailController,
                                'EMAIL ADDRESS',
                                Icons.email_outlined,
                                type:
                                TextInputType.emailAddress),
                            const SizedBox(height: 20),
                            _passwordField(),
                            const SizedBox(height: 35),
                            _primaryButton(),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── UI helpers ─────────────────────────────────────────────────────────────

  Widget _badgeText(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.cyanAccent.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(text,
        style: const TextStyle(
            color: Colors.cyanAccent,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5)),
  );

  Widget _blurOrb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );

  Widget _customField(
      TextEditingController c,
      String label,
      IconData icon, {
        TextInputType type = TextInputType.text,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
        const SizedBox(height: 8),
        TextField(
          controller: c,
          keyboardType: type,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: _inputDeco(icon),
        ),
      ],
    );
  }

  Widget _passwordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PASSWORD',
            style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: _obscure,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: _inputDeco(Icons.lock_outline).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white38,
                size: 18,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDeco(IconData icon) => InputDecoration(
    prefixIcon: Icon(icon,
        color: Colors.cyanAccent.withOpacity(0.7), size: 20),
    filled: true,
    fillColor: Colors.black.withOpacity(0.25),
    contentPadding: const EdgeInsets.symmetric(vertical: 18),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide:
      BorderSide(color: Colors.white.withOpacity(0.05)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(
          color: Colors.cyanAccent, width: 1.2),
    ),
  );

  Widget _primaryButton() => SizedBox(
    width: double.infinity,
    height: 60,
    child: ElevatedButton(
      onPressed: _loading ? null : _signup,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.cyanAccent,
        foregroundColor: const Color(0xFF0F2027),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        shadowColor: Colors.cyanAccent.withOpacity(0.3),
      ),
      child: _loading
          ? const SizedBox(
          height: 25,
          width: 25,
          child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF0F2027)))
          : const Text('CREATE ACCOUNT',
          style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 1)),
    ),
  );
}
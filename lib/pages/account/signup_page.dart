import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'otp_verify_page.dart'; // LoginPage থেকে same OTP page use করবো

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;

  bool loading = false;
  bool obscure = true;

  // ================= SIGNUP LOGIC =================
  Future<void> signupWithEmail() async {
    if (loading) return;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.length < 6) {
      _showMessage('Please fill all fields (Min 6 chars password)');
      return;
    }

    try {
      setState(() => loading = true);
      HapticFeedback.heavyImpact();

      // Step 1: Supabase-এ signup করো
      final res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      if (res.user == null) {
        _showMessage('Signup failed. Try again.');
        return;
      }

      // Step 2: Profile তৈরি করো
      await _createProfile(res.user!.id, email, name);

      // Step 3: Session থাকলেও sign out করো — OTP ছাড়া home দেবো না
      await supabase.auth.signOut();

      if (!mounted) return;

      // Step 4: OTP পাঠাও
      await supabase.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
      );

      if (!mounted) return;

      // Step 5: OTP verify page-এ পাঠাও (login flow-এর মতোই)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => OtpVerifyPage(email: email)),
            (route) => false,
      );
    } on AuthException catch (e) {
      _showMessage(e.message);
    } catch (e) {
      _showMessage('Signup failed. Try again.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _createProfile(String id, String email, String name) async {
    try {
      await supabase.from('profiles').upsert({
        'id': id,
        'full_name': name,
        'email': email,
        'role': 'member',
        'donation_eligibility': 'Eligible',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Profile error: $e');
    }
  }

  void _showMessage(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError
            ? Colors.redAccent.withOpacity(0.9)
            : Colors.greenAccent.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ================= UI BUILD =================
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
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
                top: -50,
                left: -50,
                child: _blurOrb(200, Colors.cyanAccent.withOpacity(0.1))),
            Positioned(
                bottom: 100,
                right: -30,
                child: _blurOrb(150, Colors.purpleAccent.withOpacity(0.05))),
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 28),
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
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 35),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(35),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(35),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Column(
                            children: [
                              _customField(_nameController, 'FULL NAME',
                                  Icons.person_outline),
                              const SizedBox(height: 20),
                              _customField(
                                  _emailController,
                                  'EMAIL ADDRESS',
                                  Icons.email_outlined,
                                  type: TextInputType.emailAddress),
                              const SizedBox(height: 20),
                              _passwordField(),
                              const SizedBox(height: 35),
                              _primaryButton(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= UI HELPER WIDGETS =================

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
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      boxShadow: [
        BoxShadow(color: color, blurRadius: 100, spreadRadius: 50)
      ],
    ),
  );

  Widget _customField(TextEditingController c, String label, IconData icon,
      {TextInputType type = TextInputType.text}) {
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
          obscureText: obscure,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: _inputDeco(Icons.lock_outline).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white38,
                size: 18,
              ),
              onPressed: () => setState(() => obscure = !obscure),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDeco(IconData icon) => InputDecoration(
    prefixIcon:
    Icon(icon, color: Colors.cyanAccent.withOpacity(0.7), size: 20),
    filled: true,
    fillColor: Colors.black.withOpacity(0.25),
    contentPadding: const EdgeInsets.symmetric(vertical: 18),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Colors.cyanAccent, width: 1.2),
    ),
  );

  Widget _primaryButton() => SizedBox(
    width: double.infinity,
    height: 60,
    child: ElevatedButton(
      onPressed: loading ? null : signupWithEmail,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.cyanAccent,
        foregroundColor: const Color(0xFF0F2027),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        shadowColor: Colors.cyanAccent.withOpacity(0.3),
      ),
      child: loading
          ? const SizedBox(
        height: 25,
        width: 25,
        child: CircularProgressIndicator(
            strokeWidth: 3, color: Color(0xFF0F2027)),
      )
          : const Text('CREATE ACCOUNT',
          style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 1)),
    ),
  );
}
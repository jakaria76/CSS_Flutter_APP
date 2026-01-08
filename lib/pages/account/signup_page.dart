import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../member_home.dart';

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
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _authListener();
  }

  void _authListener() {
    _authSub = supabase.auth.onAuthStateChange.listen((data) async {
      final user = data.session?.user;
      if (user != null) {
        await _createProfileIfNotExists(
          userId: user.id,
          email: user.email ?? '',
          metadata: user.userMetadata,
        );
        _goToHome();
      }
    });
  }

  Future<void> signupWithEmail() async {
    if (loading) return;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.length < 6) {
      _showMessage('Please fill all fields (Password min 6 chars)');
      return;
    }

    try {
      setState(() => loading = true);
      final AuthResponse res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      if (res.session != null && res.user != null) {
        await _createProfileIfNotExists(
          userId: res.user!.id,
          email: email,
          metadata: {'name': name},
        );
        _goToHome();
      } else {
        _showMessage('Verification link sent to your email');
      }
    } on AuthException catch (e) {
      _showMessage(e.message);
    } catch (e) {
      _showMessage('Something went wrong');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> signupWithGoogle() async => await supabase.auth.signInWithOAuth(OAuthProvider.google);
  Future<void> signupWithFacebook() async => await supabase.auth.signInWithOAuth(OAuthProvider.facebook);

  Future<void> _createProfileIfNotExists({required String userId, required String email, Map<String, dynamic>? metadata}) async {
    try {
      final existing = await supabase.from('profiles').select('id').eq('id', userId).maybeSingle();
      if (existing == null) {
        await supabase.from('profiles').insert({
          'id': userId,
          'full_name': metadata?['name'] ?? metadata?['full_name'] ?? 'User',
          'email': email,
          'role': 'member',
          'donation_eligibility': 'Eligible',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Profile error: $e');
    }
  }

  void _goToHome() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MemberHome(isGuest: false)), (_) => false);
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.cyanAccent.withOpacity(0.8), behavior: SnackBarBehavior.floating));
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _nameController.dispose();
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
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
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
            // Decorative background elements
            Positioned(top: -100, left: -100, child: _blurCircle(250, Colors.cyanAccent.withOpacity(0.1))),
            Positioned(bottom: -50, right: -50, child: _blurCircle(200, Colors.redAccent.withOpacity(0.05))),

            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Text('JOIN CSS', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 14)),
                    const SizedBox(height: 8),
                    const Text('Create Account', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                    const Text('Empower the society with your participation', style: TextStyle(color: Colors.white54, fontSize: 15)),
                    const SizedBox(height: 40),

                    // GLASS CARD
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Column(
                            children: [
                              _buildField(controller: _nameController, label: 'Full Name', icon: Icons.person_outline),
                              const SizedBox(height: 20),
                              _buildField(controller: _emailController, label: 'Email Address', icon: Icons.email_outlined, type: TextInputType.emailAddress),
                              const SizedBox(height: 20),
                              _buildPasswordField(),
                              const SizedBox(height: 35),

                              // SIGNUP BUTTON
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: loading ? null : signupWithEmail,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.cyanAccent,
                                    foregroundColor: const Color(0xFF0F2027),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 8,
                                    shadowColor: Colors.cyanAccent.withOpacity(0.4),
                                  ),
                                  child: loading
                                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F2027)))
                                      : const Text('CREATE ACCOUNT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                                ),
                              ),

                              const SizedBox(height: 30),
                              const Row(
                                children: [
                                  Expanded(child: Divider(color: Colors.white12)),
                                  Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("OR", style: TextStyle(color: Colors.white30, fontSize: 12))),
                                  Expanded(child: Divider(color: Colors.white12)),
                                ],
                              ),
                              const SizedBox(height: 30),

                              // SOCIAL BUTTONS
                              Row(
                                children: [
                                  Expanded(child: _socialButton('google', signupWithGoogle)),
                                  const SizedBox(width: 16),
                                  Expanded(child: _socialButton('facebook', signupWithFacebook)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Center(child: Text('CSS • Conscious Student Society', style: TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blurCircle(double size, Color color) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));

  Widget _buildField({required TextEditingController controller, required String label, required IconData icon, TextInputType type = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: type,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.cyanAccent.withOpacity(0.6), size: 20),
            filled: true,
            fillColor: Colors.black.withOpacity(0.2),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.cyanAccent, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PASSWORD', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: obscure,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.lock_outline, color: Colors.cyanAccent.withOpacity(0.6), size: 20),
            suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white38, size: 20), onPressed: () => setState(() => obscure = !obscure)),
            filled: true,
            fillColor: Colors.black.withOpacity(0.2),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.cyanAccent, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _socialButton(String type, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Center(
          child: type == 'google'
              ? Image.asset('assets/images/google.png', height: 24)
              : const Icon(Icons.facebook, color: Colors.blue, size: 28),
        ),
      ),
    );
  }
}
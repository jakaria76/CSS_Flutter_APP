import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'member_home.dart';

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

  // ================= EMAIL SIGNUP =================
  Future<void> signupWithEmail() async {
    if (loading) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.length < 6) {
      _showMessage('Please fill all fields (password ≥ 6 characters)');
      return;
    }

    try {
      setState(() => loading = true);

      await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name, // email signup metadata
        },
      );

      _showMessage('Check your email to verify your account');
    } on AuthException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Signup failed');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ================= GOOGLE LOGIN =================
  Future<void> signupWithGoogle() async {
    try {
      await supabase.auth.signInWithOAuth(OAuthProvider.google);
    } catch (_) {
      _showMessage('Google login failed');
    }
  }

  // ================= FACEBOOK LOGIN =================
  Future<void> signupWithFacebook() async {
    try {
      await supabase.auth.signInWithOAuth(OAuthProvider.facebook);
    } catch (_) {
      _showMessage('Facebook login failed');
    }
  }

  // ================= PROFILE CREATE (FINAL FIX) =================
  Future<void> _createProfileIfNotExists({
    required String userId,
    required String email,
    Map<String, dynamic>? metadata,
  }) async {
    final existing = await supabase
        .from('profiles')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (existing == null) {
      await supabase.from('profiles').insert({
        'user_id': userId,
        'name': metadata?['full_name'] ??
            metadata?['name'] ??
            'User',
        'email': email,
        'role': 'member',
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // ================= NAVIGATION =================
  void _goToHome() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const MemberHome(isGuest: false),
      ),
          (_) => false,
    );
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ================= AUTH LISTENER =================
  @override
  void initState() {
    super.initState();

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

  @override
  void dispose() {
    _authSub?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1D2671), Color(0xFFC33764)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Join Conscious Student Society',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 40),

                // ================= CARD =================
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 22,
                        offset: Offset(0, 12),
                        color: Colors.black26,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _input(
                        controller: _nameController,
                        label: 'Name',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      _input(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        keyboard: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: obscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () =>
                                setState(() => obscure = !obscure),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // EMAIL SIGNUP
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: loading ? null : signupWithEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1D2671),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            loading
                                ? 'Creating Account...'
                                : 'Create Account',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // GOOGLE LOGIN
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton.icon(
                          icon: Image.asset(
                            'assets/images/google.png',
                            height: 22,
                          ),
                          label: const Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: signupWithGoogle,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // FACEBOOK LOGIN
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton.icon(
                          icon: const Icon(
                            Icons.facebook,
                            color: Colors.blue,
                          ),
                          label: const Text(
                            'Continue with Facebook',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: signupWithFacebook,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
                Center(
                  child: Text(
                    'Conscious Student Society',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;

  bool loading = false;
  bool obscureNew = true;
  bool obscureConfirm = true;

  Future<void> _resetPassword() async {
    final newPass = _newPassController.text;
    final confirmPass = _confirmPassController.text;

    if (newPass.length < 6) {
      _showMessage('Password must be at least 6 characters');
      return;
    }
    if (newPass != confirmPass) {
      _showMessage('Passwords do not match');
      return;
    }

    try {
      setState(() => loading = true);
      HapticFeedback.mediumImpact();

      // ForgotOtpVerifyPage এ OTP verify হয়েছে → session আছে
      // সরাসরি updateUser() কাজ করবে
      await supabase.auth.updateUser(UserAttributes(password: newPass));

      // Security best practice: password change হলে sign out
      await supabase.auth.signOut();

      if (!mounted) return;
      _showMessage('Password reset successfully!', isError: false);
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;

      // সব screen সরিয়ে Login page এ নিয়ে যাও
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } on AuthException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Failed to reset password. Try again.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showMessage(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  void dispose() {
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Back বন্ধ
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(top: -60, right: -40,
                child: _blurOrb(180, Colors.cyanAccent.withOpacity(0.08))),
            Positioned(bottom: 100, left: -30,
                child: _blurOrb(150, Colors.purpleAccent.withOpacity(0.05))),
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
                        child: const Icon(Icons.lock_open_rounded,
                            size: 60, color: Colors.cyanAccent),
                      ),
                      const SizedBox(height: 24),
                      const Text('New Password',
                          style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                      const SizedBox(height: 10),
                      const Text(
                        'Create a strong password for your account.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                      const SizedBox(height: 40),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
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
                                _buildPasswordField(
                                  controller: _newPassController,
                                  label: 'NEW PASSWORD',
                                  obscure: obscureNew,
                                  onToggle: () =>
                                      setState(() => obscureNew = !obscureNew),
                                ),
                                const SizedBox(height: 20),
                                _buildPasswordField(
                                  controller: _confirmPassController,
                                  label: 'CONFIRM PASSWORD',
                                  obscure: obscureConfirm,
                                  onToggle: () => setState(
                                          () => obscureConfirm = !obscureConfirm),
                                ),
                                const SizedBox(height: 32),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: loading ? null : _resetPassword,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.cyanAccent,
                                      foregroundColor: const Color(0xFF0F2027),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(16)),
                                    ),
                                    child: loading
                                        ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFF0F2027)))
                                        : const Text('RESET PASSWORD',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 10)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.lock_outline,
                color: Colors.cyanAccent.withOpacity(0.6)),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white38,
              ),
              onPressed: onToggle,
            ),
            filled: true,
            fillColor: Colors.black.withOpacity(0.2),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
              const BorderSide(color: Colors.cyanAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _blurOrb(double size, Color color) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}
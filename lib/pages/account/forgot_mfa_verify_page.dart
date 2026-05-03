import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'reset_password_page.dart';

class ForgotMfaVerifyPage extends StatefulWidget {
  const ForgotMfaVerifyPage({super.key});

  @override
  State<ForgotMfaVerifyPage> createState() => _ForgotMfaVerifyPageState();
}

class _ForgotMfaVerifyPageState extends State<ForgotMfaVerifyPage> {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _supabase = Supabase.instance.client;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verifyMfa() async {
    if (_otp.length < 6) {
      _showMessage('Please enter the 6-digit authenticator code');
      return;
    }

    setState(() => _isVerifying = true);
    try {
      final factors = await _supabase.auth.mfa.listFactors();
      final factor = factors.all.firstWhere(
            (f) => f.status == FactorStatus.verified,
      );

      final challenge =
      await _supabase.auth.mfa.challenge(factorId: factor.id);

      await _supabase.auth.mfa.verify(
        factorId: factor.id,
        challengeId: challenge.id,
        code: _otp,
      );

      // ✅ AAL2 session তৈরি হয়েছে → এখন password reset করা যাবে
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
      );
    } on AuthException catch (_) {
      _showMessage('Invalid authenticator code. Try again.');
      _clearCode();
    } catch (_) {
      _showMessage('Verification failed. Try again.');
      _clearCode();
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _clearCode() {
    for (final c in _controllers) c.clear();
    _focusNodes.first.requestFocus();
  }

  void _showMessage(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
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
              child: _blurOrb(180, Colors.cyanAccent.withOpacity(0.08)),
            ),
            Positioned(
              bottom: 80,
              left: -40,
              child: _blurOrb(140, Colors.purpleAccent.withOpacity(0.05)),
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
                          Icons.shield_rounded,
                          size: 60,
                          color: Colors.cyanAccent,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'MFA Verification',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Enter the 6-digit code from your\nauthenticator app to continue.',
                        textAlign: TextAlign.center,
                        style:
                        TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                      const SizedBox(height: 40),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter:
                          ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: List.generate(
                                      6, (i) => _buildOtpBox(i)),
                                ),
                                const SizedBox(height: 32),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isVerifying
                                        ? null
                                        : _verifyMfa,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.cyanAccent,
                                      foregroundColor:
                                      const Color(0xFF0F2027),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _isVerifying
                                        ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF0F2027),
                                      ),
                                    )
                                        : const Text(
                                      'VERIFY & CONTINUE',
                                      style: TextStyle(
                                          fontWeight:
                                          FontWeight.bold),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.black.withOpacity(0.25),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
            BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
                color: Colors.cyanAccent, width: 1.5),
          ),
        ),
        onChanged: (val) {
          if (val.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (val.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          if (_otp.length == 6) {
            FocusScope.of(context).unfocus();
            _verifyMfa();
          }
        },
      ),
    );
  }

  Widget _blurOrb(double size, Color color) => Container(
      width: size,
      height: size,
      decoration:
      BoxDecoration(shape: BoxShape.circle, color: color));
}
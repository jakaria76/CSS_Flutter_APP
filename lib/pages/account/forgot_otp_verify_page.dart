import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'reset_password_page.dart';
import 'forgot_mfa_verify_page.dart'; // নতুন import

class ForgotOtpVerifyPage extends StatefulWidget {
  final String email;
  const ForgotOtpVerifyPage({super.key, required this.email});

  @override
  State<ForgotOtpVerifyPage> createState() => _ForgotOtpVerifyPageState();
}

class _ForgotOtpVerifyPageState extends State<ForgotOtpVerifyPage> {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final SupabaseClient supabase = Supabase.instance.client;

  bool loading = false;
  int _resendSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes.first.requestFocus();
    });
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendSeconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSeconds <= 0) {
        t.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    if (_otp.length < 6) {
      _showMessage('Please enter the complete 6-digit code');
      return;
    }

    try {
      setState(() => loading = true);
      HapticFeedback.mediumImpact();

      final res = await supabase.auth.verifyOTP(
        email: widget.email,
        token: _otp,
        type: OtpType.email,
      );

      if (res.session == null) throw Exception('Verification failed');

      // ✅ MFA check করো
      final factors = await supabase.auth.mfa.listFactors();
      final hasMfa =
      factors.all.any((f) => f.status == FactorStatus.verified);

      if (!mounted) return;

      if (hasMfa) {
        // MFA আছে → TOTP verify করাও তারপর reset
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ForgotMfaVerifyPage(),
          ),
        );
      } else {
        // MFA নেই → সরাসরি reset page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
        );
      }
    } on AuthException catch (e) {
      _showMessage(e.message);
      _clearOtp();
    } catch (_) {
      _showMessage('Invalid or expired code. Try again.');
      _clearOtp();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _resendOtp() async {
    try {
      HapticFeedback.lightImpact();
      await supabase.auth.signInWithOtp(
        email: widget.email,
        shouldCreateUser: false,
      );
      _startResendTimer();
      _showMessage('Code resent to ${widget.email}', isError: false);
    } on AuthException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Failed to resend. Try again.');
    }
  }

  void _clearOtp() {
    for (final c in _controllers) c.clear();
    _focusNodes.first.requestFocus();
  }

  void _showMessage(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
        isError ? Colors.redAccent : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
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
                child: _blurOrb(180, Colors.cyanAccent.withOpacity(0.08))),
            Positioned(
                bottom: 80,
                left: -40,
                child:
                _blurOrb(140, Colors.purpleAccent.withOpacity(0.05))),
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
                        child: const Icon(Icons.security_rounded,
                            size: 60, color: Colors.cyanAccent),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Enter Reset Code',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'We sent a 6-digit code to\n${widget.email}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 14),
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
                                    onPressed: loading ? null : _verifyOtp,
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
                                      'VERIFY CODE',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _resendSeconds > 0
                                    ? Text(
                                  'Resend in $_resendSeconds s',
                                  style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 13),
                                )
                                    : TextButton(
                                  onPressed: _resendOtp,
                                  child: const Text(
                                    'Resend Code',
                                    style: TextStyle(
                                        color: Colors.cyanAccent),
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
            fontWeight: FontWeight.bold),
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
            _verifyOtp();
          }
        },
      ),
    );
  }

  Widget _blurOrb(double size, Color color) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}
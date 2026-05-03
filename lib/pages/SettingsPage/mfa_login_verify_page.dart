import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'settings_constants.dart';
import '../../services/session_service.dart';

class MFALoginVerifyPage extends StatefulWidget {
  final String email;
  final String password;
  const MFALoginVerifyPage({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<MFALoginVerifyPage> createState() => _MFALoginVerifyPageState();
}

class _MFALoginVerifyPageState extends State<MFALoginVerifyPage>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  late AnimationController _fadeCtrl;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
        value: 0)
      ..forward();
    _signInAndAwaitMfa();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  // আগে sign in করো যাতে MFA challenge দেওয়া যায়
  Future<void> _signInAndAwaitMfa() async {
    try {
      await _supabase.auth.signInWithPassword(
        email: widget.email,
        password: widget.password,
      );
      // এখন session আছে কিন্তু MFA pending — ভেরিফাই না হওয়া পর্যন্ত কিছু access নেই
    } catch (e) {
      if (mounted) {
        SC.toast(context, 'Login error: ${e.toString()}', SC.red);
        Navigator.pop(context);
      }
    }
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verifyMfa() async {
    if (_otp.length < 6) {
      SC.toast(context, SC.tr('mfa_enter_code'), SC.orange);
      return;
    }
    setState(() => _isVerifying = true);
    try {
      final factors = await _supabase.auth.mfa.listFactors();
      if (factors.all.isEmpty) throw Exception('No MFA factor found');

      final factorId = factors.all
          .firstWhere((f) => f.status == FactorStatus.verified)
          .id;

      final challenge =
      await _supabase.auth.mfa.challenge(factorId: factorId);

      await _supabase.auth.mfa.verify(
        factorId: factorId,
        challengeId: challenge.id,
        code: _otp,
      );

      // MFA সফল — session save করো
      await SessionService.saveSession();

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } on AuthException catch (_) {
      if (mounted) {
        SC.toast(context, SC.tr('mfa_invalid_code'), SC.red);
        _clearCode();
      }
    } catch (e) {
      if (mounted) {
        SC.toast(context, SC.tr('mfa_invalid_code'), SC.red);
        _clearCode();
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _clearCode() {
    for (final c in _controllers) c.clear();
    _focusNodes.first.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF070B12),
        resizeToAvoidBottomInset: true,
        body: Stack(children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0B1220), Color(0xFF070B12), Color(0xFF0A0F1A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Orbs
          Positioned(
            top: -80, right: -50,
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  SC.green.withValues(alpha: 0.08),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeCtrl,
              child: Column(children: [
                // Back button
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white70, size: 15),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                    child: Column(children: [
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: SC.green.withValues(alpha: 0.1),
                          border: Border.all(
                              color: SC.green.withValues(alpha: 0.3), width: 1.5),
                        ),
                        child: const Icon(Icons.security_rounded,
                            color: SC.green, size: 42),
                      ),
                      const SizedBox(height: 24),
                      Text(SC.tr('mfa_login_title'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3)),
                      const SizedBox(height: 8),
                      Text(SC.tr('mfa_login_subtitle'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 13,
                              height: 1.5)),
                      const SizedBox(height: 36),

                      // Code input
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: Column(children: [
                              LayoutBuilder(builder: (ctx, constraints) {
                                final w = (constraints.maxWidth - 5 * 8) / 6;
                                return Row(
                                  children: List.generate(
                                      6,
                                          (i) => Row(children: [
                                        _otpBox(i, w),
                                        if (i < 5)
                                          const SizedBox(width: 8),
                                      ])),
                                );
                              }),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: _isVerifying
                                    ? Container(
                                  decoration: BoxDecoration(
                                    color: SC.green.withValues(alpha: 0.5),
                                    borderRadius:
                                    BorderRadius.circular(16),
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 22, height: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5),
                                    ),
                                  ),
                                )
                                    : ElevatedButton(
                                  onPressed: _verifyMfa,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: SC.green,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(16)),
                                  ),
                                  child: Text(SC.tr('mfa_verify_enable'),
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800)),
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _otpBox(int index, double width) => SizedBox(
    width: width,
    height: width * 1.2,
    child: TextField(
      controller: _controllers[index],
      focusNode: _focusNodes[index],
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      maxLength: 1,
      style: TextStyle(
        color: Colors.white,
        fontSize: width * 0.4,
        fontWeight: FontWeight.w800,
      ),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        counterText: '',
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
          BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: SC.green, width: 2),
        ),
        contentPadding: EdgeInsets.zero,
      ),
      onChanged: (val) {
        if (val.isNotEmpty && index < 5) {
          _focusNodes[index + 1].requestFocus();
        } else if (val.isEmpty && index > 0) {
          _focusNodes[index - 1].requestFocus();
        }
        if (_otp.length == 6) {
          FocusScope.of(context).unfocus();
          Future.delayed(const Duration(milliseconds: 200), _verifyMfa);
        }
      },
    ),
  );
}
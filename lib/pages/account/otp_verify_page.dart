import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:css/services/session_service.dart';
import 'package:css/services/auth_guard_service.dart'; // ✅ NEW

class OtpVerifyPage extends StatefulWidget {
  final String email;
  const OtpVerifyPage({super.key, required this.email});

  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage>
    with TickerProviderStateMixin {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final SupabaseClient supabase = Supabase.instance.client;

  bool loading = false;
  int _resendSeconds = 600;
  Timer? _timer;

  late AnimationController _pulseCtrl;
  late AnimationController _shimmerCtrl;
  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _startResendTimer();

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat();

    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic),
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes.first.requestFocus();
    });
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendSeconds = 600);
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
      _showMessage('৬ সংখ্যার OTP সম্পূর্ণ করুন');
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

      if (res.user == null) throw Exception('Verification failed');

      // ✅ Session save করো
      await SessionService.saveSession();

      if (!mounted) return;

      // ✅ AuthGuard চালু করো — admin block/delete হলে auto logout হবে
      AuthGuardService.init(context);

      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } on AuthException catch (e) {
      _showMessage(e.message);
      _clearOtp();
    } catch (_) {
      _showMessage('OTP ভুল বা মেয়াদ শেষ। আবার চেষ্টা করুন।');
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
      _showMessage('OTP পুনরায় পাঠানো হয়েছে', isError: false);
    } catch (_) {
      _showMessage('OTP পাঠাতে ব্যর্থ। আবার চেষ্টা করুন।');
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
        content: Text(msg,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        backgroundColor:
        isError ? const Color(0xFFE53E3E) : const Color(0xFF38A169),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(14),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF070B12),
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            _buildBackground(),
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                          child: Column(
                            children: [
                              const SizedBox(height: 32),
                              _buildIconHeader(),
                              const SizedBox(height: 28),
                              _buildTitle(),
                              const SizedBox(height: 8),
                              _buildSubtitle(),
                              const SizedBox(height: 36),
                              _buildCard(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0B1220),
                Color(0xFF070B12),
                Color(0xFF0A0F1A)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -80,
          right: -50,
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => _orb(
              260,
              const Color(0xFF06B6D4)
                  .withOpacity(0.07 + _pulseCtrl.value * 0.04),
            ),
          ),
        ),
        Positioned(
          bottom: 60,
          left: -60,
          child: _orb(200, const Color(0xFF8B5CF6).withOpacity(0.06)),
        ),
        Positioned(
          top: 200,
          left: -40,
          child: _orb(160, const Color(0xFF10B981).withOpacity(0.05)),
        ),
        CustomPaint(
          painter: _DotPainter(),
          size: Size(MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                Color(0xFF06B6D4),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _orb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
          colors: [color, Colors.transparent], stops: const [0.0, 1.0]),
    ),
  );

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border:
                    Border.all(color: Colors.white.withOpacity(0.10)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white70, size: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconHeader() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF06B6D4)
                    .withOpacity(0.12 + _pulseCtrl.value * 0.10),
                width: 1,
              ),
            ),
          ),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF0E1E30), Color(0xFF0A1520)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: const Color(0xFF06B6D4).withOpacity(0.25),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF06B6D4)
                      .withOpacity(0.15 + _pulseCtrl.value * 0.12),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.mark_email_read_rounded,
                size: 38, color: Color(0xFF06B6D4)),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (_, __) => ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: const [
            Color(0xFFE0F7FA),
            Color(0xFF06B6D4),
            Color(0xFF8B5CF6),
            Color(0xFF06B6D4),
            Color(0xFFE0F7FA),
          ],
          stops: [
            0.0,
            (_shimmerCtrl.value * 0.5).clamp(0.0, 0.25),
            (_shimmerCtrl.value * 0.5 + 0.25).clamp(0.1, 0.6),
            (_shimmerCtrl.value * 0.5 + 0.45).clamp(0.35, 0.85),
            1.0,
          ],
        ).createShader(bounds),
        child: const Text(
          'ইমেইল যাচাই করুন',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return Column(
      children: [
        Text(
          '৬ সংখ্যার কোড পাঠানো হয়েছে',
          style: TextStyle(
              color: Colors.white.withOpacity(0.45), fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF06B6D4).withOpacity(0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFF06B6D4).withOpacity(0.25), width: 0.8),
          ),
          child: Text(
            widget.email,
            style: const TextStyle(
              color: Color(0xFF06B6D4),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.055),
                Colors.white.withOpacity(0.018),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFF06B6D4),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'OTP কোড লিখুন',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  const gapCount = 5;
                  const gapSize = 8.0;
                  final boxWidth = (totalWidth - gapCount * gapSize) / 6;
                  final boxHeight = boxWidth * 1.25;

                  return Row(
                    children: List.generate(6, (i) {
                      return Row(
                        children: [
                          _buildOtpBox(i, boxWidth, boxHeight),
                          if (i < 5) const SizedBox(width: gapSize),
                        ],
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: loading ? _loadingBtn() : _verifyBtn(),
              ),
              const SizedBox(height: 22),
              _buildResendRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _verifyBtn() {
    return GestureDetector(
      onTap: _verifyOtp,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF06B6D4).withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'OTP যাচাই করুন',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _loadingBtn() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF06B6D4).withOpacity(0.5),
            const Color(0xFF0891B2).withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child:
          CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildResendRow() {
    if (_resendSeconds > 0) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: _resendSeconds / 60.0,
                  strokeWidth: 2,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  color: const Color(0xFF06B6D4).withOpacity(0.5),
                ),
                Text(
                  '$_resendSeconds',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'পুনরায় পাঠাতে অপেক্ষা করুন',
            style: TextStyle(
                color: Colors.white.withOpacity(0.35), fontSize: 12.5),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _resendOtp,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF06B6D4).withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFF06B6D4).withOpacity(0.25), width: 0.8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh_rounded, color: Color(0xFF06B6D4), size: 15),
            SizedBox(width: 7),
            Text(
              'OTP পুনরায় পাঠান',
              style: TextStyle(
                color: Color(0xFF06B6D4),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index, double width, double height) {
    return SizedBox(
      width: width,
      height: height,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: TextStyle(
          color: Colors.white,
          fontSize: width * 0.42,
          fontWeight: FontWeight.w800,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            BorderSide(color: Colors.white.withOpacity(0.10), width: 0.8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            const BorderSide(color: Color(0xFF06B6D4), width: 1.8),
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
            Future.delayed(const Duration(milliseconds: 200), _verifyOtp);
          }
        },
      ),
    );
  }
}

class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1C3050).withOpacity(0.40)
      ..style = PaintingStyle.fill;
    const step = 30.0;
    for (double x = step; x < size.width; x += step) {
      for (double y = step; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 0.9, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotPainter _) => false;
}
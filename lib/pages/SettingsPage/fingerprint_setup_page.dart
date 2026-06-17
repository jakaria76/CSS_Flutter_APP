import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'settings_constants.dart';
import 'package:css/services/biometric_auth_service.dart';

/// একটি dedicated full-screen page — যেখানে user fingerprint scan করে
/// biometric login enable করতে পারবে। SettingsPage থেকে toggle ON করলে
/// এই page open হয়; scan সফল হলে true নিয়ে pop করে।
class FingerprintSetupPage extends StatefulWidget {
  const FingerprintSetupPage({super.key});

  @override
  State<FingerprintSetupPage> createState() => _FingerprintSetupPageState();
}

enum _ScanState { idle, scanning, success, failed }

class _FingerprintSetupPageState extends State<FingerprintSetupPage>
    with TickerProviderStateMixin {
  _ScanState _state = _ScanState.idle;
  String? _errorMsg;

  late AnimationController _pulseCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 0.75)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _glowCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    if (_state == _ScanState.scanning) return;

    setState(() {
      _state = _ScanState.scanning;
      _errorMsg = null;
    });
    HapticFeedback.mediumImpact();

    // device এ fingerprint hardware/enrollment আছে কিনা আগে চেক
    final isAvail = await BiometricAuthService.isBiometricAvailable();
    if (!isAvail) {
      if (!mounted) return;
      setState(() {
        _state = _ScanState.failed;
        _errorMsg = SC.tr('fingerprint_unavailable_msg');
      });
      HapticFeedback.heavyImpact();
      return;
    }

    final success = await BiometricAuthService.enableFingerprint();

    if (!mounted) return;

    if (success) {
      HapticFeedback.heavyImpact();
      setState(() => _state = _ScanState.success);
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      Navigator.pop(context, true);
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _state = _ScanState.failed;
        _errorMsg = SC.tr('fingerprint_failed_msg');
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SC.languageNotifier,
      builder: (context, _, __) {
        return ValueListenableBuilder<String>(
          valueListenable: SC.themeModeNotifier,
          builder: (context, __, ___) {
            final isDark = SC.isDark;
            final bgColor = isDark ? SC.bgStart : const Color(0xFFF0F4FF);
            final textColor = isDark ? Colors.white : const Color(0xFF1A2332);

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: isDark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark,
              child: Scaffold(
                extendBodyBehindAppBar: true,
                backgroundColor: bgColor,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: _buildBackButton(isDark, textColor),
                  title: Text(
                    SC.tr('fingerprint_login'),
                    style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        letterSpacing: 0.5),
                  ),
                  centerTitle: true,
                ),
                body: _buildBackground(
                  child: SafeArea(
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Column(children: [
                        Expanded(
                          child: Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildScanCircle(),
                                  const SizedBox(height: 36),
                                  _buildStatusText(textColor),
                                  const SizedBox(height: 14),
                                  _buildSubText(textColor),
                                ],
                              ),
                            ),
                          ),
                        ),
                        _buildBottomArea(isDark, textColor),
                      ]),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Scan circle (animated) ───────────────────────────────────────────────

  Widget _buildScanCircle() {
    final isScanning = _state == _ScanState.scanning;
    final isSuccess = _state == _ScanState.success;
    final isFailed = _state == _ScanState.failed;

    final Color ringColor = isSuccess
        ? SC.green
        : isFailed
        ? SC.red
        : SC.cyan;

    return GestureDetector(
      onTap: (_state == _ScanState.idle || _state == _ScanState.failed)
          ? _startScan
          : null,
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, __) => Stack(alignment: Alignment.center, children: [
          // Outer glow
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ringColor.withValues(
                      alpha: (isScanning ? _glowAnim.value : 0.35) * 0.4),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
          // Outer ring
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: ringColor.withValues(alpha: 0.25), width: 1.5),
            ),
          ),
          // Mid glass ring
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) => Transform.scale(
              scale: isScanning ? _pulseAnim.value : 1.0,
              child: child,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(80),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ringColor.withValues(alpha: 0.08),
                    border: Border.all(
                        color: ringColor.withValues(alpha: 0.4), width: 2),
                  ),
                  child: Center(
                    child: isScanning
                        ? SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                          color: ringColor, strokeWidth: 2.4),
                    )
                        : Icon(
                      isSuccess
                          ? Icons.check_rounded
                          : isFailed
                          ? Icons.close_rounded
                          : Icons.fingerprint_rounded,
                      size: 72,
                      color: ringColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Status / sub text ────────────────────────────────────────────────────

  Widget _buildStatusText(Color textColor) {
    String text;
    Color color = textColor;
    switch (_state) {
      case _ScanState.idle:
        text = SC.tr('fingerprintTapToScan');
        break;
      case _ScanState.scanning:
        text = SC.tr('fingerprintScanning');
        color = SC.cyan;
        break;
      case _ScanState.success:
        text = SC.tr('fingerprint_enabled_title');
        color = SC.green;
        break;
      case _ScanState.failed:
        text = SC.tr('fingerprint_failed_title');
        color = SC.red;
        break;
    }
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
          color: color, fontWeight: FontWeight.w800, fontSize: 20),
    );
  }

  Widget _buildSubText(Color textColor) {
    String text;
    switch (_state) {
      case _ScanState.idle:
        text = SC.tr('fingerprintTapToScanSub');
        break;
      case _ScanState.scanning:
        text = SC.tr('fingerprintScanningSub');
        break;
      case _ScanState.success:
        text = SC.tr('fingerprint_enabled_msg');
        break;
      case _ScanState.failed:
        text = _errorMsg ?? SC.tr('fingerprint_failed_msg');
        break;
    }
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
          color: textColor.withValues(alpha: 0.5),
          fontSize: 13,
          height: 1.6),
    );
  }

  // ── Bottom action area ───────────────────────────────────────────────────

  Widget _buildBottomArea(bool isDark, Color textColor) {
    final showRetry = _state == _ScanState.failed;
    final showScanBtn = _state == _ScanState.idle;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      child: Column(children: [
        if (showScanBtn || showRetry)
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _startScan,
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
                  gradient: const LinearGradient(
                    colors: [SC.cyan, Color(0xFF00BFA5)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: SC.cyan.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: Text(
                    showRetry
                        ? SC.tr('retry')
                        : SC.tr('fingerprintScanBtn'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Color(0xFF0A1628),
                        letterSpacing: 1.0),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: textColor.withValues(alpha: 0.18)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              SC.tr('cancel'),
              style: TextStyle(
                  color: textColor.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w600,
                  fontSize: 14),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Back button ───────────────────────────────────────────────────────────

  Widget _buildBackButton(bool isDark, Color textColor) => Padding(
    padding: const EdgeInsets.all(10),
    child: ClipOval(
      child: Container(
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black)
              .withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.2)),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          onPressed: () => Navigator.pop(context, false),
          color: textColor,
        ),
      ),
    ),
  );

  // ── Background ────────────────────────────────────────────────────────────

  Widget _buildBackground({required Widget child}) => Stack(children: [
    Container(decoration: BoxDecoration(gradient: SC.currentGradient)),
    Positioned(
        top: -80,
        right: -60,
        child: SC.blob(260, SC.cyan.withValues(alpha: 0.04))),
    Positioned(
        bottom: 200,
        left: -120,
        child: SC.blob(240, SC.blue.withValues(alpha: 0.04))),
    child,
  ]);
}
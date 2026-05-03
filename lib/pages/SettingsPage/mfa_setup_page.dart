import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'settings_constants.dart';

class MFASetupPage extends StatefulWidget {
  const MFASetupPage({super.key});

  @override
  State<MFASetupPage> createState() => _MFASetupPageState();
}

class _MFASetupPageState extends State<MFASetupPage>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  late AnimationController _fadeCtrl;

  String? _qrUri;
  String? _factorId;
  bool _isLoadingQr = true;
  bool _isVerifying = false;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700),
        value: 0)
      ..forward();
    _startEnrollment();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  Future<void> _startEnrollment() async {
    try {
      // আগের pending unverified enrollment cancel করো
      final existing = await _supabase.auth.mfa.listFactors();
      for (final f in existing.all) {
        if (f.status == FactorStatus.unverified) {
          // নতুন API: positional argument
          await _supabase.auth.mfa.unenroll(f.id);
        }
      }

      final res = await _supabase.auth.mfa.enroll(
        factorType: FactorType.totp,
        issuer: 'CSS App',
        friendlyName: 'CSS Mobile',
      );

      if (!mounted) return;
      setState(() {
        _factorId = res.id;
        _qrUri = res.totp?.uri;
        _isLoadingQr = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingQr = false);
      SC.toast(context, 'Error: ${e.toString()}', SC.red);
    }
  }
  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verifyAndEnable() async {
    if (_otp.length < 6) {
      SC.toast(context, SC.tr('mfa_enter_code'), SC.orange);
      return;
    }
    if (_factorId == null) return;

    setState(() => _isVerifying = true);
    try {
      final challenge =
      await _supabase.auth.mfa.challenge(factorId: _factorId!);

      await _supabase.auth.mfa.verify(
        factorId: _factorId!,
        challengeId: challenge.id,
        code: _otp,
      );

      if (!mounted) return;
      setState(() => _success = true);
      SC.toast(context, SC.tr('mfa_enabled_success'), SC.green);

      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) Navigator.pop(context, true); // true = success
    } on AuthException catch (e) {
      if (mounted) {
        SC.toast(context, SC.tr('mfa_invalid_code'), SC.red);
        _clearCode();
      }
    } catch (_) {
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
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (_, __, ___) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (_, __, ___) => _buildPage(),
      ),
    );
  }

  Widget _buildPage() {
    final isDark = SC.isDark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subTextColor =
    isDark ? Colors.white.withValues(alpha: 0.55) : const Color(0xFF4A5568);
    final cardColor = isDark ? SC.cardBg : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.08);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(children: [
          Container(decoration: BoxDecoration(gradient: SC.currentGradient)),
          SC.blob(260, SC.green.withValues(alpha: 0.04)),
          FadeTransition(
            opacity: _fadeCtrl,
            child: SafeArea(
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(children: [
                  // AppBar
                  Row(children: [
                    IconButton(
                      icon:
                      Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        SC.tr('mfa_setup_title'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ]),
                  const SizedBox(height: 24),

                  // Success state
                  if (_success)
                    _buildSuccess(textColor)
                  else ...[
                    // Steps card
                    _buildStepsCard(cardColor, textColor, subTextColor, borderColor),
                    const SizedBox(height: 20),

                    // QR Card
                    _buildQrCard(cardColor, textColor, subTextColor, borderColor),
                    const SizedBox(height: 20),

                    // Code input card
                    _buildCodeCard(cardColor, textColor, subTextColor, borderColor),
                    const SizedBox(height: 24),

                    // Verify button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isVerifying ? null : _verifyAndEnable,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SC.green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isVerifying
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                            : Text(SC.tr('mfa_verify_enable'),
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildStepsCard(Color cardColor, Color textColor, Color subTextColor,
      Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(children: [
        _stepRow('১', SC.tr('mfa_step1'), subTextColor),
        _stepRow('২', SC.tr('mfa_step2'), subTextColor),
        _stepRow('৩', SC.tr('mfa_step3'), subTextColor),
      ]),
    );
  }

  Widget _stepRow(String num, String text, Color subTextColor) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: SC.green.withValues(alpha: 0.12),
          border: Border.all(color: SC.green.withValues(alpha: 0.4)),
        ),
        child: Center(
          child: Text(num,
              style: const TextStyle(
                  color: SC.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w800)),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(text,
              style: TextStyle(color: subTextColor, fontSize: 13, height: 1.5)),
        ),
      ),
    ]),
  );

  Widget _buildQrCard(Color cardColor, Color textColor, Color subTextColor,
      Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SC.green.withValues(alpha: 0.25)),
      ),
      child: Column(children: [
        Text(SC.tr('mfa_scan_qr'),
            textAlign: TextAlign.center,
            style: TextStyle(
                color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 18),
        if (_isLoadingQr)
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: SC.green, strokeWidth: 2),
            ),
          )
        else if (_qrUri != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: QrImageView(
              data: _qrUri!,
              version: QrVersions.auto,
              size: 180,
              backgroundColor: Colors.white,
            ),
          )
        else
          const Icon(Icons.error_outline, color: SC.red, size: 48),
      ]),
    );
  }

  Widget _buildCodeCard(Color cardColor, Color textColor, Color subTextColor,
      Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(SC.tr('mfa_enter_code'),
              style: TextStyle(
                  color: subTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final boxWidth = (constraints.maxWidth - 5 * 8) / 6;
            return Row(
              children: List.generate(6, (i) => Row(children: [
                _otpBox(i, boxWidth),
                if (i < 5) const SizedBox(width: 8),
              ])),
            );
          }),
        ],
      ),
    );
  }

  Widget _otpBox(int index, double width) {
    final isDark = SC.isDark;
    return SizedBox(
      width: width,
      height: width * 1.2,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF1A2332),
          fontSize: width * 0.4,
          fontWeight: FontWeight.w800,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: SC.green.withValues(alpha: 0.05),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
            BorderSide(color: SC.green.withValues(alpha: 0.25), width: 1),
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
            Future.delayed(
                const Duration(milliseconds: 200), _verifyAndEnable);
          }
        },
      ),
    );
  }

  Widget _buildSuccess(Color textColor) {
    return SizedBox(
      height: 400,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SC.green.withValues(alpha: 0.12),
              border: Border.all(color: SC.green.withValues(alpha: 0.4), width: 2),
            ),
            child: const Icon(Icons.verified_user_rounded,
                color: SC.green, size: 56),
          ),
          const SizedBox(height: 20),
          Text(SC.tr('mfa_enabled_success'),
              style: TextStyle(
                  color: textColor, fontSize: 20, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
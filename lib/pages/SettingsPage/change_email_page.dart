import 'dart:ui';
import 'package:css/pages/SettingsPage/notification_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'settings_constants.dart';
import 'package:css/services/activity_logger.dart';

class ChangeEmailPage extends StatefulWidget {
  const ChangeEmailPage({super.key});

  @override
  State<ChangeEmailPage> createState() => _ChangeEmailPageState();
}

class _ChangeEmailPageState extends State<ChangeEmailPage>
    with SingleTickerProviderStateMixin {
  final _newEmailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _passVisible = false;
  bool _loading = false;

  late AnimationController _fadeCtrl;
  String? _currentEmail;

  // ── Email validation ─────────────────────────────────────────
  bool get _emailValid =>
      RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(_newEmailCtrl.text.trim());
  bool get _isDifferent =>
      _newEmailCtrl.text.trim() != _currentEmail;
  bool get _canSubmit =>
      _newEmailCtrl.text.trim().isNotEmpty &&
          _passCtrl.text.trim().isNotEmpty &&
          _emailValid &&
          _isDifferent;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
        value: 0)
      ..forward();
    _currentEmail =
        Supabase.instance.client.auth.currentUser?.email ?? '';
    _newEmailCtrl.addListener(() => setState(() {}));
    _passCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _newEmailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Main Submit ──────────────────────────────────────────────
  Future<void> _submit() async {
    final newEmail = _newEmailCtrl.text.trim();
    final password = _passCtrl.text.trim();

    if (!_canSubmit) return;

    setState(() => _loading = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => _loading = false);
        return;
      }

      // Step 1: Re-authenticate
      await supabase.auth
          .signInWithPassword(email: user.email!, password: password);

      // Step 2: AAL level check
      final aalResponse =
      await supabase.auth.mfa.getAuthenticatorAssuranceLevel();

      final needsMfa =
          aalResponse.nextLevel == AuthenticatorAssuranceLevels.aal2 &&
              aalResponse.currentLevel !=
                  AuthenticatorAssuranceLevels.aal2;

      setState(() => _loading = false);

      if (needsMfa) {
        await _showMfaDialog(newEmail);
      } else {
        await _doUpdateEmail(newEmail);
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final msg = e.message.contains('Invalid login')
          ? SC.tr('wrong_pass_msg')
          : e.message;
      SC.toast(context, msg, SC.red);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      SC.toast(context, SC.tr('something_wrong'), SC.red);
    }
  }

  // ── Email Update ─────────────────────────────────────────────
  Future<void> _doUpdateEmail(String newEmail) async {
    setState(() => _loading = true);
    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.updateUser(UserAttributes(email: newEmail));

      await ActivityLogger.log(
        activityType: 'email_change_req',
        detail: 'email_sent',
      );
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        await NotificationHelper.send(
          userId: userId,
          titleKey: 'email_change_req',
          bodyKey: 'email_sent',
          type: 'email_change_req',
        );
      }

      if (!mounted) return;
      setState(() => _loading = false);
      _newEmailCtrl.clear();
      _passCtrl.clear();
      SC.toast(context, SC.tr('confirmation_sent_msg'), SC.green);
      Navigator.pop(context);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      SC.toast(context, e.message, SC.red);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      SC.toast(context, SC.tr('something_wrong'), SC.red);
    }
  }

  // ── MFA Dialog ───────────────────────────────────────────────
  Future<void> _showMfaDialog(String newEmail) async {
    final List<TextEditingController> otpControllers =
    List.generate(6, (_) => TextEditingController());
    final List<FocusNode> otpFocusNodes =
    List.generate(6, (_) => FocusNode());

    String getOtp() => otpControllers.map((c) => c.text).join();

    void clearOtp() {
      for (final c in otpControllers) c.clear();
      otpFocusNodes.first.requestFocus();
    }

    final verifyNotifier = ValueNotifier<bool>(false);

    Future<void> doVerify() async {
      final otp = getOtp();
      if (otp.length < 6) {
        SC.toast(context, SC.tr('mfa_enter_code'), SC.orange);
        return;
      }

      verifyNotifier.value = true;

      try {
        final supabase = Supabase.instance.client;
        final factors = await supabase.auth.mfa.listFactors();
        final totpFactor = factors.all
            .where((f) => f.status == FactorStatus.verified)
            .firstOrNull;

        if (totpFactor == null) {
          verifyNotifier.value = false;
          if (mounted) SC.toast(context, SC.tr('something_wrong'), SC.red);
          return;
        }

        await supabase.auth.mfa.challengeAndVerify(
          factorId: totpFactor.id,
          code: otp,
        );

        verifyNotifier.value = false;
        if (mounted) Navigator.pop(context, true);
      } on AuthException catch (_) {
        verifyNotifier.value = false;
        if (mounted) {
          SC.toast(context, SC.tr('mfa_invalid_code'), SC.red);
          clearOtp();
        }
      } catch (_) {
        verifyNotifier.value = false;
        if (mounted) {
          SC.toast(context, SC.tr('something_wrong'), SC.red);
          clearOtp();
        }
      }
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) {
        final isDark = SC.isDark;
        final textColor =
        isDark ? Colors.white : const Color(0xFF1A2332);
        final subTextColor = isDark
            ? Colors.white.withValues(alpha: 0.55)
            : const Color(0xFF4A5568);

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                      color: SC.blue.withValues(alpha: 0.25)),
                ),
                child: StatefulBuilder(
                  builder: (ctx2, _) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: SC.blue.withValues(alpha: 0.1),
                            border: Border.all(
                                color: SC.blue.withValues(alpha: 0.35),
                                width: 1.5),
                          ),
                          child: const Icon(Icons.security_rounded,
                              color: SC.blue, size: 36),
                        ),
                        const SizedBox(height: 18),

                        Text(
                          SC.tr('mfa_login_title'),
                          style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          SC.tr('mfa_login_subtitle'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: subTextColor,
                              fontSize: 12.5,
                              height: 1.5),
                        ),
                        const SizedBox(height: 28),

                        // OTP boxes
                        LayoutBuilder(builder: (ctx3, constraints) {
                          final w =
                              (constraints.maxWidth - 5 * 8) / 6;
                          return Row(
                            children: List.generate(
                              6,
                                  (i) => Row(children: [
                                _dialogOtpBox(
                                  index: i,
                                  width: w,
                                  controllers: otpControllers,
                                  focusNodes: otpFocusNodes,
                                  isDark: isDark,
                                  textColor: textColor,
                                  accentColor: SC.blue,
                                  onAllFilled: () {
                                    FocusScope.of(ctx2).unfocus();
                                    Future.delayed(
                                      const Duration(milliseconds: 200),
                                      doVerify,
                                    );
                                  },
                                ),
                                if (i < 5) const SizedBox(width: 8),
                              ]),
                            ),
                          );
                        }),

                        const SizedBox(height: 24),

                        Row(children: [
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: OutlinedButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, false),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: subTextColor,
                                  side: BorderSide(
                                      color: isDark
                                          ? Colors.white
                                          .withValues(alpha: 0.15)
                                          : Colors.black
                                          .withValues(alpha: 0.12)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(14)),
                                ),
                                child: Text(SC.tr('cancel'),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ValueListenableBuilder<bool>(
                              valueListenable: verifyNotifier,
                              builder: (_, isLoading, __) => SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed:
                                  isLoading ? null : doVerify,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: SC.blue,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(14)),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child:
                                    CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5),
                                  )
                                      : Text(
                                      SC.tr('mfa_verify_enable'),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14)),
                                ),
                              ),
                            ),
                          ),
                        ]),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    if (result == true && mounted) {
      await _doUpdateEmail(newEmail);
    }
  }

  // ── OTP Box ──────────────────────────────────────────────────
  Widget _dialogOtpBox({
    required int index,
    required double width,
    required List<TextEditingController> controllers,
    required List<FocusNode> focusNodes,
    required bool isDark,
    required Color textColor,
    required Color accentColor,
    required VoidCallback onAllFilled,
  }) {
    return SizedBox(
      width: width,
      height: width * 1.2,
      child: TextField(
        controller: controllers[index],
        focusNode: focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: TextStyle(
          color: textColor,
          fontSize: width * 0.4,
          fontWeight: FontWeight.w800,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: accentColor.withValues(alpha: 0.06),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: accentColor.withValues(alpha: 0.2), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: accentColor, width: 2),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (val) {
          if (val.isNotEmpty && index < 5) {
            focusNodes[index + 1].requestFocus();
          } else if (val.isEmpty && index > 0) {
            focusNodes[index - 1].requestFocus();
          }
          final otp = controllers.map((c) => c.text).join();
          if (otp.length == 6) onAllFilled();
        },
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (context, __, ___) => _buildPage(),
      ),
    );
  }

  Widget _buildPage() {
    final isDark = SC.isDark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subTextColor = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : const Color(0xFF4A5568);
    final fieldFill = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(children: [
          Container(
              decoration: BoxDecoration(gradient: SC.currentGradient)),
          Positioned(
              top: -80,
              right: -60,
              child: SC.blob(
                  260, SC.blue.withValues(alpha: 0.05))),
          Column(
            children: [
              _buildAppBar(textColor),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeCtrl,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                    children: [
                      // ── Icon ────────────────────────────────
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: SC.blue.withValues(alpha: 0.1),
                            border: Border.all(
                                color: SC.blue.withValues(alpha: 0.3),
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                  color:
                                  SC.blue.withValues(alpha: 0.15),
                                  blurRadius: 30)
                            ],
                          ),
                          child: const Icon(
                              Icons.alternate_email_rounded,
                              color: SC.blue,
                              size: 42),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          SC.tr('current_email_label').replaceAll(
                              '@email', _currentEmail ?? '—'),
                          style: TextStyle(
                              color: subTextColor, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 36),

                      // ── Password ─────────────────────────────
                      _label(SC.tr('reauth_pass_label'), textColor),
                      const SizedBox(height: 8),
                      _field(
                        ctrl: _passCtrl,
                        hint: SC.tr('reauth_pass_hint'),
                        icon: Icons.lock_outline_rounded,
                        obscure: !_passVisible,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        fieldFill: fieldFill,
                        suffix: IconButton(
                          icon: Icon(
                            _passVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: subTextColor.withValues(alpha: 0.4),
                            size: 18,
                          ),
                          onPressed: () => setState(
                                  () => _passVisible = !_passVisible),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── New Email ─────────────────────────────
                      _label(SC.tr('new_email_label'), textColor),
                      const SizedBox(height: 8),
                      _field(
                        ctrl: _newEmailCtrl,
                        hint: SC.tr('new_email_hint'),
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        fieldFill: fieldFill,
                      ),

                      // ── Inline validation hints ───────────────
                      if (_newEmailCtrl.text.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildEmailHints(subTextColor),
                      ],

                      const SizedBox(height: 16),

                      // ── Info banner ───────────────────────────
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: SC.amber.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: SC.amber.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                color: SC.amber, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                SC.tr('email_change_info'),
                                style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 12,
                                    height: 1.6),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── Submit Button ─────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: (_loading || !_canSubmit)
                              ? null
                              : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _canSubmit
                                ? SC.blue
                                : SC.blue.withValues(alpha: 0.35),
                            foregroundColor: isDark ? SC.bgStart : Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(16)),
                          ),
                          child: _loading
                              ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5))
                              : Text(SC.tr('update_email_btn'),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }

  // ── Email validation hints ───────────────────────────────────
  Widget _buildEmailHints(Color subTextColor) {
    final checks = [
      (met: _emailValid, label: SC.tr('cond_valid_email')),
      (met: _isDifferent, label: SC.tr('cond_diff_email')),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: SC.isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: checks.every((c) => c.met)
              ? SC.green.withValues(alpha: 0.4)
              : SC.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: checks.map((c) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  c.met
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  key: ValueKey(c.met),
                  size: 16,
                  color: c.met
                      ? SC.green
                      : subTextColor.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                c.label,
                style: TextStyle(
                  fontSize: 12.5,
                  color: c.met ? SC.green : subTextColor,
                  fontWeight:
                  c.met ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAppBar(Color textColor) {
    return Container(
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                color: textColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              SC.tr('change_email_title'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 18),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _label(String t, Color textColor) => Text(t,
      style: TextStyle(
          color: textColor.withValues(alpha: 0.65),
          fontSize: 13,
          fontWeight: FontWeight.w600));

  Widget _field({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    required Color textColor,
    required Color subTextColor,
    required Color fieldFill,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) =>
      TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: TextStyle(color: textColor, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: subTextColor.withValues(alpha: 0.3), fontSize: 13),
          prefixIcon: Icon(icon,
              color: subTextColor.withValues(alpha: 0.4), size: 18),
          suffixIcon: suffix,
          filled: true,
          fillColor: fieldFill,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              BorderSide(color: textColor.withValues(alpha: 0.1))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              BorderSide(color: textColor.withValues(alpha: 0.1))),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: SC.blue, width: 1.5),
          ),
        ),
      );
}
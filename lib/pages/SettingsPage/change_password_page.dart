import 'dart:ui';
import 'package:css/pages/SettingsPage/notification_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'settings_constants.dart';
import 'package:css/services/activity_logger.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage>
    with SingleTickerProviderStateMixin {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _curVisible = false;
  bool _newVisible = false;
  bool _confirmVisible = false;
  bool _loading = false;

  late AnimationController _fadeCtrl;

  // ── Conditions ───────────────────────────────────────────────
  bool get _cond1 => _newCtrl.text.length >= 6;
  bool get _cond2 => _newCtrl.text.contains(RegExp(r'[A-Z]'));
  bool get _cond3 => _newCtrl.text.contains(RegExp(r'[0-9!@#$%^&*]'));
  bool get _cond4 =>
      _confirmCtrl.text.isNotEmpty && _newCtrl.text == _confirmCtrl.text;
  bool get _allConditionsMet => _cond1 && _cond2 && _cond3 && _cond4;

  double get _strength {
    double s = 0;
    if (_cond1) s += 0.25;
    if (_newCtrl.text.length >= 10) s += 0.25;
    if (_cond2) s += 0.25;
    if (_cond3) s += 0.25;
    return s;
  }

  String get _strengthLabelKey {
    if (_strength <= 0.25) return 'weak';
    if (_strength <= 0.5) return 'medium';
    if (_strength <= 0.75) return 'good';
    return 'strong';
  }

  Color get _strengthColor {
    if (_strength <= 0.25) return SC.red;
    if (_strength <= 0.5) return SC.orange;
    if (_strength <= 0.75) return SC.amber;
    return SC.green;
  }

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
        value: 0)
      ..forward();
    _newCtrl.addListener(() => setState(() {}));
    _confirmCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Main Submit ──────────────────────────────────────────────
  Future<void> _submit() async {
    final cur = _currentCtrl.text.trim();
    final newPass = _newCtrl.text.trim();

    if (cur.isEmpty || newPass.isEmpty || _confirmCtrl.text.trim().isEmpty) {
      SC.toast(context, SC.tr('fill_all'), SC.orange);
      return;
    }
    if (!_allConditionsMet) return;

    setState(() => _loading = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => _loading = false);
        return;
      }

      // Step 1: current password দিয়ে re-authenticate
      await supabase.auth
          .signInWithPassword(email: user.email!, password: cur);

      // Step 2: AAL level check
      final aalResponse =
      await supabase.auth.mfa.getAuthenticatorAssuranceLevel();

      final needsMfa =
          aalResponse.nextLevel == AuthenticatorAssuranceLevels.aal2 &&
              aalResponse.currentLevel != AuthenticatorAssuranceLevels.aal2;

      setState(() => _loading = false);

      if (needsMfa) {
        // Step 3: MFA verify করো, তারপর password update
        await _showMfaDialog(newPass);
      } else {
        // Step 3: সরাসরি update
        await _doUpdatePassword(newPass);
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final msg = e.message.contains('Invalid login')
          ? SC.tr('wrong_cur_pass')
          : e.message;
      SC.toast(context, msg, SC.red);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      SC.toast(context, SC.tr('something_wrong'), SC.red);
    }
  }

  // ── Password Update (AAL already satisfied) ──────────────────
  Future<void> _doUpdatePassword(String newPass) async {
    setState(() => _loading = true);
    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.updateUser(UserAttributes(password: newPass));

      await ActivityLogger.log(
        activityType: 'password_change',
        detail: 'pass_update_success',
      );
      // ActivityLogger এর পরে এই line add করো
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        await NotificationHelper.send(
          userId: userId,
          titleKey: 'password_change',
          bodyKey: 'pass_update_success',
          type: 'password_change',
        );
      }

      if (!mounted) return;
      setState(() => _loading = false);
      _currentCtrl.clear();
      _newCtrl.clear();
      _confirmCtrl.clear();
      SC.toast(context, SC.tr('pass_success'), SC.green);
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
  Future<void> _showMfaDialog(String newPass) async {
    final List<TextEditingController> otpControllers =
    List.generate(6, (_) => TextEditingController());
    final List<FocusNode> otpFocusNodes =
    List.generate(6, (_) => FocusNode());

    String getOtp() => otpControllers.map((c) => c.text).join();

    void clearOtp() {
      for (final c in otpControllers) c.clear();
      otpFocusNodes.first.requestFocus();
    }

    final verifyNotifier = ValueNotifier<bool>(false); // loading state

    Future<void> doVerify(StateSetter setDialogState) async {
      final otp = getOtp();
      if (otp.length < 6) {
        SC.toast(context, SC.tr('mfa_enter_code'), SC.orange);
        return;
      }

      verifyNotifier.value = true;

      try {
        final supabase = Supabase.instance.client;
        final factors = await supabase.auth.mfa.listFactors();
        final totpFactor =
            factors.all.where((f) => f.status == FactorStatus.verified).firstOrNull;

        if (totpFactor == null) {
          verifyNotifier.value = false;
          if (mounted) SC.toast(context, SC.tr('something_wrong'), SC.red);
          return;
        }

        await supabase.auth.mfa.challengeAndVerify(
          factorId: totpFactor.id,
          code: otp,
        );

        // AAL2 achieved — এখন password update করো
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
                    color: SC.cyan.withValues(alpha: 0.25),
                  ),
                ),
                child: StatefulBuilder(
                  builder: (ctx2, setS) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: SC.cyan.withValues(alpha: 0.1),
                            border: Border.all(
                                color: SC.cyan.withValues(alpha: 0.35),
                                width: 1.5),
                          ),
                          child: const Icon(Icons.security_rounded,
                              color: SC.cyan, size: 36),
                        ),
                        const SizedBox(height: 18),

                        // Title
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
                                  onAllFilled: () {
                                    FocusScope.of(ctx2).unfocus();
                                    Future.delayed(
                                      const Duration(milliseconds: 200),
                                          () => doVerify(setS),
                                    );
                                  },
                                ),
                                if (i < 5) const SizedBox(width: 8),
                              ]),
                            ),
                          );
                        }),

                        const SizedBox(height: 24),

                        // Buttons row
                        Row(children: [
                          // Cancel
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

                          // Verify
                          Expanded(
                            child: ValueListenableBuilder<bool>(
                              valueListenable: verifyNotifier,
                              builder: (_, isLoading, __) =>
                                  SizedBox(
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: isLoading
                                          ? null
                                          : () => doVerify(setS),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: SC.cyan,
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
                                          : Text(SC.tr('mfa_verify_enable'),
                                          style: const TextStyle(
                                              fontWeight:
                                              FontWeight.w800,
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

    // Dialog থেকে true আসলে password update করো
    if (result == true && mounted) {
      await _doUpdatePassword(newPass);
    }
  }

  // ── OTP Box for Dialog ───────────────────────────────────────
  Widget _dialogOtpBox({
    required int index,
    required double width,
    required List<TextEditingController> controllers,
    required List<FocusNode> focusNodes,
    required bool isDark,
    required Color textColor,
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
          fillColor: SC.cyan.withValues(alpha: 0.06),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: SC.cyan.withValues(alpha: 0.2), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: SC.cyan, width: 2),
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
              child: SC.blob(260, SC.cyan.withValues(alpha: 0.04))),
          Positioned(
              bottom: 150,
              left: -80,
              child: SC.blob(220, SC.blue.withValues(alpha: 0.04))),
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
                            color: SC.cyan.withValues(alpha: 0.1),
                            border: Border.all(
                                color: SC.cyan.withValues(alpha: 0.3),
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                  color: SC.cyan.withValues(alpha: 0.15),
                                  blurRadius: 30)
                            ],
                          ),
                          child: const Icon(Icons.lock_reset_rounded,
                              color: SC.cyan, size: 42),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(SC.tr('secure_pass_tip'),
                            style: TextStyle(
                                color: subTextColor, fontSize: 13)),
                      ),
                      const SizedBox(height: 36),

                      // ── Current Password ─────────────────────
                      _label(SC.tr('current_pass'), textColor),
                      const SizedBox(height: 8),
                      _passField(
                        ctrl: _currentCtrl,
                        hint: SC.tr('current_pass_hint'),
                        icon: Icons.lock_outline_rounded,
                        visible: _curVisible,
                        fieldFill: fieldFill,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        onToggle: () =>
                            setState(() => _curVisible = !_curVisible),
                      ),
                      const SizedBox(height: 20),

                      // ── New Password ─────────────────────────
                      _label(SC.tr('new_pass'), textColor),
                      const SizedBox(height: 8),
                      _passField(
                        ctrl: _newCtrl,
                        hint: SC.tr('new_pass_hint'),
                        icon: Icons.lock_open_rounded,
                        visible: _newVisible,
                        fieldFill: fieldFill,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        onToggle: () =>
                            setState(() => _newVisible = !_newVisible),
                      ),

                      // ── Strength Bar ─────────────────────────
                      if (_newCtrl.text.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _strength,
                                minHeight: 5,
                                backgroundColor:
                                textColor.withValues(alpha: 0.08),
                                valueColor: AlwaysStoppedAnimation(
                                    _strengthColor),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(SC.tr(_strengthLabelKey),
                              style: TextStyle(
                                  color: _strengthColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ],
                      const SizedBox(height: 20),

                      // ── Confirm Password ─────────────────────
                      _label(SC.tr('confirm_new_pass'), textColor),
                      const SizedBox(height: 8),
                      _passField(
                        ctrl: _confirmCtrl,
                        hint: SC.tr('confirm_pass_hint'),
                        icon: Icons.verified_outlined,
                        visible: _confirmVisible,
                        fieldFill: fieldFill,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        onToggle: () => setState(
                                () => _confirmVisible = !_confirmVisible),
                      ),

                      // ── Live Condition Checklist ─────────────
                      if (_newCtrl.text.isNotEmpty ||
                          _confirmCtrl.text.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildConditionChecklist(subTextColor),
                      ],

                      const SizedBox(height: 36),
                      _buildTipsBox(subTextColor),
                      const SizedBox(height: 36),

                      // ── Submit Button ────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: (_loading ||
                              !_allConditionsMet ||
                              _currentCtrl.text.trim().isEmpty)
                              ? null
                              : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _allConditionsMet
                                ? SC.cyan
                                : SC.cyan.withValues(alpha: 0.35),
                            foregroundColor: isDark
                                ? SC.bgStart
                                : Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _loading
                              ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5))
                              : Text(SC.tr('update_pass_btn'),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  letterSpacing: 0.5)),
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

  // ── Condition Checklist ──────────────────────────────────────
  Widget _buildConditionChecklist(Color subTextColor) {
    final conditions = [
      (met: _cond1, labelKey: 'cond_min_6'),
      (met: _cond2, labelKey: 'cond_uppercase'),
      (met: _cond3, labelKey: 'cond_number_special'),
      (met: _cond4, labelKey: 'cond_pass_match'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: SC.isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _allConditionsMet
              ? SC.green.withValues(alpha: 0.4)
              : SC.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: conditions.map((c) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  c.met
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  key: ValueKey(c.met),
                  size: 17,
                  color: c.met
                      ? SC.green
                      : subTextColor.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                SC.tr(c.labelKey),
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
      child: Row(children: [
        IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        Expanded(
          child: Text(
            SC.tr('change_pass_title'),
            textAlign: TextAlign.center,
            style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 18),
          ),
        ),
        const SizedBox(width: 48),
      ]),
    );
  }

  Widget _buildTipsBox(Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SC.blue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SC.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.tips_and_updates_rounded,
                color: SC.blue, size: 16),
            const SizedBox(width: 8),
            Text(SC.tr('pass_strength_tips'),
                style: const TextStyle(
                    color: SC.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          ...['tip_length', 'tip_caps', 'tip_special', 'tip_personal']
              .map((key) => Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                      SC.blue.withValues(alpha: 0.6)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(SC.tr(key),
                      style: TextStyle(
                          color: subTextColor,
                          fontSize: 12,
                          height: 1.5)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _label(String text, Color textColor) => Text(text,
      style: TextStyle(
          color: textColor.withValues(alpha: 0.65),
          fontSize: 13,
          fontWeight: FontWeight.w600));

  Widget _passField({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    required bool visible,
    required Color fieldFill,
    required Color textColor,
    required Color subTextColor,
    required VoidCallback onToggle,
  }) =>
      TextField(
        controller: ctrl,
        obscureText: !visible,
        style: TextStyle(color: textColor, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: subTextColor.withValues(alpha: 0.5), fontSize: 13),
          prefixIcon: Icon(icon,
              color: subTextColor.withValues(alpha: 0.4), size: 18),
          suffixIcon: IconButton(
            icon: Icon(
                visible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: subTextColor.withValues(alpha: 0.4),
                size: 18),
            onPressed: onToggle,
          ),
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
            borderSide: const BorderSide(color: SC.cyan, width: 1.5),
          ),
        ),
      );
}

extension Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
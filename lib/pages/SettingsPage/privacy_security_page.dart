import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'settings_constants.dart';
import '../account/mfa_setup_page.dart';

class PrivacySecurityPage extends StatefulWidget {
  const PrivacySecurityPage({super.key});

  @override
  State<PrivacySecurityPage> createState() => _PrivacySecurityPageState();
}

class _PrivacySecurityPageState extends State<PrivacySecurityPage>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late AnimationController _fadeCtrl;

  bool _mfaEnabled = false;
  bool _mfaLoading = true;
  String? _mfaFactorId;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
        value: 0)
      ..forward();
    _checkMfaStatus();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // Supabase থেকে real MFA status check করো
  Future<void> _checkMfaStatus() async {
    if (!mounted) return;
    setState(() => _mfaLoading = true);
    try {
      final factors = await _supabase.auth.mfa.listFactors();
      final verified = factors.all
          .where((f) => f.status == FactorStatus.verified)
          .toList();

      if (!mounted) return;
      setState(() {
        _mfaEnabled = verified.isNotEmpty;
        _mfaFactorId = verified.isNotEmpty ? verified.first.id : null;
        _mfaLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _mfaLoading = false);
    }
  }

  Future<void> _openMfaSetup() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const MFASetupPage()),
    );
    // Setup page থেকে ফিরে এলে status refresh করো
    if (result == true) _checkMfaStatus();
  }

  void _showDisableDialog(
      Color cardColor, Color textColor, Color subTextColor, Color borderColor) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: SC.red.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SC.red.withValues(alpha: 0.1),
                  border:
                  Border.all(color: SC.red.withValues(alpha: 0.35), width: 1.5),
                ),
                child:
                const Icon(Icons.lock_open_rounded, color: SC.red, size: 36),
              ),
              const SizedBox(height: 16),
              Text(SC.tr('mfa_disable_title'),
                  style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 19)),
              const SizedBox(height: 12),
              Text(SC.tr('mfa_disable_desc'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: subTextColor, fontSize: 13, height: 1.6)),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(SC.tr('cancel'),
                        style: TextStyle(
                            color: subTextColor, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _disableMfa();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SC.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(SC.tr('confirm_disable'),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _disableMfa() async {
    if (_mfaFactorId == null) return;
    setState(() => _mfaLoading = true);
    try {
      // নতুন API: positional argument
      await _supabase.auth.mfa.unenroll(_mfaFactorId!);
      if (mounted) {
        SC.toast(context, SC.tr('mfa_disabled_success'), SC.orange);
        _checkMfaStatus();
      }
    } catch (e) {
      if (mounted) {
        SC.toast(context, 'Error: ${e.toString()}', SC.red);
        setState(() => _mfaLoading = false);
      }
    }
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
    final cardColor = isDark ? SC.cardBg : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subTextColor = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : const Color(0xFF4A5568);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.08);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(children: [
          Container(decoration: BoxDecoration(gradient: SC.currentGradient)),
          SC.blob(240, SC.green.withValues(alpha: 0.05)),
          Column(children: [
            _buildAppBar(textColor),
            Expanded(
              child: FadeTransition(
                opacity: _fadeCtrl,
                child: ListView(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                  children: [
                    // ── 2FA Section ──────────────────────────────────────────
                    _sectionHeader(SC.tr('mfa_setup_title'),
                        Icons.verified_user_rounded, SC.green, textColor),
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(children: [
                        // Status banner
                        Container(
                          margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: (_mfaEnabled ? SC.green : SC.red)
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: (_mfaEnabled ? SC.green : SC.red)
                                    .withValues(alpha: 0.3)),
                          ),
                          child: _mfaLoading
                              ? Row(children: [
                            const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: SC.green, strokeWidth: 2)),
                            const SizedBox(width: 12),
                            Text(SC.tr('mfa_checking'),
                                style: TextStyle(color: subTextColor)),
                          ])
                              : Row(children: [
                            Icon(
                              _mfaEnabled
                                  ? Icons.shield_rounded
                                  : Icons.shield_outlined,
                              color: _mfaEnabled ? SC.green : SC.red,
                              size: 26,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _mfaEnabled
                                          ? SC.tr('mfa_status_active')
                                          : SC.tr('mfa_status_inactive'),
                                      style: TextStyle(
                                          color: _mfaEnabled
                                              ? SC.green
                                              : SC.red,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _mfaEnabled
                                          ? SC.tr('mfa_status_active_sub')
                                          : SC.tr(
                                          'mfa_status_inactive_sub'),
                                      style: TextStyle(
                                          color: subTextColor,
                                          fontSize: 11),
                                    ),
                                  ]),
                            ),
                          ]),
                        ),

                        // Action tile
                        if (!_mfaLoading)
                          _actionTile(
                            icon: _mfaEnabled
                                ? Icons.lock_open_rounded
                                : Icons.lock_rounded,
                            iconColor: _mfaEnabled ? SC.orange : SC.green,
                            title: _mfaEnabled
                                ? SC.tr('mfa_disable_btn')
                                : SC.tr('mfa_setup_btn'),
                            subtitle: _mfaEnabled
                                ? SC.tr('mfa_disable_desc')
                                : SC.tr('mfa_step2'),
                            textColor: textColor,
                            subTextColor: subTextColor,
                            onTap: _mfaEnabled
                                ? () => _showDisableDialog(
                                cardColor, textColor, subTextColor,
                                borderColor)
                                : _openMfaSetup,
                          ),
                        if (_mfaLoading) const SizedBox(height: 14),
                      ]),
                    ),

                    const SizedBox(height: 16),

                    // Info tip
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: SC.green.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                        border:
                        Border.all(color: SC.green.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.tips_and_updates_rounded,
                                color: SC.green, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(SC.tr('security_tip'),
                                  style: TextStyle(
                                      color: subTextColor,
                                      fontSize: 12,
                                      height: 1.6)),
                            ),
                          ]),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildAppBar(Color textColor) => Container(
    padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10, bottom: 10),
    child: Row(children: [
      IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      Expanded(
        child: Text(SC.tr('privacy_security_title'),
            textAlign: TextAlign.center,
            style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
      ),
      const SizedBox(width: 48),
    ]),
  );

  Widget _sectionHeader(
      String title, IconData icon, Color color, Color textColor) =>
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 12),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(title,
              style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _actionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color subTextColor,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius:
        const BorderRadius.vertical(bottom: Radius.circular(20)),
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style:
                        TextStyle(color: subTextColor, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ]),
            ),
            Icon(Icons.chevron_right_rounded,
                color: subTextColor, size: 20),
          ]),
        ),
      );
}
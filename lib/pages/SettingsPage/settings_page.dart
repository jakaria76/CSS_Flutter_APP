import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'settings_constants.dart';

import 'change_password_page.dart';
import 'change_email_page.dart';
import 'profile_visibility_page.dart';
import 'appearance_settings_page.dart';
import 'language_settings_page.dart';
import 'privacy_security_page.dart';
import 'active_sessions_page.dart';
import 'account_activity_page.dart';
import 'data_storage_page.dart';
import 'export_data_page.dart';
import 'about_page.dart';
import 'feedback_page.dart';
import 'bug_report_page.dart';
import 'admin_feedback_page.dart';
import 'admin_bug_report_page.dart';
import 'package:css/pages/SettingsPage/help_support_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin {
  bool _isLoggingOut = false;
  bool _isAdmin = false;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
        value: 0)
      ..forward();
    _checkAdminRole();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ── Admin role check ─────────────────────────────────────────────────────
  Future<void> _checkAdminRole() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;
      final data = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', uid)
          .maybeSingle();
      if (!mounted) return;
      setState(() => _isAdmin = (data?['role'] as String?) == 'admin');
    } catch (_) {}
  }

  // ── Logout ───────────────────────────────────────────────────────────────
  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    try {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/welcome', (_) => false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoggingOut = false);
      SC.toast(context, SC.tr('logout_error'), SC.red);
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: SC.currentCardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: SC.orange.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SC.orange.withValues(alpha: 0.1),
                  border: Border.all(
                      color: SC.orange.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.logout_rounded,
                    color: SC.orange, size: 32),
              ),
              const SizedBox(height: 18),
              Text(SC.tr('logout_title'),
                  style: TextStyle(
                      color: SC.currentTextColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 20)),
              const SizedBox(height: 10),
              Text(
                SC.tr('logout_confirm'),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: SC.currentTextColor.withValues(alpha: 0.5),
                    fontSize: 14,
                    height: 1.6),
              ),
              const SizedBox(height: 28),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                          color: SC.currentTextColor
                              .withValues(alpha: 0.18)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(SC.tr('no'),
                        style: TextStyle(
                            color: SC.currentTextColor
                                .withValues(alpha: 0.65),
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _logout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SC.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(SC.tr('logout'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _go(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SC.languageNotifier,
      builder: (context, _, __) {
        return ValueListenableBuilder<String>(
          valueListenable: SC.themeModeNotifier,
          builder: (context, __, ___) {
            final isDark  = SC.isDark;
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
                    SC.tr('settings'),
                    style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        letterSpacing: 0.5),
                  ),
                  centerTitle: true,
                ),
                body: _buildBackground(
                  child: FadeTransition(
                    opacity: _fadeController,
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                          18,
                          MediaQuery.of(context).padding.top + 80,
                          18,
                          40),
                      children: [

                        // ── Account & Profile ───────────────────────────
                        SC.sectionHeader(
                            SC.tr('account_profile'),
                            Icons.manage_accounts_rounded,
                            SC.cyan),
                        SC.card([
                          SC.tile(
                            icon: Icons.lock_reset_rounded,
                            iconColor: SC.cyan,
                            title: SC.tr('change_password'),
                            subtitle: SC.tr('change_password_sub'),
                            onTap: () => _go(const ChangePasswordPage()),
                          ),
                          SC.divider(),
                          SC.tile(
                            icon: Icons.alternate_email_rounded,
                            iconColor: SC.blue,
                            title: SC.tr('change_email'),
                            subtitle: SC.tr('change_email_sub'),
                            onTap: () => _go(const ChangeEmailPage()),
                          ),
                          SC.divider(),
                          SC.tile(
                            icon: Icons.visibility_rounded,
                            iconColor: SC.teal,
                            title: SC.tr('profile_visibility'),
                            subtitle: SC.tr('profile_visibility_sub'),
                            onTap: () => _go(const ProfileVisibilityPage()),
                          ),
                        ]),

                        const SizedBox(height: 22),

                        // ── App Preferences ─────────────────────────────
                        SC.sectionHeader(
                            SC.tr('app_preferences'),
                            Icons.palette_rounded,
                            SC.purple),
                        SC.card([
                          SC.tile(
                            icon: Icons.dark_mode_rounded,
                            iconColor: SC.indigo,
                            title: SC.tr('appearance'),
                            subtitle: SC.tr('appearance_sub'),
                            onTap: () => _go(const AppearanceSettingsPage()),
                          ),
                          SC.divider(),
                          SC.tile(
                            icon: Icons.translate_rounded,
                            iconColor: SC.purple,
                            title: SC.tr('language'),
                            subtitle: SC.languageNotifier.value,
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: SC.purple.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: SC.purple.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                SC.languageNotifier.value == 'বাংলা'
                                    ? '🇧🇩'
                                    : '🇬🇧',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            onTap: () => _go(const LanguageSettingsPage()),
                          ),
                        ]),

                        const SizedBox(height: 22),

                        // ── Privacy & Security ──────────────────────────
                        SC.sectionHeader(
                            SC.tr('privacy_security'),
                            Icons.security_rounded,
                            SC.green),
                        SC.card([
                          SC.tile(
                            icon: Icons.verified_user_rounded,
                            iconColor: SC.green,
                            title: SC.tr('two_factor_auth'),
                            subtitle: SC.tr('two_factor_auth_sub'),
                            onTap: () => _go(const PrivacySecurityPage()),
                          ),
                          SC.divider(),
                          SC.tile(
                            icon: Icons.devices_rounded,
                            iconColor: SC.blue,
                            title: SC.tr('active_sessions'),
                            subtitle: SC.tr('active_sessions_sub'),
                            onTap: () => _go(const ActiveSessionsPage()),
                          ),
                          SC.divider(),
                          SC.tile(
                            icon: Icons.history_rounded,
                            iconColor: SC.teal,
                            title: SC.tr('account_activity'),
                            subtitle: SC.tr('account_activity_sub'),
                            onTap: () => _go(const AccountActivityPage()),
                          ),
                        ]),

                        const SizedBox(height: 22),

                        // ── Data & Storage ──────────────────────────────
                        SC.sectionHeader(
                            SC.tr('data_storage'),
                            Icons.storage_rounded,
                            SC.blue),
                        SC.card([
                          SC.tile(
                            icon: Icons.cleaning_services_rounded,
                            iconColor: SC.blue,
                            title: SC.tr('data_cache'),
                            subtitle: SC.tr('data_cache_sub'),
                            onTap: () => _go(const DataCachePage()),
                          ),
                          SC.divider(),
                          SC.tile(
                            icon: Icons.download_rounded,
                            iconColor: SC.cyan,
                            title: SC.tr('export_data'),
                            subtitle: SC.tr('export_data_sub'),
                            onTap: () => _go(const ExportDataPage()),
                          ),
                        ]),

                        const SizedBox(height: 22),

                        // ── Support ─────────────────────────────────────
                        SC.sectionHeader(
                            SC.tr('support'),
                            Icons.support_agent_rounded,
                            SC.orange),
                        SC.card([
                          SC.tile(
                            icon: Icons.help_center_rounded,
                            iconColor: SC.cyan,
                            title: SC.tr('help_support'),
                            subtitle: SC.tr('help_support_sub'),
                            onTap: () => _go(const HelpSupportPage()),
                          ),
                          SC.divider(),
                          SC.tile(
                            icon: Icons.groups_rounded,
                            iconColor: SC.teal,
                            title: SC.tr('about_app'),
                            subtitle: SC.tr('about_app_sub'),
                            onTap: () => _go(const AboutPage()),
                          ),
                          SC.divider(),
                          SC.tile(
                            icon: Icons.feedback_rounded,
                            iconColor: SC.amber,
                            title: SC.tr('feedback'),
                            subtitle: SC.tr('feedback_sub'),
                            onTap: () => _go(const FeedbackPage()),
                          ),
                          SC.divider(),
                          SC.tile(
                            icon: Icons.bug_report_rounded,
                            iconColor: SC.orange,
                            title: SC.tr('bug_report'),
                            subtitle: SC.tr('bug_report_sub'),
                            onTap: () => _go(const BugReportPage()),
                          ),
                        ]),

                        const SizedBox(height: 22),

                        // ── Admin Panel (শুধু admin role-এর জন্য) ──────
                        if (_isAdmin) ...[
                          SC.sectionHeader(
                              SC.tr('admin_panel'),
                              Icons.admin_panel_settings_rounded,
                              SC.red),
                          SC.card([
                            SC.tile(
                              icon: Icons.feedback_rounded,
                              iconColor: SC.amber,
                              title: SC.tr('admin_feedbacks'),
                              subtitle: SC.tr('admin_feedbacks_sub'),
                              onTap: () => _go(const AdminFeedbackPage()),
                            ),
                            SC.divider(),
                            SC.tile(
                              icon: Icons.bug_report_rounded,
                              iconColor: SC.red,
                              title: SC.tr('admin_bug_reports'),
                              subtitle: SC.tr('admin_bug_reports_sub'),
                              onTap: () => _go(const AdminBugReportPage()),
                            ),
                          ]),
                          const SizedBox(height: 22),
                        ],

                        // ── Session / Logout ────────────────────────────
                        SC.sectionHeader(
                            SC.tr('session'),
                            Icons.exit_to_app_rounded,
                            SC.red),
                        SC.card([
                          SC.tile(
                            icon: Icons.logout_rounded,
                            iconColor: SC.orange,
                            title: SC.tr('logout'),
                            subtitle: SC.tr('logout_sub'),
                            trailing: _isLoggingOut
                                ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: SC.orange, strokeWidth: 2))
                                : null,
                            onTap: _isLoggingOut ? null : _showLogoutDialog,
                          ),
                        ]),

                        const SizedBox(height: 16),

                        Center(
                          child: Text(
                            'CSS App v1.0.0',
                            style: TextStyle(
                                color: SC.currentTextColor
                                    .withValues(alpha: 0.2),
                                fontSize: 12),
                          ),
                        ),
                      ],
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

  // ── Back button (theme-aware) ─────────────────────────────────────────────
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
          onPressed: () => Navigator.pop(context),
          color: textColor,
        ),
      ),
    ),
  );

  // ── Background ────────────────────────────────────────────────────────────
  Widget _buildBackground({required Widget child}) =>
      Stack(children: [
        Container(
            decoration: BoxDecoration(gradient: SC.currentGradient)),
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
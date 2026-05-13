import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'settings_constants.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late final Future<PackageInfo> _packageInfoFuture;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      value: 0,
    )..forward();
    _packageInfoFuture = PackageInfo.fromPlatform();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _openEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'consciousstudentsociety@gmail.com',
      queryParameters: {'subject': 'CSS App Support'},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      SC.toast(context, SC.tr('email_open_error'), SC.red);
    }
  }

  Future<void> _copyEmail() async {
    await Clipboard.setData(
        const ClipboardData(text: 'consciousstudentsociety@gmail.com'));
    if (!mounted) return;
    SC.toast(context, SC.tr('email_copied'), SC.green);
  }

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
    final isDark       = SC.isDark;
    final textColor    = isDark ? Colors.white : const Color(0xFF1A2332);
    final subTextColor = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : const Color(0xFF4A5568);
    final cardColor    = isDark ? SC.cardBg : Colors.white;
    final borderColor  = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.08);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(children: [
          // ── Background ──────────────────────────────────────────
          Container(decoration: BoxDecoration(gradient: SC.currentGradient)),
          Positioned(
              top: -100, right: -80,
              child: SC.blob(300, SC.cyan.withValues(alpha: isDark ? 0.05 : 0.04))),
          Positioned(
              bottom: 200, left: -100,
              child: SC.blob(250, SC.purple.withValues(alpha: isDark ? 0.04 : 0.03))),
          Positioned(
              top: 300, left: -60,
              child: SC.blob(180, SC.blue.withValues(alpha: isDark ? 0.04 : 0.03))),

          SafeArea(
            top: false,
            child: Column(children: [
              _buildAppBar(textColor, isDark),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeController,
                  child: FutureBuilder<PackageInfo>(
                    future: _packageInfoFuture,
                    builder: (context, snapshot) {
                      final version     = snapshot.data?.version     ?? '—';
                      final buildNumber = snapshot.data?.buildNumber ?? '—';
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 48),
                        children: [
                          // ── Hero Section ─────────────────────────
                          _buildHeroCard(version, isDark, textColor, subTextColor),
                          const SizedBox(height: 24),

                          // ── App Info ─────────────────────────────
                          _sectionLabel(SC.tr('app_info'), Icons.info_rounded, SC.cyan, textColor),
                          const SizedBox(height: 10),
                          _buildInfoCard(cardColor, borderColor, isDark, [
                            _infoRow(Icons.verified_rounded, SC.cyan,
                                SC.tr('version'), version, textColor, subTextColor),
                            _divider(borderColor),
                            _infoRow(Icons.build_circle_rounded, SC.blue,
                                SC.tr('build_number'), buildNumber, textColor, subTextColor),
                            _divider(borderColor),
                            _infoRow(Icons.calendar_month_rounded, SC.teal,
                                SC.tr('release_date'), 'May 2026', textColor, subTextColor),
                            _divider(borderColor),
                            _infoRow(Icons.phone_android_rounded, SC.indigo,
                                'Platform', 'Flutter (Android)', textColor, subTextColor),
                          ]),
                          const SizedBox(height: 24),

                          // ── Developer ────────────────────────────
                          _sectionLabel(SC.tr('developer'), Icons.code_rounded, SC.purple, textColor),
                          const SizedBox(height: 10),
                          _buildDeveloperCard(cardColor, borderColor, isDark, textColor, subTextColor),
                          const SizedBox(height: 24),

                          // ── Contact ──────────────────────────────
                          _sectionLabel(SC.tr('contact'), Icons.contact_support_rounded, SC.teal, textColor),
                          const SizedBox(height: 10),
                          _buildContactCard(cardColor, borderColor, isDark, textColor, subTextColor),
                          const SizedBox(height: 24),

                          // ── Legal ────────────────────────────────
                          _sectionLabel(SC.tr('legal'), Icons.gavel_rounded, SC.amber, textColor),
                          const SizedBox(height: 10),
                          _buildInfoCard(cardColor, borderColor, isDark, [
                            _actionRow(
                              Icons.privacy_tip_rounded, SC.amber,
                              SC.tr('privacy_policy'),
                              SC.tr('privacy_sub'),
                              textColor, subTextColor,
                              onTap: () => _openLegal(isPrivacy: true),
                            ),
                            _divider(borderColor),
                            _actionRow(
                              Icons.description_rounded, SC.orange,
                              SC.tr('terms_service'),
                              SC.tr('terms_sub'),
                              textColor, subTextColor,
                              onTap: () => _openLegal(isPrivacy: false),
                            ),
                          ]),
                          const SizedBox(height: 32),

                          // ── Footer ───────────────────────────────
                          _buildFooter(isDark, subTextColor),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  Widget _buildAppBar(Color textColor, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10, bottom: 12),
      child: Row(children: [
        IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        Expanded(
          child: Text(
            SC.tr('about_title'),
            textAlign: TextAlign.center,
            style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5),
          ),
        ),
        const SizedBox(width: 48),
      ]),
    );
  }

  // ── Hero Card ──────────────────────────────────────────────────────────────
  Widget _buildHeroCard(String version, bool isDark, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [SC.cyan.withValues(alpha: 0.12), SC.blue.withValues(alpha: 0.08)]
              : [SC.cyan.withValues(alpha: 0.08), SC.blue.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: SC.cyan.withValues(alpha: isDark ? 0.2 : 0.15)),
      ),
      child: Column(children: [
        // Animated logo with glow (Updated with Assets Image)
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // এখানে ইমেজ সেট করা হয়েছে
            image: const DecorationImage(
              image: AssetImage('assets/images/csslogo.jpg'),
              fit: BoxFit.cover,
            ),
            gradient: LinearGradient(
              colors: [SC.cyan.withValues(alpha: 0.25), SC.blue.withValues(alpha: 0.15)],
            ),
            border: Border.all(color: SC.cyan.withValues(alpha: 0.4), width: 2),
            boxShadow: [
              BoxShadow(
                  color: SC.cyan.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text(
          SC.tr('app_name'),
          style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 6),

        Text(
          'সচেতন ছাত্র সমাজ',
          style: TextStyle(
              color: SC.cyan.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3),
        ),
        const SizedBox(height: 16),

        // Version badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: SC.cyan.withValues(alpha: isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SC.cyan.withValues(alpha: 0.25)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.verified_rounded, color: SC.cyan, size: 15),
            const SizedBox(width: 6),
            Text(
              '${SC.tr('version')} $version',
              style: TextStyle(
                  color: SC.cyan,
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // Stats row
        Row(children: [
          _statBox('2026', 'Launch', SC.teal, isDark),
          const SizedBox(width: 10),
          _statBox('Flutter', 'Framework', SC.blue, isDark),
          const SizedBox(width: 10),
          _statBox('Supabase', 'Backend', SC.purple, isDark),
        ]),
      ]),
    );
  }

  Widget _statBox(String value, String label, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.1 : 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 10)),
        ]),
      ),
    );
  }

  // ── Developer Card ─────────────────────────────────────────────────────────
  Widget _buildDeveloperCard(Color cardColor, Color borderColor, bool isDark,
      Color textColor, Color subTextColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: [
        // Dev team header
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                SC.purple.withValues(alpha: isDark ? 0.12 : 0.06),
                SC.blue.withValues(alpha: isDark ? 0.06 : 0.03)
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [SC.purple.withValues(alpha: 0.3), SC.blue.withValues(alpha: 0.2)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.people_alt_rounded, color: SC.purple, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(SC.tr('developer'),
                    style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(SC.tr('dev_team'),
                    style: TextStyle(color: SC.purple, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
        ),
        _divider(borderColor),

        // Tech stack
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tech Stack',
                style: TextStyle(
                    color: subTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _techChip('Flutter', SC.blue, isDark),
              _techChip('Dart', SC.cyan, isDark),
              _techChip('Supabase', SC.teal, isDark),
              _techChip('Cloudinary', SC.orange, isDark),
              _techChip('OpenStreetMap', SC.green, isDark),
            ]),
          ]),
        ),
        _divider(borderColor),

        // Built with love
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(children: [
            Icon(Icons.favorite_rounded, color: SC.red, size: 18),
            const SizedBox(width: 8),
            Text(
              'সিএসএস-এর জন্য ভালোবাসা দিয়ে তৈরি',
              style: TextStyle(color: subTextColor, fontSize: 12),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _techChip(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700)),
    );
  }

  // ── Contact Card ───────────────────────────────────────────────────────────
  Widget _buildContactCard(Color cardColor, Color borderColor, bool isDark,
      Color textColor, Color subTextColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: [
        // Email row with copy + open buttons
        Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: SC.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.email_rounded, color: SC.teal, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(SC.tr('contact'),
                    style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('consciousstudentsociety@gmail.com',
                    style: TextStyle(
                        color: subTextColor,
                        fontSize: 11),
                    overflow: TextOverflow.ellipsis),
              ]),
            ),
            // Copy button
            GestureDetector(
              onTap: _copyEmail,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SC.teal.withValues(alpha: isDark ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.copy_rounded, color: SC.teal, size: 16),
              ),
            ),
            const SizedBox(width: 8),
            // Open mail app button
            GestureDetector(
              onTap: _openEmail,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SC.blue.withValues(alpha: isDark ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.open_in_new_rounded, color: SC.blue, size: 16),
              ),
            ),
          ]),
        ),
        _divider(borderColor),

        // Facebook row
        _actionRow(
          Icons.facebook_rounded, const Color(0xFF1877F2),
          'Facebook',
          'facebook.com/consciousstudentsociety',
          textColor, subTextColor,
          onTap: () async {
            final uri = Uri.parse('https://www.facebook.com/organizationofcss');
            if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
          },
        ),
        _divider(borderColor),

        // Support hours
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: SC.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.schedule_rounded, color: SC.amber, size: 20),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Support Time',
                  style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('CSS is always with you',
                  style: TextStyle(color: subTextColor, fontSize: 11)),
            ]),
          ]),
        ),
      ]),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────
  Widget _buildFooter(bool isDark, Color subTextColor) {
    return Column(children: [
      Container(
        width: 40,
        height: 1,
        color: SC.cyan.withValues(alpha: 0.2),
      ),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.favorite_rounded, color: SC.red.withValues(alpha: 0.6), size: 12),
        const SizedBox(width: 6),
        Text(
          '© 2026 CSS App. All rights reserved.',
          style: TextStyle(
              color: subTextColor.withValues(alpha: 0.4),
              fontSize: 11),
        ),
      ]),
      const SizedBox(height: 6),
      Text(
        'Made with Flutter & Supabase',
        style: TextStyle(
            color: subTextColor.withValues(alpha: 0.25),
            fontSize: 10),
      ),
    ]);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _sectionLabel(String title, IconData icon, Color color, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildInfoCard(Color cardColor, Color borderColor, bool isDark,
      List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, Color iconColor, String title, String value,
      Color textColor, Color subTextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(title,
              style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ),
        Text(value,
            style: TextStyle(
                color: iconColor,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _actionRow(IconData icon, Color iconColor, String title, String subtitle,
      Color textColor, Color subTextColor, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(color: subTextColor, fontSize: 11),
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              color: subTextColor.withValues(alpha: 0.4), size: 14),
        ]),
      ),
    );
  }

  Widget _divider(Color borderColor) =>
      Divider(height: 1, color: borderColor, indent: 18, endIndent: 18);

  void _openLegal({required bool isPrivacy}) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => _LegalPage(isPrivacy: isPrivacy)));
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Legal Page — Privacy Policy & Terms of Service (Full Content)
// ══════════════════════════════════════════════════════════════════════════════

class _LegalPage extends StatelessWidget {
  final bool isPrivacy;
  const _LegalPage({required this.isPrivacy});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (context, __, ___) => _buildPage(context),
      ),
    );
  }

  Widget _buildPage(BuildContext context) {
    final isDark       = SC.isDark;
    final textColor    = isDark ? Colors.white : const Color(0xFF1A2332);
    final subTextColor = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : const Color(0xFF4A5568);
    final cardColor    = isDark ? SC.cardBg : Colors.white;
    final borderColor  = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.08);
    final accentColor  = isPrivacy ? SC.amber : SC.cyan;

    final List<Map<String, dynamic>> sections = isPrivacy
        ? _privacySections()
        : _termsSections();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(children: [
          Container(decoration: BoxDecoration(gradient: SC.currentGradient)),
          Positioned(top: -80, right: -60,
              child: SC.blob(260, accentColor.withValues(alpha: 0.05))),
          Positioned(bottom: 200, left: -100,
              child: SC.blob(240, SC.blue.withValues(alpha: 0.04))),

          SafeArea(
            top: false,
            child: Column(children: [
              // ── AppBar ──────────────────────────────────────────
              Container(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 10,
                    bottom: 12),
                child: Row(children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: textColor, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      isPrivacy ? SC.tr('pp_title') : SC.tr('tos_title'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          letterSpacing: 0.5),
                    ),
                  ),
                  const SizedBox(width: 48),
                ]),
              ),

              // ── Content ─────────────────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 48),
                  children: [
                    // ── Header banner ────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor.withValues(alpha: isDark ? 0.15 : 0.08),
                            accentColor.withValues(alpha: isDark ? 0.05 : 0.03),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPrivacy ? Icons.shield_rounded : Icons.gavel_rounded,
                            color: accentColor, size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(
                              isPrivacy ? SC.tr('pp_title') : SC.tr('tos_title'),
                              style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                isPrivacy ? SC.tr('pp_last_updated') : SC.tr('tos_last_updated'),
                                style: TextStyle(
                                    color: accentColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ]),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    // ── Section cards ────────────────────────────
                    ...sections.asMap().entries.map((entry) {
                      final index = entry.key;
                      final section = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _legalSectionCard(
                          index + 1,
                          section['icon'] as IconData,
                          section['title'] as String,
                          section['body'] as String,
                          accentColor, cardColor, borderColor,
                          isDark, textColor, subTextColor,
                        ),
                      );
                    }),

                    // ── Agreement notice ─────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: SC.blue.withValues(alpha: isDark ? 0.1 : 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: SC.blue.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_rounded, color: SC.blue, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isPrivacy
                                  ? 'CSS App ব্যবহার করে আপনি এই গোপনীয়তা নীতিতে সম্মতি দিচ্ছেন।'
                                  : 'CSS App ব্যবহার করে আপনি এই শর্তাবলীতে সম্মতি দিচ্ছেন।',
                              style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 12,
                                  height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Center(
                      child: Text(
                        '© 2026 CSS App. All rights reserved.',
                        style: TextStyle(
                            color: subTextColor.withValues(alpha: 0.35),
                            fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _legalSectionCard(
      int number,
      IconData icon,
      String title,
      String body,
      Color accentColor,
      Color cardColor,
      Color borderColor,
      bool isDark,
      Color textColor,
      Color subTextColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Card header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: isDark ? 0.08 : 0.04),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(children: [
            // Number badge
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text('$number',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: accentColor, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
        ),

        // Body
        Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            body,
            style: TextStyle(
                color: subTextColor,
                fontSize: 13,
                height: 1.75),
          ),
        ),
      ]),
    );
  }

  List<Map<String, dynamic>> _privacySections() => [
    {
      'icon': Icons.waving_hand_rounded,
      'title': SC.tr('pp_intro_title'),
      'body': SC.tr('pp_intro_body'),
    },
    {
      // The standard 'database' look in Material Design
      'icon': Icons.storage_rounded,

      'title': SC.tr('pp_data_title'),
      'body': SC.tr('pp_data_body'),
    },
    {
      'icon': Icons.settings_suggest_rounded,
      'title': SC.tr('pp_use_title'),
      'body': SC.tr('pp_use_body'),
    },
    {
      'icon': Icons.lock_rounded,
      'title': SC.tr('pp_security_title'),
      'body': SC.tr('pp_security_body'),
    },
    {
      'icon': Icons.contact_mail_rounded,
      'title': SC.tr('pp_contact_title'),
      'body': SC.tr('pp_contact_body'),
    },
  ];

  List<Map<String, dynamic>> _termsSections() => [
    {
      'icon': Icons.handshake_rounded,
      'title': SC.tr('tos_accept_title'),
      'body': SC.tr('tos_accept_body'),
    },
    {
      'icon': Icons.rule_rounded,
      'title': SC.tr('tos_use_title'),
      'body': SC.tr('tos_use_body'),
    },
    {
      'icon': Icons.manage_accounts_rounded,
      'title': SC.tr('tos_account_title'),
      'body': SC.tr('tos_account_body'),
    },
    {
      'icon': Icons.block_rounded,
      'title': SC.tr('tos_terminate_title'),
      'body': SC.tr('tos_terminate_body'),
    },
    {
      'icon': Icons.update_rounded,
      'title': SC.tr('tos_changes_title'),
      'body': SC.tr('tos_changes_body'),
    },
  ];
}
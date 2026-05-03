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

  // ── FutureBuilder approach — setState নির্ভরযোগ্য না Android-এ ──────────
  late final Future<PackageInfo> _packageInfoFuture;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 0,
    )..forward();
    _packageInfoFuture = PackageInfo.fromPlatform();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ── Default mail app খোলো ────────────────────────────────────────────────
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
    final cardColor    = isDark ? SC.cardBg  : Colors.white;
    final textColor    = isDark ? Colors.white : const Color(0xFF1A2332);
    final subTextColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : const Color(0xFF4A5568);
    final borderColor  = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.08);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: _buildBackground(
          child: Column(children: [
            _buildAppBar(textColor),
            Expanded(
              child: FadeTransition(
                opacity: _fadeController,
                child: FutureBuilder<PackageInfo>(
                  future: _packageInfoFuture,
                  builder: (context, snapshot) {
                    // data আসার আগে '—' দেখাবে, আসলে real value দেখাবে
                    final version     = snapshot.data?.version     ?? '—';
                    final buildNumber = snapshot.data?.buildNumber ?? '—';

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 40),
                      children: [

                        // ── App logo ─────────────────────────────────
                        Center(
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: SC.cyan.withValues(alpha: 0.12),
                              border: Border.all(
                                  color: SC.cyan.withValues(alpha: 0.3),
                                  width: 2),
                            ),
                            child: const Icon(Icons.groups_rounded,
                                color: SC.cyan, size: 44),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Center(
                          child: Text(
                            SC.tr('app_name'),
                            style: TextStyle(
                                color: textColor,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // version — FutureBuilder এর ভেতরে থাকায় real data পাবে
                        Center(
                          child: Text(
                            '${SC.tr('version')} $version',
                            style: TextStyle(
                                color: subTextColor, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── App Info ──────────────────────────────────
                        _sectionHeader(SC.tr('app_info'),
                            Icons.info_rounded, SC.cyan, textColor),
                        _customCard(cardColor, borderColor, isDark, [
                          _customTile(
                            Icons.info_outline_rounded, SC.cyan,
                            SC.tr('version'), version,
                            textColor, subTextColor,
                          ),
                          _divider(borderColor),
                          _customTile(
                            Icons.build_rounded, SC.blue,
                            SC.tr('build_number'), buildNumber,
                            textColor, subTextColor,
                          ),
                          _divider(borderColor),
                          _customTile(
                            Icons.calendar_today_rounded, SC.teal,
                            SC.tr('release_date'), 'January 2026',
                            textColor, subTextColor,
                          ),
                        ]),

                        const SizedBox(height: 22),

                        // ── Developer ─────────────────────────────────
                        _sectionHeader(SC.tr('developer'),
                            Icons.code_rounded, SC.purple, textColor),
                        _customCard(cardColor, borderColor, isDark, [
                          _customTile(
                            Icons.people_rounded, SC.purple,
                            SC.tr('developer'), SC.tr('dev_team'),
                            textColor, subTextColor,
                          ),
                          _divider(borderColor),
                          _customTile(
                            Icons.email_rounded, SC.blue,
                            SC.tr('contact'),
                            'consciousstudentsociety@gmail.com',
                            textColor, subTextColor,
                            onTap: _openEmail,
                            trailingIcon: Icons.open_in_new_rounded,
                          ),
                        ]),

                        const SizedBox(height: 22),

                        // ── Legal ─────────────────────────────────────
                        _sectionHeader(SC.tr('legal'),
                            Icons.gavel_rounded, SC.amber, textColor),
                        _customCard(cardColor, borderColor, isDark, [
                          _customTile(
                            Icons.privacy_tip_rounded, SC.amber,
                            SC.tr('privacy_policy'), SC.tr('privacy_sub'),
                            textColor, subTextColor,
                            onTap: () => _openLegalPage(isPrivacy: true),
                          ),
                          _divider(borderColor),
                          _customTile(
                            Icons.description_rounded, SC.orange,
                            SC.tr('terms_service'), SC.tr('terms_sub'),
                            textColor, subTextColor,
                            onTap: () => _openLegalPage(isPrivacy: false),
                          ),
                        ]),

                        const SizedBox(height: 30),

                        // ── Footer ────────────────────────────────────
                        Center(
                          child: Text(
                            '© 2026 CSS App. All rights reserved.',
                            style: TextStyle(
                                color: subTextColor.withValues(alpha: 0.4),
                                fontSize: 11),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Legal page navigation ────────────────────────────────────────────────
  void _openLegalPage({required bool isPrivacy}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _LegalPage(isPrivacy: isPrivacy)),
    );
  }

  // ── AppBar ───────────────────────────────────────────────────────────────
  Widget _buildAppBar(Color textColor) => Container(
    padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10, bottom: 10),
    child: Row(children: [
      IconButton(
        icon: Icon(Icons.arrow_back_ios_new,
            color: textColor, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      Expanded(
        child: Text(
          SC.tr('about_title'),
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
        SafeArea(top: false, child: child),
      ]);

  // ── Section header ────────────────────────────────────────────────────────
  Widget _sectionHeader(
      String title, IconData icon, Color color, Color textColor) =>
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 12),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
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

  // ── Card ──────────────────────────────────────────────────────────────────
  Widget _customCard(Color cardColor, Color borderColor, bool isDark,
      List<Widget> children) =>
      Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
                color: Colors.black
                    .withValues(alpha: isDark ? 0.25 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(children: children),
      );

  // ── Tile ──────────────────────────────────────────────────────────────────
  Widget _customTile(
      IconData icon,
      Color iconColor,
      String title,
      String subtitle,
      Color textColor,
      Color subTextColor, {
        VoidCallback? onTap,
        IconData? trailingIcon,
      }) =>
      ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title,
            style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: TextStyle(color: subTextColor, fontSize: 12)),
        onTap: onTap,
        trailing: onTap != null
            ? Icon(trailingIcon ?? Icons.chevron_right_rounded,
            color: subTextColor, size: 20)
            : null,
      );

  // ── Divider ───────────────────────────────────────────────────────────────
  Widget _divider(Color borderColor) =>
      Divider(height: 1, color: borderColor, indent: 18, endIndent: 18);
}

// ════════════════════════════════════════════════════════════════════════════
// In-app Legal Page (Privacy Policy & Terms of Service)
// ════════════════════════════════════════════════════════════════════════════

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
    final cardColor    = isDark ? SC.cardBg  : Colors.white;
    final borderColor  = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.08);
    final accentColor  = isPrivacy ? SC.amber : SC.cyan;

    final List<Map<String, String>> sections = isPrivacy
        ? [
      {'title': SC.tr('pp_intro_title'),    'body': SC.tr('pp_intro_body')},
      {'title': SC.tr('pp_data_title'),     'body': SC.tr('pp_data_body')},
      {'title': SC.tr('pp_use_title'),      'body': SC.tr('pp_use_body')},
      {'title': SC.tr('pp_security_title'), 'body': SC.tr('pp_security_body')},
      {'title': SC.tr('pp_contact_title'),  'body': SC.tr('pp_contact_body')},
    ]
        : [
      {'title': SC.tr('tos_accept_title'),    'body': SC.tr('tos_accept_body')},
      {'title': SC.tr('tos_use_title'),       'body': SC.tr('tos_use_body')},
      {'title': SC.tr('tos_account_title'),   'body': SC.tr('tos_account_body')},
      {'title': SC.tr('tos_terminate_title'), 'body': SC.tr('tos_terminate_body')},
      {'title': SC.tr('tos_changes_title'),   'body': SC.tr('tos_changes_body')},
    ];

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
              child: SC.blob(260, accentColor.withValues(alpha: 0.04))),
          Positioned(
              bottom: 200,
              left: -120,
              child: SC.blob(240, SC.blue.withValues(alpha: 0.04))),

          SafeArea(
            top: false,
            child: Column(children: [
              // ── AppBar ──────────────────────────────────────────────
              Container(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 10,
                    bottom: 10),
                child: Row(children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new,
                        color: textColor, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      isPrivacy
                          ? SC.tr('pp_title')
                          : SC.tr('tos_title'),
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

              // ── Content ────────────────────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 40),
                  children: [
                    // Last updated badge
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color:
                              accentColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          isPrivacy
                              ? SC.tr('pp_last_updated')
                              : SC.tr('tos_last_updated'),
                          style: TextStyle(
                              color: accentColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section cards
                    ...sections.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(
                                    alpha: isDark ? 0.25 : 0.06),
                                blurRadius: 14,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                width: 4,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  borderRadius:
                                  BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  s['title']!,
                                  style: TextStyle(
                                      color: textColor,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 12),
                            Text(
                              s['body']!,
                              style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 13,
                                  height: 1.7),
                            ),
                          ],
                        ),
                      ),
                    )),

                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        '© 2026 CSS App',
                        style: TextStyle(
                            color: subTextColor.withValues(alpha: 0.4),
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
}
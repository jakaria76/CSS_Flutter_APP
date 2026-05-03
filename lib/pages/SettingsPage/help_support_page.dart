import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late final List<Map<String, String>> _allFaqs;

  static const String _supportEmail =
      'consciousstudentsociety@gmail.com';

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      value: 0,
    )..forward();

    _allFaqs = [
      {'q': 'faq_q1', 'a': 'faq_a1'},
      {'q': 'faq_q2', 'a': 'faq_a2'},
      {'q': 'faq_q3', 'a': 'faq_a3'},
      {'q': 'faq_q4', 'a': 'faq_a4'},
    ];

    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {
        'subject': SC.tr('email_subject'),
        'body': SC.tr('email_body'),
      },
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) SC.toast(context, SC.tr('email_not_found'), SC.red);
    }
  }

  void _openLiveChat() {
    SC.toast(context, SC.tr('chat_coming_soon'), SC.cyan);
  }

  List<Map<String, String>> get _filteredFaqs {
    if (_searchQuery.isEmpty) return _allFaqs;
    return _allFaqs.where((faq) {
      final q = SC.tr(faq['q']!).toLowerCase();
      final a = SC.tr(faq['a']!).toLowerCase();
      return q.contains(_searchQuery) || a.contains(_searchQuery);
    }).toList();
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
    final isDark = SC.isDark;
    final cardColor = isDark ? SC.cardBg : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subTextColor = isDark
        ? Colors.white.withValues(alpha: 0.50)
        : const Color(0xFF4A5568);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.08);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(children: [
          Container(
              decoration: BoxDecoration(gradient: SC.currentGradient)),
          Positioned(
            top: -60,
            right: -60,
            child: SC.blob(220, SC.teal.withValues(alpha: 0.05)),
          ),
          Column(children: [
            _buildAppBar(textColor),
            Expanded(
              child: FadeTransition(
                opacity: _fadeCtrl,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Hero ──────────────────────────────────
                      Text(
                        SC.tr('how_can_we_help'),
                        style: TextStyle(
                            color: textColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _supportEmail,
                        style: TextStyle(
                            color: SC.cyan.withValues(alpha: 0.8),
                            fontSize: 12),
                      ),
                      const SizedBox(height: 18),

                      // ── Search ────────────────────────────────
                      _buildSearchBar(
                          cardColor, textColor, subTextColor, borderColor),
                      const SizedBox(height: 28),

                      // ── Contact Us ────────────────────────────
                      _sectionHeader(SC.tr('contact_us'),
                          Icons.support_agent_rounded, SC.cyan, subTextColor),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: _contactCard(
                            icon: Icons.chat_bubble_rounded,
                            title: SC.tr('live_chat'),
                            color: SC.cyan,
                            cardColor: cardColor,
                            textColor: textColor,
                            borderColor: borderColor,
                            onTap: _openLiveChat,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _contactCard(
                            icon: Icons.email_rounded,
                            title: SC.tr('send_email'),
                            color: SC.blue,
                            cardColor: cardColor,
                            textColor: textColor,
                            borderColor: borderColor,
                            onTap: _sendEmail,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),

                      // ── Email address card ────────────────────
                      InkWell(
                        onTap: _sendEmail,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: SC.blue.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: SC.blue.withValues(alpha: 0.2)),
                          ),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: SC.blue.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.mail_outline_rounded,
                                  color: SC.blue, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    SC.tr('send_email'),
                                    style: TextStyle(
                                        color: textColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _supportEmail,
                                    style: TextStyle(
                                        color: SC.blue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded,
                                color: SC.blue.withValues(alpha: 0.5),
                                size: 14),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── FAQ ───────────────────────────────────
                      _sectionHeader(SC.tr('faqs'), Icons.quiz_rounded,
                          SC.purple, subTextColor),
                      const SizedBox(height: 12),

                      _filteredFaqs.isEmpty
                          ? _emptyResult(subTextColor)
                          : Column(
                        children: _filteredFaqs
                            .map((faq) => _faqTile(
                          questionKey: faq['q']!,
                          answerKey: faq['a']!,
                          cardColor: cardColor,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          borderColor: borderColor,
                        ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildAppBar(Color textColor) {
    return Container(
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10, bottom: 4),
      child: Row(children: [
        IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        Expanded(
          child: Text(
            SC.tr('help_support'),
            textAlign: TextAlign.center,
            style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),
        ),
        const SizedBox(width: 48),
      ]),
    );
  }

  Widget _buildSearchBar(Color cardColor, Color textColor,
      Color subTextColor, Color borderColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: textColor, fontSize: 14),
        decoration: InputDecoration(
          hintText: SC.tr('search_placeholder'),
          hintStyle: TextStyle(color: subTextColor, fontSize: 14),
          prefixIcon:
          const Icon(Icons.search_rounded, color: SC.cyan, size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear_rounded,
                color: subTextColor, size: 18),
            onPressed: () => _searchController.clear(),
          )
              : null,
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        ),
      ),
    );
  }

  Widget _contactCard({
    required IconData icon,
    required String title,
    required Color color,
    required Color cardColor,
    required Color textColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 10),
          Text(title,
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _faqTile({
    required String questionKey,
    required String answerKey,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          title: Text(SC.tr(questionKey),
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
          iconColor: SC.cyan,
          collapsedIconColor: subTextColor,
          shape:
          const RoundedRectangleBorder(side: BorderSide.none),
          collapsedShape:
          const RoundedRectangleBorder(side: BorderSide.none),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(SC.tr(answerKey),
                  style: TextStyle(
                      color: subTextColor, fontSize: 13, height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyResult(Color subTextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Center(
        child: Column(children: [
          Icon(Icons.search_off_rounded, color: subTextColor, size: 40),
          const SizedBox(height: 10),
          Text(SC.tr('no_result'),
              style: TextStyle(color: subTextColor, fontSize: 14)),
        ]),
      ),
    );
  }

  Widget _sectionHeader(
      String title, IconData icon, Color accent, Color subTextColor) {
    return Row(children: [
      Icon(icon, color: accent, size: 16),
      const SizedBox(width: 8),
      Text(title.toUpperCase(),
          style: TextStyle(
              color: subTextColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8)),
    ]);
  }
}
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
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _heroCtrl;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const String _supportEmail = 'consciousstudentsociety@gmail.com';

  // FAQ keys — SC.tr() দিয়ে dynamically render হবে
  static const List<_FaqItem> _faqItems = [
    _FaqItem(qKey: 'faq_q1', aKey: 'faq_a1'),
    _FaqItem(qKey: 'faq_q2', aKey: 'faq_a2'),
    _FaqItem(qKey: 'faq_q3', aKey: 'faq_a3'),
    _FaqItem(qKey: 'faq_q4', aKey: 'faq_a4'),
  ];

  final Set<int> _expandedFaqs = {};

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
        value: 0)
      ..forward();
    _heroCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
        value: 0)
      ..forward();
    _searchController.addListener(
            () => setState(() => _searchQuery = _searchController.text.toLowerCase()));
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _heroCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<int> get _filteredIndices {
    if (_searchQuery.isEmpty) return List.generate(_faqItems.length, (i) => i);
    return List.generate(_faqItems.length, (i) => i).where((i) {
      final q = SC.tr(_faqItems[i].qKey).toLowerCase();
      final a = SC.tr(_faqItems[i].aKey).toLowerCase();
      return q.contains(_searchQuery) || a.contains(_searchQuery);
    }).toList();
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

  void _openLiveChat() =>
      SC.toast(context, SC.tr('chat_coming_soon'), SC.cyan);

  // ── Build ──────────────────────────────────────────────────────────────────
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
    final cardColor    = isDark ? const Color(0xFF161D2E) : Colors.white;
    final card2        = isDark ? const Color(0xFF1C2436) : const Color(0xFFEFF3FA);
    final textColor    = isDark ? Colors.white : const Color(0xFF1A2332);
    final subTextColor = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : const Color(0xFF6B7280);
    final borderColor  = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.07);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? SC.bgStart : const Color(0xFFF1F5FB),
        body: Stack(
          children: [
            // ── Background ──
            Positioned.fill(
              child: Container(
                  decoration: BoxDecoration(gradient: SC.currentGradient)),
            ),
            Positioned(
                top: -80,
                right: -60,
                child: _blob(260, SC.teal.withValues(alpha: 0.06))),
            Positioned(
                bottom: 80,
                left: -60,
                child: _blob(220, SC.purple.withValues(alpha: 0.05))),
            Positioned(
                top: 300,
                right: -40,
                child: _blob(160, SC.blue.withValues(alpha: 0.04))),

            // ── Content ──
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildAppBar(textColor, borderColor, cardColor),
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeCtrl,
                      child: SingleChildScrollView(
                        padding:
                        const EdgeInsets.fromLTRB(20, 4, 20, 60),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            _buildHero(textColor),
                            const SizedBox(height: 20),
                            _buildStatsRow(
                                cardColor, textColor, subTextColor, borderColor),
                            const SizedBox(height: 24),
                            _buildSearchBar(
                                cardColor, textColor, subTextColor, borderColor),
                            const SizedBox(height: 28),
                            _sectionHeader(
                                SC.tr('contact_section'),
                                Icons.support_agent_rounded,
                                SC.cyan,
                                subTextColor),
                            const SizedBox(height: 14),
                            _buildContactGrid(
                                cardColor, textColor, borderColor),
                            const SizedBox(height: 14),
                            _buildEmailDetailCard(textColor),
                            const SizedBox(height: 28),
                            _sectionHeader(
                                SC.tr('faq_section'),
                                Icons.quiz_rounded,
                                SC.purple,
                                subTextColor),
                            const SizedBox(height: 14),
                            _buildFaqList(
                                cardColor, textColor, subTextColor, borderColor),
                            const SizedBox(height: 40),
                          ],
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

  // ── AppBar ─────────────────────────────────────────────────────────────────
  Widget _buildAppBar(Color textColor, Color borderColor, Color cardColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: textColor, size: 18),
            ),
          ),
          const Spacer(),
          Text(
            SC.tr('help_support'),
            style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.3),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // ── Hero ───────────────────────────────────────────────────────────────────
  Widget _buildHero(Color textColor) {
    return SlideTransition(
      position: Tween<Offset>(
          begin: const Offset(0, 0.3), end: Offset.zero)
          .animate(CurvedAnimation(
          parent: _heroCtrl, curve: Curves.easeOut)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [SC.isDark ? Colors.white : const Color(0xFF1A2332), SC.teal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              SC.tr('help_hero_title'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                height: 1.25,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.mail_outline_rounded,
                  color: SC.cyan.withValues(alpha: 0.7), size: 13),
              const SizedBox(width: 5),
              Text(
                _supportEmail,
                style: TextStyle(
                    color: SC.cyan.withValues(alpha: 0.8),
                    fontSize: 12,
                    letterSpacing: 0.2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stats Row ──────────────────────────────────────────────────────────────
  Widget _buildStatsRow(Color cardColor, Color textColor,
      Color subTextColor, Color borderColor) {
    final stats = [
      {'num': '${_faqItems.length}', 'labelKey': 'stat_faq'},
      {'num': '24h',                 'labelKey': 'stat_response'},
      {'num': '2',                   'labelKey': 'stat_contact'},
    ];
    return Row(
      children: stats.asMap().entries.map((e) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: e.key < stats.length - 1 ? 10 : 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (b) => LinearGradient(
                    colors: [SC.cyan, SC.purple],
                  ).createShader(b),
                  child: Text(
                    e.value['num']!,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 2),
                Text(SC.tr(e.value['labelKey']!),
                    style: TextStyle(color: subTextColor, fontSize: 11)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Search Bar ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar(Color cardColor, Color textColor,
      Color subTextColor, Color borderColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _searchQuery.isNotEmpty
              ? SC.cyan.withValues(alpha: 0.35)
              : borderColor,
        ),
        boxShadow: _searchQuery.isNotEmpty
            ? [BoxShadow(
            color: SC.cyan.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 2)]
            : [],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: textColor, fontSize: 14),
        decoration: InputDecoration(
          hintText: SC.tr('faq_search_hint'),
          hintStyle: TextStyle(color: subTextColor, fontSize: 14),
          prefixIcon:
          const Icon(Icons.search_rounded, color: SC.cyan, size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.cancel_rounded,
                color: subTextColor, size: 20),
            onPressed: () => _searchController.clear(),
          )
              : null,
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(vertical: 15, horizontal: 4),
        ),
      ),
    );
  }

  // ── Contact Grid ───────────────────────────────────────────────────────────
  Widget _buildContactGrid(
      Color cardColor, Color textColor, Color borderColor) {
    return Row(
      children: [
        Expanded(
          child: _contactCard(
            icon: Icons.chat_bubble_rounded,
            titleKey: 'live_chat',
            subtitleKey: 'chat_soon_sub',
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
            titleKey: 'send_email',
            subtitleKey: 'direct_reply',
            color: SC.blue,
            cardColor: cardColor,
            textColor: textColor,
            borderColor: borderColor,
            onTap: _sendEmail,
          ),
        ),
      ],
    );
  }

  Widget _contactCard({
    required IconData icon,
    required String titleKey,
    required String subtitleKey,
    required Color color,
    required Color cardColor,
    required Color textColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(SC.tr(titleKey),
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            const SizedBox(height: 3),
            Text(SC.tr(subtitleKey),
                style: TextStyle(
                    color: color.withValues(alpha: 0.7), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // ── Email Detail Card ──────────────────────────────────────────────────────
  Widget _buildEmailDetailCard(Color textColor) {
    return InkWell(
      onTap: _sendEmail,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: SC.blue.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SC.blue.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(SC.tr('send_email'),
                      style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(_supportEmail,
                      style: const TextStyle(
                          color: SC.blue,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: SC.blue.withValues(alpha: 0.5), size: 14),
          ],
        ),
      ),
    );
  }

  // ── FAQ List ───────────────────────────────────────────────────────────────
  Widget _buildFaqList(Color cardColor, Color textColor,
      Color subTextColor, Color borderColor) {
    final indices = _filteredIndices;

    if (indices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, color: subTextColor, size: 44),
              const SizedBox(height: 12),
              Text(SC.tr('faq_no_result'),
                  style: TextStyle(color: subTextColor, fontSize: 14)),
              const SizedBox(height: 4),
              Text(SC.tr('faq_no_result_sub'),
                  style: TextStyle(
                      color: subTextColor.withValues(alpha: 0.6),
                      fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: indices.map((i) => _faqTile(
        index: i,
        cardColor: cardColor,
        textColor: textColor,
        subTextColor: subTextColor,
        borderColor: borderColor,
      )).toList(),
    );
  }

  Widget _faqTile({
    required int index,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
  }) {
    final isOpen   = _expandedFaqs.contains(index);
    final question = SC.tr(_faqItems[index].qKey);
    final answer   = SC.tr(_faqItems[index].aKey);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOpen
              ? SC.purple.withValues(alpha: 0.3)
              : borderColor,
        ),
        boxShadow: isOpen
            ? [BoxShadow(
            color: SC.purple.withValues(alpha: 0.06),
            blurRadius: 20,
            spreadRadius: 2)]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            // Header
            InkWell(
              onTap: () => setState(() {
                isOpen
                    ? _expandedFaqs.remove(index)
                    : _expandedFaqs.add(index);
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 15),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: SC.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                              color: SC.purple,
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        question,
                        style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            height: 1.35),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: isOpen ? 0.5 : 0,
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeInOut,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isOpen ? SC.purple : subTextColor,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Answer
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: isOpen
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                        color: SC.purple.withValues(alpha: 0.12)),
                  ),
                  color: SC.purple.withValues(alpha: 0.03),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 3,
                      height: 60,
                      margin: const EdgeInsets.only(right: 12, top: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [SC.purple, SC.blue],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        answer,
                        style: TextStyle(
                            color: subTextColor,
                            fontSize: 13,
                            height: 1.65),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section Header ─────────────────────────────────────────────────────────
  Widget _sectionHeader(
      String title, IconData icon, Color accent, Color subTextColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: accent, size: 14),
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
              color: subTextColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0),
        ),
      ],
    );
  }

  // ── Blob ───────────────────────────────────────────────────────────────────
  Widget _blob(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, Colors.transparent]),
    ),
  );
}

// ── FAQ Item Model ─────────────────────────────────────────────────────────────
class _FaqItem {
  final String qKey;
  final String aKey;
  const _FaqItem({required this.qKey, required this.aKey});
}
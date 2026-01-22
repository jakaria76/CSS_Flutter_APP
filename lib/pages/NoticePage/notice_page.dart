import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:css/models/notice_model.dart';

class NoticePage extends StatefulWidget {
  const NoticePage({super.key});

  @override
  State<NoticePage> createState() => _NoticePageState();
}

class _NoticePageState extends State<NoticePage> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  bool _loading = true;
  List<Notice> notices = [];
  String? _error;
  String _searchQuery = '';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fetchNotices();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // সার্চ ফিল্টার লজিক
  List<Notice> get _filteredNotices {
    if (_searchQuery.isEmpty) return notices;
    return notices
        .where((n) => n.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Future<void> _fetchNotices() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _supabase
          .from('notices')
          .select()
          .order('publish_date', ascending: false);

      notices = (data as List).map((e) => Notice.fromMap(e)).toList();
      _animationController.forward(from: 0);
    } catch (e) {
      _error = 'বিজ্ঞপ্তি লোড করতে সমস্যা হয়েছে';
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openPdf(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showErrorSnackBar('ডকুমেন্টটি খোলা যাচ্ছে না');
    }
  }

  void _showErrorSnackBar(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          if (_loading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)))
          else if (_error != null)
            SliverFillRemaining(child: _buildErrorState())
          else if (_filteredNotices.isEmpty)
              SliverFillRemaining(child: _buildEmptyState())
            else
              _buildNoticeList(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF0F2027),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 90),
        title: const Text(
          'বিজ্ঞপ্তি বোর্ড',
          style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Colors.white,
              letterSpacing: 1.2
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topRight,
                colors: [Color(0xFF0F2027), Color(0xFF2C5364)]
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                  top: -50,
                  right: -50,
                  child: CircleAvatar(
                      radius: 120,
                      backgroundColor: Colors.cyanAccent.withOpacity(0.05)
                  )
              ),
              const Center(
                  child: Opacity(
                      opacity: 0.05,
                      child: Icon(Icons.campaign_rounded, size: 150, color: Colors.white)
                  )
              ),
            ],
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'বিজ্ঞপ্তি খুঁজুন...',
              hintStyle: const TextStyle(color: Colors.white30),
              prefixIcon: const Icon(Icons.search, color: Colors.cyanAccent),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoticeList() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final notice = _filteredNotices[index];
            return FadeTransition(
              opacity: _animationController,
              child: _buildNoticeCard(notice, index),
            );
          },
          childCount: _filteredNotices.length,
        ),
      ),
    );
  }

  Widget _buildNoticeCard(Notice notice, int index) {
    final isNew = DateTime.now().difference(notice.publishDate).inDays < 3;
    final themeColor = index % 2 == 0 ? Colors.cyanAccent : Colors.purpleAccent;
    final secondaryColor = index % 2 == 0 ? Colors.blue : Colors.pink;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Container(
            height: 5,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [themeColor, secondaryColor]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.all(20),
            leading: CircleAvatar(
                backgroundColor: Colors.white10,
                child: Text(
                    '${index + 1}',
                    style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)
                )
            ),
            title: Text(
                notice.title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, height: 1.4)
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(children: [
                const Icon(Icons.calendar_today, size: 12, color: Colors.white38),
                const SizedBox(width: 5),
                Text(
                    DateFormat('dd MMM yyyy').format(notice.publishDate),
                    style: const TextStyle(color: Colors.white38, fontSize: 12)
                ),
                if (isNew) ...[
                  const SizedBox(width: 10),
                  _cardBadge('NEW', Colors.redAccent)
                ],
                if (notice.pdfUrl != null) ...[
                  const SizedBox(width: 10),
                  _cardBadge('PDF', Colors.blueAccent)
                ],
              ]),
            ),
          ),
          if (notice.pdfUrl != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: const BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(24))
              ),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                        onPressed: () => _openPdf(notice.pdfUrl!),
                        icon: Icon(Icons.picture_as_pdf_rounded, color: themeColor),
                        label: Text('ডকুমেন্ট দেখুন', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold))
                    ),
                  ]
              ),
            )
        ],
      ),
    );
  }

  Widget _cardBadge(String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: color.withOpacity(0.3))
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold))
  );

  Widget _buildErrorState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
        const SizedBox(height: 10),
        Text(_error ?? 'ত্রুটি ঘটেছে', style: const TextStyle(color: Colors.white54)),
      ],
    ),
  );

  Widget _buildEmptyState() => const Center(
    child: Text('কোনো বিজ্ঞপ্তি পাওয়া যায়নি', style: TextStyle(color: Colors.white24)),
  );
}
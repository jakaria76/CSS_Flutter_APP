import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:css/models/notice_model.dart';
import 'dart:math' as math;

class NoticePage extends StatefulWidget {
  const NoticePage({super.key});

  @override
  State<NoticePage> createState() => _NoticePageState();
}

class _NoticePageState extends State<NoticePage> with TickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  bool _loading = true;
  List<Notice> notices = [];
  String? _error;

  late AnimationController _mainFadeController;
  late AnimationController _rotationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchNotices();
  }

  void _initAnimations() {
    _mainFadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _mainFadeController,
      curve: Curves.easeInOut,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _mainFadeController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _fetchNotices() async {
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
      _mainFadeController.forward(from: 0);
    } catch (e) {
      _error = 'বিজ্ঞপ্তি লোড করতে সমস্যা হয়েছে';
      debugPrint(e.toString());
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openPdf(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _showCustomSnackbar('PDF খোলা হচ্ছে...', Icons.picture_as_pdf, Colors.cyanAccent);
      } else {
        _showCustomSnackbar('PDF খুলতে সমস্যা হয়েছে', Icons.error, Colors.redAccent);
      }
    } catch (e) {
      _showCustomSnackbar('লিংক খুলতে ব্যর্থ', Icons.link_off, Colors.redAccent);
    }
  }

  void _showCustomSnackbar(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: const Color(0xFF1A2332),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color.withOpacity(0.3))),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) return 'আজ';
    if (difference.inDays == 1) return 'গতকাল';
    if (difference.inDays < 7) return '${difference.inDays} দিন আগে';
    return DateFormat('dd MMM yyyy', 'bn').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.3, -0.5),
            radius: 1.8,
            colors: [Color(0xFF1A2332), Color(0xFF0F1419), Color(0xFF0A0E1A)],
          ),
        ),
        child: Stack(
          children: [
            // Background Orbs (About Page Style)
            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) => Stack(
                children: [
                  _positionedOrb(top: -100, left: -50, size: 350, color: Colors.cyanAccent.withOpacity(0.08)),
                  _positionedOrb(bottom: 100, right: -100, size: 450, color: Colors.purpleAccent.withOpacity(0.06)),
                ],
              ),
            ),
            // Content
            _loading
                ? _buildPremiumLoader()
                : _error != null
                ? _buildErrorScreen()
                : FadeTransition(
              opacity: _fadeAnimation,
              child: _buildMainContent(),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: const Text('NOTICES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.cyanAccent, size: 20),
            onPressed: _fetchNotices,
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildNoticeCard(notices[index], index),
              childCount: notices.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildNoticeCard(Notice notice, int index) {
    final isNew = DateTime.now().difference(notice.publishDate).inDays < 3;
    final color = index % 2 == 0 ? Colors.cyanAccent : Colors.purpleAccent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _modernGlassCard(
        child: InkWell(
          onTap: notice.pdfUrl != null ? () => _openPdf(notice.pdfUrl!) : null,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _badge(
                      label: _getRelativeTime(notice.publishDate).toUpperCase(),
                      icon: Icons.access_time_filled_rounded,
                      color: color,
                    ),
                    if (isNew) _badge(label: "NEW", icon: Icons.bolt, color: Colors.orangeAccent),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  notice.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (notice.pdfUrl != null)
                      _actionButton(
                        label: "View Document",
                        icon: Icons.picture_as_pdf_rounded,
                        color: Colors.redAccent,
                        onTap: () => _openPdf(notice.pdfUrl!),
                      ),
                    const Spacer(),
                    // arrow_forward_circle_outline এর বদলে নিচের এটি ব্যবহার করুন
                    Icon(Icons.arrow_circle_right_outlined, color: color.withOpacity(0.5)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= UI HELPERS (About Page Style) =================

  Widget _modernGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _badge({required String label, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _actionButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.cyanAccent.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 2)),
            child: const CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 3),
          ),
          const SizedBox(height: 24),
          const Text('Loading Notices...', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 50),
          const SizedBox(height: 20),
          Text(_error ?? 'Error occurred', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _fetchNotices, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _positionedOrb({double? top, double? left, double? right, double? bottom, required double size, required Color color}) {
    return Positioned(top: top, left: left, right: right, bottom: bottom,
      child: Container(width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 20)]),
      ),
    );
  }
}
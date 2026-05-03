import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'settings_constants.dart';

class AdminFeedbackPage extends StatefulWidget {
  const AdminFeedbackPage({super.key});

  @override
  State<AdminFeedbackPage> createState() => _AdminFeedbackPageState();
}

class _AdminFeedbackPageState extends State<AdminFeedbackPage> {
  List<Map<String, dynamic>> _feedbacks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
  }

  Future<void> _loadFeedbacks() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await Supabase.instance.client
          .from('feedbacks')
          .select()
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _feedbacks = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _isLoading = false; _error = SC.tr('error_loading'); });
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
    final isDark      = SC.isDark;
    final bgColor     = isDark ? SC.bgStart  : const Color(0xFFF0F4FF);
    final cardColor   = isDark ? SC.cardBg   : Colors.white;
    final textColor   = isDark ? Colors.white : const Color(0xFF1A2332);
    final subColor    = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : const Color(0xFF4A5568);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.08);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: _backButton(isDark, textColor),
          title: Text(SC.tr('admin_feedbacks'),
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  letterSpacing: 0.5)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: textColor),
              onPressed: _loadFeedbacks,
            ),
          ],
        ),
        body: Stack(children: [
          Container(
              decoration: BoxDecoration(gradient: SC.currentGradient)),
          Positioned(
              top: -80,
              right: -60,
              child: SC.blob(260, SC.amber.withValues(alpha: 0.04))),
          Positioned(
              bottom: 200,
              left: -120,
              child: SC.blob(240, SC.cyan.withValues(alpha: 0.04))),
          SafeArea(
            child: _isLoading
                ? Center(
                child: CircularProgressIndicator(color: SC.amber))
                : _error != null
                ? Center(
                child: Text(_error!,
                    style: TextStyle(color: textColor)))
                : _feedbacks.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.feedback_outlined,
                      size: 60,
                      color: textColor
                          .withValues(alpha: 0.2)),
                  const SizedBox(height: 12),
                  Text(SC.tr('no_feedbacks'),
                      style: TextStyle(
                          color: textColor
                              .withValues(alpha: 0.4),
                          fontSize: 15)),
                ],
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                  16, 16, 16, 40),
              itemCount: _feedbacks.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 12),
              itemBuilder: (_, i) => _feedbackCard(
                _feedbacks[i],
                cardColor,
                textColor,
                subColor,
                borderColor,
                isDark,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _feedbackCard(
      Map<String, dynamic> item,
      Color cardColor,
      Color textColor,
      Color subColor,
      Color borderColor,
      bool isDark,
      ) {
    final int rating   = (item['rating'] as int?) ?? 0;
    final String name  = (item['user_name']  as String?) ?? SC.tr('anonymous_user');
    final String email = (item['user_email'] as String?) ?? '';
    final String msg   = (item['message']   as String?) ?? '';
    final DateTime? dt = item['created_at'] != null
        ? DateTime.tryParse(item['created_at'])
        : null;
    final String date = dt != null
        ? '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
        : '';

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header: name + date ─────────────────────────────────────
        Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: SC.amber.withValues(alpha: 0.15),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: SC.amber, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  if (email.isNotEmpty)
                    Text(email,
                        style: TextStyle(
                            color: subColor, fontSize: 11)),
                ]),
          ),
          Text(date,
              style: TextStyle(color: subColor, fontSize: 11)),
        ]),

        const SizedBox(height: 12),

        // ── Stars ───────────────────────────────────────────────────
        if (rating > 0) ...[
          Row(children: [
            Text('${SC.tr('rating_label')}: ',
                style: TextStyle(color: subColor, fontSize: 12)),
            ...List.generate(5, (i) => Icon(
                i < rating
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: SC.amber,
                size: 16)),
          ]),
          const SizedBox(height: 10),
        ],

        // ── Message ─────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: SC.amber.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: SC.amber.withValues(alpha: 0.15)),
          ),
          child: Text(msg,
              style: TextStyle(
                  color: textColor, fontSize: 13, height: 1.5)),
        ),
      ]),
    );
  }

  Widget _backButton(bool isDark, Color textColor) => Padding(
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
}
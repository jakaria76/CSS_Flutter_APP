import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'settings_constants.dart';

class BugReportPage extends StatefulWidget {
  const BugReportPage({super.key});

  @override
  State<BugReportPage> createState() => _BugReportPageState();
}

class _BugReportPageState extends State<BugReportPage>
    with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _descController  = TextEditingController();
  late String _selectedCategory;
  bool _isSending = false;
  late AnimationController _fadeController;

  // category key list — value Supabase-এ যাবে SC.tr() থেকে
  static const _categoryKeys = [
    'cat_ui_ux',
    'cat_login',
    'cat_crash',
    'cat_perf',
    'cat_others',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categoryKeys.first;
    _fadeController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
        value: 0)
      ..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_titleController.text.trim().isEmpty ||
        _descController.text.trim().isEmpty) {
      SC.toast(context, SC.tr('fill_all_fields'), SC.orange);
      return;
    }
    setState(() => _isSending = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;

      String? userName;
      if (user != null) {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('name')
            .eq('id', user.id)
            .maybeSingle();
        userName = profile?['name'] as String?;
      }

      await Supabase.instance.client.from('bug_reports').insert({
        'user_id':     user?.id,
        'user_email':  user?.email,
        'user_name':   userName,
        'category':    SC.tr(_selectedCategory),
        'title':       _titleController.text.trim(),
        'description': _descController.text.trim(),
      });

      if (!mounted) return;
      _titleController.clear();
      _descController.clear();
      setState(() => _selectedCategory = _categoryKeys.first);
      SC.toast(context, SC.tr('report_success'), SC.green);
    } catch (_) {
      if (!mounted) return;
      SC.toast(context, SC.tr('report_save_error'), SC.red);
    } finally {
      if (mounted) setState(() => _isSending = false);
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
    final textColor    = isDark ? Colors.white : const Color(0xFF1A2332);
    final subTextColor = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : const Color(0xFF4A5568).withValues(alpha: 0.6);
    final cardColor   = isDark ? SC.cardBg  : Colors.white;
    final borderColor = isDark
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
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 40),
                  children: [
                    // ── Category ──────────────────────────────────────
                    _sectionHeader(SC.tr('bug_category'),
                        Icons.category_rounded, SC.orange, textColor),
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 4),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          dropdownColor: cardColor,
                          style:
                          TextStyle(color: textColor, fontSize: 14),
                          icon: Icon(Icons.keyboard_arrow_down_rounded,
                              color: textColor.withValues(alpha: 0.4)),
                          items: _categoryKeys
                              .map((key) => DropdownMenuItem(
                            value: key,
                            child: Text(SC.tr(key)),
                          ))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedCategory = val!),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ── Title & Description ───────────────────────────
                    _sectionHeader(SC.tr('bug_desc_label'),
                        Icons.bug_report_rounded, SC.red, textColor),
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Column(children: [
                        TextField(
                          controller: _titleController,
                          style:
                          TextStyle(color: textColor, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: SC.tr('bug_title_hint'),
                            hintStyle: TextStyle(
                                color: subTextColor, fontSize: 14),
                            border: InputBorder.none,
                          ),
                        ),
                        Divider(color: borderColor),
                        TextField(
                          controller: _descController,
                          maxLines: 5,
                          style:
                          TextStyle(color: textColor, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: SC.tr('bug_desc_hint'),
                            hintStyle: TextStyle(
                                color: subTextColor, fontSize: 14),
                            border: InputBorder.none,
                          ),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 24),

                    // ── Submit ────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSending ? null : _submitReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SC.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _isSending
                            ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                            : Text(SC.tr('send_report'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

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
        child: Text(SC.tr('bug_report_title'),
            textAlign: TextAlign.center,
            style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: 0.5)),
      ),
      const SizedBox(width: 48),
    ]),
  );

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
}
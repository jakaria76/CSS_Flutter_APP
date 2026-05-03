import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'settings_constants.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage>
    with SingleTickerProviderStateMixin {
  final _feedbackController = TextEditingController();
  bool _isSending = false;
  int _rating = 0;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
        value: 0)
      ..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _sendFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      SC.toast(context, SC.tr('pleaseWriteFeedback'), SC.orange);
      return;
    }
    setState(() => _isSending = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;

      // profiles থেকে name আনো
      String? userName;
      if (user != null) {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('name')
            .eq('id', user.id)
            .maybeSingle();
        userName = profile?['name'] as String?;
      }

      await Supabase.instance.client.from('feedbacks').insert({
        'user_id':    user?.id,
        'user_email': user?.email,
        'user_name':  userName,
        'rating':     _rating > 0 ? _rating : null,
        'message':    _feedbackController.text.trim(),
      });

      if (!mounted) return;
      _feedbackController.clear();
      setState(() => _rating = 0);
      SC.toast(context, SC.tr('feedbackSent'), SC.green);
    } catch (_) {
      if (!mounted) return;
      SC.toast(context, SC.tr('feedback_save_error'), SC.red);
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
    final bgColor      = isDark ? SC.bgStart  : const Color(0xFFF0F4FF);
    final cardColor    = isDark ? SC.cardBg   : Colors.white;
    final textColor    = isDark ? Colors.white : const Color(0xFF1A2332);
    final subTextColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final borderColor  = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.08);
    final hintColor    = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.3);
    final inputFillColor = isDark
        ? Colors.white.withValues(alpha: 0.03)
        : Colors.black.withValues(alpha: 0.03);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: _backButton(isDark, textColor),
          title: Text(SC.tr('giveFeedback'),
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  letterSpacing: 0.5)),
          centerTitle: true,
        ),
        body: _buildBackground(
          child: FadeTransition(
            opacity: _fadeController,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                  18, MediaQuery.of(context).padding.top + 80, 18, 40),
              children: [
                // ── Rating ─────────────────────────────────────────────
                _sectionHeader(
                    SC.tr('rateUs'), Icons.star_rounded, SC.amber, textColor),
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
                  padding: const EdgeInsets.symmetric(
                      vertical: 20, horizontal: 18),
                  child: Column(children: [
                    Text(SC.tr('howIsApp'),
                        style: TextStyle(
                            color: subTextColor
                                .withValues(alpha: isDark ? 0.7 : 0.6),
                            fontSize: 14)),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        return GestureDetector(
                          onTap: () => setState(() => _rating = i + 1),
                          child: Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              i < _rating
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: SC.amber,
                              size: 36,
                            ),
                          ),
                        );
                      }),
                    ),
                  ]),
                ),

                const SizedBox(height: 22),

                // ── Write feedback ──────────────────────────────────────
                _sectionHeader(SC.tr('writeFeedback'), Icons.edit_rounded,
                    SC.cyan, textColor),
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
                  padding: const EdgeInsets.all(18),
                  child: TextField(
                    controller: _feedbackController,
                    maxLines: 5,
                    style: TextStyle(color: textColor, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: SC.tr('hintFeedback'),
                      hintStyle:
                      TextStyle(color: hintColor, fontSize: 14),
                      filled: true,
                      fillColor: inputFillColor,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                          const BorderSide(color: SC.cyan, width: 1.5)),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Send ────────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSending ? null : _sendFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SC.amber,
                      foregroundColor: const Color(0xFF060E17),
                      disabledBackgroundColor:
                      SC.amber.withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                        : Text(SC.tr('send'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
          icon:
          const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          onPressed: () => Navigator.pop(context),
          color: textColor,
        ),
      ),
    ),
  );

  Widget _sectionHeader(
      String title, IconData icon, Color color, Color textColor) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 4),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(width: 10),
          Text(title.toUpperCase(),
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4)),
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
        child,
      ]);
}
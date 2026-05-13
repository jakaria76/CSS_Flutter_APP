import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_constants.dart';

class ProfileVisibilityPage extends StatefulWidget {
  const ProfileVisibilityPage({super.key});

  @override
  State<ProfileVisibilityPage> createState() => _ProfileVisibilityPageState();
}

class _ProfileVisibilityPageState extends State<ProfileVisibilityPage>
    with SingleTickerProviderStateMixin {
  String _visibility = 'public';
  bool _loading = false;
  bool _saving  = false;

  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 0,
    )..forward();
    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final data = await Supabase.instance.client
            .from('profiles')
            .select('visibility')
            .eq('id', userId)
            .single();
        if (mounted) {
          setState(() {
            _visibility = (data['visibility'] as String?) ?? 'public';
          });
        }
      }
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _visibility = prefs.getString('profile_visibility') ?? 'public';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save(String value) async {
    if (_saving || _visibility == value) return;
    setState(() {
      _visibility = value;
      _saving     = true;
    });
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({'visibility': value}).eq('id', userId);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_visibility', value);
      if (mounted) SC.toast(context, SC.tr('visibility_updated'), SC.green);
    } catch (_) {
      if (mounted) SC.toast(context, SC.tr('visibility_error'), SC.red);
    } finally {
      if (mounted) setState(() => _saving = false);
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
    final cardColor    = isDark ? SC.cardBg : Colors.white;
    final textColor    = isDark ? Colors.white : const Color(0xFF1A2332);
    final subTextColor = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : const Color(0xFF4A5568);
    final borderColor  = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.08);

    final options = [
      _VisOption(
        value: 'public',
        icon: Icons.public_rounded,
        color: SC.green,
        title: SC.tr('vis_public'),
        subtitle: SC.tr('vis_public_sub'),
      ),
      _VisOption(
        value: 'private',
        icon: Icons.lock_rounded,
        color: SC.red,
        title: SC.tr('vis_private'),
        subtitle: SC.tr('vis_private_sub'),
      ),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(children: [
          // ── Background ───────────────────────────────────────
          Container(decoration: BoxDecoration(gradient: SC.currentGradient)),
          Positioned(
            top: -60, right: -60,
            child: SC.blob(240, SC.teal.withValues(alpha: isDark ? 0.06 : 0.04)),
          ),
          Positioned(
            bottom: 150, left: -80,
            child: SC.blob(200, SC.green.withValues(alpha: isDark ? 0.04 : 0.03)),
          ),

          SafeArea(
            top: false,
            child: Column(children: [
              _buildAppBar(textColor, isDark),
              Expanded(
                child: _loading
                    ? Center(
                    child: CircularProgressIndicator(
                        color: SC.cyan, strokeWidth: 2))
                    : FadeTransition(
                  opacity: _fadeCtrl,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 48),
                    children: [
                      // ── Header icon ───────────────────
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: SC.teal.withValues(alpha: 0.1),
                            border: Border.all(
                              color: SC.teal.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: SC.teal.withValues(alpha: 0.15),
                                blurRadius: 30,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.visibility_rounded,
                            color: SC.teal,
                            size: 42,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Center(
                        child: Text(
                          SC.tr('visibility_desc'),
                          style: TextStyle(
                              color: subTextColor, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Option Cards ──────────────────
                      for (final opt in options) ...[
                        _optCard(opt, cardColor, textColor,
                            subTextColor, borderColor, isDark),
                        const SizedBox(height: 12),
                      ],

                      // ── Current Status Banner ─────────
                      const SizedBox(height: 4),
                      _statusBanner(isDark),

                      const SizedBox(height: 20),

                      // ── Info Tip ──────────────────────
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: SC.amber
                              .withValues(alpha: isDark ? 0.07 : 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: SC.amber
                                .withValues(alpha: isDark ? 0.25 : 0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: SC.amber, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                SC.tr('visibility_tip'),
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 12,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 12,
      ),
      child: Row(children: [
        IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        Expanded(
          child: Text(
            SC.tr('visibility_title'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(
          width: 48,
          child: _saving
              ? Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  color: SC.cyan, strokeWidth: 2),
            ),
          )
              : null,
        ),
      ]),
    );
  }

  // ── Option Card ────────────────────────────────────────────────────────────
  Widget _optCard(
      _VisOption opt,
      Color cardColor,
      Color textColor,
      Color subTextColor,
      Color borderColor,
      bool isDark,
      ) {
    final selected = _visibility == opt.value;

    return GestureDetector(
      onTap: _saving ? null : () => _save(opt.value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? opt.color.withValues(alpha: isDark ? 0.1 : 0.07)
              : cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? opt.color.withValues(alpha: 0.5)
                : borderColor,
            width: selected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: isDark ? 0.25 : 0.05),
              blurRadius: selected ? 20 : 14,
              offset: const Offset(0, 4),
            ),
            if (selected)
              BoxShadow(
                color: opt.color.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(children: [
          // Icon
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: opt.color.withValues(
                  alpha: selected ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(14),
              border: selected
                  ? Border.all(
                  color: opt.color.withValues(alpha: 0.35),
                  width: 0.8)
                  : null,
            ),
            child: Icon(opt.icon, color: opt.color, size: 22),
          ),
          const SizedBox(width: 16),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opt.title,
                  style: TextStyle(
                    color: selected ? opt.color : textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  opt.subtitle,
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Radio indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? opt.color : Colors.transparent,
              border: Border.all(
                color: selected
                    ? opt.color
                    : subTextColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: selected
                ? const Icon(Icons.check_rounded,
                color: Colors.white, size: 15)
                : null,
          ),
        ]),
      ),
    );
  }

  // ── Status Banner ──────────────────────────────────────────────────────────
  Widget _statusBanner(bool isDark) {
    final isPublic = _visibility == 'public';
    final color    = isPublic ? SC.green : SC.red;
    final icon     = isPublic ? Icons.public_rounded : Icons.lock_rounded;
    final label    = isPublic ? SC.tr('vis_public') : SC.tr('vis_private');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 8),
          Text(
            '${SC.tr('current_visibility')}: $label',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisOption {
  final String   value;
  final IconData icon;
  final Color    color;
  final String   title;
  final String   subtitle;
  const _VisOption({
    required this.value,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}
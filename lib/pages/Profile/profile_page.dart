import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/profile_model.dart';
import '../../services/profile_service.dart';
import '../SettingsPage/settings_page.dart';
import '../SettingsPage/settings_constants.dart';
import 'edit_profile_page.dart';
import 'package:css/services/session_service.dart';
import 'package:css/services/activity_logger.dart';

import 'package:css/widgets/profile/profile_body.dart';
import 'package:css/widgets/profile/profile_cards.dart';
import 'package:css/widgets/profile/profile_header.dart';
import 'package:css/widgets/profile/profile_sections.dart';
import 'package:css/widgets/profile/profile_widgets.dart';

import 'package:css/services/cloudinary_service.dart';
class ProfilePage extends StatefulWidget {
  final String? id;
  const ProfilePage({super.key, this.id});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  final ProfileService _service = ProfileService();
  late Future<ProfileModel?> _profileFuture;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _shimmerController;
  final TextEditingController _passwordController = TextEditingController();
  bool _passwordVisible = false;

  // ── Design tokens ─────────────────────────────────────────────────────────
  static const _cyan   = Color(0xFF00E5FF);
  static const _blue   = Color(0xFF4A90E2);
  static const _orange = Color(0xFFFF8A65);
  static const _red    = Color(0xFFEF5350);
  static const _green  = Color(0xFF4CAF50);
  static const _teal   = Color(0xFF26A69A);
  static const _amber  = Color(0xFFFFB300);
  static const _purple = Color(0xFF9C27B0);
  static const _bgStart = Color(0xFF060E17);
  static const _cardBg  = Color(0xFF0F1E2E);
  static const _surface = Color(0xFF162030);

  // ── Light mode colors ──────────────────────────────────────────────────────
  static const _lightBg      = Color(0xFFF0F4FF);
  static const _lightCard    = Color(0xFFFFFFFF);
  static const _lightSurface = Color(0xFFF5F8FF);

  // ── Theme-aware getters ────────────────────────────────────────────────────
  bool get _isDark => SC.isDark;

  Color get _bgColor      => _isDark ? _bgStart      : _lightBg;
  Color get _cardColor    => _isDark ? _cardBg       : _lightCard;
  Color get _surfaceColor => _isDark ? _surface      : _lightSurface;
  Color get _textColor    => _isDark ? Colors.white  : const Color(0xFF1A2332);
  Color get _subTextColor => _isDark ? Colors.white  : const Color(0xFF4A5568);
  Color get _borderColor  => _isDark
      ? Colors.white.withValues(alpha: 0.07)
      : Colors.black.withValues(alpha: 0.08);

  String _t(String key) => SC.tr(key);

  Color _accentFor(ProfileModel p) {
    if (p.isAdvisor)        return _amber;
    if (p.isPreviousMember) return _purple;
    return _cyan;
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _reload();
    _rotationController = AnimationController(
        vsync: this, duration: const Duration(seconds: 25))
      ..repeat();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900), value: 0)
      ..forward();
    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    _shimmerController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _reload() => setState(() {
    _profileFuture = widget.id != null
        ? _service.getProfileById(widget.id!)
        : _service.getProfile();
  });

// ══════════════════════════════════════════════════════════════════════════
// profile_page.dart এর _deleteAccount() method replace করো
// ══════════════════════════════════════════════════════════════════════════

  Future<void> _deleteAccount() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      _toast(_t('pleaseEnterPassword'), _orange);
      return;
    }
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          LoadingOverlay(message: _t('deletingAccount'), isDark: _isDark),
    );

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (mounted) Navigator.of(context).pop();
        return;
      }

      // ── Step 1: Cloudinary image URL নাও (delete করার আগে) ──
      final profile = await ProfileService().getProfile();
      final imageUrl = profile?.profileImageUrl;

      // ── Step 2: Edge Function call — password verify + সব delete ──
      final response = await supabase.functions.invoke(
        'delete-self-account',
        body: { 'password': password },
      );

      final result = response.data as Map<String, dynamic>?;

      // Edge Function থেকে error আসলে
      if (result == null || result.containsKey('error')) {
        if (mounted) Navigator.of(context).pop();
        final errMsg = result?['error'] ?? _t('somethingWentWrong');
        // Invalid password specific message
        if (errMsg == 'Invalid password') {
          _toast(_t('wrongPassword'), _red);
        } else {
          _toast(errMsg.toString(), _red);
        }
        return;
      }

      // ── Step 3: Cloudinary থেকে profile image delete করো ──
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          await CloudinaryService.deleteFile(imageUrl, resourceType: 'image');
        } catch (_) {
          // image delete fail হলেও account delete সফল ধরো
        }
      }

      // ── Step 4: Local session ও sign out ──
      await ActivityLogger.log(activityType: 'account_deleted');
      await SessionService.deleteCurrentSession();
      try {
        await supabase.auth.signOut();
      } catch (_) {
        // auth user already deleted, signOut fail হতে পারে — ignore
      }

      // ── Step 5: Welcome page এ navigate করো ──
      if (!mounted) return;
      Navigator.of(context).pop(); // loading dismiss
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/welcome', (_) => false);
      _toast(_t('accountDeleted'), _green);

    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _toast(_t('somethingWentWrong'), _red);
      }
    }
  }

  void _toast(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Text(msg,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    ));
  }

  void _showDeleteDialog() {
    _passwordController.clear();
    _passwordVisible = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: GlassCard(
            borderColor: _red.withValues(alpha: 0.4),
            isDark: _isDark,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _pulsingIcon(Icons.warning_amber_rounded, _red),
                const SizedBox(height: 20),
                Text(_t('deleteAccount'),
                    style: TextStyle(
                        color: _textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 22)),
                const SizedBox(height: 12),
                Text(_t('deleteAccountDesc'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: _subTextColor.withValues(alpha: 0.7),
                        fontSize: 14,
                        height: 1.6)),
                const SizedBox(height: 24),
                PasswordField(
                  controller: _passwordController,
                  visible: _passwordVisible,
                  isDark: _isDark,
                  onToggle: () =>
                      setDlg(() => _passwordVisible = !_passwordVisible),
                ),
                const SizedBox(height: 28),
                Row(children: [
                  Expanded(
                      child: OutlineBtn(
                          label: _t('cancel'),
                          isDark: _isDark,
                          onTap: () => Navigator.pop(ctx))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: SolidBtn(
                        label: _t('continue'),
                        color: _red,
                        onTap: () {
                          Navigator.pop(ctx);
                          _confirmDelete();
                        },
                      )),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: GlassCard(
          borderColor: _red.withValues(alpha: 0.5),
          isDark: _isDark,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline_rounded, color: _red, size: 60),
              const SizedBox(height: 18),
              Text(_t('finalConfirmation'),
                  style: TextStyle(
                      color: _textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Text(_t('finalConfirmationDesc'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _subTextColor.withValues(alpha: 0.7),
                      fontSize: 14,
                      height: 1.6)),
              const SizedBox(height: 28),
              Row(children: [
                Expanded(
                    child: OutlineBtn(
                        label: _t('goBack'),
                        isDark: _isDark,
                        onTap: () => Navigator.pop(ctx))),
                const SizedBox(width: 12),
                Expanded(
                    child: SolidBtn(
                      label: _t('yesDelete'),
                      color: _red,
                      onTap: () {
                        Navigator.pop(ctx);
                        _deleteAccount();
                      },
                    )),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (context, __, ___) => _buildScaffold(),
      ),
    );
  }

  Widget _buildScaffold() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: _bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: widget.id != null
              ? Padding(
            padding: const EdgeInsets.all(10),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: (_isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: (_isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.2)),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 16, color: _textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          )
              : null,
          actions: widget.id == null
              ? [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: (_isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: (_isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.2)),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.settings_rounded,
                          size: 20, color: _textColor),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsPage()),
                      ),
                      tooltip: _t('settings'),
                    ),
                  ),
                ),
              ),
            ),
          ]
              : null,
        ),
        body: _buildBackground(
          child: FutureBuilder<ProfileModel?>(
            future: _profileFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return _buildLoading();
              if (!snapshot.hasData || snapshot.data == null)
                return _buildEmpty();
              final p = snapshot.data!;
              return RefreshIndicator(
                onRefresh: () async => _reload(),
                backgroundColor: _cardColor,
                color: _cyan,
                strokeWidth: 2.5,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── Header ─────────────────────────────────────────────
                    ProfileHeader(
                      profile: p,
                      pulseAnimation: _pulseController,
                      textColor: _textColor,
                      subTextColor: _subTextColor,
                      cardColor: _cardColor,
                      accentColor: _accentFor(p),
                    ),

                    // ── Body ───────────────────────────────────────────────
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          FadeTransition(
                            opacity: _fadeController,
                            child: _buildBody(p),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        floatingActionButton: widget.id == null ? _buildFab() : null,
      ),
    );
  }

  // ── Route to correct body ──────────────────────────────────────────────────

  Widget _buildBody(ProfileModel p) {
    if (p.isAdvisor) {
      return AdvisorBody(
        p: p,
        isDark: _isDark,
        textColor: _textColor,
        subTextColor: _subTextColor,
        cardColor: _cardColor,
        surfaceColor: _surfaceColor,
        borderColor: _borderColor,
        isSelf: widget.id == null,
        onDelete: _showDeleteDialog,
      );
    }
    if (p.isPreviousMember) {
      return PreviousBody(
        p: p,
        isDark: _isDark,
        textColor: _textColor,
        subTextColor: _subTextColor,
        cardColor: _cardColor,
        surfaceColor: _surfaceColor,
        borderColor: _borderColor,
        isSelf: widget.id == null,
        onDelete: _showDeleteDialog,
      );
    }
    return PresentBody(
      p: p,
      isDark: _isDark,
      textColor: _textColor,
      subTextColor: _subTextColor,
      cardColor: _cardColor,
      surfaceColor: _surfaceColor,
      borderColor: _borderColor,
      isSelf: widget.id == null,
      onDelete: _showDeleteDialog,
    );
  }

  // ── FAB ───────────────────────────────────────────────────────────────────

  Widget _buildFab() => FutureBuilder<ProfileModel?>(
    future: _profileFuture,
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const SizedBox.shrink();
      final accent = _accentFor(snapshot.data!);
      return FloatingActionButton.extended(
        heroTag: 'profile_page_fab_${widget.id ?? "self"}',
        onPressed: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      EditProfilePage(profile: snapshot.data!)));
          _reload();
        },
        backgroundColor: accent,
        foregroundColor: const Color(0xFF060E17),
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        icon: const Icon(Icons.edit_rounded, size: 20),
        label: Text(_t('editProfile'),
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 0.5)),
      );
    },
  );

  // ── Background ─────────────────────────────────────────────────────────────

  Widget _buildBackground({required Widget child}) => Stack(children: [
    Container(decoration: BoxDecoration(gradient: SC.currentGradient)),
    Positioned(
        top: -100,
        right: -80,
        child: _blob(300, _cyan.withValues(alpha: 0.04))),
    Positioned(
        bottom: 200,
        left: -120,
        child: _blob(280, _blue.withValues(alpha: 0.05))),
    Positioned(
        top: 400,
        right: -60,
        child: _blob(200, _teal.withValues(alpha: 0.04))),
    child,
  ]);

  Widget _blob(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );

  // ── Loading ────────────────────────────────────────────────────────────────

  Widget _buildLoading() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
            width: 52,
            height: 52,
            child: CircularProgressIndicator(
                color: _cyan,
                strokeWidth: 2.5,
                backgroundColor: _cyan.withValues(alpha: 0.12))),
        const SizedBox(height: 20),
        Text(_t('loadingProfile'),
            style: TextStyle(
                color: _subTextColor.withValues(alpha: 0.5),
                fontSize: 14)),
      ],
    ),
  );

  // ── Empty ──────────────────────────────────────────────────────────────────

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: (_isDark ? Colors.white : Colors.black)
                .withValues(alpha: 0.04),
            shape: BoxShape.circle,
            border: Border.all(
                color: (_isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.08)),
          ),
          child: Icon(Icons.person_off_outlined,
              size: 56, color: _textColor.withValues(alpha: 0.2)),
        ),
        const SizedBox(height: 20),
        Text(_t('profileNotFound'),
            style: TextStyle(
                color: _textColor.withValues(alpha: 0.7), fontSize: 16)),
      ],
    ),
  );

  // ── Pulsing icon (delete dialog) ───────────────────────────────────────────

  Widget _pulsingIcon(IconData icon, Color color) => AnimatedBuilder(
    animation: _pulseController,
    builder: (_, __) => Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(
            alpha: 0.08 + _pulseController.value * 0.04),
        border: Border.all(
            color: color.withValues(
                alpha: 0.3 + _pulseController.value * 0.1)),
      ),
      child: Icon(icon, color: color, size: 36),
    ),
  );
}
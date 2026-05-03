import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:css/pages/SettingsPage/settings_constants.dart';

// ════════════════════════════════════════════════════════════════
// DESIGN TOKENS
// ════════════════════════════════════════════════════════════════
class _D {
  static const white     = Color(0xFFEFF4FF);
  static const textDim   = Color(0xFF8BA0BF);
  static const violet    = Color(0xFF8B5CF6);
  static const cyan      = Color(0xFF06B6D4);
  static const emerald   = Color(0xFF10B981);
  static const amber     = Color(0xFFF59E0B);
  static const rose      = Color(0xFFF43F5E);
  static const indigo    = Color(0xFF6366F1);
  static const sky       = Color(0xFF38BDF8);
  static const teal      = Color(0xFF14B8A6);
  static const orange    = Color(0xFFF97316);

  // Light mode
  static const lightBg      = Color(0xFFF0F4FF);
  static const lightText    = Color(0xFF1A2332);
  static const lightSubText = Color(0xFF4A5568);
}

class PersonDetailsPage extends StatefulWidget {
  final String  name;
  final String  role;
  final String  category;
  final String  heroTag;
  final String? imageUrl;
  final String? message;
  final String? bio;
  final String? presentAddress;
  final String? bloodGroup;
  final String? locationDms;
  final String? schoolName;
  final String? schoolGroup;
  final int?    schoolPassingYear;
  final String? collegeName;
  final String? collegeGroup;
  final int?    collegePassingYear;
  final String? universityName;
  final String? department;
  final int?    currentYear;
  final int?    currentSemester;
  final Color   themeColor;

  /// Pass the profile owner's visibility setting here.
  /// Accepted values: 'public' | 'private'
  /// Defaults to 'public' so existing call-sites stay unchanged.
  final String visibility;

  /// Whether the viewer is the profile owner.
  /// Owners always see their own private profile.
  final bool isOwner;

  const PersonDetailsPage({
    super.key,
    required this.name,
    required this.role,
    required this.category,
    required this.heroTag,
    this.imageUrl,
    this.message,
    this.bio,
    this.presentAddress,
    this.bloodGroup,
    this.locationDms,
    this.schoolName,
    this.schoolGroup,
    this.schoolPassingYear,
    this.collegeName,
    this.collegeGroup,
    this.collegePassingYear,
    this.universityName,
    this.department,
    this.currentYear,
    this.currentSemester,
    this.themeColor = const Color(0xFF8B5CF6),
    this.visibility = 'public',
    this.isOwner = false,
  });

  @override
  State<PersonDetailsPage> createState() => _PersonDetailsPageState();
}

class _PersonDetailsPageState extends State<PersonDetailsPage>
    with TickerProviderStateMixin {

  late AnimationController _entryCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _shimmerCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double>   _fadeSlow;
  late Animation<double>   _fadeFast;
  late Animation<Offset>   _slideUp;
  late Animation<double>   _floatAnim;

  final _scrollCtrl = ScrollController();

  /// True when the profile is private AND the viewer is not the owner.
  bool get _isPrivate =>
      widget.visibility == 'private' && !widget.isOwner;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600))
      ..repeat(reverse: true);

    _fadeSlow  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _fadeFast  = CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut));
    _slideUp   = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: _entryCtrl, curve: Curves.easeOutCubic));
    _floatAnim = Tween<double>(begin: -6, end: 6).animate(
        CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _floatCtrl.dispose();
    _shimmerCtrl.dispose();
    _pulseCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  bool get _hasMessage    => widget.message?.trim().isNotEmpty    == true;
  bool get _hasBio        => widget.bio?.trim().isNotEmpty        == true;
  bool get _hasBlood      => widget.bloodGroup?.trim().isNotEmpty == true;
  bool get _hasLocation   => widget.locationDms?.trim().isNotEmpty== true;
  bool get _hasAddress    => widget.presentAddress?.trim().isNotEmpty == true;
  bool get _hasSchool     =>
      widget.schoolName?.trim().isNotEmpty    == true ||
          widget.schoolGroup?.trim().isNotEmpty   == true ||
          widget.schoolPassingYear != null;
  bool get _hasCollege    =>
      widget.collegeName?.trim().isNotEmpty   == true ||
          widget.collegeGroup?.trim().isNotEmpty  == true ||
          widget.collegePassingYear != null;
  bool get _hasUniversity =>
      widget.universityName?.trim().isNotEmpty== true ||
          widget.department?.trim().isNotEmpty    == true ||
          widget.currentYear != null ||
          widget.currentSemester != null;
  bool get _hasEducation  => _hasSchool || _hasCollege || _hasUniversity;

  String? _join(List<String> p) => p.isEmpty ? null : p.join('  ·  ');

  // ════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════
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
    final isDark    = SC.isDark;
    final bgColor   = isDark ? SC.bgStart : _D.lightBg;
    final textColor = isDark ? _D.white    : _D.lightText;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(children: [
          _bg(isDark),
          _floatingOrbs(),
          SafeArea(
            child: Column(children: [
              _topBar(isDark, textColor),
              Expanded(
                child: _isPrivate
                    ? _privateLockScreen(isDark, textColor)
                    : FadeTransition(
                  opacity: _fadeSlow,
                  child: SlideTransition(
                    position: _slideUp,
                    child: SingleChildScrollView(
                      controller: _scrollCtrl,
                      physics: const BouncingScrollPhysics(),
                      padding:
                      const EdgeInsets.fromLTRB(16, 8, 16, 60),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _heroSection(isDark, textColor),
                          const SizedBox(height: 16),
                          if (_hasBlood || _hasLocation || _hasAddress)
                            ...[
                              _quickBadges(isDark),
                              const SizedBox(height: 16)
                            ],
                          if (_hasMessage)
                            ...[
                              _noteCard(isDark),
                              const SizedBox(height: 14)
                            ],
                          if (_hasBio)
                            ...[
                              _bioCard(isDark),
                              const SizedBox(height: 14)
                            ],
                          if (_hasEducation)
                            _educationCard(isDark),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // PRIVATE LOCK SCREEN
  // ════════════════════════════════════════════════════════════════
  Widget _privateLockScreen(bool isDark, Color textColor) {
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : _D.lightSubText;

    return FadeTransition(
      opacity: _fadeSlow,
      child: SlideTransition(
        position: _slideUp,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
          child: Column(
            children: [
              // ── Blurred avatar preview ─────────────────────────────
              _heroSection(isDark, textColor, blurred: true),
              const SizedBox(height: 32),

              // ── Lock card ──────────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 36),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.07),
                      ),
                    ),
                    child: Column(children: [
                      // Animated lock icon
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, __) => Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [
                              _D.rose.withValues(
                                  alpha: 0.18 + _pulseCtrl.value * 0.12),
                              _D.rose.withValues(alpha: 0.04),
                            ]),
                            border: Border.all(
                              color: _D.rose.withValues(
                                  alpha: 0.3 + _pulseCtrl.value * 0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _D.rose.withValues(
                                    alpha: 0.15 + _pulseCtrl.value * 0.1),
                                blurRadius: 24,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            color: _D.rose,
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        SC.tr('private_profile'),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        SC.tr('private_profile_desc')
                            .replaceAll('{name}', widget.name),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: subColor,
                          fontSize: 13.5,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Divider
                      Container(
                        height: 0.8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Colors.transparent,
                            isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.black.withValues(alpha: 0.10),
                            Colors.transparent,
                          ]),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Info chips row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _lockInfoChip(
                            icon: Icons.person_outline_rounded,
                            label: widget.name,
                            color: widget.themeColor,
                            isDark: isDark,
                          ),
                          const SizedBox(width: 10),
                          _lockInfoChip(
                            icon: Icons.lock_outline_rounded,
                            label: SC.tr('vis_private'),
                            color: _D.rose,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lockInfoChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            )),
      ]),
    );
  }

  // ── Background ────────────────────────────────────────────────────────────
  Widget _bg(bool isDark) => CustomPaint(
    size: Size.infinite,
    painter: _MeshPainter(isDark),
    child: Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const RadialGradient(
          center: Alignment(-0.5, -0.7),
          radius: 1.4,
          colors: [Color(0xFF0E1729), Color(0xFF070B12)],
        )
            : RadialGradient(
          center: const Alignment(-0.5, -0.7),
          radius: 1.4,
          colors: [const Color(0xFFE8EFF8), _D.lightBg],
        ),
      ),
    ),
  );

  Widget _floatingOrbs() {
    return AnimatedBuilder(
      animation: _floatCtrl,
      builder: (_, __) => Stack(children: [
        Positioned(
          top: -80 + _floatAnim.value,
          right: -60,
          child: _orb(280, widget.themeColor.withValues(alpha: 0.10)),
        ),
        Positioned(
          top: 180 - _floatAnim.value * 0.6,
          left: -80,
          child: _orb(220, _D.cyan.withValues(alpha: 0.07)),
        ),
        Positioned(
          bottom: 100 + _floatAnim.value * 0.4,
          right: -40,
          child: _orb(180, _D.emerald.withValues(alpha: 0.06)),
        ),
        Positioned(
          bottom: 300 - _floatAnim.value * 0.3,
          left: -50,
          child: _orb(160, _D.violet.withValues(alpha: 0.07)),
        ),
      ]),
    );
  }

  Widget _orb(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
          colors: [color, Colors.transparent], stops: const [0.0, 1.0]),
    ),
  );

  // ── Top Bar ───────────────────────────────────────────────────────────────
  Widget _topBar(bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: FadeTransition(
        opacity: _fadeFast,
        child: Row(children: [
          _glassBtn(
            onTap: () => Navigator.pop(context),
            isDark: isDark,
            child: Icon(Icons.arrow_back_ios_new_rounded,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : _D.lightText.withValues(alpha: 0.7),
                size: 16),
          ),
          const Spacer(),
          _categoryPill(),
          const Spacer(),
          _glassBtn(
            onTap: () {},
            isDark: isDark,
            child: Icon(Icons.share_rounded,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : _D.lightText.withValues(alpha: 0.4),
                size: 16),
          ),
        ]),
      ),
    );
  }

  Widget _categoryPill() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [
        widget.themeColor.withValues(alpha: 0.18),
        widget.themeColor.withValues(alpha: 0.06),
      ]),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
          color: widget.themeColor.withValues(alpha: 0.3), width: 0.8),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) => Container(
          width: 5, height: 5,
          decoration: BoxDecoration(
            color: widget.themeColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.themeColor
                    .withValues(alpha: 0.3 + _pulseCtrl.value * 0.4),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ),
      const SizedBox(width: 7),
      Text(
        widget.category.toUpperCase(),
        style: TextStyle(
          color: widget.themeColor, fontSize: 9.5,
          fontWeight: FontWeight.w800, letterSpacing: 1.8,
        ),
      ),
    ]),
  );

  Widget _glassBtn({
    required VoidCallback onTap,
    required Widget child,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.09)
                      : Colors.black.withValues(alpha: 0.08)),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  // ── Hero Section ──────────────────────────────────────────────────────────
  /// [blurred] — private mode te avatar blur kore dekhabe
  Widget _heroSection(bool isDark, Color textColor, {bool blurred = false}) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(colors: [
          widget.themeColor.withValues(alpha: isDark ? 0.12 : 0.08),
          _D.cyan.withValues(alpha: isDark ? 0.06 : 0.04),
          Colors.transparent,
        ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        border: Border.all(
          color: widget.themeColor.withValues(alpha: 0.22),
          width: 0.8,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                blurred
                    ? _blurredAvatar()
                    : _avatar(),
                const SizedBox(width: 18),
                Expanded(child: _nameBlock(isDark, textColor, blurred: blurred)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Normal avatar
  Widget _avatar() {
    return AnimatedBuilder(
      animation: _floatCtrl,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _floatAnim.value * 0.3),
        child: child,
      ),
      child: Hero(
        tag: widget.heroTag,
        child: Stack(children: [
          Container(
            width: 120, height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(colors: [
                widget.themeColor.withValues(alpha: 0.4),
                _D.cyan.withValues(alpha: 0.2),
              ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              boxShadow: [
                BoxShadow(
                  color: widget.themeColor.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: 120, height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: widget.themeColor.withValues(alpha: 0.4),
                    width: 1.5),
              ),
              child: (widget.imageUrl?.isNotEmpty == true)
                  ? Image.network(widget.imageUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _avatarFallback())
                  : _avatarFallback(),
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                ),
                gradient: LinearGradient(colors: [
                  Colors.transparent,
                  widget.themeColor.withValues(alpha: 0.35),
                ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  /// Blurred avatar for private profiles
  Widget _blurredAvatar() {
    return Hero(
      tag: widget.heroTag,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          width: 120, height: 160,
          child: Stack(fit: StackFit.expand, children: [
            // Underlying image (or fallback)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  widget.themeColor.withValues(alpha: 0.4),
                  _D.cyan.withValues(alpha: 0.2),
                ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
              ),
              child: (widget.imageUrl?.isNotEmpty == true)
                  ? Image.network(widget.imageUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _avatarFallback())
                  : _avatarFallback(),
            ),
            // Heavy blur overlay
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                decoration: BoxDecoration(
                  color: _D.rose.withValues(alpha: 0.18),
                  border: Border.all(
                      color: _D.rose.withValues(alpha: 0.35), width: 1.5),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Center(
                  child: Icon(Icons.lock_rounded, color: _D.rose, size: 32),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _avatarFallback() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [
        widget.themeColor.withValues(alpha: 0.15),
        _D.cyan.withValues(alpha: 0.08),
      ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight),
    ),
    child: Icon(Icons.person_rounded,
        size: 54,
        color: widget.themeColor.withValues(alpha: 0.45)),
  );

  Widget _nameBlock(bool isDark, Color textColor, {bool blurred = false}) {
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : _D.lightSubText;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Shimmer bar
      AnimatedBuilder(
        animation: _shimmerCtrl,
        builder: (_, __) => Container(
          height: 3,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              colors: [
                widget.themeColor,
                _D.cyan,
                _D.violet,
                widget.themeColor
              ],
              stops: [
                0.0,
                (_shimmerCtrl.value * 0.6).clamp(0.0, 0.4),
                (_shimmerCtrl.value * 0.6 + 0.3).clamp(0.2, 0.8),
                1.0,
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Text(widget.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textColor, fontSize: 22,
            fontWeight: FontWeight.w900, height: 1.15, letterSpacing: -0.5,
          )),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            widget.themeColor.withValues(alpha: 0.22),
            _D.cyan.withValues(alpha: 0.10),
          ]),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
              color: widget.themeColor.withValues(alpha: 0.35), width: 0.8),
        ),
        child: Text(widget.role,
            style: TextStyle(
              color: widget.themeColor, fontSize: 10,
              fontWeight: FontWeight.w800, letterSpacing: 0.5,
            )),
      ),
      const SizedBox(height: 14),
      Container(
        height: 0.8,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
            Colors.transparent,
          ]),
        ),
      ),
      const SizedBox(height: 12),

      // Private badge — replaces info chips when blurred
      if (blurred) ...[
        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _D.rose.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: _D.rose.withValues(alpha: 0.3), width: 0.8),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.lock_rounded, color: _D.rose, size: 12),
            const SizedBox(width: 6),
            Text(SC.tr('vis_private'),
                style: const TextStyle(
                  color: _D.rose,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                )),
          ]),
        ),
      ] else ...[
        if (_hasBlood) ...[
          _infoChip(
            icon: Icons.water_drop_rounded,
            label: widget.bloodGroup!,
            color: _D.rose,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
        ],
        if (_hasLocation) ...[
          _infoChip(
            icon: Icons.location_on_rounded,
            label: widget.locationDms!,
            color: _D.emerald,
            isDark: isDark,
            small: true,
          ),
          const SizedBox(height: 8),
        ],
        if (_hasAddress)
          _infoChip(
            icon: Icons.home_rounded,
            label: widget.presentAddress!,
            color: _D.sky,
            isDark: isDark,
            small: true,
          ),
      ],
    ]);
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    bool small = false,
  }) {
    final labelColor = small
        ? (isDark
        ? Colors.white.withValues(alpha: 0.55)
        : _D.lightSubText)
        : color;

    return Row(children: [
      Container(
        width: 26, height: 26,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 0.6),
        ),
        child: Icon(icon, color: color, size: 13),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Text(label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: labelColor,
              fontSize: small ? 11 : 13,
              fontWeight: small ? FontWeight.w500 : FontWeight.w700,
              letterSpacing: small ? 0.1 : 0.3,
            )),
      ),
    ]);
  }

  // ── Quick Badges ──────────────────────────────────────────────────────────
  Widget _quickBadges(bool isDark) {
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : _D.lightSubText.withValues(alpha: 0.5);

    final items = <Map<String, dynamic>>[];
    if (_hasBlood)
      items.add({
        'icon': Icons.water_drop_rounded,
        'label': widget.bloodGroup!,
        'color': _D.rose,
        'sub': SC.tr('personBlood'),
      });
    if (_hasLocation)
      items.add({
        'icon': Icons.my_location_rounded,
        'label': SC.tr('personLocation'),
        'color': _D.teal,
        'sub': SC.tr('personGPS'),
      });
    if (_hasAddress)
      items.add({
        'icon': Icons.home_rounded,
        'label': SC.tr('personAddress'),
        'color': _D.sky,
        'sub': SC.tr('personHome'),
      });
    if (items.isEmpty) return const SizedBox.shrink();

    return Row(
      children: items.map((item) {
        final color = item['color'] as Color;
        return Expanded(
          child: Container(
            margin:
            EdgeInsets.only(right: item == items.last ? 0 : 10),
            padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                color.withValues(alpha: 0.14),
                color.withValues(alpha: 0.05),
              ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: color.withValues(alpha: 0.25), width: 0.7),
            ),
            child: Column(children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item['icon'] as IconData,
                    color: color, size: 16),
              ),
              const SizedBox(height: 7),
              Text(item['label'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color, fontSize: 12,
                    fontWeight: FontWeight.w800, letterSpacing: 0.2,
                  )),
              Text(item['sub'] as String,
                  style: TextStyle(
                    color: subColor, fontSize: 9.5,
                    fontWeight: FontWeight.w500, letterSpacing: 0.5,
                  )),
            ]),
          ),
        );
      }).toList(),
    );
  }

  // ── Note Card ─────────────────────────────────────────────────────────────
  Widget _noteCard(bool isDark) {
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : _D.lightSubText.withValues(alpha: 0.5);

    return _sectionShell(
      topColor: _D.amber,
      bottomColor: _D.orange,
      icon: Icons.format_quote_rounded,
      label: SC.tr('personMessage'),
      isDark: isDark,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 3,
            margin: const EdgeInsets.only(top: 2),
            height: 20 + (widget.message!.length / 40) * 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: const LinearGradient(
                colors: [_D.amber, _D.orange, Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(widget.message!,
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.85)
                      : _D.lightText.withValues(alpha: 0.85),
                  fontSize: 15, height: 1.80,
                  fontStyle: FontStyle.italic, letterSpacing: 0.1,
                )),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: _D.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.person_rounded, size: 14, color: _D.amber),
          ),
          const SizedBox(width: 8),
          Text(widget.name,
              style: const TextStyle(
                color: _D.amber, fontSize: 11.5, fontWeight: FontWeight.w700,
              )),
          const SizedBox(width: 6),
          Text('· ${widget.role}',
              style: TextStyle(color: subColor, fontSize: 11)),
        ]),
      ]),
    );
  }

  // ── Bio Card ──────────────────────────────────────────────────────────────
  Widget _bioCard(bool isDark) {
    return _sectionShell(
      topColor: _D.violet,
      bottomColor: _D.indigo,
      icon: Icons.person_outline_rounded,
      label: SC.tr('personBio'),
      isDark: isDark,
      child: Text(widget.bio!,
          style: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.72)
                : _D.lightSubText,
            fontSize: 14.5, height: 1.90, letterSpacing: 0.15,
          )),
    );
  }

  // ── Education Card ────────────────────────────────────────────────────────
  Widget _educationCard(bool isDark) {
    return _sectionShell(
      topColor: _D.emerald,
      bottomColor: _D.teal,
      icon: Icons.school_rounded,
      label: SC.tr('personEducation'),
      isDark: isDark,
      child: Column(children: [
        if (_hasSchool) ...[
          _educStep(
            index: 0,
            stepLabel: 'SSC',
            stepColor: _D.emerald,
            accentColor: const Color(0xFF34D399),
            title: widget.schoolName ?? SC.tr('personSchool'),
            subtitle: _join([
              if (widget.schoolGroup?.isNotEmpty == true) widget.schoolGroup!,
              if (widget.schoolPassingYear != null)
                '${SC.tr('personPassingYear')}${widget.schoolPassingYear}',
            ]),
            isDark: isDark,
          ),
          if (_hasCollege || _hasUniversity)
            _educConnector(_D.emerald, _D.cyan),
        ],
        if (_hasCollege) ...[
          _educStep(
            index: 1,
            stepLabel: 'HSC',
            stepColor: _D.cyan,
            accentColor: _D.sky,
            title: widget.collegeName ?? SC.tr('personCollege'),
            subtitle: _join([
              if (widget.collegeGroup?.isNotEmpty == true) widget.collegeGroup!,
              if (widget.collegePassingYear != null)
                '${SC.tr('personPassingYear')}${widget.collegePassingYear}',
            ]),
            isDark: isDark,
          ),
          if (_hasUniversity) _educConnector(_D.cyan, _D.violet),
        ],
        if (_hasUniversity)
          _educStep(
            index: 2,
            stepLabel: 'BSC',
            stepColor: _D.violet,
            accentColor: const Color(0xFFA78BFA),
            title: widget.universityName ?? SC.tr('personUniversity'),
            subtitle: _join([
              if (widget.department?.isNotEmpty == true) widget.department!,
              if (widget.currentYear != null)
                '${widget.currentYear}${SC.tr('personYear')}',
              if (widget.currentSemester != null)
                '${widget.currentSemester}${SC.tr('personSemester')}',
            ]),
            isDark: isDark,
          ),
      ]),
    );
  }

  Widget _educStep({
    required int    index,
    required String stepLabel,
    required Color  stepColor,
    required Color  accentColor,
    required String title,
    required bool   isDark,
    String?         subtitle,
  }) {
    final titleColor = isDark ? _D.white : _D.lightText;

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [stepColor, accentColor],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(color: stepColor.withValues(alpha: 0.35),
                blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Center(
          child: Text(stepLabel,
              style: const TextStyle(
                color: Colors.white, fontSize: 10,
                fontWeight: FontWeight.w900, letterSpacing: 0.5,
              )),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          decoration: BoxDecoration(
            color: stepColor.withValues(alpha: isDark ? 0.07 : 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: stepColor.withValues(alpha: 0.18), width: 0.7),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      color: titleColor, fontSize: 14.5,
                      fontWeight: FontWeight.w800, letterSpacing: -0.1,
                    )),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(subtitle,
                      style: TextStyle(
                        color: accentColor.withValues(alpha: 0.7),
                        fontSize: 12, height: 1.5, letterSpacing: 0.2,
                      )),
                ],
              ]),
        ),
      ),
    ]);
  }

  Widget _educConnector(Color top, Color bottom) => Padding(
    padding: const EdgeInsets.only(left: 20, top: 6, bottom: 6),
    child: Container(
      width: 2, height: 22,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            top.withValues(alpha: 0.5),
            bottom.withValues(alpha: 0.3)
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(1),
      ),
    ),
  );

  // ── Section Shell ─────────────────────────────────────────────────────────
  Widget _sectionShell({
    required Color    topColor,
    required Color    bottomColor,
    required IconData icon,
    required String   label,
    required Widget   child,
    required bool     isDark,
  }) {
    final shellBg = isDark
        ? Colors.white.withValues(alpha: 0.032)
        : Colors.white.withValues(alpha: 0.85);
    final shellBorder = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.07);
    final labelColor = isDark
        ? Colors.white.withValues(alpha: 0.88)
        : _D.lightText.withValues(alpha: 0.88);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: shellBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: shellBorder),
          ),
          child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  topColor.withValues(alpha: 0.20),
                  bottomColor.withValues(alpha: 0.08),
                ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                border: Border(
                    bottom: BorderSide(
                        color: topColor.withValues(alpha: 0.15),
                        width: 0.8)),
              ),
              child: Row(children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [topColor, bottomColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                          color: topColor.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Text(label,
                    style: TextStyle(
                      color: labelColor, fontSize: 13.5,
                      fontWeight: FontWeight.w800, letterSpacing: 0.3,
                    )),
                const Spacer(),
                Row(
                    children: [
                      topColor,
                      bottomColor,
                      topColor.withValues(alpha: 0.4)
                    ]
                        .map((c) => Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                          color: c, shape: BoxShape.circle),
                    ))
                        .toList()),
              ]),
            ),
            Padding(padding: const EdgeInsets.all(20), child: child),
          ]),
        ),
      ),
    );
  }
}

// ── Painters ──────────────────────────────────────────────────────────────────
class _MeshPainter extends CustomPainter {
  final bool isDark;
  const _MeshPainter(this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.4
      ..color = isDark
          ? const Color(0xFF1E3050).withValues(alpha: 0.25)
          : const Color(0xFF7090C0).withValues(alpha: 0.10);

    for (double x = -size.height; x < size.width + size.height; x += 48) {
      canvas.drawLine(
          Offset(x, 0), Offset(x + size.height, size.height), linePaint);
    }

    final dotPaint = Paint()
      ..color = isDark
          ? const Color(0xFF1C3055).withValues(alpha: 0.45)
          : const Color(0xFF6080A0).withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;

    for (double x = 32; x < size.width; x += 32) {
      for (double y = 32; y < size.height; y += 32) {
        canvas.drawCircle(Offset(x, y), 0.9, dotPaint);
      }
    }

    final hexPaint = Paint()
      ..color = isDark
          ? const Color(0xFF8B5CF6).withValues(alpha: 0.06)
          : const Color(0xFF8B5CF6).withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    _drawHex(canvas, Offset(size.width * 0.85, size.height * 0.12),
        55, hexPaint);
    _drawHex(
        canvas,
        Offset(size.width * 0.78, size.height * 0.10),
        35,
        hexPaint
          ..color = const Color(0xFF06B6D4).withValues(alpha: 0.04));
  }

  void _drawHex(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - math.pi / 6;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_MeshPainter old) => old.isDark != isDark;
}
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/profile_model.dart';
import '../../models/member_type.dart';
import '../../services/profile_service.dart';
import '../SettingsPage/settings_page.dart';
import '../SettingsPage/settings_constants.dart';
import 'edit_profile_page.dart';
import 'package:css/services/session_service.dart';
import 'package:css/services/activity_logger.dart';


class ProfilePage extends StatefulWidget {
  final String? id;
  const ProfilePage({super.key, this.id});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  final ProfileService _service = ProfileService();
  late Future<ProfileModel?> _profileFuture;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _shimmerController;
  final TextEditingController _passwordController = TextEditingController();
  bool _passwordVisible = false;

  // ── Design tokens ────────────────────────────────────────────────────────────
  static const _bgStart  = Color(0xFF060E17);
  static const _bgMid    = Color(0xFF0D1F33);
  static const _bgEnd    = Color(0xFF0A1E2A);
  static const _cardBg   = Color(0xFF0F1E2E);
  static const _cyan     = Color(0xFF00E5FF);
  static const _blue     = Color(0xFF4A90E2);
  static const _orange   = Color(0xFFFF8A65);
  static const _red      = Color(0xFFEF5350);
  static const _green    = Color(0xFF4CAF50);
  static const _teal     = Color(0xFF26A69A);
  static const _purple   = Color(0xFF9C27B0);
  static const _amber    = Color(0xFFFFB300);
  static const _indigo   = Color(0xFF5C6BC0);
  static const _surface  = Color(0xFF162030);

  // ── Light mode colors ────────────────────────────────────────────────────────
  static const _lightBg      = Color(0xFFF0F4FF);
  static const _lightCard    = Color(0xFFFFFFFF);
  static const _lightSurface = Color(0xFFF5F8FF);

  // ── Theme-aware getters ───────────────────────────────────────────────────────
  bool get _isDark => SC.isDark;

  Color get _bgColor       => _isDark ? _bgStart     : _lightBg;
  Color get _cardColor     => _isDark ? _cardBg      : _lightCard;
  Color get _surfaceColor  => _isDark ? _surface     : _lightSurface;
  Color get _textColor     => _isDark ? Colors.white : const Color(0xFF1A2332);
  Color get _subTextColor  => _isDark ? Colors.white : const Color(0xFF4A5568);
  Color get _borderColor   => _isDark
      ? Colors.white.withValues(alpha: 0.07)
      : Colors.black.withValues(alpha: 0.08);

  String _t(String key) => SC.tr(key);

  Color _accentFor(ProfileModel p) {
    if (p.isAdvisor)        return _amber;
    if (p.isPreviousMember) return _purple;
    return _cyan;
  }

  @override
  void initState() {
    super.initState();
    _reload();
    _rotationController = AnimationController(
        vsync: this, duration: const Duration(seconds: 25))..repeat();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900), value: 0)
      ..forward();
    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
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

  String _fmtDate(DateTime? d) => d == null
      ? ''
      : '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  // ══════════════════════════════════════════════════════════════════════════════
  // DELETE FLOW
  // ══════════════════════════════════════════════════════════════════════════════

  Future<void> _deleteAccount() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) { _toast(_t('pleaseEnterPassword'), _orange); return; }
    if (!mounted) return;

    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => _LoadingOverlay(message: _t('deletingAccount'), isDark: _isDark),
    );

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) { if (mounted) Navigator.of(context).pop(); return; }

      await supabase.auth.signInWithPassword(email: user.email!, password: password);
      await supabase.from('profiles').delete().eq('id', user.id);
      try { await supabase.storage.from('profile-images').remove(['profiles/${user.id}.jpg']); } catch (_) {}

      await ActivityLogger.log(activityType: 'logout');
      await SessionService.deleteCurrentSession();
      await supabase.auth.signOut();

      if (!mounted) return;
      Navigator.of(context).pop();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/welcome', (_) => false);
      _toast(_t('accountDeleted'), _green);
    } on AuthException catch (e) {
      if (mounted) { Navigator.of(context).pop(); _toast(e.message, _red); }
    } catch (_) {
      if (mounted) { Navigator.of(context).pop(); _toast(_t('somethingWentWrong'), _red); }
    }
  }

  void _toast(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
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
          child: _GlassCard(
            borderColor: _red.withValues(alpha: 0.4),
            isDark: _isDark,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _pulsingIcon(Icons.warning_amber_rounded, _red),
                const SizedBox(height: 20),
                Text(_t('deleteAccount'),
                    style: TextStyle(color: _textColor,
                        fontWeight: FontWeight.w700, fontSize: 22)),
                const SizedBox(height: 12),
                Text(_t('deleteAccountDesc'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _subTextColor.withValues(alpha: 0.7),
                        fontSize: 14, height: 1.6)),
                const SizedBox(height: 24),
                _PasswordField(
                  controller: _passwordController,
                  visible: _passwordVisible,
                  isDark: _isDark,
                  onToggle: () => setDlg(() => _passwordVisible = !_passwordVisible),
                ),
                const SizedBox(height: 28),
                Row(children: [
                  Expanded(child: _OutlineBtn(
                      label: _t('cancel'),
                      isDark: _isDark,
                      onTap: () => Navigator.pop(ctx))),
                  const SizedBox(width: 12),
                  Expanded(child: _SolidBtn(
                    label: _t('continue'), color: _red,
                    onTap: () { Navigator.pop(ctx); _confirmDelete(); },
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
        child: _GlassCard(
          borderColor: _red.withValues(alpha: 0.5),
          isDark: _isDark,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline_rounded, color: _red, size: 60),
              const SizedBox(height: 18),
              Text(_t('finalConfirmation'),
                  style: TextStyle(color: _textColor, fontSize: 20,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Text(_t('finalConfirmationDesc'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _subTextColor.withValues(alpha: 0.7),
                      fontSize: 14, height: 1.6)),
              const SizedBox(height: 28),
              Row(children: [
                Expanded(child: _OutlineBtn(
                    label: _t('goBack'),
                    isDark: _isDark,
                    onTap: () => Navigator.pop(ctx))),
                const SizedBox(width: 12),
                Expanded(child: _SolidBtn(
                  label: _t('yesDelete'), color: _red,
                  onTap: () { Navigator.pop(ctx); _deleteAccount(); },
                )),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════════

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
        appBar: (widget.id != null || widget.id == null)
            ? AppBar(
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
                    color: (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.2)),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, size: 16,
                        color: _textColor),
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
                      color: (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.2)),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.settings_rounded, size: 20,
                          color: _textColor),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      ),
                      tooltip: _t('settings'),
                    ),
                  ),
                ),
              ),
            ),
          ]
              : null,
        )
            : null,
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
                backgroundColor: _cardColor, color: _cyan, strokeWidth: 2.5,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildHeader(p),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          FadeTransition(
                            opacity: _fadeController,
                            child: Column(children: _buildBody(p)),
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

  List<Widget> _buildBody(ProfileModel p) {
    if (p.isAdvisor)        return _buildAdvisorBody(p);
    if (p.isPreviousMember) return _buildPreviousBody(p);
    return _buildPresentBody(p);
  }

  // ── Present committee body ────────────────────────────────────────────────────

  List<Widget> _buildPresentBody(ProfileModel p) => [
    _buildQuickStats(p),
    const SizedBox(height: 28),
    _buildSection(_t('basicInformation'), Icons.person_rounded, _blue, [
      _row(Icons.badge_outlined,             _t('fullNameEN'),          p.fullName),
      _row(Icons.translate_rounded,          _t('fullNameBN'),          p.fullNameBn),
      _row(Icons.wc_rounded,                 _t('gender'),              p.gender),
      _row(Icons.cake_outlined,              _t('dateOfBirth'),         _fmtDate(p.dateOfBirth)),
      _row(Icons.verified_user_outlined,     _t('memberType'),          MemberType.label(p.memberType)),
      _row(Icons.workspace_premium_outlined, _t('committeePosition'),   p.committeePosition),
      _row(Icons.calendar_month_outlined,    _t('memberSince'),         _fmtDate(p.memberSince)),
    ]),
    if (_hasContent(p.presentCommitteeNote))
      _noteCard(p.presentCommitteeNote!, _teal, Icons.sticky_note_2_rounded, _t('committeeNote')),
    _buildSection(_t('contactDetails'), Icons.contacts_rounded, _orange, [
      _row(Icons.chat_bubble_outline_rounded, _t('whatsapp'),           p.whatsappNumber),
      _row(Icons.phone_iphone_rounded,        _t('alternativeMobile'),  p.alternativeMobile),
      _row(Icons.email_outlined,              _t('email'),              p.email),
      _row(Icons.link_rounded,               _t('facebookLink'),       p.facebookLink),
      _row(Icons.home_outlined,              _t('presentAddress'),     p.presentAddress),
      _row(Icons.location_city_outlined,     _t('permanentAddress'),   p.permanentAddress),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _row(Icons.map_outlined,     _t('district'), p.district)),
        const SizedBox(width: 10),
        Expanded(child: _row(Icons.explore_outlined, _t('upazila'),  p.upazila)),
      ]),
    ]),
    _buildSection(_t('bloodDonation'), Icons.favorite_rounded, _red, [
      _row(Icons.water_drop_rounded,         _t('bloodGroup'),         p.bloodGroup),
      _row(Icons.history_rounded,            _t('lastDonation'),       _fmtDate(p.lastDonationDate)),
      _row(Icons.event_available_rounded,    _t('nextAvailable'),      _fmtDate(p.nextAvailableDonationDate)),
      _row(Icons.health_and_safety_outlined, _t('eligibility'),        p.donationEligibility),
      _row(Icons.pin_drop_outlined,          _t('preferredLocation'),  p.preferredDonationLocation),
    ]),
    _buildSection(_t('academicRecords'), Icons.school_rounded, _green, [
      _subHeader(_t('secondary')),
      _row(Icons.school_outlined,          _t('school'),              p.schoolName),
      _row(Icons.history_edu_rounded,      _t('sscGroupYear'),
          '${p.schoolGroup ?? 'N/A'} · ${p.schoolPassingYear ?? ''}'),
      _row(Icons.account_balance_outlined, _t('college'),             p.collegeName),
      _row(Icons.history_edu_rounded,      _t('hscGroupYear'),
          '${p.collegeGroup ?? 'N/A'} · ${p.collegePassingYear ?? ''}'),
      _subHeader(_t('higherEducation')),
      _row(Icons.account_balance_rounded,  _t('university'),          p.universityName),
      _row(Icons.category_outlined,        _t('department'),          p.department),
      _row(Icons.fingerprint_rounded,      _t('studentId'),           p.studentId),
      _rowPair(
        _row(Icons.layers_outlined,   _t('year'),     p.currentYear?.toString()),
        _row(Icons.repeat_rounded,    _t('semester'), p.currentSemester?.toString()),
      ),
    ]),
    _buildSection(_t('bioSocial'), Icons.public_rounded, _purple, [
      _row(Icons.notes_rounded,          _t('shortBio'),          p.shortBio),
      _row(Icons.flag_outlined,          _t('whyJoined'),         p.whyJoined),
      _row(Icons.ads_click_rounded,      _t('futureGoals'),       p.futureGoals),
      _row(Icons.interests_outlined,     _t('hobbies'),           p.hobbies),
      _row(Icons.alternate_email_rounded,_t('facebook'),          p.facebook),
      _row(Icons.language_rounded,       _t('portfolio'),         p.portfolioWebsite),
    ]),
    _buildSection(_t('location'), Icons.location_on_rounded, _teal, [
      _row(Icons.gps_fixed_rounded,    _t('coordinates'),   '${p.latitude ?? 'N/A'}, ${p.longitude ?? 'N/A'}'),
      _row(Icons.my_location_rounded,  _t('locationName'),  p.locationDms),
    ]),
    if (widget.id == null) ...[const SizedBox(height: 8), _buildDangerZone()],
  ];

  // ── Previous committee body ───────────────────────────────────────────────────

  List<Widget> _buildPreviousBody(ProfileModel p) => [
    _buildQuickStats(p),
    const SizedBox(height: 28),
    _tenureCard(p),
    const SizedBox(height: 20),
    _buildSection(_t('basicInformation'), Icons.person_rounded, _blue, [
      _row(Icons.badge_outlined,          _t('fullNameEN'),   p.fullName),
      _row(Icons.translate_rounded,       _t('fullNameBN'),   p.fullNameBn),
      _row(Icons.wc_rounded,              _t('gender'),       p.gender),
      _row(Icons.cake_outlined,           _t('dateOfBirth'),  _fmtDate(p.dateOfBirth)),
      _row(Icons.verified_user_outlined,  _t('memberType'),   MemberType.label(p.memberType)),
      _row(Icons.calendar_month_outlined, _t('memberSince'),  _fmtDate(p.memberSince)),
    ]),
    if (_hasContent(p.previousCommitteeNote))
      _noteCard(p.previousCommitteeNote!, _purple, Icons.sticky_note_2_rounded, _t('previousMemberNote')),
    _buildSection(_t('contactDetails'), Icons.contacts_rounded, _orange, [
      _row(Icons.chat_bubble_outline_rounded, _t('whatsapp'),           p.whatsappNumber),
      _row(Icons.phone_iphone_rounded,        _t('alternativeMobile'),  p.alternativeMobile),
      _row(Icons.email_outlined,              _t('email'),              p.email),
      _row(Icons.link_rounded,               _t('facebookLink'),       p.facebookLink),
      _row(Icons.home_outlined,              _t('presentAddress'),     p.presentAddress),
      _row(Icons.location_city_outlined,     _t('permanentAddress'),   p.permanentAddress),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _row(Icons.map_outlined,     _t('district'), p.district)),
        const SizedBox(width: 10),
        Expanded(child: _row(Icons.explore_outlined, _t('upazila'),  p.upazila)),
      ]),
    ]),
    _buildSection(_t('bloodDonation'), Icons.favorite_rounded, _red, [
      _row(Icons.water_drop_rounded,         _t('bloodGroup'),         p.bloodGroup),
      _row(Icons.history_rounded,            _t('lastDonation'),       _fmtDate(p.lastDonationDate)),
      _row(Icons.event_available_rounded,    _t('nextAvailable'),      _fmtDate(p.nextAvailableDonationDate)),
      _row(Icons.health_and_safety_outlined, _t('eligibility'),        p.donationEligibility),
      _row(Icons.pin_drop_outlined,          _t('preferredLocation'),  p.preferredDonationLocation),
    ]),
    _buildSection(_t('academicRecords'), Icons.school_rounded, _green, [
      _subHeader(_t('secondary')),
      _row(Icons.school_outlined,          _t('school'),   p.schoolName),
      _row(Icons.history_edu_rounded,      _t('ssc'),
          '${p.schoolGroup ?? 'N/A'} · ${p.schoolPassingYear ?? ''}'),
      _row(Icons.account_balance_outlined, _t('college'),  p.collegeName),
      _row(Icons.history_edu_rounded,      _t('hsc'),
          '${p.collegeGroup ?? 'N/A'} · ${p.collegePassingYear ?? ''}'),
      _subHeader(_t('higherEducation')),
      _row(Icons.account_balance_rounded, _t('university'), p.universityName),
      _row(Icons.category_outlined,       _t('department'), p.department),
    ]),
    _buildSection(_t('bioSocial'), Icons.public_rounded, _purple, [
      _row(Icons.notes_rounded,           _t('shortBio'),   p.shortBio),
      _row(Icons.flag_outlined,           _t('whyJoined'),  p.whyJoined),
      _row(Icons.interests_outlined,      _t('hobbies'),    p.hobbies),
      _row(Icons.alternate_email_rounded, _t('facebook'),   p.facebook),
    ]),
    if (widget.id == null) ...[const SizedBox(height: 8), _buildDangerZone()],
  ];

  // ── Advisor body ──────────────────────────────────────────────────────────────

  List<Widget> _buildAdvisorBody(ProfileModel p) => [
    _buildAdvisorStats(p),
    const SizedBox(height: 28),
    _buildSection(_t('basicInformation'), Icons.person_rounded, _blue, [
      _row(Icons.badge_outlined,         _t('fullNameEN'),   p.fullName),
      _row(Icons.translate_rounded,      _t('fullNameBN'),   p.fullNameBn),
      _row(Icons.wc_rounded,             _t('gender'),       p.gender),
      _row(Icons.cake_outlined,          _t('dateOfBirth'),  _fmtDate(p.dateOfBirth)),
      _row(Icons.verified_user_outlined, _t('role'),         MemberType.label(p.memberType)),
      _row(Icons.calendar_month_outlined,_t('since'),        _fmtDate(p.memberSince)),
    ]),
    _buildSection(_t('professionalInformation'), Icons.work_rounded, _amber, [
      _row(Icons.work_outline_rounded,      _t('occupation'),   p.occupation),
      _row(Icons.account_balance_outlined,  _t('institution'),  p.institution),
      _row(Icons.military_tech_outlined,    _t('designation'),  p.designation),
      _row(Icons.stars_outlined,            _t('expertise'),    p.expertise),
    ]),
    if (_hasContent(p.advisorNote))
      _noteCard(p.advisorNote!, _amber, Icons.lightbulb_outline_rounded, _t('advisorNote')),
    _buildSection(_t('contactDetails'), Icons.contacts_rounded, _orange, [
      _row(Icons.chat_bubble_outline_rounded, _t('whatsapp'),           p.whatsappNumber),
      _row(Icons.phone_iphone_rounded,        _t('alternativeMobile'),  p.alternativeMobile),
      _row(Icons.email_outlined,              _t('email'),              p.email),
      _row(Icons.link_rounded,               _t('facebook'),           p.facebookLink),
      _row(Icons.language_rounded,           _t('portfolio'),          p.portfolioWebsite),
    ]),
    _buildSection(_t('bloodDonation'), Icons.favorite_rounded, _red, [
      _row(Icons.water_drop_rounded,         _t('bloodGroup'),     p.bloodGroup),
      _row(Icons.history_rounded,            _t('lastDonation'),   _fmtDate(p.lastDonationDate)),
      _row(Icons.event_available_rounded,    _t('nextAvailable'),  _fmtDate(p.nextAvailableDonationDate)),
      _row(Icons.health_and_safety_outlined, _t('eligibility'),    p.donationEligibility),
    ]),
    if (widget.id == null) ...[const SizedBox(height: 8), _buildDangerZone()],
  ];

  // ══════════════════════════════════════════════════════════════════════════════
  // HEADER — Rectangle avatar (Instagram/LinkedIn card style)
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(ProfileModel p) {
    final accent = _accentFor(p);

    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.fromLTRB(
            20, MediaQuery.of(context).padding.top + 24, 20, 32),
        child: Column(children: [

          // ── Rectangle avatar with animated glow border ─────────────────
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) {
              final t = _pulseController.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow pulse ring (rounded rect)
                  Container(
                    width: 138 + t * 8,
                    height: 160 + t * 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28 + t * 4),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.18 - t * 0.14),
                        width: 1.5,
                      ),
                    ),
                  ),

                  // Gradient border wrapper
                  Container(
                    width: 128,
                    height: 150,
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        colors: [
                          accent.withValues(alpha: 0.9),
                          _blue.withValues(alpha: 0.5),
                          accent.withValues(alpha: 0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.28 + t * 0.10),
                          blurRadius: 24 + t * 12,
                          spreadRadius: 2,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: p.profileImageUrl != null
                          ? Image.network(
                        p.profileImageUrl!,
                        width: 123,
                        height: 145,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _avatarPlaceholder(accent),
                      )
                          : _avatarPlaceholder(accent),
                    ),
                  ),

                  // Corner accent dots (decorative)
                  ..._cornerDots(accent),
                ],
              );
            },
          ),

          const SizedBox(height: 22),

          // ── Name ──────────────────────────────────────────────────────
          Text(
            (p.fullName ?? _t('memberName')).toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textColor, fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              height: 1.2,
            ),
          ),
          if ((p.fullNameBn ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              p.fullNameBn!,
              style: TextStyle(
                  color: _subTextColor.withValues(alpha: 0.6), fontSize: 14),
            ),
          ],

          const SizedBox(height: 14),

          // ── Badge ─────────────────────────────────────────────────────
          if (p.isAdvisor)
            _AdvisorBadge(
              designation: p.designation,
              institution: p.institution,
              accent: _amber,
            )
          else if (p.isPreviousMember)
            _TenureBadge(
              position: p.previousPosition,
              tenureLabel: p.tenureLabel,
              accent: _purple,
            )
          else
            _PositionBadge(
              label: p.committeePosition ?? _t('volunteer'),
              accent: accent,
            ),

          const SizedBox(height: 10),

          // ── Member type pill ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withValues(alpha: 0.28)),
            ),
            child: Text(
              MemberType.label(p.memberType),
              style: TextStyle(
                  color: accent, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Avatar placeholder (no image) ────────────────────────────────────────────
  Widget _avatarPlaceholder(Color accent) {
    return Container(
      width: 123,
      height: 145,
      color: _cardColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_rounded,
            size: 62,
            color: accent.withValues(alpha: 0.25),
          ),
        ],
      ),
    );
  }

  // ── Decorative corner dots around the avatar ──────────────────────────────────
  List<Widget> _cornerDots(Color accent) {
    const double dotSize = 7;
    final color = accent.withValues(alpha: 0.55);
    return [
      // top-left
      Positioned(
        top: 0, left: 0,
        child: _dot(dotSize, color),
      ),
      // top-right
      Positioned(
        top: 0, right: 0,
        child: _dot(dotSize, color),
      ),
      // bottom-left
      Positioned(
        bottom: 0, left: 0,
        child: _dot(dotSize, color),
      ),
      // bottom-right
      Positioned(
        bottom: 0, right: 0,
        child: _dot(dotSize, color),
      ),
    ];
  }

  Widget _dot(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════════
  // QUICK STATS
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildQuickStats(ProfileModel p) => Row(children: [
    _statCard(_t('bloodGroup'),
        p.bloodGroup ?? '—', _red, Icons.water_drop_rounded),
    const SizedBox(width: 10),
    _statCard(_t('donations'),
        p.totalDonationCount?.toString() ?? '0', _orange, Icons.favorite_rounded),
    const SizedBox(width: 10),
    _statCard(_t('status'),
        _shortStatus(p.donationEligibility), _green, Icons.verified_rounded),
  ]);

  Widget _buildAdvisorStats(ProfileModel p) => Row(children: [
    _statCard(_t('bloodGroup'),
        p.bloodGroup ?? '—', _red, Icons.water_drop_rounded),
    const SizedBox(width: 10),
    _statCard(_t('donations'),
        p.totalDonationCount?.toString() ?? '0', _orange, Icons.favorite_rounded),
    const SizedBox(width: 10),
    _statCard(_t('expertise'),
        _shortWord(p.expertise), _amber, Icons.stars_rounded),
  ]);

  String _shortStatus(String? s) {
    if (s == null || s.isEmpty) return _t('check');
    if (s.toLowerCase().contains('eligible')) return _t('eligible');
    return s.length > 7 ? s.substring(0, 7) : s;
  }

  String _shortWord(String? s) {
    if (s == null || s.isEmpty) return '—';
    final first = s.split(RegExp(r'[,،]')).first.trim();
    return first.length > 8 ? '${first.substring(0, 8)}…' : first;
  }

  Widget _statCard(String label, String value, Color accent, IconData icon) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 6),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: accent.withValues(alpha: 0.25), width: 1.5),
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(height: 10),
            Text(value,
              style: TextStyle(color: accent, fontSize: 18,
                  fontWeight: FontWeight.w800, letterSpacing: 0.3),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(label,
              style: TextStyle(color: _subTextColor.withValues(alpha: 0.5),
                  fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ]),
        ),
      );

  // ══════════════════════════════════════════════════════════════════════════════
  // SPECIAL CARDS
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _tenureCard(ProfileModel p) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _purple.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _purple.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _purple.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.history_edu_rounded, color: _purple, size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_t('previousPosition'),
              style: TextStyle(
                  color: _subTextColor.withValues(alpha: 0.5),
                  fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
          const SizedBox(height: 4),
          Text(p.previousPosition ?? _t('notProvided'),
              style: TextStyle(
                color: (p.previousPosition != null)
                    ? _textColor.withValues(alpha: 0.92)
                    : _textColor.withValues(alpha: 0.25),
                fontSize: 15, fontWeight: FontWeight.w700,
              )),
          if (p.tenureLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: _purple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(p.tenureLabel,
                  style: const TextStyle(color: _purple,
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ])),
      ]),
    );
  }

  Widget _noteCard(String note, Color accent, IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: accent, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(color: accent,
                  fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
          const SizedBox(height: 6),
          Text(note,
              style: TextStyle(
                  color: _textColor.withValues(alpha: 0.78),
                  fontSize: 13, height: 1.6)),
        ])),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // SECTION / ROW HELPERS
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildSection(
      String title, IconData icon, Color accent, List<Widget> rows) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderColor),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: _isDark ? 0.35 : 0.07),
            blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(
                color: (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.06))),
          ),
          child: Row(children: [
            Container(width: 3, height: 22,
                decoration: BoxDecoration(
                    color: accent, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: accent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: TextStyle(color: accent,
                      fontWeight: FontWeight.w700, fontSize: 15,
                      letterSpacing: 0.3)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(children: rows),
        ),
      ]),
    );
  }

  Widget _row(IconData icon, String label, String? value) {
    final filled = value != null &&
        value.isNotEmpty &&
        value != 'null' &&
        value != ' · ';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
                color: (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
          ),
          child: Icon(icon, size: 16,
              color: _subTextColor.withValues(alpha: 0.5)),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 1),
            Text(label,
                style: TextStyle(
                    color: _subTextColor.withValues(alpha: 0.45),
                    fontSize: 10, fontWeight: FontWeight.w600,
                    letterSpacing: 0.7)),
            const SizedBox(height: 3),
            Text(
              filled ? value : _t('notProvided'),
              style: TextStyle(
                color: filled
                    ? _textColor.withValues(alpha: 0.92)
                    : _textColor.withValues(alpha: 0.25),
                fontSize: 14, fontWeight: FontWeight.w500, height: 1.4,
              ),
            ),
          ],
        )),
      ]),
    );
  }

  Widget _rowPair(Widget a, Widget b) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: a),
        const SizedBox(width: 10),
        Expanded(child: b),
      ]);

  Widget _subHeader(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 18, 0, 8),
    child: Row(children: [
      Text(text.toUpperCase(),
          style: TextStyle(color: _cyan.withValues(alpha: 0.65),
              fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.6)),
      const SizedBox(width: 10),
      Expanded(child: Container(
          height: 1,
          color: (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.07))),
    ]),
  );

  bool _hasContent(String? s) =>
      s != null && s.trim().isNotEmpty && s != 'null';

  // ── Danger zone ───────────────────────────────────────────────────────────────

  Widget _buildDangerZone() => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: _red.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: _red.withValues(alpha: 0.25), width: 1.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.warning_amber_rounded, color: _red, size: 18),
        const SizedBox(width: 8),
        Text(_t('dangerZone'),
            style: const TextStyle(color: _red, fontWeight: FontWeight.w700,
                fontSize: 15, letterSpacing: 0.3)),
      ]),
      const SizedBox(height: 10),
      Text(_t('dangerZoneDesc'),
          style: TextStyle(
              color: _subTextColor.withValues(alpha: 0.5),
              fontSize: 13, height: 1.55)),
      const SizedBox(height: 18),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _showDeleteDialog,
          icon: const Icon(Icons.delete_forever_rounded, size: 18, color: _red),
          label: Text(_t('deleteMyAccount'),
              style: const TextStyle(color: _red, fontWeight: FontWeight.w700,
                  fontSize: 14, letterSpacing: 0.5)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: _red, width: 1.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    ]),
  );

  // ── FAB ───────────────────────────────────────────────────────────────────────

  Widget _buildFab() => FutureBuilder<ProfileModel?>(
    future: _profileFuture,
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const SizedBox.shrink();
      final accent = _accentFor(snapshot.data!);
      return FloatingActionButton.extended(
        // Add this line to resolve the Hero tag conflict
        heroTag: 'profile_page_fab_${widget.id ?? "self"}',
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(
              builder: (_) => EditProfilePage(profile: snapshot.data!)));
          _reload();
        },
        backgroundColor: accent,
        foregroundColor: const Color(0xFF060E17),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(Icons.edit_rounded, size: 20),
        label: Text(_t('editProfile'),
            style: const TextStyle(fontWeight: FontWeight.w800,
                fontSize: 14, letterSpacing: 0.5)),
      );
    },
  );

  // ── Background / Loading / Empty ──────────────────────────────────────────────

  Widget _buildBackground({required Widget child}) => Stack(children: [
    Container(
      decoration: BoxDecoration(gradient: SC.currentGradient),
    ),
    Positioned(top: -100, right: -80,
        child: _blob(300, _cyan.withValues(alpha: 0.04))),
    Positioned(bottom: 200, left: -120,
        child: _blob(280, _blue.withValues(alpha: 0.05))),
    Positioned(top: 400, right: -60,
        child: _blob(200, _teal.withValues(alpha: 0.04))),
    child,
  ]);

  Widget _blob(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );

  Widget _buildLoading() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      SizedBox(width: 52, height: 52,
          child: CircularProgressIndicator(color: _cyan, strokeWidth: 2.5,
              backgroundColor: _cyan.withValues(alpha: 0.12))),
      const SizedBox(height: 20),
      Text(_t('loadingProfile'),
          style: TextStyle(
              color: _subTextColor.withValues(alpha: 0.5), fontSize: 14)),
    ],
  ));

  Widget _buildEmpty() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
          shape: BoxShape.circle,
          border: Border.all(
              color: (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
        ),
        child: Icon(Icons.person_off_outlined, size: 56,
            color: _textColor.withValues(alpha: 0.2)),
      ),
      const SizedBox(height: 20),
      Text(_t('profileNotFound'),
          style: TextStyle(
              color: _textColor.withValues(alpha: 0.7), fontSize: 16)),
    ],
  ));

  Widget _pulsingIcon(IconData icon, Color color) => AnimatedBuilder(
    animation: _pulseController,
    builder: (_, __) => Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.08 + _pulseController.value * 0.04),
        border: Border.all(
            color: color.withValues(alpha: 0.3 + _pulseController.value * 0.1)),
      ),
      child: Icon(icon, color: color, size: 36),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _LoadingOverlay extends StatelessWidget {
  final String message;
  final bool isDark;
  const _LoadingOverlay({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.black54,
    child: Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(width: 44, height: 44,
              child: CircularProgressIndicator(
                  color: Color(0xFFEF5350), strokeWidth: 2.5)),
          const SizedBox(height: 18),
          Text(message,
              style: TextStyle(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.65),
                  fontSize: 13)),
        ]),
      ),
    ),
  );
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final bool isDark;
  const _GlassCard(
      {required this.child, required this.borderColor, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF0F1E2E) : Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: borderColor, width: 1.5),
    ),
    child: child,
  );
}

class _PositionBadge extends StatelessWidget {
  final String label;
  final Color accent;
  const _PositionBadge({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.5),
      color: accent.withValues(alpha: 0.08),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.workspace_premium_rounded, color: accent, size: 15),
      const SizedBox(width: 7),
      Text(label,
          style: TextStyle(color: accent, fontSize: 12,
              fontWeight: FontWeight.w700, letterSpacing: 1.1)),
    ]),
  );
}

class _TenureBadge extends StatelessWidget {
  final String? position;
  final String tenureLabel;
  final Color accent;
  const _TenureBadge({
    required this.position,
    required this.tenureLabel,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.5),
      color: accent.withValues(alpha: 0.08),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.history_edu_rounded, color: accent, size: 15),
      const SizedBox(width: 7),
      if (position != null)
        Text(position!,
            style: TextStyle(color: accent, fontSize: 12,
                fontWeight: FontWeight.w700, letterSpacing: 0.8)),
      if (tenureLabel.isNotEmpty) ...[
        Container(
          width: 1, height: 12,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          color: accent.withValues(alpha: 0.35),
        ),
        Text(tenureLabel,
            style: TextStyle(color: accent.withValues(alpha: 0.75),
                fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    ]),
  );
}

class _AdvisorBadge extends StatelessWidget {
  final String? designation;
  final String? institution;
  final Color accent;
  const _AdvisorBadge({
    required this.designation,
    required this.institution,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final label = [
      if (designation != null && designation!.isNotEmpty) designation!,
      if (institution != null && institution!.isNotEmpty) institution!,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.5),
        color: accent.withValues(alpha: 0.08),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.work_outline_rounded, color: accent, size: 15),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label.isNotEmpty ? label : 'Advisor',
            style: TextStyle(color: accent, fontSize: 12,
                fontWeight: FontWeight.w700, letterSpacing: 0.8),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool visible;
  final bool isDark;
  final VoidCallback onToggle;
  const _PasswordField({
    required this.controller,
    required this.visible,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    obscureText: !visible,
    style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF1A2332), fontSize: 14),
    decoration: InputDecoration(
      hintText: SC.tr('enterYourPassword'),
      hintStyle: TextStyle(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.28),
          fontSize: 13),
      prefixIcon: Icon(Icons.lock_outline_rounded,
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
          size: 18),
      suffixIcon: IconButton(
        icon: Icon(
          visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
          size: 18,
        ),
        onPressed: onToggle,
      ),
      filled: true,
      fillColor:
      (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
      ),
    ),
  );
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  const _OutlineBtn(
      {required this.label, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 14),
      side: BorderSide(
          color:
          (isDark ? Colors.white : Colors.black).withValues(alpha: 0.18)),
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: Text(label,
        style: TextStyle(
            color: (isDark ? Colors.white : Colors.black)
                .withValues(alpha: 0.65),
            fontWeight: FontWeight.w600,
            fontSize: 14)),
  );
}

class _SolidBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SolidBtn(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: onTap,
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      elevation: 0,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: Text(label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
  );
}
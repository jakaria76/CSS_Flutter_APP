import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:css/pages/JoinCommunity/community_applications_admin_page.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';
import 'package:css/services/community_application_service.dart';
import 'package:css/models/community_application_model.dart';

// ── Design Tokens ───────────────────────────────────────────────
class _DT {
  // Core palette
  static const deepBg      = Color(0xFF060B14);
  static const cardBg      = Color(0xFF0D1520);
  static const cardBgLight = Color(0xFFF7F9FF);
  static const surfaceD    = Color(0xFF111B2B);
  static const surfaceL    = Color(0xFFFFFFFF);

  // Accents
  static const indigo      = Color(0xFF5B21F0);
  static const indigoLight = Color(0xFF7C45FF);
  static const emerald     = Color(0xFF00E5A0);
  static const emeraldDeep = Color(0xFF00B87A);
  static const gold        = Color(0xFFFFB830);
  static const coral       = Color(0xFFFF5F6D);
  static const sky         = Color(0xFF38BDF8);

  // Section gradients
  static const gradPersonal  = [Color(0xFF00E5A0), Color(0xFF38BDF8)];
  static const gradAddress   = [Color(0xFF5B21F0), Color(0xFF7C45FF)];
  static const gradEducation = [Color(0xFFFFB830), Color(0xFFFF5F6D)];
  static const gradContact   = [Color(0xFF00E5A0), Color(0xFF5B21F0)];
  static const gradPayment   = [Color(0xFFFF5F6D), Color(0xFFFFB830)];
  static const gradSubmit    = [Color(0xFF5B21F0), Color(0xFF00E5A0)];
  static const gradAdmin     = [Color(0xFF7C45FF), Color(0xFF38BDF8)];

  // Text
  static const textPrimD   = Color(0xFFE8EDF5);
  static const textSecD    = Color(0xFF7A8FAF);
  static const textPrimL   = Color(0xFF0D1520);
  static const textSecL    = Color(0xFF5A6A84);

  // Border
  static const borderD = Color(0x1AFFFFFF);
  static const borderL = Color(0x14000000);

  static const radius = 20.0;
  static const radiusSm = 14.0;
  static const radiusXs = 10.0;
}

class JoinCommunityFormPage extends StatefulWidget {
  const JoinCommunityFormPage({super.key});

  @override
  State<JoinCommunityFormPage> createState() => _JoinCommunityFormPageState();
}

class _JoinCommunityFormPageState extends State<JoinCommunityFormPage>
    with TickerProviderStateMixin {
  final _service  = CommunityApplicationService();
  final _formKey  = GlobalKey<FormState>();

  // ── Controllers ──
  final _fullNameCtrl      = TextEditingController();
  final _fatherNameCtrl    = TextEditingController();
  final _motherNameCtrl    = TextEditingController();
  final _reasonCtrl        = TextEditingController();
  final _villageCtrl       = TextEditingController();
  final _upazilaCtrl       = TextEditingController();
  final _districtCtrl      = TextEditingController();
  final _eduPrimaryCtrl    = TextEditingController();
  final _eduSecondaryCtrl  = TextEditingController();
  final _eduHscCtrl        = TextEditingController();
  final _eduGradCtrl       = TextEditingController();
  final _mobileCtrl        = TextEditingController();
  final _facebookCtrl      = TextEditingController();
  final _paymentNumberCtrl = TextEditingController();
  final _transactionIdCtrl = TextEditingController();
  final _emailCtrl         = TextEditingController();
  final _bkashCtrl         = TextEditingController();
  final _nagadCtrl         = TextEditingController();

  String? _bloodGroup;
  XFile?  _applicantPhoto;
  XFile?  _paymentScreenshot;

  bool _isSubmitting       = false;
  bool _isLoadingData      = true;
  bool _isAdmin            = false;
  bool _isSavingPaymentNum = false;

  String? _bkashNumber;
  String? _nagadNumber;
  CommunityApplicationModel? _existingApplication;

  // Animations
  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late AnimationController _shimmerCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;
  late Animation<double>   _shimmerAnim;

  static const _bloodGroups = ['A+','A-','B+','B-','AB+','AB-','O+','O-'];
  static const _tblPayment  = 'payment_settings';
  static const _keyBkash    = 'bkash_number';
  static const _keyNagad    = 'nagad_number';

  @override
  void initState() {
    super.initState();
    _fadeCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _slideCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _fadeAnim    = CurvedAnimation(parent: _fadeCtrl,  curve: Curves.easeOut);
    _slideAnim   = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _shimmerAnim = CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut);
    _initData();
  }

  Future<void> _initData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _isLoadingData = false);
      return;
    }
    try {
      final profileResponse = await Supabase.instance.client
          .from('profiles').select('role').eq('id', userId).maybeSingle();
      final isAdmin = profileResponse?['role'] == 'admin';
      final existing = await _service.getMyApplication();
      final bkashRow = await Supabase.instance.client
          .from(_tblPayment).select('value').eq('id', _keyBkash).maybeSingle();
      final nagadRow = await Supabase.instance.client
          .from(_tblPayment).select('value').eq('id', _keyNagad).maybeSingle();
      final bkash = bkashRow?['value'] as String?;
      final nagad = nagadRow?['value'] as String?;
      if (mounted) {
        setState(() {
          _isAdmin             = isAdmin;
          _existingApplication = existing;
          _bkashNumber         = bkash;
          _nagadNumber         = nagad;
          _bkashCtrl.text      = bkash ?? '';
          _nagadCtrl.text      = nagad ?? '';
          _isLoadingData       = false;
        });
        _fadeCtrl.forward();
        _slideCtrl.forward();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _savePaymentNumbers() async {
    final bkash = _bkashCtrl.text.trim();
    final nagad = _nagadCtrl.text.trim();
    if (bkash.isEmpty && nagad.isEmpty) return;
    setState(() => _isSavingPaymentNum = true);
    try {
      if (bkash.isNotEmpty) {
        await Supabase.instance.client.from(_tblPayment)
            .upsert({'id': _keyBkash, 'value': bkash});
      }
      if (nagad.isNotEmpty) {
        await Supabase.instance.client.from(_tblPayment)
            .upsert({'id': _keyNagad, 'value': nagad});
      }
      if (mounted) {
        setState(() {
          _bkashNumber        = bkash.isNotEmpty ? bkash : _bkashNumber;
          _nagadNumber        = nagad.isNotEmpty ? nagad : _nagadNumber;
          _isSavingPaymentNum = false;
        });
        SC.toast(context, SC.tr('joinPaymentNumberSaved'), const Color(0xFF00E5A0));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSavingPaymentNum = false);
        SC.toast(context, SC.tr('joinPaymentNumberSaveFail'), _DT.coral);
      }
    }
  }

  @override
  void dispose() {
    for (final c in [
      _fullNameCtrl, _fatherNameCtrl, _motherNameCtrl, _reasonCtrl,
      _villageCtrl, _upazilaCtrl, _districtCtrl, _eduPrimaryCtrl,
      _eduSecondaryCtrl, _eduHscCtrl, _eduGradCtrl, _mobileCtrl,
      _facebookCtrl, _paymentNumberCtrl, _transactionIdCtrl, _emailCtrl,
      _bkashCtrl, _nagadCtrl,
    ]) c.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickApplicantPhoto() async {
    final source = await _showImageSourceSheet();
    if (source == null) return;
    final img = await _service.pickImage(source: source);
    if (img != null) setState(() => _applicantPhoto = img);
  }

  Future<void> _pickPaymentScreenshot() async {
    final source = await _showImageSourceSheet();
    if (source == null) return;
    final img = await _service.pickImage(source: source);
    if (img != null) setState(() => _paymentScreenshot = img);
  }

  Future<ImageSource?> _showImageSourceSheet() async {
    final isDark = SC.isDark;
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0D1520).withOpacity(0.95) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.06),
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _sheetTile(
                  ctx: ctx, isDark: isDark,
                  icon: Icons.camera_alt_rounded,
                  label: SC.tr('camera'),
                  gradient: const [Color(0xFF5B21F0), Color(0xFF38BDF8)],
                  source: ImageSource.camera,
                ),
                const SizedBox(height: 10),
                _sheetTile(
                  ctx: ctx, isDark: isDark,
                  icon: Icons.photo_library_rounded,
                  label: SC.tr('gallery'),
                  gradient: const [Color(0xFF00E5A0), Color(0xFF5B21F0)],
                  source: ImageSource.gallery,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetTile({
    required BuildContext ctx,
    required bool isDark,
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required ImageSource source,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pop(ctx, source),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(_DT.radiusSm),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(
                  color: isDark ? _DT.textPrimD : _DT.textPrimL,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 13,
                color: isDark ? Colors.white24 : Colors.black26),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      SC.toast(context, SC.tr('joinFormFillAll'), _DT.coral);
      return;
    }
    if (_bloodGroup == null) {
      SC.toast(context, SC.tr('joinFormSelectBloodGroup'), _DT.coral);
      return;
    }
    if (_applicantPhoto == null) {
      SC.toast(context, SC.tr('joinFormAddPhoto'), _DT.coral);
      return;
    }
    if (_paymentScreenshot == null) {
      SC.toast(context, SC.tr('joinFormAddPaymentScreenshot'), _DT.coral);
      return;
    }
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      SC.toast(context, SC.tr('joinFormLoginRequired'), _DT.coral);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final photoUrl      = await _service.uploadApplicantPhoto(_applicantPhoto!);
      final screenshotUrl = await _service.uploadPaymentScreenshot(_paymentScreenshot!);
      final application = CommunityApplicationModel(
        userId:               userId,
        fullName:             _fullNameCtrl.text.trim(),
        fatherName:           _fatherNameCtrl.text.trim(),
        motherName:           _motherNameCtrl.text.trim(),
        bloodGroup:           _bloodGroup!,
        photoUrl:             photoUrl,
        reasonToJoin:         _reasonCtrl.text.trim(),
        village:              _villageCtrl.text.trim(),
        upazila:              _upazilaCtrl.text.trim(),
        district:             _districtCtrl.text.trim(),
        eduPrimary:           _eduPrimaryCtrl.text.trim().isEmpty ? null : _eduPrimaryCtrl.text.trim(),
        eduSecondary:         _eduSecondaryCtrl.text.trim().isEmpty ? null : _eduSecondaryCtrl.text.trim(),
        eduHigherSecondary:   _eduHscCtrl.text.trim().isEmpty ? null : _eduHscCtrl.text.trim(),
        eduGraduate:          _eduGradCtrl.text.trim().isEmpty ? null : _eduGradCtrl.text.trim(),
        mobileNumber:         _mobileCtrl.text.trim(),
        facebookLink:         _facebookCtrl.text.trim().isEmpty ? null : _facebookCtrl.text.trim(),
        paymentNumber:        _paymentNumberCtrl.text.trim(),
        transactionId:        _transactionIdCtrl.text.trim(),
        paymentScreenshotUrl: screenshotUrl,
        paymentAmount:        100,
        email:                _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      );
      await _service.submitApplication(application);
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSuccessDialog();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        SC.toast(context, SC.tr('joinFormSubmitFail'), _DT.coral);
      }
    }
  }

  void _showSuccessDialog() {
    final isDark = SC.isDark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0D1520).withOpacity(0.96)
                    : Colors.white.withOpacity(0.96),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.06),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated check circle
                  Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E5A0), Color(0xFF38BDF8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5A0).withOpacity(0.4),
                          blurRadius: 32,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
                  ),
                  const SizedBox(height: 24),
                  Text(SC.tr('joinFormSuccessTitle'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark ? _DT.textPrimD : _DT.textPrimL,
                          letterSpacing: -0.3)),
                  const SizedBox(height: 10),
                  Text(SC.tr('joinFormSuccessMessage'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13.5,
                          color: isDark ? _DT.textSecD : _DT.textSecL,
                          height: 1.55)),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: _GradientButton(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF5B21F0), Color(0xFF00E5A0)]),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      child: Text(SC.tr('joinFormDone'),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────
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
    final bgColor   = isDark ? _DT.deepBg : const Color(0xFFF0F4FF);
    final textColor = isDark ? _DT.textPrimD : _DT.textPrimL;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(isDark, textColor),
        body: _isLoadingData
            ? _buildLoader(isDark)
            : FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  72 + MediaQuery.of(context).padding.top + 12,
                  16,
                  56,
                ),
                children: [
                  if (_isAdmin) ...[
                    _buildAdminCard(isDark),
                    const SizedBox(height: 12),
                    _buildAdminPaymentEditor(isDark),
                    const SizedBox(height: 32),
                  ],
                  if (_existingApplication != null)
                    _buildAlreadyAppliedState(isDark, textColor)
                  else
                    ..._buildFormFields(isDark, textColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, Color textColor) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(72),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withOpacity(0.5)
                  : Colors.white.withOpacity(0.8),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          color: textColor, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    // Gradient accent line
                    Container(
                      width: 3,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5B21F0), Color(0xFF00E5A0)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(SC.tr('joinFormPageTitle'),
                            style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                letterSpacing: -0.3)),
                        Text(SC.tr('joinFormPageSubtitle'),
                            style: TextStyle(
                                color: isDark ? _DT.textSecD : _DT.textSecL,
                                fontSize: 11.5)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoader(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _shimmerAnim,
            builder: (_, __) => Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color.lerp(const Color(0xFF5B21F0), const Color(0xFF00E5A0), _shimmerAnim.value)!,
                    Color.lerp(const Color(0xFF00E5A0), const Color(0xFF38BDF8), _shimmerAnim.value)!,
                  ],
                ),
              ),
              padding: const EdgeInsets.all(3),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? _DT.deepBg : const Color(0xFFF0F4FF),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDark ? _DT.emerald : _DT.indigo,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(SC.tr('loading'),
              style: TextStyle(
                  color: isDark ? _DT.textSecD : _DT.textSecL,
                  fontSize: 13,
                  letterSpacing: 0.2)),
        ],
      ),
    );
  }

  // ─── Admin Card ───────────────────────────────────────────────
  Widget _buildAdminCard(bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CommunityApplicationsAdminPage()));
      },
      child: _GlassCard(
        isDark: isDark,
        gradientBorder: _DT.gradAdmin,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: _DT.gradAdmin),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(SC.tr('adminPageTitle'),
                      style: TextStyle(
                          color: isDark ? _DT.textPrimD : _DT.textPrimL,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(SC.tr('adminPageSubtitle'),
                      style: TextStyle(
                          color: isDark ? _DT.textSecD : _DT.textSecL,
                          fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  color: isDark ? Colors.white38 : Colors.black38, size: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Admin Payment Editor ─────────────────────────────────────
  Widget _buildAdminPaymentEditor(bool isDark) {
    return _GlassCard(
      isDark: isDark,
      gradientBorder: _DT.gradPayment,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: _DT.gradPayment),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(SC.tr('adminPaymentTitle'),
                      style: TextStyle(
                          color: isDark ? _DT.textPrimD : _DT.textPrimL,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  Text(SC.tr('adminPaymentSubtitle'),
                      style: TextStyle(
                          color: isDark ? _DT.textSecD : _DT.textSecL,
                          fontSize: 11.5)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _adminPaymentField(
            controller: _bkashCtrl,
            label: 'bKash নম্বর',
            icon: Icons.phone_android_rounded,
            gradient: const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFFF4081)]),
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _adminPaymentField(
            controller: _nagadCtrl,
            label: 'Nagad নম্বর',
            icon: Icons.phone_android_rounded,
            gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFFB347)]),
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          _GradientButton(
            gradient: const LinearGradient(colors: [Color(0xFF00E5A0), Color(0xFF5B21F0)]),
            onTap: _isSavingPaymentNum ? null : _savePaymentNumbers,
            loading: _isSavingPaymentNum,
            icon: Icons.save_rounded,
            child: Text(
              _isSavingPaymentNum ? SC.tr('saving') : SC.tr('adminPaymentSaveBtn'),
              style: const TextStyle(fontWeight: FontWeight.bold,
                  fontSize: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminPaymentField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required LinearGradient gradient,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StyledTextField(
            controller: controller,
            label: label,
            isDark: isDark,
            keyboardType: TextInputType.phone,
          ),
        ),
      ],
    );
  }

  // ─── Already Applied State ────────────────────────────────────
  Widget _buildAlreadyAppliedState(bool isDark, Color textColor) {
    final app   = _existingApplication!;
    final isApproved = app.status == 'approved';
    final isRejected = app.status == 'rejected';

    final statusColor = isApproved
        ? const Color(0xFF00E5A0)
        : isRejected ? _DT.coral : _DT.gold;
    final statusText  = isApproved
        ? SC.tr('joinStatusApproved')
        : isRejected ? SC.tr('joinStatusRejected') : SC.tr('joinStatusPending');
    final statusIcon  = isApproved
        ? Icons.verified_rounded
        : isRejected ? Icons.cancel_rounded : Icons.hourglass_top_rounded;

    return _GlassCard(
      isDark: isDark,
      gradientBorder: isApproved
          ? [const Color(0xFF00E5A0), const Color(0xFF38BDF8)]
          : isRejected
          ? [_DT.coral, _DT.gold]
          : [_DT.gold, const Color(0xFF5B21F0)],
      child: Column(
        children: [
          Container(
            width: 88, height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor.withOpacity(0.12),
              border: Border.all(color: statusColor.withOpacity(0.35), width: 2),
            ),
            child: Icon(statusIcon, size: 42, color: statusColor),
          ),
          const SizedBox(height: 20),
          Text(SC.tr('joinAlreadyAppliedTitle'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.2)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: statusColor.withOpacity(0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, color: statusColor, size: 15),
                const SizedBox(width: 7),
                Text(statusText,
                    style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Form Fields ──────────────────────────────────────────────
  List<Widget> _buildFormFields(bool isDark, Color textColor) {
    return [
      _SectionHeader(
          label: SC.tr('joinSectionPersonal'),
          icon: Icons.person_rounded,
          colors: _DT.gradPersonal,
          isDark: isDark),
      _GlassCard(isDark: isDark, gradientBorder: _DT.gradPersonal, child: Column(children: [
        _photoPicker(
          label: SC.tr('joinFieldPhoto'),
          file: _applicantPhoto,
          onTap: _pickApplicantPhoto,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        _StyledTextField(controller: _fullNameCtrl,   label: SC.tr('joinFieldFullName'),   isDark: isDark, required: true),
        const SizedBox(height: 10),
        _StyledTextField(controller: _fatherNameCtrl, label: SC.tr('joinFieldFatherName'), isDark: isDark, required: true),
        const SizedBox(height: 10),
        _StyledTextField(controller: _motherNameCtrl, label: SC.tr('joinFieldMotherName'), isDark: isDark, required: true),
        const SizedBox(height: 16),
        _bloodGroupPicker(isDark, textColor),
        const SizedBox(height: 10),
        _StyledTextField(controller: _reasonCtrl, label: SC.tr('joinFieldReason'), isDark: isDark, required: true, maxLines: 4),
      ])),

      _SectionHeader(
          label: SC.tr('joinSectionAddress'),
          icon: Icons.location_on_rounded,
          colors: _DT.gradAddress,
          isDark: isDark),
      _GlassCard(isDark: isDark, gradientBorder: _DT.gradAddress, child: Column(children: [
        _StyledTextField(controller: _villageCtrl,  label: SC.tr('joinFieldVillage'),  isDark: isDark, required: true),
        const SizedBox(height: 10),
        _StyledTextField(controller: _upazilaCtrl,  label: SC.tr('joinFieldUpazila'),  isDark: isDark, required: true),
        const SizedBox(height: 10),
        _StyledTextField(controller: _districtCtrl, label: SC.tr('joinFieldDistrict'), isDark: isDark, required: true),
      ])),

      _SectionHeader(
          label: SC.tr('joinSectionEducation'),
          icon: Icons.school_rounded,
          colors: _DT.gradEducation,
          isDark: isDark),
      _GlassCard(isDark: isDark, gradientBorder: _DT.gradEducation, child: Column(children: [
        _optionalLabel(SC.tr('joinFieldEduPrimary'),   isDark),
        _StyledTextField(controller: _eduPrimaryCtrl,   label: SC.tr('joinFieldEduPrimary'),   isDark: isDark),
        const SizedBox(height: 10),
        _optionalLabel(SC.tr('joinFieldEduSecondary'), isDark),
        _StyledTextField(controller: _eduSecondaryCtrl, label: SC.tr('joinFieldEduSecondary'), isDark: isDark),
        const SizedBox(height: 10),
        _optionalLabel(SC.tr('joinFieldEduHsc'),       isDark),
        _StyledTextField(controller: _eduHscCtrl,       label: SC.tr('joinFieldEduHsc'),       isDark: isDark),
        const SizedBox(height: 10),
        _optionalLabel(SC.tr('joinFieldEduGrad'),      isDark),
        _StyledTextField(controller: _eduGradCtrl,      label: SC.tr('joinFieldEduGrad'),      isDark: isDark),
      ])),

      _SectionHeader(
          label: SC.tr('joinSectionContact'),
          icon: Icons.contact_phone_rounded,
          colors: _DT.gradContact,
          isDark: isDark),
      _GlassCard(isDark: isDark, gradientBorder: _DT.gradContact, child: Column(children: [
        _StyledTextField(controller: _mobileCtrl,   label: SC.tr('joinFieldMobile'),  isDark: isDark, required: true, keyboardType: TextInputType.phone),
        const SizedBox(height: 10),
        _StyledTextField(controller: _facebookCtrl, label: SC.tr('joinFieldFacebook'), isDark: isDark),
        const SizedBox(height: 10),
        _StyledTextField(controller: _emailCtrl,    label: SC.tr('joinFieldEmail'),    isDark: isDark, keyboardType: TextInputType.emailAddress),
      ])),

      _SectionHeader(
          label: SC.tr('joinSectionPayment'),
          icon: Icons.account_balance_wallet_rounded,
          colors: _DT.gradPayment,
          isDark: isDark),
      _GlassCard(isDark: isDark, gradientBorder: _DT.gradPayment, child: Column(children: [
        _paymentNotice(isDark),
        const SizedBox(height: 16),
        _StyledTextField(controller: _paymentNumberCtrl, label: SC.tr('joinFieldPaymentNumber'), isDark: isDark, required: true, keyboardType: TextInputType.phone),
        const SizedBox(height: 10),
        _StyledTextField(controller: _transactionIdCtrl, label: SC.tr('joinFieldTransactionId'), isDark: isDark, required: true),
        const SizedBox(height: 16),
        _photoPicker(
          label: SC.tr('joinFieldPaymentScreenshot'),
          file: _paymentScreenshot,
          onTap: _pickPaymentScreenshot,
          isDark: isDark,
        ),
      ])),

      const SizedBox(height: 36),
      _GradientButton(
        gradient: const LinearGradient(colors: [Color(0xFF5B21F0), Color(0xFF00E5A0)]),
        onTap: _isSubmitting ? null : _submit,
        loading: _isSubmitting,
        icon: Icons.send_rounded,
        height: 58,
        child: Text(SC.tr('joinSubmitButton'),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
      ),
    ];
  }

  Widget _optionalLabel(String text, bool isDark) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Text(text,
            style: TextStyle(
                color: isDark ? _DT.textSecD : _DT.textSecL,
                fontSize: 12)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: _DT.gold.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _DT.gold.withOpacity(0.3)),
          ),
          child: const Text('Optional',
              style: TextStyle(color: _DT.gold, fontSize: 9.5, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );

  Widget _bloodGroupPicker(bool isDark, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(SC.tr('joinFieldBloodGroup'),
                style: TextStyle(
                    color: isDark ? _DT.textSecD : _DT.textSecL,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: _DT.coral.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _DT.coral.withOpacity(0.3)),
              ),
              child: const Text('Required',
                  style: TextStyle(color: _DT.coral, fontSize: 9.5, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _bloodGroups.map((bg) {
            final selected = _bloodGroup == bg;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _bloodGroup = bg);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(colors: [Color(0xFF5B21F0), Color(0xFF00E5A0)])
                      : null,
                  color: selected
                      ? null
                      : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? Colors.transparent
                        : (isDark ? _DT.borderD : _DT.borderL),
                    width: selected ? 0 : 1,
                  ),
                  boxShadow: selected
                      ? [BoxShadow(
                      color: const Color(0xFF5B21F0).withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4))]
                      : [],
                ),
                child: Text(bg,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: selected
                            ? Colors.white
                            : (isDark ? _DT.textPrimD : _DT.textPrimL))),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _photoPicker({
    required String label,
    required XFile? file,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.03)
              : Colors.black.withOpacity(0.02),
          borderRadius: BorderRadius.circular(_DT.radiusSm),
          border: Border.all(
            color: file != null
                ? const Color(0xFF5B21F0).withOpacity(0.45)
                : (isDark ? _DT.borderD : _DT.borderL),
            width: file != null ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: file != null
            ? Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(file.path), fit: BoxFit.cover),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12, right: 12,
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF5B21F0), Color(0xFF00E5A0)]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
                ),
                child: const Icon(Icons.edit_rounded, color: Colors.white, size: 15),
              ),
            ),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFF5B21F0).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_a_photo_rounded,
                  color: isDark ? Colors.white38 : _DT.indigo.withOpacity(0.6), size: 26),
            ),
            const SizedBox(height: 12),
            Text(label,
                style: TextStyle(
                    color: isDark ? _DT.textSecD : _DT.textSecL,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('Tap to add',
                style: TextStyle(
                    color: isDark
                        ? const Color(0xFF5B21F0).withOpacity(0.6)
                        : _DT.indigo.withOpacity(0.5),
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _paymentNotice(bool isDark) {
    final hasBkash = _bkashNumber?.isNotEmpty == true;
    final hasNagad = _nagadNumber?.isNotEmpty == true;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _DT.gold.withOpacity(0.08),
            borderRadius: BorderRadius.circular(_DT.radiusXs),
            border: Border.all(color: _DT.gold.withOpacity(0.22)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: _DT.gold, size: 17),
              const SizedBox(width: 10),
              Expanded(
                child: Text(SC.tr('joinPaymentNotice'),
                    style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.55)),
              ),
            ],
          ),
        ),
        if (hasBkash || hasNagad) ...[
          const SizedBox(height: 12),
          if (hasBkash)
            _paymentMethodCard(
              isDark: isDark,
              label: 'bKash',
              number: _bkashNumber!,
              gradient: const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFFF4081)]),
              icon: Icons.phone_android_rounded,
            ),
          if (hasBkash && hasNagad) const SizedBox(height: 10),
          if (hasNagad)
            _paymentMethodCard(
              isDark: isDark,
              label: 'Nagad',
              number: _nagadNumber!,
              gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFFB347)]),
              icon: Icons.phone_android_rounded,
            ),
        ] else ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(_DT.radiusXs),
              border: Border.all(color: isDark ? _DT.borderD : _DT.borderL),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_empty_rounded,
                    color: isDark ? Colors.white24 : Colors.black26, size: 17),
                const SizedBox(width: 8),
                Text(SC.tr('joinPaymentNumberNotSet'),
                    style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38, fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _paymentMethodCard({
    required bool isDark,
    required String label,
    required String number,
    required LinearGradient gradient,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: number));
        SC.toast(context, SC.tr('joinPaymentNumberCopied'), const Color(0xFF00E5A0));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: gradient.colors.first.withOpacity(isDark ? 0.1 : 0.06),
          borderRadius: BorderRadius.circular(_DT.radiusXs),
          border: Border.all(color: gradient.colors.first.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: Colors.white, size: 15),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: gradient.colors.first,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6)),
                  const SizedBox(height: 2),
                  Text(number,
                      style: TextStyle(
                          color: isDark ? _DT.textPrimD : _DT.textPrimL,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3)),
                ],
              ),
            ),
            Column(
              children: [
                Icon(Icons.copy_all_rounded,
                    color: isDark ? Colors.white30 : Colors.black26, size: 17),
                const SizedBox(height: 2),
                Text(SC.tr('tapToCopy'),
                    style: TextStyle(
                        color: isDark ? Colors.white24 : Colors.black26, fontSize: 9.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable Components ──────────────────────────────────────────

/// A card with a subtle gradient-glow border effect
class _GlassCard extends StatelessWidget {
  final bool isDark;
  final List<Color> gradientBorder;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _GlassCard({
    required this.isDark,
    required this.gradientBorder,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_DT.radius),
          gradient: LinearGradient(
            colors: gradientBorder.map((c) => c.withOpacity(isDark ? 0.3 : 0.18)).toList(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(1.2),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? _DT.cardBg : _DT.surfaceL,
            borderRadius: BorderRadius.circular(_DT.radius - 1.2),
            boxShadow: isDark
                ? []
                : [BoxShadow(
                color: gradientBorder.first.withOpacity(0.07),
                blurRadius: 20,
                offset: const Offset(0, 6))],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Section header with gradient icon + decorative line
class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color> colors;
  final bool isDark;

  const _SectionHeader({
    required this.label,
    required this.icon,
    required this.colors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                  color: isDark ? _DT.textPrimD : _DT.textPrimL)),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  colors.first.withOpacity(0.4),
                  colors.last.withOpacity(0.0),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Styled text field with consistent look
class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isDark;
  final bool required;
  final int maxLines;
  final TextInputType keyboardType;

  const _StyledTextField({
    required this.controller,
    required this.label,
    required this.isDark,
    this.required = false,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(
          color: isDark ? _DT.textPrimD : _DT.textPrimL,
          fontSize: 14,
          fontWeight: FontWeight.w500),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? SC.tr('joinFieldRequired') : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: isDark ? _DT.textSecD : _DT.textSecL,
            fontSize: 13),
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.03),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_DT.radiusSm),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_DT.radiusSm),
            borderSide: BorderSide(
                color: isDark ? _DT.borderD : _DT.borderL, width: 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_DT.radiusSm),
            borderSide: const BorderSide(color: Color(0xFF5B21F0), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_DT.radiusSm),
            borderSide: BorderSide(color: _DT.coral, width: 1)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_DT.radiusSm),
            borderSide: BorderSide(color: _DT.coral, width: 1.5)),
        contentPadding: EdgeInsets.symmetric(
            horizontal: 16, vertical: maxLines > 1 ? 14 : 0),
        suffixIcon: required
            ? Icon(Icons.star_rounded, size: 8, color: _DT.coral.withOpacity(0.7))
            : null,
      ),
    );
  }
}

/// Gradient button with optional loading + icon
class _GradientButton extends StatelessWidget {
  final LinearGradient gradient;
  final VoidCallback? onTap;
  final Widget child;
  final bool loading;
  final IconData? icon;
  final double height;

  const _GradientButton({
    required this.gradient,
    required this.onTap,
    required this.child,
    this.loading = false,
    this.icon,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: onTap == null ? 0.55 : 1,
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(_DT.radiusSm),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: loading
                ? const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                ],
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
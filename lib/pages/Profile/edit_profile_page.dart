import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/profile_model.dart';
import '../../models/member_type.dart';
import '../../services/profile_service.dart';
import '../SettingsPage/settings_constants.dart';
import 'package:css/services/activity_logger.dart';

class EditProfilePage extends StatefulWidget {
  final ProfileModel profile;
  const EditProfilePage({super.key, required this.profile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage>
    with SingleTickerProviderStateMixin {
  final _formKey  = GlobalKey<FormState>();
  final _service  = ProfileService();
  final _picker   = ImagePicker();

  Uint8List? _imageBytes;
  bool _saving          = false;
  bool _fetchingLocation = false;

  final _mapController = MapController();
  LatLng _selectedLocation = const LatLng(23.8103, 90.4125);
  List<Marker> _markers = [];

  // ── Dropdown selections ────────────────────────────────────────────────────
  String? _selectedGender;
  String? _selectedMemberType;
  String? _selectedBloodGroup;
  String? _selectedCommitteePos;
  String? _selectedPreviousPos;
  String? _selectedAdvisorType;

  // ── Design tokens ──────────────────────────────────────────────────────────
  static const _bg      = Color(0xFF060E17);
  static const _cardBg  = Color(0xFF0F1E2E);
  static const _surface = Color(0xFF162030);
  static const _cyan    = Color(0xFF00E5FF);
  static const _blue    = Color(0xFF4A90E2);
  static const _orange  = Color(0xFFFF8A65);
  static const _red     = Color(0xFFEF5350);
  static const _green   = Color(0xFF4CAF50);
  static const _teal    = Color(0xFF26A69A);
  static const _purple  = Color(0xFF9C27B0);
  static const _indigo  = Color(0xFF5C6BC0);
  static const _amber   = Color(0xFFFFB300);
  static const _gold    = Color(0xFFFFD700);

  // ── Light mode colors ──────────────────────────────────────────────────────
  static const _lightBg     = Color(0xFFF0F4FF);
  static const _lightCard   = Color(0xFFFFFFFF);
  static const _lightSurface = Color(0xFFF5F8FF);

  // ── Theme-aware helpers ────────────────────────────────────────────────────
  bool get _isDark => SC.isDark;

  Color get _bgColor      => _isDark ? _bg        : _lightBg;
  Color get _cardColor    => _isDark ? _cardBg    : _lightCard;
  Color get _surfaceColor => _isDark ? _surface   : _lightSurface;
  Color get _textColor    => _isDark ? Colors.white : const Color(0xFF1A2332);
  Color get _subColor     => _isDark ? Colors.white : const Color(0xFF4A5568);
  Color get _borderColor  => _isDark
      ? Colors.white.withValues(alpha: 0.08)
      : Colors.black.withValues(alpha: 0.08);

  // ── Translation helper ─────────────────────────────────────────────────────
  String _t(String key) => SC.tr(key);

  // ── Committee positions list ───────────────────────────────────────────────
  static const _committeePositions = [
    "সভাপতি", "সহ-সভাপতি", "সাধারণ সম্পাদক", "যুগ্ম-সাধারণ সম্পাদক",
    "সাংগঠনিক সম্পাদক", "সহ-সাংগঠনিক সম্পাদক", "দপ্তর সম্পাদক",
    "সিনিয়র সহ-দপ্তর সম্পাদক", "সহ-দপ্তর সম্পাদক", "অর্থ সম্পাদক",
    "সিনিয়র অর্থ সম্পাদক", "সহ-অর্থ সম্পাদক", "শিক্ষা সম্পাদক",
    "সহ-শিক্ষা সম্পাদক", "পরিকল্পনা সম্পাদক", "সহ-পরিকল্পনা সম্পাদক",
    "মানব সম্পদ সম্পাদক", "সহ-মানব সম্পদ সম্পাদক", "পরিবেশ সম্পাদক",
    "সহ-পরিবেশ সম্পাদক", "ধর্ম সম্পাদক", "সহ-ধর্ম সম্পাদক",
    "প্রচার সম্পাদক", "সহ-প্রচার সম্পাদক", "ব্র্যান্ড ও গণমাধ্যম সম্পাদক",
    "সিনিয়র ব্র্যান্ড ও গণমাধ্যম সম্পাদক", "গ্রাফিক্স ডিজাইনার",
    "সহ-গ্রাফিক্স ডিজাইনার", "ক্রিয়া সম্পাদক", "সহ-ক্রিয়া সম্পাদক",
    "পাঠাগার সম্পাদক", "সহ-পাঠাগার সম্পাদক", "সাংস্কৃতিক সম্পাদক",
    "সহ-সাংস্কৃতিক সম্পাদক", "বিজ্ঞান ও প্রযুক্তি সম্পাদক",
    "সহ-বিজ্ঞান ও প্রযুক্তি সম্পাদক", "সমাজ কল্যাণ সম্পাদক",
    "সহ-সমাজ কল্যাণ সম্পাদক", "স্বাস্থ্য সম্পাদক", "সহ-স্বাস্থ্য সম্পাদক",
    "নারী সম্পাদক", "সহ-নারী সম্পাদক", "আন্তর্জাতিক সম্পাদক",
    "সহ-আন্তর্জাতিক সম্পাদক", "ছাত্র কল্যাণ সম্পাদক",
    "সহ-ছাত্র কল্যাণ সম্পাদক", "সাহিত্য সম্পাদক", "সহ-সাহিত্য সম্পাদক",
    "তথ্য ও গবেষণা সম্পাদক", "সহ-তথ্য ও গবেষণা সম্পাদক",
    "ত্রাণ ও দুর্যোগ সম্পাদক", "সিনিয়র ত্রাণ ও দুর্যোগ সম্পাদক",
    "সহ-ত্রাণ ও দুর্যোগ সম্পাদক", "কার্যকরী সদস্য",
  ];

  static String _advisorTypeLabel(String type) {
    return type == 'chief_advisor'
        ? 'প্রধান উপদেষ্টা (Chief Advisor)'
        : 'উপদেষ্টা (Advisor)';
  }

  // ── Controllers ────────────────────────────────────────────────────────────
  late TextEditingController fullNameCtrl, fullNameBnCtrl, dobCtrl,
      memberSinceCtrl, whatsappCtrl, altMobileCtrl, emailCtrl, fbLinkCtrl,
      presentAddrCtrl, permanentAddrCtrl, districtCtrl, upazilaCtrl,
      lastDonationCtrl, nextDonationCtrl, eligibilityCtrl, donationCountCtrl,
      prefLocationCtrl, latCtrl, lngCtrl, addressCtrl, committeePosCtrl;

  late TextEditingController schoolNameCtrl, schoolGroupCtrl, schoolYearCtrl,
      collegeNameCtrl, collegeGroupCtrl, collegeYearCtrl, uniNameCtrl,
      deptCtrl, studentIdCtrl, currYearCtrl, currSemCtrl, bioCtrl,
      whyJoinedCtrl, goalsCtrl, hobbiesCtrl, fbUserCtrl, portfolioCtrl,
      presentNoteCtrl;

  late TextEditingController tenureFromCtrl, tenureToCtrl, previousNoteCtrl;

  late TextEditingController occupationCtrl, institutionCtrl, designationCtrl,
      expertiseCtrl, advisorNoteCtrl;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  bool get _isPresent  => _selectedMemberType == MemberType.presentCommittee;
  bool get _isPrevious => _selectedMemberType == MemberType.previousCommittee;
  bool get _isAdvisor  => _selectedMemberType == MemberType.advisor;
  bool get _isCommittee => _isPresent || _isPrevious;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;

    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    _selectedGender       = p.gender;
    _selectedMemberType   = p.memberType;
    _selectedBloodGroup   = p.bloodGroup;
    _selectedCommitteePos = p.committeePosition;
    _selectedPreviousPos  = p.previousPosition;
    _selectedAdvisorType  = (p as dynamic).advisorType ?? 'advisor';

    fullNameCtrl      = TextEditingController(text: p.fullName);
    fullNameBnCtrl    = TextEditingController(text: p.fullNameBn);
    dobCtrl           = TextEditingController(text: _fmt(p.dateOfBirth));
    memberSinceCtrl   = TextEditingController(text: _fmt(p.memberSince));
    whatsappCtrl      = TextEditingController(text: p.whatsappNumber);
    altMobileCtrl     = TextEditingController(text: p.alternativeMobile);
    emailCtrl         = TextEditingController(text: p.email);
    fbLinkCtrl        = TextEditingController(text: p.facebookLink);
    presentAddrCtrl   = TextEditingController(text: p.presentAddress);
    permanentAddrCtrl = TextEditingController(text: p.permanentAddress);
    districtCtrl      = TextEditingController(text: p.district);
    upazilaCtrl       = TextEditingController(text: p.upazila);
    lastDonationCtrl  = TextEditingController(text: _fmt(p.lastDonationDate));
    nextDonationCtrl  = TextEditingController(text: _fmt(p.nextAvailableDonationDate));
    eligibilityCtrl   = TextEditingController(text: p.donationEligibility);
    donationCountCtrl = TextEditingController(text: p.totalDonationCount?.toString());
    prefLocationCtrl  = TextEditingController(text: p.preferredDonationLocation);
    latCtrl           = TextEditingController(text: p.latitude?.toString());
    lngCtrl           = TextEditingController(text: p.longitude?.toString());
    addressCtrl       = TextEditingController(text: p.locationDms);
    committeePosCtrl  = TextEditingController(text: p.committeePosition);

    schoolNameCtrl  = TextEditingController(text: p.schoolName);
    schoolGroupCtrl = TextEditingController(text: p.schoolGroup);
    schoolYearCtrl  = TextEditingController(text: p.schoolPassingYear?.toString());
    collegeNameCtrl = TextEditingController(text: p.collegeName);
    collegeGroupCtrl= TextEditingController(text: p.collegeGroup);
    collegeYearCtrl = TextEditingController(text: p.collegePassingYear?.toString());
    uniNameCtrl     = TextEditingController(text: p.universityName);
    deptCtrl        = TextEditingController(text: p.department);
    studentIdCtrl   = TextEditingController(text: p.studentId);
    currYearCtrl    = TextEditingController(text: p.currentYear?.toString());
    currSemCtrl     = TextEditingController(text: p.currentSemester?.toString());
    bioCtrl         = TextEditingController(text: p.shortBio);
    whyJoinedCtrl   = TextEditingController(text: p.whyJoined);
    goalsCtrl       = TextEditingController(text: p.futureGoals);
    hobbiesCtrl     = TextEditingController(text: p.hobbies);
    fbUserCtrl      = TextEditingController(text: p.facebook);
    portfolioCtrl   = TextEditingController(text: p.portfolioWebsite);
    presentNoteCtrl = TextEditingController(text: p.presentCommitteeNote);

    tenureFromCtrl  = TextEditingController(text: p.tenureFrom?.toString());
    tenureToCtrl    = TextEditingController(text: p.tenureTo?.toString());
    previousNoteCtrl= TextEditingController(text: p.previousCommitteeNote);

    occupationCtrl  = TextEditingController(text: p.occupation);
    institutionCtrl = TextEditingController(text: p.institution);
    designationCtrl = TextEditingController(text: p.designation);
    expertiseCtrl   = TextEditingController(text: p.expertise);
    advisorNoteCtrl = TextEditingController(text: p.advisorNote);

    if (p.latitude != null && p.longitude != null) {
      _selectedLocation = LatLng(p.latitude!, p.longitude!);
    }
    _refreshMarker(_selectedLocation);
  }

  @override
  void dispose() {
    _animController.dispose();
    for (final c in [
      fullNameCtrl, fullNameBnCtrl, dobCtrl, memberSinceCtrl,
      whatsappCtrl, altMobileCtrl, emailCtrl, fbLinkCtrl,
      presentAddrCtrl, permanentAddrCtrl, districtCtrl, upazilaCtrl,
      lastDonationCtrl, nextDonationCtrl, eligibilityCtrl, donationCountCtrl,
      prefLocationCtrl, latCtrl, lngCtrl, addressCtrl, committeePosCtrl,
      schoolNameCtrl, schoolGroupCtrl, schoolYearCtrl,
      collegeNameCtrl, collegeGroupCtrl, collegeYearCtrl,
      uniNameCtrl, deptCtrl, studentIdCtrl, currYearCtrl, currSemCtrl,
      bioCtrl, whyJoinedCtrl, goalsCtrl, hobbiesCtrl,
      fbUserCtrl, portfolioCtrl, presentNoteCtrl,
      tenureFromCtrl, tenureToCtrl, previousNoteCtrl,
      occupationCtrl, institutionCtrl, designationCtrl,
      expertiseCtrl, advisorNoteCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _fmt(DateTime? d) =>
      d == null ? '' : d.toIso8601String().split('T')[0];

  String _toDMS(double lat, double lng) {
    String dir(double v, List<String> dirs) => v >= 0 ? dirs[0] : dirs[1];
    String fmt(double v) {
      v = v.abs();
      final d = v.floor();
      final m = ((v - d) * 60).floor();
      final s = (v - d - m / 60) * 3600;
      return "$d°$m'${s.toStringAsFixed(1)}\"";
    }
    return "${fmt(lat)}${dir(lat, ['N', 'S'])}, ${fmt(lng)}${dir(lng, ['E', 'W'])}";
  }

  void _refreshMarker(LatLng pos) => setState(() {
    _markers = [Marker(point: pos, width: 48, height: 48, child: const _MapPin())];
  });

  Future<void> _onMapTap(TapPosition _, LatLng pos) async {
    setState(() {
      _selectedLocation = pos;
      latCtrl.text     = pos.latitude.toStringAsFixed(6);
      lngCtrl.text     = pos.longitude.toStringAsFixed(6);
      addressCtrl.text = _toDMS(pos.latitude, pos.longitude);
    });
    _refreshMarker(pos);
  }

  Future<void> _useMyLocation() async {
    setState(() => _fetchingLocation = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _toast(_t('locationServicesDisabled'), _orange); return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        _toast(_t('locationPermissionDenied'), _red); return;
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final loc = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _selectedLocation = loc;
        latCtrl.text     = loc.latitude.toStringAsFixed(6);
        lngCtrl.text     = loc.longitude.toStringAsFixed(6);
        addressCtrl.text = _toDMS(loc.latitude, loc.longitude);
      });
      _refreshMarker(loc);
      _mapController.move(loc, 15);
    } catch (e) {
      _toast('${_t('couldNotGetLocation')}: $e', _red);
    } finally {
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }

  void _onDonationDatePicked(DateTime d) {
    final next = DateTime(d.year, d.month + 3, d.day);
    setState(() {
      nextDonationCtrl.text = _fmt(next);
      eligibilityCtrl.text  = DateTime.now().isAfter(next)
          ? _t('eligible')
          : _t('ineligible');
    });
  }

  void _toast(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.info_outline_rounded, color: Colors.white, size: 17),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(14),
    ));
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
          centerTitle: true,
          title: Text(_t('editProfile'),
              style: TextStyle(
                  color: _textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 18, letterSpacing: 0.5)),
          leading: Padding(
            padding: const EdgeInsets.all(10),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.15)),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
                    color: _textColor,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: _buildBackground(
          child: _saving
              ? _buildSavingOverlay()
              : FadeTransition(
            opacity: _fadeAnim,
            child: Form(
              key: _formKey,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(
                        height: MediaQuery.of(context).padding.top +
                            kToolbarHeight + 8),
                  ),
                  SliverToBoxAdapter(child: _buildAvatarHeader()),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        _buildFormSections(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: _saving ? null : _buildSaveFab(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  // ── Form sections ──────────────────────────────────────────────────────────

  List<Widget> _buildFormSections() {
    return [
      _sectionCard(_t('basicInformation'), Icons.person_rounded, _blue, [
        _field(_t('fullNameEN'), fullNameCtrl,
            icon: Icons.badge_outlined, required: true),
        _field(_t('fullNameBN'), fullNameBnCtrl,
            icon: Icons.translate_rounded),
        _rowPair(
          _dropdown(_t('gender'), ['Male', 'Female', 'Other'],
              _selectedGender, (v) => setState(() => _selectedGender = v)),
          _datePicker(_t('birthDate'), dobCtrl),
        ),
        _memberTypeDropdown(),
        _datePicker(_t('memberSince'), memberSinceCtrl),
        if (_isPresent) ...[
          _animatedSection(child: _dropdown(
            _t('committeePosition'), _committeePositions,
            _selectedCommitteePos, (v) => setState(() {
            _selectedCommitteePos = v;
            committeePosCtrl.text = v ?? '';
          }),
          )),
        ],
      ]),

      if (_isAdvisor)
        _animatedSection(
          child: _sectionCard(
            _t('advisorType'),
            Icons.workspace_premium_rounded,
            _gold,
            [
              Row(
                children: [
                  Expanded(
                    child: _buildSimpleAdvisorOption(
                      label: _t('chiefAdvisor'),
                      type: 'chief_advisor',
                      color: _gold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSimpleAdvisorOption(
                      label: _t('advisor'),
                      type: 'advisor',
                      color: _amber,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

      if (_isPrevious)
        _animatedSection(
          child: _sectionCard(_t('previousPositionTenure'),
              Icons.history_edu_rounded, _purple, [
                _dropdown(
                  _t('whichPosition'), _committeePositions,
                  _selectedPreviousPos,
                      (v) => setState(() => _selectedPreviousPos = v),
                ),
                _rowPair(
                  _field(_t('tenureFrom'), tenureFromCtrl,
                      icon: Icons.calendar_today_rounded, number: true),
                  _field(_t('tenureTo'), tenureToCtrl,
                      icon: Icons.event_rounded, number: true),
                ),
                _field(_t('previousMemberNote'), previousNoteCtrl,
                    icon: Icons.sticky_note_2_outlined, maxLines: 4),
              ]),
        ),

      if (_isPresent)
        _animatedSection(
          child: _sectionCard(_t('committeeNote'),
              Icons.sticky_note_2_rounded, _teal, [
                _field(_t('currentCommitteeNote'), presentNoteCtrl,
                    icon: Icons.sticky_note_2_outlined, maxLines: 4),
              ]),
        ),

      if (_isAdvisor)
        _animatedSection(
          child: _sectionCard(_t('professionalInformation'),
              Icons.work_rounded, _amber, [
                _field(_t('occupation'), occupationCtrl,
                    icon: Icons.work_outline_rounded),
                _field(_t('institution'), institutionCtrl,
                    icon: Icons.account_balance_outlined),
                _field(_t('designation'), designationCtrl,
                    icon: Icons.military_tech_outlined),
                _field(_t('expertiseField'), expertiseCtrl,
                    icon: Icons.stars_outlined, maxLines: 2),
                _field(_t('advisorNote'), advisorNoteCtrl,
                    icon: Icons.sticky_note_2_outlined, maxLines: 4),
              ]),
        ),

      _sectionCard(_t('contactDetails'), Icons.contacts_rounded, _orange, [
        _field(_t('whatsapp'), whatsappCtrl,
            icon: Icons.chat_bubble_outline_rounded),
        _field(_t('alternativeMobile'), altMobileCtrl,
            icon: Icons.phone_iphone_rounded),
        _field(_t('email'), emailCtrl, icon: Icons.email_outlined),
        _field(_t('facebookLink'), fbLinkCtrl, icon: Icons.link_rounded),
        _field(_t('presentAddress'), presentAddrCtrl,
            icon: Icons.home_outlined, maxLines: 2),
        _field(_t('permanentAddress'), permanentAddrCtrl,
            icon: Icons.location_city_outlined, maxLines: 2),
        _rowPair(
          _field(_t('district'), districtCtrl, icon: Icons.map_outlined),
          _field(_t('upazila'), upazilaCtrl, icon: Icons.explore_outlined),
        ),
      ]),

      _sectionCard(_t('bloodDonation'), Icons.favorite_rounded, _red, [
        _dropdown(_t('bloodGroup'),
            ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'],
            _selectedBloodGroup,
                (v) => setState(() => _selectedBloodGroup = v)),
        _datePicker(_t('lastDonationDate'), lastDonationCtrl, isDonation: true),
        _field(_t('totalDonationCount'), donationCountCtrl,
            icon: Icons.add_moderator_rounded, number: true),
        _field(_t('preferredLocation'), prefLocationCtrl,
            icon: Icons.pin_drop_outlined),
        _field(_t('eligibilityStatus'), eligibilityCtrl,
            icon: Icons.health_and_safety_outlined, readOnly: true),
      ]),

      if (_isCommittee) ...[
        _animatedSection(
          child: _sectionCard(_t('academicRecords'), Icons.school_rounded, _green, [
            _subLabel(_t('secondary')),
            _field(_t('school'), schoolNameCtrl, icon: Icons.school_outlined),
            _rowPair(
              _field(_t('sscGroup'), schoolGroupCtrl),
              _field(_t('passingYear'), schoolYearCtrl, number: true),
            ),
            _divider(),
            _field(_t('college'), collegeNameCtrl,
                icon: Icons.account_balance_outlined),
            _rowPair(
              _field(_t('hscGroup'), collegeGroupCtrl),
              _field(_t('passingYear'), collegeYearCtrl, number: true),
            ),
          ]),
        ),
        _animatedSection(
          child: _sectionCard(_t('universityDetails'),
              Icons.account_balance_rounded, _indigo, [
                _field(_t('university'), uniNameCtrl,
                    icon: Icons.location_city_outlined),
                _field(_t('department'), deptCtrl,
                    icon: Icons.category_outlined),
                _field(_t('studentId'), studentIdCtrl,
                    icon: Icons.fingerprint_rounded),
                _rowPair(
                  _field(_t('currentYear'), currYearCtrl, number: true),
                  _field(_t('semester'), currSemCtrl, number: true),
                ),
              ]),
        ),
        _animatedSection(
          child: _sectionCard(_t('bioSocial'), Icons.public_rounded, _purple, [
            _field(_t('shortBio'), bioCtrl,
                icon: Icons.notes_rounded, maxLines: 3),
            _field(_t('whyJoined'), whyJoinedCtrl,
                icon: Icons.flag_outlined, maxLines: 2),
            _field(_t('futureGoals'), goalsCtrl,
                icon: Icons.ads_click_rounded, maxLines: 2),
            _field(_t('hobbies'), hobbiesCtrl,
                icon: Icons.interests_outlined),
            _field(_t('facebookUsername'), fbUserCtrl,
                icon: Icons.alternate_email_rounded),
            _field(_t('portfolio'), portfolioCtrl,
                icon: Icons.language_rounded),
          ]),
        ),
      ],

      _buildMapSection(),
    ];
  }

  Widget _buildSimpleAdvisorOption({
    required String label,
    required String type,
    required Color color,
  }) {
    final isSelected = _selectedAdvisorType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedAdvisorType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : _surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : _borderColor,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: isSelected ? color : _subColor.withValues(alpha: 0.3),
              size: 20,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? _textColor : _subColor.withValues(alpha: 0.5),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _memberTypeDropdown() {
    final items = MemberType.all;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: (items.contains(_selectedMemberType)) ? _selectedMemberType : null,
        isExpanded: true,
        dropdownColor: _isDark ? const Color(0xFF152030) : Colors.white,
        style: TextStyle(color: _textColor, fontSize: 14, fontWeight: FontWeight.w500),
        decoration: _inputDecoration(_t('memberType'), Icons.badge_rounded),
        icon: Icon(Icons.keyboard_arrow_down_rounded,
            color: _subColor.withValues(alpha: 0.4), size: 20),
        items: items.map((v) => DropdownMenuItem(
          value: v,
          child: Row(children: [
            _memberTypeDot(v),
            const SizedBox(width: 10),
            Text(MemberType.label(v), overflow: TextOverflow.ellipsis),
          ]),
        )).toList(),
        onChanged: (v) => setState(() {
          _selectedMemberType = v;
          _selectedCommitteePos = null;
          _selectedPreviousPos  = null;
          committeePosCtrl.text = '';
          if (v == MemberType.advisor) {
            _selectedAdvisorType ??= 'advisor';
          }
        }),
      ),
    );
  }

  Widget _memberTypeDot(String type) {
    final color = switch (type) {
      MemberType.presentCommittee  => _teal,
      MemberType.previousCommittee => _purple,
      MemberType.advisor           => _amber,
      _                            => _blue,
    };
    return Container(
      width: 10, height: 10,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _animatedSection({required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - v)),
          child: c,
        ),
      ),
      child: child,
    );
  }

  Widget _buildBackground({required Widget child}) => Stack(children: [
    Container(
      decoration: BoxDecoration(gradient: SC.currentGradient),
    ),
    Positioned(top: -80, right: -60,
        child: _blob(260, _cyan.withValues(alpha: 0.04))),
    Positioned(bottom: 300, left: -100,
        child: _blob(240, _blue.withValues(alpha: 0.04))),
    child,
  ]);

  Widget _blob(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );

  Widget _buildSavingOverlay() => Center(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 30),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(width: 44, height: 44,
            child: CircularProgressIndicator(color: _cyan, strokeWidth: 2.5)),
        const SizedBox(height: 18),
        Text(_t('savingProfile'),
            style: TextStyle(
                color: _subColor.withValues(alpha: 0.65), fontSize: 13)),
      ]),
    ),
  );

  Widget _buildAvatarHeader() {
    final typeColor = switch (_selectedMemberType) {
      MemberType.presentCommittee  => _teal,
      MemberType.previousCommittee => _purple,
      MemberType.advisor           => _selectedAdvisorType == 'chief_advisor'
          ? _gold
          : _amber,
      _                            => _cyan,
    };

    String typeLabel = '';
    if (_selectedMemberType == MemberType.advisor && _selectedAdvisorType != null) {
      typeLabel = _advisorTypeLabel(_selectedAdvisorType!);
    } else if (_selectedMemberType != null) {
      typeLabel = MemberType.label(_selectedMemberType);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(children: [
        Stack(alignment: Alignment.center, children: [
          Container(
            width: 134, height: 134,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                  color: typeColor.withValues(alpha: 0.2),
                  blurRadius: 30, spreadRadius: 4)],
            ),
          ),
          Container(
            width: 132, height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [
                typeColor.withValues(alpha: 0.7),
                _blue.withValues(alpha: 0.4),
              ]),
            ),
            padding: const EdgeInsets.all(2.5),
            child: ClipOval(
              child: CircleAvatar(
                backgroundColor: _cardColor,
                backgroundImage: _imageBytes != null
                    ? MemoryImage(_imageBytes!)
                    : (widget.profile.profileImageUrl != null
                    ? NetworkImage(widget.profile.profileImageUrl!)
                    : null) as ImageProvider?,
                child: (_imageBytes == null &&
                    widget.profile.profileImageUrl == null)
                    ? Icon(Icons.person_rounded, size: 60,
                    color: _textColor.withValues(alpha: 0.12))
                    : null,
              ),
            ),
          ),
          Positioned(
            bottom: 4, right: 4,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: typeColor, shape: BoxShape.circle,
                  border: Border.all(color: _bgColor, width: 2.5),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: Color(0xFF060E17), size: 18),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        Text(
          fullNameCtrl.text.isNotEmpty ? fullNameCtrl.text : _t('yourName'),
          style: TextStyle(color: _textColor, fontSize: 18,
              fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
        const SizedBox(height: 6),
        if (typeLabel.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: typeColor.withValues(alpha: 0.35)),
            ),
            child: Text(
              typeLabel,
              style: TextStyle(color: typeColor, fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
      ]),
    );
  }

  Widget _buildMapSection() {
    return _sectionCard(_t('mapLocation'), Icons.map_rounded, _teal, [
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 220,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 14,
              onTap: _onMapTap,
              interactionOptions:
              const InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              TileLayer(
                urlTemplate:
                'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.yourapp.cssapp',
                retinaMode: MediaQuery.devicePixelRatioOf(context) > 1.0,
              ),
              MarkerLayer(markers: _markers),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      _field(_t('locationDMS'), addressCtrl,
          icon: Icons.my_location_rounded, readOnly: true),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _fetchingLocation ? null : _useMyLocation,
          icon: _fetchingLocation
              ? const SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2,
                  color: Color(0xFF060E17)))
              : const Icon(Icons.gps_fixed_rounded, size: 17),
          label: Text(
            _fetchingLocation ? _t('locating') : _t('useMyCurrentLocation'),
            style: const TextStyle(fontWeight: FontWeight.w700,
                fontSize: 13, letterSpacing: 0.3),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _teal,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _teal.withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(vertical: 13),
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13)),
          ),
        ),
      ),
      const SizedBox(height: 6),
      Center(
        child: Text(_t('tapMapToPlacePin'),
            style: TextStyle(
                color: _subColor.withValues(alpha: 0.4), fontSize: 11)),
      ),
    ]);
  }

  Widget _sectionCard(
      String title, IconData icon, Color accent, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: _isDark ? 0.3 : 0.07),
            blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 13),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: _borderColor)),
          ),
          child: Row(children: [
            Container(width: 3, height: 20,
                decoration: BoxDecoration(
                    color: accent, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 11),
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: accent, size: 17),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(title,
                  style: TextStyle(color: accent, fontWeight: FontWeight.w700,
                      fontSize: 14, letterSpacing: 0.3)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
          child: Column(children: children),
        ),
      ]),
    );
  }

  Widget _field(String label, TextEditingController c, {
    bool required = false,
    bool number   = false,
    bool readOnly = false,
    int  maxLines = 1,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        maxLines:   maxLines,
        readOnly:   readOnly,
        style: TextStyle(
          color: readOnly
              ? _subColor.withValues(alpha: 0.5)
              : _textColor,
          fontSize: 14, fontWeight: FontWeight.w500,
        ),
        keyboardType: number
            ? TextInputType.number
            : (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
        decoration: _inputDecoration(label, icon, readOnly: readOnly),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? _t('required') : null
            : null,
      ),
    );
  }

  Widget _dropdown(String label, List<String> items, String? value,
      void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: (value != null && items.contains(value)) ? value : null,
        isExpanded:   true,
        dropdownColor: _isDark ? const Color(0xFF152030) : Colors.white,
        menuMaxHeight: 320,
        style: TextStyle(color: _textColor, fontSize: 14, fontWeight: FontWeight.w500),
        decoration: _inputDecoration(label, null),
        icon: Icon(Icons.keyboard_arrow_down_rounded,
            color: _subColor.withValues(alpha: 0.4), size: 20),
        items: items.map((e) => DropdownMenuItem(
            value: e,
            child: Text(e, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: _textColor)))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _datePicker(String label, TextEditingController c,
      {bool isDonation = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        readOnly: true,
        style: TextStyle(color: _textColor, fontSize: 14, fontWeight: FontWeight.w500),
        decoration: _inputDecoration(label, Icons.calendar_today_rounded),
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: DateTime.tryParse(c.text) ?? DateTime.now(),
            firstDate: DateTime(1950),
            lastDate: DateTime(2100),
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(
                colorScheme: _isDark
                    ? const ColorScheme.dark(
                  primary: _cyan,
                  onPrimary: Color(0xFF060E17),
                  surface: Color(0xFF152030),
                  onSurface: Colors.white,
                )
                    : const ColorScheme.light(
                  primary: _cyan,
                  onPrimary: Color(0xFF060E17),
                  surface: Colors.white,
                  onSurface: Color(0xFF1A2332),
                ),
              ),
              child: child!,
            ),
          );
          if (d != null && mounted) {
            setState(() {
              c.text = _fmt(d);
              if (isDonation) _onDonationDatePicked(d);
            });
          }
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData? icon,
      {bool readOnly = false}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
          color: _subColor.withValues(alpha: 0.5), fontSize: 12),
      prefixIcon: icon != null
          ? Icon(icon,
          color: _cyan.withValues(alpha: readOnly ? 0.3 : 0.55), size: 18)
          : null,
      filled: true,
      fillColor: readOnly
          ? (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.02)
          : _surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: _cyan, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: _red.withValues(alpha: 0.6)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: _red, width: 1.5),
      ),
      errorStyle: const TextStyle(color: _red, fontSize: 11),
    );
  }

  Widget _rowPair(Widget a, Widget b) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: a),
        const SizedBox(width: 12),
        Expanded(child: b),
      ]);

  Widget _subLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Text(text.toUpperCase(),
          style: TextStyle(color: _cyan.withValues(alpha: 0.65),
              fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
      const SizedBox(width: 10),
      Expanded(child: Container(height: 1, color: _borderColor)),
    ]),
  );

  Widget _divider() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Divider(color: _borderColor, height: 1),
  );

  Widget _buildSaveFab() => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: _cyan.withValues(alpha: 0.3),
          blurRadius: 20, spreadRadius: -4)],
    ),
    child: FloatingActionButton.extended(
      onPressed: _saveProfile,
      backgroundColor: _cyan,
      foregroundColor: const Color(0xFF060E17),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      icon: const Icon(Icons.cloud_upload_rounded, size: 20),
      label: Text(_t('saveChanges'),
          style: const TextStyle(fontWeight: FontWeight.w800,
              fontSize: 14, letterSpacing: 0.3)),
    ),
  );

  Future<void> _pickImage() async {
    final x = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 60);
    if (x != null) {
      final b = await x.readAsBytes();
      if (mounted) setState(() => _imageBytes = b);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final p = widget.profile;

    p.fullName          = fullNameCtrl.text;
    p.fullNameBn        = fullNameBnCtrl.text;
    p.gender            = _selectedGender;
    p.dateOfBirth       = DateTime.tryParse(dobCtrl.text);
    p.memberType        = _selectedMemberType;
    p.memberSince       = DateTime.tryParse(memberSinceCtrl.text);
    p.whatsappNumber    = whatsappCtrl.text;
    p.alternativeMobile = altMobileCtrl.text;
    p.email             = emailCtrl.text;
    p.facebookLink      = fbLinkCtrl.text;
    p.presentAddress    = presentAddrCtrl.text;
    p.permanentAddress  = permanentAddrCtrl.text;
    p.district          = districtCtrl.text;
    p.upazila           = upazilaCtrl.text;
    p.bloodGroup                = _selectedBloodGroup;
    p.lastDonationDate          = DateTime.tryParse(lastDonationCtrl.text);
    p.totalDonationCount        = int.tryParse(donationCountCtrl.text);
    p.preferredDonationLocation = prefLocationCtrl.text;
    p.donationEligibility       = eligibilityCtrl.text;
    p.latitude          = double.tryParse(latCtrl.text);
    p.longitude         = double.tryParse(lngCtrl.text);
    p.locationDms       = addressCtrl.text;

    if (_isPresent) {
      p.committeePosition     = committeePosCtrl.text;
      p.presentCommitteeNote  = presentNoteCtrl.text;
      p.previousPosition      = null;
      p.tenureFrom            = null;
      p.tenureTo              = null;
      p.previousCommitteeNote = null;
    }

    if (_isPrevious) {
      p.previousPosition      = _selectedPreviousPos;
      p.tenureFrom            = int.tryParse(tenureFromCtrl.text);
      p.tenureTo              = int.tryParse(tenureToCtrl.text);
      p.previousCommitteeNote = previousNoteCtrl.text;
      p.committeePosition     = null;
      p.presentCommitteeNote  = null;
    }

    if (_isAdvisor) {
      try {
        (p as dynamic).advisorType = _selectedAdvisorType ?? 'advisor';
      } catch (_) {}
      p.occupation            = occupationCtrl.text;
      p.institution           = institutionCtrl.text;
      p.designation           = designationCtrl.text;
      p.expertise             = expertiseCtrl.text;
      p.advisorNote           = advisorNoteCtrl.text;
      p.committeePosition     = null;
      p.previousPosition      = null;
      p.tenureFrom            = null;
      p.tenureTo              = null;
      p.presentCommitteeNote  = null;
      p.previousCommitteeNote = null;
    }

    if (_isCommittee) {
      p.schoolName         = schoolNameCtrl.text;
      p.schoolGroup        = schoolGroupCtrl.text;
      p.schoolPassingYear  = int.tryParse(schoolYearCtrl.text);
      p.collegeName        = collegeNameCtrl.text;
      p.collegeGroup       = collegeGroupCtrl.text;
      p.collegePassingYear = int.tryParse(collegeYearCtrl.text);
      p.universityName     = uniNameCtrl.text;
      p.department         = deptCtrl.text;
      p.studentId          = studentIdCtrl.text;
      p.currentYear        = int.tryParse(currYearCtrl.text);
      p.currentSemester    = int.tryParse(currSemCtrl.text);
      p.shortBio           = bioCtrl.text;
      p.whyJoined          = whyJoinedCtrl.text;
      p.futureGoals        = goalsCtrl.text;
      p.hobbies            = hobbiesCtrl.text;
      p.facebook           = fbUserCtrl.text;
      p.portfolioWebsite   = portfolioCtrl.text;
    }

    try {
      if (_imageBytes != null) {
        final tempFile = File(
          '${Directory.systemTemp.path}/profile_${p.id}_'
              '${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await tempFile.writeAsBytes(_imageBytes!);
        final imageUrl = await _service.uploadProfileImageFile(tempFile);
        await tempFile.delete();
        if (imageUrl != null) {
          p.profileImageUrl = imageUrl;
        }
      }

      await _service.saveProfile(p);

// ✅ Profile update log — কোন field change হয়েছে সেটা detail-এ
      await ActivityLogger.log(
        activityType: 'profile_update',
        detail: 'phone_change', // আপনি চাইলে dynamic করতে পারেন
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _toast('${_t('saveFailed')}: $e', _red);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Map pin ────────────────────────────────────────────────────────────────────

class _MapPin extends StatelessWidget {
  const _MapPin();
  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.topCenter, children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFEF5350),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.35), blurRadius: 8)],
        ),
        child: const Icon(Icons.circle, color: Colors.white, size: 10),
      ),
      Positioned(
        bottom: 0,
        child: Container(
          width: 3, height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFFEF5350),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    ]);
  }
}
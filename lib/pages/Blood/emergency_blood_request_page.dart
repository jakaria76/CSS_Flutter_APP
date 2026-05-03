import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../SettingsPage/settings_constants.dart';
import 'package:css/pages/SettingsPage/notification_helper.dart';

class EmergencyBloodRequestPage extends StatefulWidget {
  const EmergencyBloodRequestPage({super.key});

  @override
  State<EmergencyBloodRequestPage> createState() =>
      _EmergencyBloodRequestPageState();
}

class _EmergencyBloodRequestPageState extends State<EmergencyBloodRequestPage>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final _nameController     = TextEditingController();
  final _phoneController    = TextEditingController();
  final _hospitalController = TextEditingController();
  final _addressController  = TextEditingController();
  final _notesController    = TextEditingController();

  String? _selectedBloodGroup;
  int     _unitsNeeded  = 1;
  bool    _isSubmitting = false;
  bool    _submitted    = false;

  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<Offset>   _slideAnim;

  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-',
  ];

  bool  get _isDark      => SC.isDark;
  Color get _bgColor     => _isDark ? const Color(0xFF060810) : const Color(0xFFF0F4FF);
  Color get _cardColor   => _isDark ? const Color(0xFF0F1E2E) : Colors.white;
  Color get _textColor   => _isDark ? Colors.white : const Color(0xFF1A2332);
  Color get _subColor    => _isDark ? Colors.white : const Color(0xFF4A5568);
  Color get _borderColor => (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.1);
  Color get _fillColor   => (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.05);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: _slideController, curve: Curves.easeOutCubic));
    _slideController.forward();
    _prefillName();
  }

  Future<void> _prefillName() async {
    try {
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) return;
      final data = await supabase
          .from('profiles')
          .select('full_name')
          .eq('id', uid)
          .single();
      final name = data['full_name'] as String?;
      if (name != null && name.trim().isNotEmpty && mounted) {
        _nameController.text = name.trim();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _hospitalController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBloodGroup == null) {
      _showSnack(SC.tr('selectBloodGroupWarn'));
      return;
    }

    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      _showSnack(SC.tr('loginRequired'));
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() => _isSubmitting = true);

    try {
      // ── ১. Profile থেকে sender name নাও ──────────────────────────
      String senderName = _nameController.text.trim();
      try {
        final profileData = await supabase
            .from('profiles')
            .select('full_name')
            .eq('id', currentUser.id)
            .single();
        final profileName = profileData['full_name'] as String?;
        if (profileName != null && profileName.trim().isNotEmpty) {
          senderName = profileName.trim();
        }
      } catch (_) {}

      // ── ২. Blood request insert → inserted row এর id নাও ─────────
      //     .select('id').single() দিয়ে নিশ্চিত করা হচ্ছে যে id পাবো
      final inserted = await supabase
          .from('emergency_blood_requests')
          .insert({
        'requester_name':    _nameController.text.trim(),
        'phone':             _phoneController.text.trim(),
        'blood_group':       _selectedBloodGroup,
        'units_needed':      _unitsNeeded,
        'hospital':          _hospitalController.text.trim(),
        'address':           _addressController.text.trim(),
        'notes':             _notesController.text.trim(),
        'status':            'pending',
        'created_at':        DateTime.now().toIso8601String(),
        'donated_by':        <String>[],
        'donation_count':    0,
        'requester_user_id': currentUser.id,
      })
          .select('id')
          .single();

      // ── ৩. id কে String এ convert করো (int বা UUID দুটোই handle) ─
      final newRequestId = inserted['id']?.toString();
      debugPrint('✅ Blood request inserted. ID=$newRequestId  Sender=$senderName');

      if (newRequestId == null) {
        debugPrint('⚠️ requestId is null — notification skipped');
      } else {
        // ── ৪. সবাইকে notification পাঠাও ────────────────────────────
        await NotificationHelper.sendBloodRequest(
          excludeUserId: currentUser.id,
          requesterName: senderName,
          requestId:     newRequestId,
        );
        debugPrint('✅ Blood request notification sent');
      }

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitted    = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      debugPrint('❌ Submit error: $e');
      _showSnack(SC.tr('submitFailed'));
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: TextStyle(color: _textColor)),
      backgroundColor: _cardColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(14),
    ));
  }

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
        backgroundColor: _bgColor,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle:
          _isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (_isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: _borderColor),
              ),
              child: Icon(Icons.arrow_back_ios_new,
                  color: _textColor, size: 16),
            ),
          ),
          title: Row(mainAxisSize: MainAxisSize.min, children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Transform.scale(
                scale: 1.0 + _pulseController.value * 0.2,
                child: const Icon(Icons.emergency,
                    color: Color(0xFFFF2244), size: 20),
              ),
            ),
            const SizedBox(width: 8),
            Text(SC.tr('emergencyRequest'),
                style: TextStyle(
                    color: _textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2)),
          ]),
          centerTitle: true,
        ),
        body: Stack(children: [
          _buildBackground(),
          SafeArea(
              child: _submitted ? _buildSuccessView() : _buildForm()),
        ]),
      ),
    );
  }

  Widget _buildBackground() {
    if (!_isDark) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0F4FF), Color(0xFFE8EFFF),
              Color(0xFFEFF6FF), Color(0xFFF5F8FF)],
          ),
        ),
      );
    }
    return Stack(children: [
      Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4), radius: 1.5,
            colors: [Color(0xFF200510), Color(0xFF060810), Color(0xFF030508)],
          ),
        ),
      ),
      Positioned(
        top: 60, left: -100,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (_, __) => Container(
            width: 300, height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFFFF2244)
                    .withValues(alpha: 0.1 + _pulseController.value * 0.05),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 100, right: -60,
        child: Container(
          width: 200, height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              const Color(0xFF7C4DFF).withValues(alpha: 0.07),
              Colors.transparent,
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _buildForm() {
    return SlideTransition(
      position: _slideAnim,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Alert banner ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: const Color(0xFFFF2244).withValues(alpha: 0.08),
                  border: Border.all(
                      color: const Color(0xFFFF2244).withValues(alpha: 0.4)),
                ),
                child: Row(children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, __) => Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFF2244).withValues(
                            alpha: 0.6 + _pulseController.value * 0.4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(SC.tr('requestVisibleNote'),
                        style: TextStyle(
                            color: _subColor.withValues(alpha: 0.75),
                            fontSize: 13,
                            height: 1.5)),
                  ),
                ]),
              ),

              const SizedBox(height: 28),
              _sectionLabel(SC.tr('requesterInfo')),
              const SizedBox(height: 14),
              _buildField(
                controller: _nameController,
                label: SC.tr('fullName'),
                icon: Icons.person_outline,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? SC.tr('nameRequired')
                    : null,
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _phoneController,
                label: SC.tr('phoneNumber'),
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return SC.tr('phoneRequired');
                  if (v.trim().length < 11) return SC.tr('phoneInvalid');
                  return null;
                },
              ),

              const SizedBox(height: 28),
              _sectionLabel(SC.tr('bloodRequirement')),
              const SizedBox(height: 14),
              Text(SC.tr('bloodGroupNeeded'),
                  style: TextStyle(
                      color: _subColor.withValues(alpha: 0.55),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),

              // ── Blood group chips ──────────────────────────────
              Wrap(
                spacing: 10, runSpacing: 10,
                children: _bloodGroups.map((g) {
                  final selected = _selectedBloodGroup == g;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedBloodGroup = g);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: selected
                            ? const LinearGradient(colors: [
                          Color(0xFFFF2244), Color(0xFFFF6B8A)
                        ])
                            : null,
                        color: selected ? null : _fillColor,
                        border: Border.all(
                          color: selected
                              ? Colors.transparent
                              : _borderColor,
                          width: 1.5,
                        ),
                      ),
                      child: Text(g,
                          style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : _subColor.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w800,
                              fontSize: 14)),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              Text(SC.tr('unitsNeeded'),
                  style: TextStyle(
                      color: _subColor.withValues(alpha: 0.55),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: _fillColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _borderColor),
                ),
                child: Row(children: [
                  const Icon(Icons.bloodtype_outlined,
                      color: Color(0xFFFF6B8A), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$_unitsNeeded ${_unitsNeeded == 1 ? SC.tr('unit') : SC.tr('units')}',
                      style: TextStyle(
                          color: _textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  Row(children: [
                    _counterBtn(
                      icon: Icons.remove,
                      onTap: () {
                        if (_unitsNeeded > 1) {
                          HapticFeedback.selectionClick();
                          setState(() => _unitsNeeded--);
                        }
                      },
                      active: _unitsNeeded > 1,
                    ),
                    const SizedBox(width: 8),
                    _counterBtn(
                      icon: Icons.add,
                      onTap: () {
                        if (_unitsNeeded < 10) {
                          HapticFeedback.selectionClick();
                          setState(() => _unitsNeeded++);
                        }
                      },
                      active: _unitsNeeded < 10,
                    ),
                  ]),
                ]),
              ),

              const SizedBox(height: 28),
              _sectionLabel(SC.tr('locationLabel')),
              const SizedBox(height: 14),
              _buildField(
                controller: _hospitalController,
                label: SC.tr('hospitalName'),
                icon: Icons.local_hospital_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? SC.tr('hospitalRequired')
                    : null,
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _addressController,
                label: SC.tr('fullAddress'),
                icon: Icons.location_on_outlined,
                maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? SC.tr('addressRequired')
                    : null,
              ),

              const SizedBox(height: 28),
              _sectionLabel(SC.tr('additionalInfo')),
              const SizedBox(height: 14),
              _buildField(
                controller: _notesController,
                label: SC.tr('additionalNotes'),
                icon: Icons.notes_outlined,
                maxLines: 3,
              ),

              const SizedBox(height: 36),

              // ── Submit button ──────────────────────────────────
              GestureDetector(
                onTap: _isSubmitting ? null : _submitRequest,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: _isSubmitting
                        ? const LinearGradient(
                        colors: [Color(0xFFFF8A8A), Color(0xFFFFB3B3)])
                        : const LinearGradient(
                        colors: [Color(0xFFFF1744), Color(0xFFFF6B8A)]),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFFFF2244).withValues(
                              alpha: _isSubmitting ? 0.15 : 0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8))
                    ],
                  ),
                  child: Center(
                    child: _isSubmitting
                        ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5)),
                        SizedBox(width: 12),
                        Text('পাঠানো হচ্ছে...',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                      ],
                    )
                        : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emergency,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Text(SC.tr('sendEmergencyRequest'),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 1.5)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) => Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00E676)
                    .withValues(alpha: 0.12 + _pulseController.value * 0.08),
                border: Border.all(
                    color: const Color(0xFF00E676).withValues(alpha: 0.5),
                    width: 2),
              ),
              child: const Icon(Icons.check_circle_outline,
                  color: Color(0xFF00E676), size: 50),
            ),
          ),
          const SizedBox(height: 28),
          Text(SC.tr('requestSent'),
              style: TextStyle(
                  color: _textColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          Text(SC.tr('requestSentDesc'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _subColor.withValues(alpha: 0.55),
                  fontSize: 14,
                  height: 1.6)),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                    colors: [Color(0xFFFF2244), Color(0xFFFF6B8A)]),
              ),
              child: Text(SC.tr('goBack'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Row(children: [
      Container(
        width: 3, height: 14,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF2244), Color(0xFF7C4DFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 10),
      Text(label,
          style: TextStyle(
              color: _subColor.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2)),
    ]);
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(color: _textColor, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: _subColor.withValues(alpha: 0.45), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFFFF6B8A), size: 20),
        filled: true,
        fillColor: _fillColor,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _borderColor)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
                color: Color(0xFFFF2244), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFFF6B8A))),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
                color: Color(0xFFFF2244), width: 1.5)),
        errorStyle: const TextStyle(color: Color(0xFFFF6B8A)),
      ),
    );
  }

  Widget _counterBtn({
    required IconData icon,
    required VoidCallback onTap,
    required bool active,
  }) {
    return GestureDetector(
      onTap: active ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 34, height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? const Color(0xFFFF2244).withValues(alpha: 0.15)
              : _fillColor,
          border: Border.all(
              color: active
                  ? const Color(0xFFFF2244).withValues(alpha: 0.4)
                  : _borderColor),
        ),
        child: Icon(icon,
            size: 16,
            color: active
                ? const Color(0xFFFF6B8A)
                : _subColor.withValues(alpha: 0.25)),
      ),
    );
  }
}
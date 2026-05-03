import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'payment_page.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class EventRegisterPage extends StatefulWidget {
  final int eventId;
  final double price;
  const EventRegisterPage(
      {super.key, required this.eventId, required this.price});

  @override
  State<EventRegisterPage> createState() => _EventRegisterPageState();
}

class _EventRegisterPageState extends State<EventRegisterPage> {
  final supabase   = Supabase.instance.client;
  final _formKey   = GlobalKey<FormState>();

  final nameCtrl      = TextEditingController();
  final mobileCtrl    = TextEditingController();
  final emailCtrl     = TextEditingController();
  final instituteCtrl = TextEditingController();
  final classCtrl     = TextEditingController();
  final whyCtrl       = TextEditingController();

  String gender        = '';
  bool willVolunteer   = false;
  bool loading         = false;
  XFile? pickedFile;

  @override
  void dispose() {
    nameCtrl.dispose(); mobileCtrl.dispose(); emailCtrl.dispose();
    instituteCtrl.dispose(); classCtrl.dispose(); whyCtrl.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => pickedFile = picked);
  }

  Future<String?> uploadUserImage(String userId) async {
    if (pickedFile == null) return null;
    try {
      final bytes = await pickedFile!.readAsBytes();
      final ext   = pickedFile!.path.split('.').last;
      final path  = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await supabase.storage.from('user-images').uploadBinary(path, bytes,
          fileOptions: const FileOptions(upsert: true));
      return supabase.storage.from('user-images').getPublicUrl(path);
    } catch (e) {
      debugPrint('Image upload error: $e');
      return null;
    }
  }

  Future<void> submit() async {
    if (gender.isEmpty) {
      SC.toast(context, SC.tr('selectGender'), SC.orange);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => loading = true);
    try {
      final existing = await supabase
          .from('event_registrations')
          .select('id')
          .eq('event_id', widget.eventId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existing != null) {
        SC.toast(context, SC.tr('alreadyRegisteredMsg'), SC.orange);
        return;
      }

      if (widget.price > 0) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentPage(
              eventId: widget.eventId,
              price: widget.price,
              formData: {
                'full_name': nameCtrl.text.trim(),
                'mobile': mobileCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'gender': gender,
                'institute_name': instituteCtrl.text.trim(),
                'class_name': classCtrl.text.trim(),
                'why_join': whyCtrl.text.trim(),
                'will_volunteer': willVolunteer,
                'user_image_file': pickedFile,
              },
            ),
          ),
        );
        return;
      }

      final imageUrl = await uploadUserImage(user.id);
      await supabase.from('event_registrations').insert({
        'event_id': widget.eventId,
        'user_id': user.id,
        'full_name': nameCtrl.text.trim(),
        'mobile': mobileCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'gender': gender,
        'institute_name': instituteCtrl.text.trim(),
        'class_name': classCtrl.text.trim(),
        'will_volunteer': willVolunteer,
        'why_join': whyCtrl.text.trim(),
        'payment_method': 'Free',
        'payment_status': 'verified',
        'user_image_url': imageUrl,
      });

      if (!mounted) return;
      Navigator.pop(context);
      SC.toast(context, SC.tr('registrationSuccess'), SC.green);
    } catch (_) {
      SC.toast(context, SC.tr('somethingWrong'), SC.red);
    } finally {
      if (mounted) setState(() => loading = false);
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
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF4A5568);
    final borderColor  = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.08);
    final cardColor    = isDark ? SC.cardBg : Colors.white;

    InputDecoration inputStyle(String label, IconData icon) => InputDecoration(
      labelText: label.toUpperCase(),
      labelStyle: TextStyle(
          color: subTextColor.withValues(alpha: 0.6),
          fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      prefixIcon: Icon(icon, color: SC.cyan.withValues(alpha: 0.6), size: 20),
      filled: true,
      fillColor: isDark
          ? Colors.black.withValues(alpha: 0.2)
          : Colors.black.withValues(alpha: 0.04),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: SC.cyan)),
      errorStyle: const TextStyle(color: Colors.redAccent),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(SC.tr('registration').toUpperCase(),
              style: TextStyle(
                  fontWeight: FontWeight.w900, letterSpacing: 2,
                  fontSize: 18, color: SC.cyan)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: textColor, size: 18),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(gradient: SC.currentGradient),
          child: Stack(
            children: [
              Positioned(
                  top: 100, left: -50,
                  child: SC.blob(150, SC.cyan.withValues(alpha: 0.08))),
              SafeArea(
                child: loading
                    ? Center(child: CircularProgressIndicator(color: SC.cyan))
                    : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 20),
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (widget.price > 0)
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: Colors.orange.withOpacity(0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.payments_outlined,
                                    color: Colors.orange, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  '${SC.tr('registrationFee')}: ৳${widget.price.toInt()}',
                                  style: const TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        _buildImagePicker(isDark, borderColor),
                        const SizedBox(height: 30),
                        _buildGlassCard(isDark, borderColor, cardColor, [
                          _buildTextField(nameCtrl, SC.tr('fullName'),
                              Icons.person_outline, textColor, inputStyle),
                          _buildTextField(mobileCtrl, SC.tr('mobileNumber'),
                              Icons.phone_android_outlined, textColor, inputStyle,
                              type: TextInputType.phone),
                          _buildTextField(emailCtrl, SC.tr('emailAddress'),
                              Icons.email_outlined, textColor, inputStyle,
                              type: TextInputType.emailAddress,
                              required: false),
                          _buildGenderDropdown(textColor, subTextColor,
                              borderColor, isDark, inputStyle),
                          _buildTextField(instituteCtrl, SC.tr('instituteName'),
                              Icons.school_outlined, textColor, inputStyle),
                          _buildTextField(classCtrl, SC.tr('classYear'),
                              Icons.grade_outlined, textColor, inputStyle),
                          _buildTextField(whyCtrl, SC.tr('whyJoin'),
                              Icons.help_outline, textColor, inputStyle,
                              maxLines: 3),
                          _buildVolunteerSwitch(textColor),
                        ]),
                        const SizedBox(height: 35),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SC.cyan,
                              foregroundColor: const Color(0xFF0F2027),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 8,
                              shadowColor: SC.cyan.withValues(alpha: 0.4),
                            ),
                            onPressed: submit,
                            child: Text(
                              widget.price > 0
                                  ? SC.tr('proceedToPayment').toUpperCase()
                                  : SC.tr('registerForFree').toUpperCase(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 50),
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

  Widget _buildGlassCard(bool isDark, Color borderColor, Color cardColor,
      List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: borderColor),
          ),
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _buildImagePicker(bool isDark, Color borderColor) {
    return Center(
      child: Stack(
        children: [
          Container(
            height: 120, width: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: SC.cyan, width: 2),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04),
            ),
            child: ClipOval(child: _renderImage()),
          ),
          Positioned(
            bottom: 0, right: 0,
            child: GestureDetector(
              onTap: pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration:
                BoxDecoration(color: SC.cyan, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt,
                    color: Color(0xFF0F2027), size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderImage() {
    if (pickedFile == null) {
      return Icon(Icons.person_add_alt_1_outlined, color: SC.cyan, size: 40);
    }
    return kIsWeb
        ? Image.network(pickedFile!.path, fit: BoxFit.cover)
        : Image.file(File(pickedFile!.path), fit: BoxFit.cover);
  }

  Widget _buildTextField(
      TextEditingController ctrl,
      String label,
      IconData icon,
      Color textColor,
      InputDecoration Function(String, IconData) inputStyle, {
        TextInputType type = TextInputType.text,
        bool required = true,
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        maxLines: maxLines,
        style: TextStyle(color: textColor, fontSize: 15),
        decoration: inputStyle(label, icon),
        validator: required ? (v) => v!.isEmpty ? SC.tr('required') : null : null,
      ),
    );
  }

  Widget _buildGenderDropdown(
      Color textColor,
      Color subTextColor,
      Color borderColor,
      bool isDark,
      InputDecoration Function(String, IconData) inputStyle,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        value: gender.isEmpty ? null : gender,
        dropdownColor: isDark ? SC.cardBg : Colors.white,
        style: TextStyle(color: textColor),
        decoration: inputStyle(SC.tr('gender'), Icons.wc),
        items: ['Male', 'Female', 'Other']
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) => setState(() => gender = v ?? ''),
      ),
    );
  }

  Widget _buildVolunteerSwitch(Color textColor) {
    return Row(
      children: [
        Icon(Icons.volunteer_activism_outlined,
            color: SC.cyan.withValues(alpha: 0.6), size: 20),
        const SizedBox(width: 12),
        Expanded(
            child: Text(SC.tr('wantToVolunteer'),
                style: TextStyle(color: textColor.withValues(alpha: 0.8),
                    fontSize: 14))),
        Switch(
          value: willVolunteer,
          activeColor: SC.cyan,
          onChanged: (v) => setState(() => willVolunteer = v),
        ),
      ],
    );
  }
}
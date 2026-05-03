import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart'; // পাথ নিশ্চিত করুন

class RegistrationForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController mobileCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController instituteCtrl;
  final TextEditingController classCtrl;
  final TextEditingController whyCtrl;
  final String gender;
  final bool willVolunteer;
  final ValueChanged<String?> onGenderChanged;
  final ValueChanged<bool?> onVolunteerChanged;
  final VoidCallback onPickImage;
  final VoidCallback onSubmit;
  final bool isPaid;
  final bool hasImage;

  const RegistrationForm({
    super.key,
    required this.formKey,
    required this.nameCtrl,
    required this.mobileCtrl,
    required this.emailCtrl,
    required this.instituteCtrl,
    required this.classCtrl,
    required this.whyCtrl,
    required this.gender,
    required this.willVolunteer,
    required this.onGenderChanged,
    required this.onVolunteerChanged,
    required this.onPickImage,
    required this.onSubmit,
    required this.isPaid,
    this.hasImage = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (context, __, ___) => _buildForm(context),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final isDark = SC.isDark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final fieldFillColor = isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.08);

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGlassSection(isDark, [
            _buildField(nameCtrl, SC.tr('full_name'), Icons.person_outline, isDark, textColor, fieldFillColor, borderColor),
            _buildField(mobileCtrl, SC.tr('mobile_number'), Icons.phone_android_outlined, isDark, textColor, fieldFillColor, borderColor, type: TextInputType.phone),
            _buildField(emailCtrl, SC.tr('email_address'), Icons.email_outlined, isDark, textColor, fieldFillColor, borderColor, type: TextInputType.emailAddress, required: false),

            _buildDropdown(isDark, textColor, fieldFillColor, borderColor),

            _buildField(instituteCtrl, SC.tr('institute_name'), Icons.school_outlined, isDark, textColor, fieldFillColor, borderColor),
            _buildField(classCtrl, SC.tr('class_year'), Icons.grade_outlined, isDark, textColor, fieldFillColor, borderColor),
            _buildField(whyCtrl, SC.tr('why_join'), Icons.chat_bubble_outline, isDark, textColor, fieldFillColor, borderColor, maxLines: 3),

            _buildVolunteerTile(isDark, textColor),
          ]),
          const SizedBox(height: 25),
          _buildActionButtons(isDark, textColor),
        ],
      ),
    );
  }

  Widget _buildGlassSection(bool isDark, List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
          ),
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, bool isDark, Color textColor, Color fill, Color border, {TextInputType type = TextInputType.text, bool required = true, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        maxLines: maxLines,
        style: TextStyle(color: textColor, fontSize: 14),
        decoration: InputDecoration(
          labelText: label.toUpperCase(),
          labelStyle: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1),
          prefixIcon: Icon(icon, color: SC.cyan.withValues(alpha: 0.6), size: 18),
          filled: true,
          fillColor: fill,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: SC.cyan, width: 1)),
        ),
        validator: required ? (v) => v == null || v.trim().isEmpty ? SC.tr('required_error') : null : null,
      ),
    );
  }

  Widget _buildDropdown(bool isDark, Color textColor, Color fill, Color border) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: gender.isEmpty ? null : gender,
        dropdownColor: isDark ? const Color(0xFF203A43) : Colors.white,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          labelText: SC.tr('gender_label'),
          labelStyle: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.bold),
          prefixIcon: Icon(Icons.wc, color: SC.cyan.withValues(alpha: 0.6), size: 18),
          filled: true,
          fillColor: fill,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: SC.cyan)),
        ),
        items: [
          DropdownMenuItem(value: 'Male', child: Text(SC.tr('male'))),
          DropdownMenuItem(value: 'Female', child: Text(SC.tr('female'))),
          DropdownMenuItem(value: 'Other', child: Text(SC.tr('other'))),
        ],
        onChanged: onGenderChanged,
      ),
    );
  }

  Widget _buildVolunteerTile(bool isDark, Color textColor) {
    return Theme(
      data: ThemeData(unselectedWidgetColor: textColor.withValues(alpha: 0.4)),
      child: CheckboxListTile(
        value: willVolunteer,
        onChanged: onVolunteerChanged,
        title: Text(SC.tr('want_volunteer'), style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 13)),
        activeColor: SC.cyan,
        checkColor: isDark ? const Color(0xFF0F2027) : Colors.white,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  Widget _buildActionButtons(bool isDark, Color textColor) {
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: onPickImage,
          icon: Icon(hasImage ? Icons.check_circle : Icons.add_a_photo_outlined, color: hasImage ? SC.green : SC.cyan),
          label: Text(hasImage ? SC.tr('photo_selected') : SC.tr('upload_photo'), style: const TextStyle(letterSpacing: 1)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            side: BorderSide(color: hasImage ? SC.green.withValues(alpha: 0.5) : SC.cyan.withValues(alpha: 0.3)),
            foregroundColor: textColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: SC.cyan,
              foregroundColor: isDark ? const Color(0xFF0F2027) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 8,
              shadowColor: SC.cyan.withValues(alpha: 0.4),
            ),
            child: Text(
              isPaid ? SC.tr('proceed_payment') : SC.tr('register_free'),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}
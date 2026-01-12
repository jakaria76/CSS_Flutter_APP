import 'dart:ui';
import 'package:flutter/material.dart';

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
  final bool hasImage; // ছবি সিলেক্ট করা হয়েছে কিনা তা বোঝার জন্য নতুন প্যারামিটার

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
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // গ্লাস কার্ডের ভেতরে ইনপুট ফিল্ডগুলো রাখা হয়েছে
          _buildGlassSection([
            _buildField(nameCtrl, 'Full Name', Icons.person_outline),
            _buildField(mobileCtrl, 'Mobile Number', Icons.phone_android_outlined, type: TextInputType.phone),
            _buildField(emailCtrl, 'Email Address', Icons.email_outlined, type: TextInputType.emailAddress, required: false),

            _buildDropdown(),

            _buildField(instituteCtrl, 'Institute Name', Icons.school_outlined),
            _buildField(classCtrl, 'Class / Year', Icons.grade_outlined),
            _buildField(whyCtrl, 'Why do you want to join?', Icons.chat_bubble_outline, maxLines: 3),

            _buildVolunteerTile(),
          ]),

          const SizedBox(height: 25),

          // ফটো আপলোড এবং সাবমিট বাটন সেকশন
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildGlassSection(List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {TextInputType type = TextInputType.text, bool required = true, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label.toUpperCase(),
          labelStyle: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1),
          prefixIcon: Icon(icon, color: Colors.cyanAccent.withOpacity(0.6), size: 18),
          filled: true,
          fillColor: Colors.black.withOpacity(0.2),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.cyanAccent, width: 1)),
        ),
        validator: required ? (v) => v == null || v.trim().isEmpty ? 'Required' : null : null,
      ),
    );
  }

  Widget _buildDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: gender.isEmpty ? null : gender,
        dropdownColor: const Color(0xFF203A43),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'GENDER',
          labelStyle: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
          prefixIcon: Icon(Icons.wc, color: Colors.cyanAccent.withOpacity(0.6), size: 18),
          filled: true,
          fillColor: Colors.black.withOpacity(0.2),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.cyanAccent)),
        ),
        items: const [
          DropdownMenuItem(value: 'Male', child: Text('Male')),
          DropdownMenuItem(value: 'Female', child: Text('Female')),
          DropdownMenuItem(value: 'Other', child: Text('Other')),
        ],
        onChanged: onGenderChanged,
      ),
    );
  }

  Widget _buildVolunteerTile() {
    return Theme(
      data: ThemeData(unselectedWidgetColor: Colors.white38),
      child: CheckboxListTile(
        value: willVolunteer,
        onChanged: onVolunteerChanged,
        title: const Text('I want to volunteer', style: TextStyle(color: Colors.white70, fontSize: 13)),
        activeColor: Colors.cyanAccent,
        checkColor: const Color(0xFF0F2027),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // ফটো আপলোড বাটন
        OutlinedButton.icon(
          onPressed: onPickImage,
          icon: Icon(hasImage ? Icons.check_circle : Icons.add_a_photo_outlined, color: hasImage ? Colors.greenAccent : Colors.cyanAccent),
          label: Text(hasImage ? 'PHOTO SELECTED' : 'UPLOAD PHOTO', style: const TextStyle(letterSpacing: 1)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            side: BorderSide(color: hasImage ? Colors.greenAccent.withOpacity(0.5) : Colors.cyanAccent.withOpacity(0.3)),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        const SizedBox(height: 20),

        // মেইন সাবমিট বাটন
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: const Color(0xFF0F2027),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 8,
              shadowColor: Colors.cyanAccent.withOpacity(0.4),
            ),
            child: Text(
              isPaid ? 'PROCEED TO PAYMENT' : 'REGISTER FOR FREE',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}
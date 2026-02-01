import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart'; // kIsWeb এর জন্য প্রয়োজন
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventRegisterPage extends StatefulWidget {
  final int eventId;
  final double price;

  const EventRegisterPage({
    super.key,
    required this.eventId,
    required this.price,
  });

  @override
  State<EventRegisterPage> createState() => _EventRegisterPageState();
}

class _EventRegisterPageState extends State<EventRegisterPage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final instituteCtrl = TextEditingController();
  final classCtrl = TextEditingController();
  final whyCtrl = TextEditingController();

  String gender = '';
  bool willVolunteer = false;
  bool loading = false;

  // XFile ব্যবহার করা হয়েছে যাতে Web ও Mobile উভয়ই সাপোর্ট করে
  XFile? pickedFile;

  @override
  void dispose() {
    nameCtrl.dispose();
    mobileCtrl.dispose();
    emailCtrl.dispose();
    instituteCtrl.dispose();
    classCtrl.dispose();
    whyCtrl.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() {
        pickedFile = picked;
      });
    }
  }

  Future<String?> uploadUserImage(String userId) async {
    if (pickedFile == null) return null;
    try {
      final bytes = await pickedFile!.readAsBytes();
      final fileExt = pickedFile!.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final path = '$userId/$fileName';

      // uploadBinary ব্যবহার করা হয়েছে যা সব প্ল্যাটফর্মের জন্য নিরাপদ
      await supabase.storage.from('user-images').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );

      return supabase.storage.from('user-images').getPublicUrl(path);
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  Future<void> submit() async {
    if (gender.isEmpty) {
      showMsg('Please select your gender');
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
        if (mounted) setState(() => loading = false);
        showMsg('You are already registered!');
        return;
      }

      String? imageUrl = await uploadUserImage(user.id);

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
        'payment_method': widget.price > 0 ? 'Paid' : 'Free',
        'user_image_url': imageUrl,
      });

      if (mounted) {
        Navigator.pop(context);
        showMsg('Registration successful!');
      }
    } catch (e) {
      showMsg('Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.cyanAccent.withValues(alpha: 0.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('REGISTRATION ', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(top: 100, left: -50, child: _blurCircle(150, Colors.cyanAccent.withValues(alpha: 0.1))),

            SafeArea(
              child: loading
                  ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                  : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildImagePicker(),
                      const SizedBox(height: 30),
                      _buildGlassCard([
                        _buildTextField(nameCtrl, 'Full Name', Icons.person_outline),
                        _buildTextField(mobileCtrl, 'Mobile Number', Icons.phone_android_outlined, type: TextInputType.phone),
                        _buildTextField(emailCtrl, 'Email Address', Icons.email_outlined, type: TextInputType.emailAddress, required: false),
                        _buildGenderDropdown(),
                        _buildTextField(instituteCtrl, 'Institute Name', Icons.school_outlined),
                        _buildTextField(classCtrl, 'Class / Year', Icons.grade_outlined),
                        _buildTextField(whyCtrl, 'Why do you want to join?', Icons.help_outline, maxLines: 3),
                        _buildVolunteerSwitch(),
                      ]),
                      const SizedBox(height: 35),
                      _buildSubmitButton(),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard(List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(children: children),
        ),
      ),
    );
  }

  // ইমপ্রুভড ইমেজ পিকার উইজেট
  Widget _buildImagePicker() {
    return Center(
      child: Stack(
        children: [
          Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.cyanAccent, width: 2),
              color: Colors.white.withValues(alpha: 0.05),
            ),
            child: ClipOval(
              child: _renderImage(),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.cyanAccent, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, color: Color(0xFF0F2027), size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // এই ফাংশনটি ইমেজ রেন্ডার করার সমস্যা সমাধান করে
  Widget _renderImage() {
    if (pickedFile == null) {
      return const Icon(Icons.person_add_alt_1_outlined, color: Colors.cyanAccent, size: 40);
    }

    if (kIsWeb) {
      return Image.network(pickedFile!.path, fit: BoxFit.cover);
    } else {
      return Image.file(File(pickedFile!.path), fit: BoxFit.cover);
    }
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {TextInputType type = TextInputType.text, bool required = true, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          labelText: label.toUpperCase(),
          labelStyle: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          prefixIcon: Icon(icon, color: Colors.cyanAccent.withValues(alpha: 0.6), size: 20),
          filled: true,
          fillColor: Colors.black.withValues(alpha: 0.2),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.cyanAccent)),
          errorStyle: const TextStyle(color: Colors.redAccent),
        ),
        validator: required ? (v) => v!.isEmpty ? 'Required' : null : null,
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        value: gender.isEmpty ? null : gender,
        dropdownColor: const Color(0xFF203A43),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'GENDER',
          labelStyle: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
          prefixIcon: Icon(Icons.wc, color: Colors.cyanAccent.withValues(alpha: 0.6), size: 20),
          filled: true,
          fillColor: Colors.black.withValues(alpha: 0.2),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.cyanAccent)),
        ),
        items: ['Male', 'Female', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (v) => setState(() => gender = v ?? ''),
      ),
    );
  }

  Widget _buildVolunteerSwitch() {
    return Row(
      children: [
        Icon(Icons.volunteer_activism_outlined, color: Colors.cyanAccent.withValues(alpha: 0.6), size: 20),
        const SizedBox(width: 12),
        const Expanded(child: Text('Want to volunteer?', style: TextStyle(color: Colors.white70, fontSize: 14))),
        Switch(
          value: willVolunteer,
          activeColor: Colors.cyanAccent,
          onChanged: (v) => setState(() => willVolunteer = v),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyanAccent,
          foregroundColor: const Color(0xFF0F2027),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          shadowColor: Colors.cyanAccent.withValues(alpha: 0.4),
        ),
        onPressed: submit,
        child: Text(
          widget.price > 0 ? 'PROCEED TO PAYMENT' : 'REGISTER FOR FREE',
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
      ),
    );
  }

  Widget _blurCircle(double size, Color color) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}
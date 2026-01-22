import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart'; // প্ল্যাটফর্ম চেক করার জন্য (kIsWeb)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers
  final titleCtrl = TextEditingController();
  final tagCtrl = TextEditingController();
  final shortDescCtrl = TextEditingController();
  final fullDescCtrl = TextEditingController();
  final venueCtrl = TextEditingController();
  final latCtrl = TextEditingController();
  final lngCtrl = TextEditingController();
  final priceCtrl = TextEditingController(text: '0');

  DateTime? startDate;
  DateTime? endDate;

  bool isPublished = false;
  bool isFeatured = false;
  bool loading = false;

  XFile? bannerImage;
  final List<XFile> galleryImages = [];

  @override
  void dispose() {
    titleCtrl.dispose();
    tagCtrl.dispose();
    shortDescCtrl.dispose();
    fullDescCtrl.dispose();
    venueCtrl.dispose();
    latCtrl.dispose();
    lngCtrl.dispose();
    priceCtrl.dispose();
    super.dispose();
  }

  // ================= IMAGE PICKERS =================

  Future<void> pickBanner() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => bannerImage = picked);
    }
  }

  Future<void> pickGalleryImages() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() => galleryImages.addAll(picked));
    }
  }

  // ================= UPLOAD FUNCTIONS =================

  Future<String?> uploadBanner() async {
    if (bannerImage == null) return null;
    final bytes = await bannerImage!.readAsBytes();
    final path = 'banners/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await supabase.storage.from('event-banners').uploadBinary(path, bytes,
        fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'));
    return supabase.storage.from('event-banners').getPublicUrl(path);
  }

  Future<void> uploadGallery(int eventId) async {
    for (final img in galleryImages) {
      try {
        final bytes = await img.readAsBytes();
        final path = '$eventId/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('event-gallery').uploadBinary(path, bytes,
            fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'));
        final url = supabase.storage.from('event-gallery').getPublicUrl(path);
        await supabase.from('event_images').insert({'event_id': eventId, 'image_url': url});
      } catch (_) {}
    }
  }

  // ================= SUBMIT =================

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (startDate == null) {
      _showMsg('Please select start date & time');
      return;
    }
    setState(() => loading = true);
    try {
      final bannerUrl = await uploadBanner();

      // 1️⃣ Event insert (সিলেক্ট করে ইভেন্ট অবজেক্টটি নেওয়া হচ্ছে)
      final event = await supabase.from('events').insert({
        'title': titleCtrl.text.trim(),
        'tag': tagCtrl.text.trim(),
        'short_description': shortDescCtrl.text.trim(),
        'full_description': fullDescCtrl.text.trim(),
        'venue': venueCtrl.text.trim(),
        'latitude': double.tryParse(latCtrl.text),
        'longitude': double.tryParse(lngCtrl.text),
        'start_datetime': startDate!.toIso8601String(),
        'end_datetime': endDate?.toIso8601String(),
        'price': double.tryParse(priceCtrl.text) ?? 0,
        'is_published': isPublished,
        'is_featured': isFeatured,
        'banner_url': bannerUrl,
      }).select().single();

      // গ্যালারি আপলোড
      await uploadGallery(event['id']);

      // 2️⃣ 🔔 Notification trigger (Edge Function-এ ডাটা পাঠানো হচ্ছে)
      await supabase.functions.invoke(
        'send_event_notification',
        body: {
          'title': event['title'],
          'description': event['short_description'],
          'event_id': event['id'],
          'banner_url': bannerUrl,
        },
      );

      if (!mounted) return;
      Navigator.pop(context);
      _showMsg('Event created & notification sent');

    } catch (e) {
      _showMsg('Failed to create event: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ================= DATE PICKER =================

  Future<void> pickDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );
    if (date == null) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) startDate = dt; else endDate = dt;
    });
  }

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.cyanAccent.withOpacity(0.8)));
  }

  // ================= UI HELPERS =================

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label.toUpperCase(),
      labelStyle: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      prefixIcon: Icon(icon, color: Colors.cyanAccent.withOpacity(0.6), size: 20),
      filled: true,
      fillColor: Colors.black.withOpacity(0.2),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.cyanAccent, width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,

        // কাস্টম ব্যাক বাটন যোগ করা হয়েছে
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05), // হালকা গ্লাস ইফেক্ট
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.cyanAccent, size: 18),
          ),
          onPressed: () => Navigator.pop(context), // পেজটি বন্ধ করে আগের পেজে যাবে
        ),

        title: const Text(
          'CREATE EVENT',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.cyanAccent,
          ),
        ),
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
            Positioned(top: 100, left: -50, child: _blurCircle(150, Colors.cyanAccent.withOpacity(0.1))),
            SafeArea(
              child: loading
                  ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                  : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('EVENT BANNER'),
                      _buildBannerPicker(),
                      const SizedBox(height: 25),
                      _buildSectionTitle('BASIC INFORMATION'),
                      _buildGlassCard([
                        TextFormField(controller: titleCtrl, style: const TextStyle(color: Colors.white), decoration: _inputStyle('Event Title', Icons.title), validator: (v) => v!.isEmpty ? 'Required' : null),
                        const SizedBox(height: 15),
                        TextFormField(controller: tagCtrl, style: const TextStyle(color: Colors.white), decoration: _inputStyle('Category Tag', Icons.label_outline)),
                        const SizedBox(height: 15),
                        TextFormField(controller: priceCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _inputStyle('Ticket Price (৳)', Icons.payments_outlined)),
                      ]),
                      const SizedBox(height: 25),
                      _buildSectionTitle('DESCRIPTIONS'),
                      _buildGlassCard([
                        TextFormField(controller: shortDescCtrl, style: const TextStyle(color: Colors.white), decoration: _inputStyle('Short Summary', Icons.short_text)),
                        const SizedBox(height: 15),
                        TextFormField(controller: fullDescCtrl, maxLines: 4, style: const TextStyle(color: Colors.white), decoration: _inputStyle('Detailed Description', Icons.description_outlined)),
                      ]),
                      const SizedBox(height: 25),
                      _buildSectionTitle('SCHEDULE & VENUE'),
                      _buildGlassCard([
                        TextFormField(controller: venueCtrl, style: const TextStyle(color: Colors.white), decoration: _inputStyle('Venue Name', Icons.location_on_outlined)),
                        const SizedBox(height: 15),
                        _buildDatePickerTile('START DATE', startDate, () => pickDate(true)),
                        const Divider(color: Colors.white10, height: 20),
                        _buildDatePickerTile('END DATE (OPTIONAL)', endDate, () => pickDate(false)),
                      ]),
                      const SizedBox(height: 25),
                      _buildSectionTitle('EVENT GALLERY'),
                      _buildGallerySection(),
                      const SizedBox(height: 25),
                      _buildGlassCard([
                        _buildSwitchTile('Publish Immediately', isPublished, (v) => setState(() => isPublished = v)),
                        _buildSwitchTile('Feature this Event', isFeatured, (v) => setState(() => isFeatured = v)),
                      ]),
                      const SizedBox(height: 40),
                      _buildSubmitButton(),
                      const SizedBox(height: 30),
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

  // ================= UI COMPONENTS =================

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(title, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.5)),
    );
  }

  Widget _buildGlassCard(List<Widget> children) {
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

  Widget _buildBannerPicker() {
    return GestureDetector(
      onTap: pickBanner,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: bannerImage != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: kIsWeb
              ? Image.network(bannerImage!.path, fit: BoxFit.cover)
              : Image.file(File(bannerImage!.path), fit: BoxFit.cover),
        )
            : const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.cyanAccent),
            SizedBox(height: 8),
            Text('Upload Event Banner', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerTile(String label, DateTime? dt, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.cyanAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.calendar_today_outlined, color: Colors.cyanAccent, size: 18),
      ),
      title: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
      subtitle: Text(dt == null ? 'Not Set' : dt.toString().substring(0, 16), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildGallerySection() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: galleryImages.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return GestureDetector(
              onTap: pickGalleryImages,
              child: Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                ),
                child: const Icon(Icons.add_a_photo_outlined, color: Colors.cyanAccent),
              ),
            );
          }
          final img = galleryImages[index - 1];
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: kIsWeb
                  ? Image.network(img.path, fit: BoxFit.cover)
                  : Image.file(File(img.path), fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool val, Function(bool) onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
      value: val,
      onChanged: onChanged,
      activeColor: Colors.cyanAccent,
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
          shadowColor: Colors.cyanAccent.withOpacity(0.4),
        ),
        onPressed: submit,
        child: const Text('CREATE EVENT NOW', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
      ),
    );
  }

  Widget _blurCircle(double size, Color color) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}
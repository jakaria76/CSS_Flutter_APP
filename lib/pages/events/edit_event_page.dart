import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditEventPage extends StatefulWidget {
  final int eventId;
  const EditEventPage({super.key, required this.eventId});

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final titleCtrl = TextEditingController();
  final tagCtrl = TextEditingController();
  final shortDescCtrl = TextEditingController();
  final fullDescCtrl = TextEditingController();
  final venueCtrl = TextEditingController();
  final latCtrl = TextEditingController();
  final lngCtrl = TextEditingController();
  final priceCtrl = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;
  bool isPublished = false;
  bool isFeatured = false;
  bool loading = true;

  String? existingBannerUrl;
  File? newBanner;
  final List<File> newGalleryImages = [];

  @override
  void initState() {
    super.initState();
    loadEvent();
  }

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

  Future<void> loadEvent() async {
    try {
      final e = await supabase
          .from('events')
          .select()
          .eq('id', widget.eventId)
          .maybeSingle();

      if (e == null) {
        showMsg('Event not found');
        Navigator.pop(context);
        return;
      }

      titleCtrl.text = e['title'] ?? '';
      tagCtrl.text = e['tag'] ?? '';
      shortDescCtrl.text = e['short_description'] ?? '';
      fullDescCtrl.text = e['full_description'] ?? '';
      venueCtrl.text = e['venue'] ?? '';
      latCtrl.text = (e['latitude'] ?? '').toString();
      lngCtrl.text = (e['longitude'] ?? '').toString();
      priceCtrl.text = (e['price'] ?? 0).toString();

      startDate = e['start_datetime'] != null ? DateTime.parse(e['start_datetime']) : null;
      endDate = e['end_datetime'] != null ? DateTime.parse(e['end_datetime']) : null;
      isPublished = e['is_published'] ?? false;
      isFeatured = e['is_featured'] ?? false;
      existingBannerUrl = e['banner_url'];
    } catch (_) {
      showMsg('Failed to load event');
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> pickBanner() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) setState(() => newBanner = File(picked.path));
  }

  Future<void> pickGalleryImages() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isNotEmpty && mounted) {
      setState(() => newGalleryImages.addAll(picked.map((e) => File(e.path))));
    }
  }

  Future<String?> uploadBannerIfNeeded() async {
    if (newBanner == null) return existingBannerUrl;
    try {
      final path = '${widget.eventId}/banner_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('event-banners').upload(path, newBanner!, fileOptions: const FileOptions(upsert: true));
      return supabase.storage.from('event-banners').getPublicUrl(path);
    } catch (_) { return existingBannerUrl; }
  }

  Future<void> uploadNewGalleryImages() async {
    for (final img in newGalleryImages) {
      try {
        final path = '${widget.eventId}/gal_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('event-gallery').upload(path, img, fileOptions: const FileOptions(upsert: true));
        final url = supabase.storage.from('event-gallery').getPublicUrl(path);
        await supabase.from('event_images').insert({'event_id': widget.eventId, 'image_url': url});
      } catch (_) {}
    }
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (startDate == null) { showMsg('Start date is required'); return; }

    setState(() => loading = true);
    try {
      final bannerUrl = await uploadBannerIfNeeded();
      await supabase.from('events').update({
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
      }).eq('id', widget.eventId);

      await uploadNewGalleryImages();
      if (!mounted) return;
      Navigator.pop(context);
      showMsg('Event updated successfully');
    } catch (_) { showMsg('Failed to update event'); } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> pickDate(bool isStart) async {
    final date = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: DateTime.now());
    if (date == null) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() { if (isStart) startDate = dt; else endDate = dt; });
  }

  void showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, backgroundColor: Colors.cyanAccent.withOpacity(0.8)));
  }

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
        title: const Text('EDIT EVENT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
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
            Positioned(bottom: -50, right: -50, child: _blurCircle(200, Colors.redAccent.withOpacity(0.05))),
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
                      _buildSectionTitle('BANNER IMAGE'),
                      _buildBannerPreview(),
                      const SizedBox(height: 25),

                      _buildSectionTitle('GENERAL DETAILS'),
                      _buildGlassCard([
                        TextFormField(controller: titleCtrl, style: const TextStyle(color: Colors.white), decoration: _inputStyle('Event Title', Icons.title), validator: (v) => v!.isEmpty ? 'Required' : null),
                        const SizedBox(height: 15),
                        TextFormField(controller: tagCtrl, style: const TextStyle(color: Colors.white), decoration: _inputStyle('Tag', Icons.label_outline)),
                        const SizedBox(height: 15),
                        TextFormField(controller: priceCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _inputStyle('Price (৳)', Icons.payments_outlined)),
                      ]),

                      const SizedBox(height: 25),
                      _buildSectionTitle('DESCRIPTION'),
                      _buildGlassCard([
                        TextFormField(controller: shortDescCtrl, style: const TextStyle(color: Colors.white), decoration: _inputStyle('Short Summary', Icons.short_text)),
                        const SizedBox(height: 15),
                        TextFormField(controller: fullDescCtrl, maxLines: 4, style: const TextStyle(color: Colors.white), decoration: _inputStyle('Full Description', Icons.description_outlined)),
                      ]),

                      const SizedBox(height: 25),
                      _buildSectionTitle('LOCATION & TIME'),
                      _buildGlassCard([
                        TextFormField(controller: venueCtrl, style: const TextStyle(color: Colors.white), decoration: _inputStyle('Venue Name', Icons.location_on_outlined)),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(child: TextFormField(controller: latCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _inputStyle('Lat', Icons.map))),
                            const SizedBox(width: 10),
                            Expanded(child: TextFormField(controller: lngCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _inputStyle('Lng', Icons.map))),
                          ],
                        ),
                        const Divider(color: Colors.white10, height: 30),
                        _buildDatePickerTile('START DATE', startDate, () => pickDate(true)),
                        _buildDatePickerTile('END DATE', endDate, () => pickDate(false)),
                      ]),

                      const SizedBox(height: 25),
                      _buildSectionTitle('SETTINGS'),
                      _buildGlassCard([
                        _buildSwitchTile('Publish Event', isPublished, (v) => setState(() => isPublished = v)),
                        _buildSwitchTile('Featured Event', isFeatured, (v) => setState(() => isFeatured = v)),
                      ]),

                      const SizedBox(height: 25),
                      _buildSectionTitle('ADD TO GALLERY'),
                      _buildGalleryPicker(),

                      const SizedBox(height: 40),
                      _buildSaveButton(),
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

  Widget _buildBannerPreview() {
    return GestureDetector(
      onTap: pickBanner,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          image: newBanner != null
              ? DecorationImage(image: FileImage(newBanner!), fit: BoxFit.cover)
              : (existingBannerUrl != null ? DecorationImage(image: NetworkImage(existingBannerUrl!), fit: BoxFit.cover) : null),
        ),
        child: Stack(
          children: [
            if (newBanner == null && existingBannerUrl == null)
              const Center(child: Icon(Icons.add_a_photo_outlined, color: Colors.cyanAccent, size: 40)),
            Positioned(
              bottom: 12, right: 12,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.cyanAccent, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, size: 18, color: Color(0xFF0F2027)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerTile(String label, DateTime? dt, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: const Icon(Icons.calendar_today_outlined, color: Colors.cyanAccent, size: 20),
      title: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
      subtitle: Text(dt == null ? 'Not Set' : dt.toString().substring(0, 16), style: const TextStyle(color: Colors.white, fontSize: 14)),
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

  Widget _buildGalleryPicker() {
    return Column(
      children: [
        if (newGalleryImages.isNotEmpty)
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: newGalleryImages.length,
              itemBuilder: (context, i) => Container(
                margin: const EdgeInsets.only(right: 10),
                width: 80,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: DecorationImage(image: FileImage(newGalleryImages[i]), fit: BoxFit.cover)),
              ),
            ),
          ),
        const SizedBox(height: 10),
        _buildActionIconButton(Icons.photo_library_outlined, 'ADD MORE IMAGES', pickGalleryImages),
      ],
    );
  }

  Widget _buildActionIconButton(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.cyanAccent,
        minimumSize: const Size(double.infinity, 50),
        side: const BorderSide(color: Colors.cyanAccent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyanAccent,
          foregroundColor: const Color(0xFF0F2027),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
        ),
        onPressed: submit,
        child: const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
      ),
    );
  }

  Widget _blurCircle(double size, Color color) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class EditEventPage extends StatefulWidget {
  final int eventId;
  const EditEventPage({super.key, required this.eventId});

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  final supabase   = Supabase.instance.client;
  final _formKey   = GlobalKey<FormState>();

  final titleCtrl      = TextEditingController();
  final tagCtrl        = TextEditingController();
  final shortDescCtrl  = TextEditingController();
  final fullDescCtrl   = TextEditingController();
  final venueCtrl      = TextEditingController();
  final latCtrl        = TextEditingController();
  final lngCtrl        = TextEditingController();
  final priceCtrl      = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;
  bool isPublished = false;
  bool isFeatured  = false;
  bool loading     = true;

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
    titleCtrl.dispose(); tagCtrl.dispose(); shortDescCtrl.dispose();
    fullDescCtrl.dispose(); venueCtrl.dispose(); latCtrl.dispose();
    lngCtrl.dispose(); priceCtrl.dispose();
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
        SC.toast(context, SC.tr('eventNotFound'), SC.red);
        Navigator.pop(context);
        return;
      }
      titleCtrl.text     = e['title'] ?? '';
      tagCtrl.text       = e['tag'] ?? '';
      shortDescCtrl.text = e['short_description'] ?? '';
      fullDescCtrl.text  = e['full_description'] ?? '';
      venueCtrl.text     = e['venue'] ?? '';
      latCtrl.text       = (e['latitude'] ?? '').toString();
      lngCtrl.text       = (e['longitude'] ?? '').toString();
      priceCtrl.text     = (e['price'] ?? 0).toString();
      startDate = e['start_datetime'] != null
          ? DateTime.parse(e['start_datetime'])
          : null;
      endDate = e['end_datetime'] != null
          ? DateTime.parse(e['end_datetime'])
          : null;
      isPublished      = e['is_published'] ?? false;
      isFeatured       = e['is_featured'] ?? false;
      existingBannerUrl = e['banner_url'];
    } catch (_) {
      SC.toast(context, SC.tr('failedLoadEvent'), SC.red);
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> pickBanner() async {
    final picked =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) setState(() => newBanner = File(picked.path));
  }

  Future<void> pickGalleryImages() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isNotEmpty && mounted) {
      setState(() =>
          newGalleryImages.addAll(picked.map((e) => File(e.path))));
    }
  }

  Future<String?> uploadBannerIfNeeded() async {
    if (newBanner == null) return existingBannerUrl;
    try {
      final path =
          '${widget.eventId}/banner_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('event-banners').upload(path, newBanner!,
          fileOptions: const FileOptions(upsert: true));
      return supabase.storage.from('event-banners').getPublicUrl(path);
    } catch (_) {
      return existingBannerUrl;
    }
  }

  Future<void> uploadNewGalleryImages() async {
    for (final img in newGalleryImages) {
      try {
        final path =
            '${widget.eventId}/gal_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('event-gallery').upload(path, img,
            fileOptions: const FileOptions(upsert: true));
        final url =
        supabase.storage.from('event-gallery').getPublicUrl(path);
        await supabase
            .from('event_images')
            .insert({'event_id': widget.eventId, 'image_url': url});
      } catch (_) {}
    }
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (startDate == null) {
      SC.toast(context, SC.tr('startDateRequired'), SC.orange);
      return;
    }
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
      SC.toast(context, SC.tr('eventUpdated'), SC.green);
    } catch (_) {
      SC.toast(context, SC.tr('failedUpdateEvt'), SC.red);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> pickDate(bool isStart) async {
    final date = await showDatePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
        initialDate: DateTime.now());
    if (date == null) return;
    final time =
    await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    final dt =
    DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() { if (isStart) startDate = dt; else endDate = dt; });
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
          borderSide: BorderSide(color: SC.cyan, width: 1.5)),
      errorStyle: const TextStyle(color: Colors.redAccent),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(SC.tr('editEvent').toUpperCase(),
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: SC.cyan)),
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
                  bottom: -50,
                  right: -50,
                  child: SC.blob(200, SC.red.withValues(alpha: 0.05))),
              SafeArea(
                child: loading
                    ? Center(child: CircularProgressIndicator(color: SC.cyan))
                    : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(SC.tr('bannerImage')),
                        _buildBannerPreview(isDark, borderColor),
                        const SizedBox(height: 25),
                        _sectionTitle(SC.tr('generalDetails')),
                        _glassCard(isDark, borderColor, cardColor, [
                          TextFormField(
                              controller: titleCtrl,
                              style: TextStyle(color: textColor),
                              decoration: inputStyle(SC.tr('eventTitle'), Icons.title),
                              validator: (v) => v!.isEmpty ? SC.tr('required') : null),
                          const SizedBox(height: 15),
                          TextFormField(
                              controller: tagCtrl,
                              style: TextStyle(color: textColor),
                              decoration: inputStyle(SC.tr('tag'), Icons.label_outline)),
                          const SizedBox(height: 15),
                          TextFormField(
                              controller: priceCtrl,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: textColor),
                              decoration: inputStyle(SC.tr('price'), Icons.payments_outlined)),
                        ]),
                        const SizedBox(height: 25),
                        _sectionTitle(SC.tr('description')),
                        _glassCard(isDark, borderColor, cardColor, [
                          TextFormField(
                              controller: shortDescCtrl,
                              style: TextStyle(color: textColor),
                              decoration: inputStyle(SC.tr('shortSummary'), Icons.short_text)),
                          const SizedBox(height: 15),
                          TextFormField(
                              controller: fullDescCtrl,
                              maxLines: 4,
                              style: TextStyle(color: textColor),
                              decoration: inputStyle(SC.tr('fullDescription'), Icons.description_outlined)),
                        ]),
                        const SizedBox(height: 25),
                        _sectionTitle(SC.tr('locationTime')),
                        _glassCard(isDark, borderColor, cardColor, [
                          TextFormField(
                              controller: venueCtrl,
                              style: TextStyle(color: textColor),
                              decoration: inputStyle(SC.tr('venueName'), Icons.location_on_outlined)),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                  child: TextFormField(
                                      controller: latCtrl,
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(color: textColor),
                                      decoration: inputStyle('Lat', Icons.map))),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: TextFormField(
                                      controller: lngCtrl,
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(color: textColor),
                                      decoration: inputStyle('Lng', Icons.map))),
                            ],
                          ),
                          Divider(color: borderColor, height: 30),
                          _dateTile(SC.tr('startDate'), startDate, textColor, subTextColor, () => pickDate(true)),
                          _dateTile(SC.tr('endDate'), endDate, textColor, subTextColor, () => pickDate(false)),
                        ]),
                        const SizedBox(height: 25),
                        _sectionTitle(SC.tr('settings')),
                        _glassCard(isDark, borderColor, cardColor, [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(SC.tr('publishEvent'),
                                style: TextStyle(color: textColor, fontSize: 14)),
                            value: isPublished,
                            onChanged: (v) => setState(() => isPublished = v),
                            activeColor: SC.cyan,
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(SC.tr('featuredEvent'),
                                style: TextStyle(color: textColor, fontSize: 14)),
                            value: isFeatured,
                            onChanged: (v) => setState(() => isFeatured = v),
                            activeColor: SC.cyan,
                          ),
                        ]),
                        const SizedBox(height: 25),
                        _sectionTitle(SC.tr('addToGallery')),
                        _buildGalleryPicker(isDark, borderColor, textColor),
                        const SizedBox(height: 40),
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
                            ),
                            onPressed: submit,
                            child: Text(SC.tr('saveChanges').toUpperCase(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2)),
                          ),
                        ),
                        const SizedBox(height: 30),
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

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10),
    child: Text(title.toUpperCase(),
        style: TextStyle(
            color: SC.cyan, fontWeight: FontWeight.bold,
            fontSize: 11, letterSpacing: 1.5)),
  );

  Widget _glassCard(bool isDark, Color borderColor, Color cardColor,
      List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
          ),
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _buildBannerPreview(bool isDark, Color borderColor) {
    return GestureDetector(
      onTap: pickBanner,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
          image: newBanner != null
              ? DecorationImage(image: FileImage(newBanner!), fit: BoxFit.cover)
              : (existingBannerUrl != null
              ? DecorationImage(
              image: NetworkImage(existingBannerUrl!),
              fit: BoxFit.cover)
              : null),
        ),
        child: Stack(
          children: [
            if (newBanner == null && existingBannerUrl == null)
              Center(child: Icon(Icons.add_a_photo_outlined,
                  color: SC.cyan, size: 40)),
            Positioned(
              bottom: 12, right: 12,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: SC.cyan, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt,
                    size: 18, color: Color(0xFF0F2027)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateTile(String label, DateTime? dt, Color textColor,
      Color subTextColor, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Icon(Icons.calendar_today_outlined, color: SC.cyan, size: 20),
      title: Text(label,
          style: TextStyle(
              color: subTextColor.withValues(alpha: 0.6),
              fontSize: 10,
              fontWeight: FontWeight.bold)),
      subtitle: Text(dt == null ? SC.tr('notSet') : dt.toString().substring(0, 16),
          style: TextStyle(color: textColor, fontSize: 14)),
    );
  }

  Widget _buildGalleryPicker(bool isDark, Color borderColor, Color textColor) {
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
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                        image: FileImage(newGalleryImages[i]),
                        fit: BoxFit.cover)),
              ),
            ),
          ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: pickGalleryImages,
          icon: const Icon(Icons.photo_library_outlined, size: 18),
          label: Text(SC.tr('addMoreImages').toUpperCase()),
          style: OutlinedButton.styleFrom(
            foregroundColor: SC.cyan,
            minimumSize: const Size(double.infinity, 50),
            side: BorderSide(color: SC.cyan),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }
}
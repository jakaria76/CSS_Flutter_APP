import 'dart:io';
import 'dart:ui';
import 'package:css/pages/SettingsPage/notification_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:css/services/cloudinary_service.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final titleCtrl       = TextEditingController();
  final tagCtrl         = TextEditingController();
  final shortDescCtrl   = TextEditingController();
  final fullDescCtrl    = TextEditingController();
  final venueCtrl       = TextEditingController();
  final latCtrl         = TextEditingController();
  final lngCtrl         = TextEditingController();
  final priceCtrl       = TextEditingController(text: '0');
  final locationDmsCtrl = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;
  bool isPublished = false;
  bool isFeatured  = false;
  bool loading     = false;
  String _loadingStep = '';

  XFile? bannerImage;
  final List<XFile> galleryImages = [];

  MapController? _mapController;
  LatLng _selectedLocation = const LatLng(23.8103, 90.4125);
  List<Marker> _markers   = [];
  bool _fetchingLocation  = false;

  @override
  void initState() {
    super.initState();
    _setInitialMarkerData(_selectedLocation);
  }

  @override
  void dispose() {
    titleCtrl.dispose(); tagCtrl.dispose(); shortDescCtrl.dispose();
    fullDescCtrl.dispose(); venueCtrl.dispose(); latCtrl.dispose();
    lngCtrl.dispose(); priceCtrl.dispose(); locationDmsCtrl.dispose();
    super.dispose();
  }

  void _setInitialMarkerData(LatLng pos) {
    _markers = [
      Marker(
        point: pos, width: 80, height: 80,
        child: const Icon(Icons.location_on, size: 50, color: Colors.redAccent),
      )
    ];
    latCtrl.text = pos.latitude.toStringAsFixed(6);
    lngCtrl.text = pos.longitude.toStringAsFixed(6);
    locationDmsCtrl.text = _convertToDMS(pos.latitude, pos.longitude);
  }

  String _convertToDMS(double lat, double lng) {
    String latDir = lat >= 0 ? 'N' : 'S';
    String lngDir = lng >= 0 ? 'E' : 'W';
    String format(double val) {
      val = val.abs();
      int d = val.floor();
      int m = ((val - d) * 60).floor();
      double s = (val - d - m / 60) * 3600;
      return "${d}°${m}'${s.toStringAsFixed(1)}\"";
    }
    return "${format(lat)}$latDir, ${format(lng)}$lngDir";
  }

  Future<void> _handleMyLocation() async {
    setState(() => _fetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw "Location service disabled.";
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw "Location permission denied";
      }
      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      await _updateMarker(LatLng(pos.latitude, pos.longitude));
    } catch (e) {
      SC.toast(context, 'Location error: $e', SC.red);
    } finally {
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }

  Future<void> _updateMarker(LatLng pos) async {
    setState(() {
      _selectedLocation = pos;
      _markers = [
        Marker(
          point: pos, width: 80, height: 80,
          child: const Icon(Icons.location_on, size: 50, color: Colors.redAccent),
        )
      ];
      latCtrl.text = pos.latitude.toStringAsFixed(6);
      lngCtrl.text = pos.longitude.toStringAsFixed(6);
      locationDmsCtrl.text = _convertToDMS(pos.latitude, pos.longitude);
    });
    _mapController?.move(pos, 15.0);
  }

  Future<void> pickBanner() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => bannerImage = picked);
  }

  Future<void> pickGalleryImages() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isNotEmpty) setState(() => galleryImages.addAll(picked));
  }

  Future<String?> uploadBanner() async {
    if (bannerImage == null) return null;
    try {
      final file = File(bannerImage!.path);
      return await CloudinaryService.uploadImage(file,
          folder: CloudinaryService.folderEvents);
    } catch (e) {
      debugPrint('Banner upload error: $e');
      return null;
    }
  }

  Future<void> uploadGallery(int eventId) async {
    for (final img in galleryImages) {
      try {
        final file = File(img.path);
        final url = await CloudinaryService.uploadImage(file,
            folder: '${CloudinaryService.folderEvents}/$eventId');
        if (url != null) {
          await supabase
              .from('event_images')
              .insert({'event_id': eventId, 'image_url': url});
        }
      } catch (e) {
        debugPrint('Gallery upload error: $e');
      }
    }
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (startDate == null) {
      SC.toast(context, SC.tr('selectStartDate'), SC.orange);
      return;
    }
    setState(() { loading = true; _loadingStep = SC.tr('uploadingBanner'); });
    try {
      final bannerUrl = await uploadBanner();
      setState(() => _loadingStep = SC.tr('savingEvent'));
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

      setState(() => _loadingStep = SC.tr('uploadingGallery'));
      await uploadGallery(event['id']);

      setState(() => _loadingStep = SC.tr('sendingEmails'));
      final session = supabase.auth.currentSession;
      if (session == null) {
        if (!mounted) return;
        Navigator.pop(context);
        return;
      }

      // ✅ Notification — session check এর পরে, email এর আগে
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        await NotificationHelper.send(
          userId: userId,
          titleKey: 'event_created',
          bodyKey: 'event_created_body',
          type: 'event_notification',
          eventId: event['id'].toString(),
        );
      }

      try {
        final result = await supabase.functions.invoke(
          'send_event_notification',
          headers: {'Authorization': 'Bearer ${session.accessToken}'},
          body: {
            'title': event['title'],
            'description': event['short_description'],
            'event_id': event['id'],
            'banner_url': bannerUrl,
            'venue': event['venue'],
            'start_datetime': event['start_datetime'],
            'price': event['price'],
          },
        );
        final sent = result.data?['sent'] ?? 0;
        final total = result.data?['total'] ?? 0;
        if (!mounted) return;
        Navigator.pop(context);
        SC.toast(context, '✅ Event created! $sent/$total email sent.', SC.green);
      } catch (_) {
        if (!mounted) return;
        Navigator.pop(context);
        SC.toast(context, '✅ Event created!', SC.green);
      }

    } catch (e) {
      SC.toast(context, '❌ Failed: $e', SC.red);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
  Future<void> pickDate(bool isStart) async {
    final date = await showDatePicker(
        context: context,
        firstDate: DateTime.now(),
        lastDate: DateTime(2100),
        initialDate: DateTime.now());
    if (date == null) return;
    final time =
    await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    final dt =
    DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() => isStart ? startDate = dt : endDate = dt);
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
    final isDark      = SC.isDark;
    final textColor   = isDark ? Colors.white : const Color(0xFF1A2332);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF4A5568);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.08);
    final cardColor   = isDark ? SC.cardBg : Colors.white;

    InputDecoration inputStyle(String label, IconData icon) {
      return InputDecoration(
        labelText: label.toUpperCase(),
        labelStyle: TextStyle(
            color: subTextColor.withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2),
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
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
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
          title: Text(
            SC.tr('createEvent').toUpperCase(),
            style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: SC.cyan),
          ),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(gradient: SC.currentGradient),
          child: Stack(
            children: [
              Positioned(
                  top: 100,
                  left: -50,
                  child: SC.blob(150, SC.cyan.withValues(alpha: 0.08))),
              SafeArea(
                child: loading
                    ? _buildLoadingOverlay(isDark)
                    : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(SC.tr('eventBanner')),
                        _buildBannerPicker(isDark, borderColor),
                        const SizedBox(height: 25),
                        _sectionTitle(SC.tr('basicInfo')),
                        _buildGlassCard(isDark, borderColor, cardColor, [
                          TextFormField(
                              controller: titleCtrl,
                              style: TextStyle(color: textColor),
                              decoration: inputStyle(SC.tr('eventTitle'), Icons.title),
                              validator: (v) => v!.isEmpty ? SC.tr('required') : null),
                          const SizedBox(height: 15),
                          TextFormField(
                              controller: tagCtrl,
                              style: TextStyle(color: textColor),
                              decoration: inputStyle(SC.tr('categoryTag'), Icons.label_outline)),
                          const SizedBox(height: 15),
                          TextFormField(
                              controller: priceCtrl,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: textColor),
                              decoration: inputStyle(SC.tr('ticketPrice'), Icons.payments_outlined)),
                        ]),
                        const SizedBox(height: 25),
                        _sectionTitle(SC.tr('descriptions')),
                        _buildGlassCard(isDark, borderColor, cardColor, [
                          TextFormField(
                              controller: shortDescCtrl,
                              style: TextStyle(color: textColor),
                              decoration: inputStyle(SC.tr('shortSummary'), Icons.short_text)),
                          const SizedBox(height: 15),
                          TextFormField(
                              controller: fullDescCtrl,
                              maxLines: 4,
                              style: TextStyle(color: textColor),
                              decoration: inputStyle(SC.tr('detailedDesc'), Icons.description_outlined)),
                        ]),
                        const SizedBox(height: 25),
                        _sectionTitle(SC.tr('scheduleVenue')),
                        _buildGlassCard(isDark, borderColor, cardColor, [
                          TextFormField(
                              controller: venueCtrl,
                              style: TextStyle(color: textColor),
                              decoration: inputStyle(SC.tr('venueName'), Icons.location_on_outlined)),
                          const SizedBox(height: 15),
                          _buildDatePickerTile(SC.tr('startDate'), startDate, textColor, subTextColor, () => pickDate(true)),
                          Divider(color: borderColor, height: 20),
                          _buildDatePickerTile(SC.tr('endDateOptional'), endDate, textColor, subTextColor, () => pickDate(false)),
                        ]),
                        const SizedBox(height: 25),
                        _sectionTitle(SC.tr('eventLocation')),
                        _buildGlassCard(isDark, borderColor, cardColor, [
                          Container(
                            height: 250,
                            margin: const EdgeInsets.only(bottom: 15),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: borderColor),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: FlutterMap(
                                key: const ValueKey('event_map'),
                                mapController: _mapController ??= MapController(),
                                options: MapOptions(
                                  initialCenter: _selectedLocation,
                                  initialZoom: 14,
                                  minZoom: 3,
                                  maxZoom: 19,
                                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                                  onTap: (_, point) => _updateMarker(point),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.yourapp.blooddonor',
                                    maxZoom: 19,
                                  ),
                                  MarkerLayer(markers: _markers),
                                  const SimpleAttributionWidget(
                                    source: Text('© OpenStreetMap contributors',
                                        style: TextStyle(fontSize: 10)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          TextFormField(
                            controller: locationDmsCtrl,
                            readOnly: true,
                            style: TextStyle(color: textColor),
                            decoration: inputStyle(SC.tr('locationDms'), Icons.my_location_rounded),
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _fetchingLocation ? null : _handleMyLocation,
                              icon: Icon(Icons.gps_fixed_rounded,
                                  size: 18,
                                  color: _fetchingLocation
                                      ? Colors.white38
                                      : const Color(0xFF0F2027)),
                              label: Text(
                                _fetchingLocation
                                    ? SC.tr('gettingLocation')
                                    : SC.tr('useMyLocation'),
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: SC.teal,
                                foregroundColor: const Color(0xFF0F2027),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 25),
                        _sectionTitle(SC.tr('eventGallery')),
                        _buildGallerySection(isDark, borderColor),
                        const SizedBox(height: 25),
                        _buildGlassCard(isDark, borderColor, cardColor, [
                          _buildSwitchTile(SC.tr('publishNow'), isPublished, textColor,
                                  (v) => setState(() => isPublished = v)),
                          _buildSwitchTile(SC.tr('featureEvent'), isFeatured, textColor,
                                  (v) => setState(() => isFeatured = v)),
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
      ),
    );
  }

  Widget _buildLoadingOverlay(bool isDark) {
    final cardColor = isDark ? SC.cardBg : Colors.white;
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: SC.cyan.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: SC.cyan),
                const SizedBox(height: 20),
                Text(SC.tr('creatingEvent').toUpperCase(),
                    style: TextStyle(
                        color: SC.cyan,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        fontSize: 13)),
                const SizedBox(height: 8),
                Text(_loadingStep,
                    style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.black.withValues(alpha: 0.4),
                        fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(title.toUpperCase(),
          style: TextStyle(
              color: SC.cyan,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.5)),
    );
  }

  Widget _buildGlassCard(bool isDark, Color borderColor, Color cardColor,
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

  Widget _buildBannerPicker(bool isDark, Color borderColor) {
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
        ),
        child: bannerImage != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: kIsWeb
              ? Image.network(bannerImage!.path, fit: BoxFit.cover)
              : Image.file(File(bannerImage!.path), fit: BoxFit.cover),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                size: 40, color: SC.cyan),
            const SizedBox(height: 8),
            Text(SC.tr('uploadBanner'),
                style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerTile(String label, DateTime? dt, Color textColor,
      Color subTextColor, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: SC.cyan.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(Icons.calendar_today_outlined, color: SC.cyan, size: 18),
      ),
      title: Text(label,
          style: TextStyle(
              color: subTextColor.withValues(alpha: 0.6),
              fontSize: 10,
              fontWeight: FontWeight.bold)),
      subtitle: Text(
          dt == null ? SC.tr('notSet') : dt.toString().substring(0, 16),
          style: TextStyle(
              color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildGallerySection(bool isDark, Color borderColor) {
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
                  color: SC.cyan.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SC.cyan.withValues(alpha: 0.3)),
                ),
                child: Icon(Icons.add_a_photo_outlined, color: SC.cyan),
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

  Widget _buildSwitchTile(
      String title, bool val, Color textColor, Function(bool) onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: TextStyle(color: textColor, fontSize: 14)),
      value: val,
      onChanged: onChanged,
      activeColor: SC.cyan,
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: SC.cyan,
          foregroundColor: const Color(0xFF0F2027),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          shadowColor: SC.cyan.withValues(alpha: 0.4),
        ),
        onPressed: submit,
        child: Text(SC.tr('createEventNow').toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
      ),
    );
  }
}
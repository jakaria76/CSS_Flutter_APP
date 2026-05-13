import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/about_models.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

const LatLng cssLocation = LatLng(24.069222, 89.801083);

class FooterSection extends StatefulWidget {
  final ContactInfo? contactInfo;
  const FooterSection({super.key, this.contactInfo});

  @override
  State<FooterSection> createState() => _FooterSectionState();
}

class _FooterSectionState extends State<FooterSection> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  bool _isSatellite = true; // default satellite

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (context, __, ___) => _buildFooter(context),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final isDark = SC.isDark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subTextColor = isDark ? Colors.white.withValues(alpha: 0.35) : const Color(0xFF4A5568);
    final cardBg = isDark ? SC.cardBg : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08);

    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        children: [
          // ── Section Label ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
            child: Row(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: SC.cyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: SC.cyan.withValues(alpha: 0.25)),
                  ),
                  child: Icon(Icons.contacts_rounded, color: SC.cyan, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      SC.tr('contact_us_title'),
                      style: TextStyle(color: SC.cyan, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2),
                    ),
                    const SizedBox(height: 3),
                    Text(SC.tr('contact_us_sub'), style: TextStyle(color: subTextColor, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),

          // ── Map Container ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildMap(isDark, borderColor),
          ),

          const SizedBox(height: 16),

          // ── Contact Cards ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildContactCards(isDark, textColor, subTextColor, cardBg, borderColor),
          ),

          const SizedBox(height: 16),

          // ── Social Row ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildSocialRow(isDark, subTextColor, cardBg, borderColor),
          ),

          const SizedBox(height: 20),

          // ── Bottom Bar ──
          _buildBottomBar(subTextColor, borderColor),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildMap(bool isDark, Color borderColor) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: cssLocation,
                initialZoom: 16,
              ),
              children: [
                // ── ১. মূল স্যাটেলাইট ইমেজ লেয়ার ──
                TileLayer(
                  urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.example.css',
                  maxNativeZoom: 19,
                ),

                // ── ২. স্যাটেলাইট মোডে থাকাকালীন নাম বা লেবেল দেখানোর লেয়ার ──
                if (_isSatellite)
                  TileLayer(
                    // ArcGIS Reference লেয়ার যা স্যাটেলাইট ইমেজের উপর রাস্তা ও নাম দেখায়
                    urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
                    userAgentPackageName: 'com.example.css',
                    backgroundColor: Colors.transparent, // স্বচ্ছ রাখা জরুরি
                    maxNativeZoom: 19,
                  )
                else
                // নরমাল মোডের জন্য Stadia বা OSM
                  TileLayer(
                    urlTemplate: 'https://tiles.stadiamaps.com/tiles/osm_bright/{z}/{x}/{y}{r}.png?api_key={api_key}',
                    additionalOptions: const {'api_key': '358e61e3-35bf-4799-8478-31851fd2ea7c'},
                    userAgentPackageName: 'com.example.css',
                    maxNativeZoom: 20,
                  ),

                // ── ৩. মার্কার ──
                MarkerLayer(
                  markers: [
                    Marker(
                      point: cssLocation,
                      width: 80, height: 80,
                      child: Icon(Icons.location_on_rounded, size: 42, color: SC.red),
                    ),
                  ],
                ),
              ],
            ),

            // ── Map type toggle chip ──
            Positioned(
              top: 14, left: 14,
              child: GestureDetector(
                onTap: () => setState(() => _isSatellite = !_isSatellite),
                child: _mapChip(
                  _isSatellite ? SC.tr('satellite_view') : SC.tr('normal_view'),
                  _isSatellite ? Icons.satellite_alt_rounded : Icons.map_rounded,
                  _isSatellite ? SC.green : SC.cyan,
                ),
              ),
            ),

            // ── Google Maps button ──
            Positioned(
              bottom: 14, left: 14,
              child: GestureDetector(
                onTap: () => launchUrl(Uri.parse(
                  'https://www.google.com/maps/search/?api=1&query=${cssLocation.latitude},${cssLocation.longitude}',
                )),
                child: _mapChip(SC.tr('open_google_maps'), Icons.open_in_new_rounded, SC.cyan),
              ),
            ),

            // ── Zoom buttons ──
            Positioned(
              bottom: 14, right: 14,
              child: Column(
                children: [
                  _zoomBtn(Icons.add_rounded, 1),
                  const SizedBox(height: 6),
                  _zoomBtn(Icons.remove_rounded, -1),
                ],
              ),
            ),

            // ── OSM Attribution ──
            if (!_isSatellite)
              Positioned(
                bottom: 4, right: 60,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '© OpenStreetMap contributors',
                    style: TextStyle(fontSize: 8, color: Colors.black87),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _mapChip(String text, IconData icon, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _zoomBtn(IconData icon, double delta) {
    return GestureDetector(
      onTap: () => _mapController.move(
        _mapController.camera.center,
        _mapController.camera.zoom + delta,
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: Colors.black87),
      ),
    );
  }

  Widget _buildContactCards(bool isDark, Color textColor, Color subTextColor, Color cardBg, Color borderColor) {
    final contact = widget.contactInfo;
    return Column(
      children: [
        _contactCard(
          icon: Icons.location_on_rounded,
          label: SC.tr('hq_label'),
          value: contact?.address ?? 'Shambhudia Chauhali, Sirajganj',
          color: SC.orange,
          isDark: isDark,
          textColor: textColor,
          borderColor: borderColor,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _contactCard(
                icon: Icons.phone_rounded,
                label: SC.tr('hotline_label'),
                value: contact?.phone ?? '01317536550',
                color: SC.green,
                isDark: isDark,
                textColor: textColor,
                borderColor: borderColor,
                onTap: () => launchUrl(Uri.parse('tel:${contact?.phone ?? "01317536550"}')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _contactCard(
                icon: Icons.alternate_email_rounded,
                label: SC.tr('email_label'),
                value: contact?.email ?? 'css@gmail.com',
                color: SC.cyan,
                isDark: isDark,
                textColor: textColor,
                borderColor: borderColor,
                onTap: () => launchUrl(Uri.parse('mailto:${contact?.email ?? "css@gmail.com"}')),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _contactCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    required Color textColor,
    required Color borderColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? color.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? color.withValues(alpha: 0.2) : borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500, height: 1.4),
              maxLines: 2,
            ),
            if (onTap != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label.contains(SC.tr('hotline_label')) ? SC.tr('call_now') : SC.tr('mail_now'),
                  style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSocialRow(bool isDark, Color subTextColor, Color cardBg, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Text(
            SC.tr('follow_us'),
            style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          _socialBtn(
            Icons.facebook_rounded,
            const Color(0xFF1877F2),
                () => launchUrl(Uri.parse('https://www.facebook.com/organizationofcss')),
          ),
          const SizedBox(width: 10),
          _socialBtn(
            Icons.language_rounded,
            SC.cyan,
                () => launchUrl(Uri.parse('https://consciousstudentsociety.site')),
          ),
        ],
      ),
    );
  }

  Widget _socialBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildBottomBar(Color subTextColor, Color borderColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: subTextColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.copyright_rounded, size: 12, color: subTextColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              SC.tr('copyright_text'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subTextColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
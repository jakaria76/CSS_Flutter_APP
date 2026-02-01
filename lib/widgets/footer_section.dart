import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart'; // ফোন ও ইমেইল ক্লিক করার জন্য এটি ব্যবহার করতে পারেন
import '../models/about_models.dart';

const LatLng cssLocation = LatLng(24.069222, 89.801083);

class FooterSection extends StatefulWidget {
  final ContactInfo? contactInfo;
  const FooterSection({super.key, this.contactInfo});

  @override
  State<FooterSection> createState() => _FooterSectionState();
}

class _FooterSectionState extends State<FooterSection> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    if (widget.contactInfo == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 40, 20, 30),
      child: Column(
        children: [
          /// ================= SATELLITE MAP (Original) =================
          Container(
            height: 280,
            margin: const EdgeInsets.only(bottom: 28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.18),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
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
                      minZoom: 4,
                      maxZoom: 18,
                      interactionOptions:
                      InteractionOptions(flags: InteractiveFlag.all),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                        userAgentPackageName: 'com.css.mobile',
                        retinaMode: true,
                      ),
                      TileLayer(
                        urlTemplate:
                        'https://services.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
                        userAgentPackageName: 'com.css.mobile',
                        retinaMode: true,
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: cssLocation,
                            width: 80,
                            height: 80,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.redAccent.withOpacity(0.6),
                                    blurRadius: 18,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.location_on_rounded,
                                size: 42,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.12),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 15,
                    left: 15,
                    child: _buildMapChip(),
                  ),
                  Positioned(
                    bottom: 15,
                    right: 15,
                    child: Column(
                      children: [
                        _zoomBtn(Icons.add, 1),
                        const SizedBox(height: 8),
                        _zoomBtn(Icons.remove, -1),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// ================= DESIGNER CONTACT CARD =================
          _buildDesignerContactCard(),
        ],
      ),
    );
  }

  /// ম্যাপের উপরের চিপ উইজেট
  Widget _buildMapChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.greenAccent, width: 0.6),
      ),
      child: const Row(
        children: [
          Icon(Icons.satellite_rounded, size: 16, color: Colors.greenAccent),
          SizedBox(width: 8),
          Text(
            "Satellite Map",
            style: TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// ম্যাপ জুম বাটন
  Widget _zoomBtn(IconData icon, double delta) {
    return GestureDetector(
      onTap: () => _mapController.move(
        _mapController.camera.center,
        _mapController.camera.zoom + delta,
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)],
        ),
        child: Icon(icon, size: 20, color: Colors.black87),
      ),
    );
  }

  /// সম্পূর্ণ নতুন ডিজাইনের কন্টাক্ট কার্ড
  Widget _buildDesignerContactCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.06),
                  Colors.white.withOpacity(0.01),
                ],
              ),
            ),
            child: Column(
              children: [
                // Header (Optional)
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "GET IN TOUCH",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // কন্টাক্ট আইটেমগুলো
                _designerFooterItem(
                  Icons.map_rounded,
                  widget.contactInfo!.address,
                  "OUR HEADQUARTERS",
                  Colors.orangeAccent,
                ),
                _buildDivider(),
                _designerFooterItem(
                  Icons.phone_iphone_rounded,
                  widget.contactInfo!.phone,
                  "DIRECT HOTLINE",
                  Colors.greenAccent,
                  onTap: () => launchUrl(Uri.parse('tel:${widget.contactInfo!.phone}')),
                ),
                _buildDivider(),
                _designerFooterItem(
                  Icons.alternate_email_rounded,
                  widget.contactInfo!.email,
                  "OFFICIAL EMAIL",
                  Colors.cyanAccent,
                  onTap: () => launchUrl(Uri.parse('mailto:${widget.contactInfo!.email}')),
                ),

                const SizedBox(height: 10),
                const Text(
                  "© 2026 CONSCIOUS STUDENT SOCIETY",
                  style: TextStyle(
                    color: Colors.white10,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _designerFooterItem(
      IconData icon, String text, String label, Color color, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withOpacity(0.1),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              // আইকন বক্স উইথ নিওন গ্লো
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: color.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(width: 18),

              // টেক্সট কন্টেন্ট
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: color.withOpacity(0.6),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // অ্যারো ইন্ডিকেটর (অপশনাল)
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: Colors.white.withOpacity(0.1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withOpacity(0.05),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
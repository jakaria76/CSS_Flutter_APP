import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Profile/profile_page.dart';

class NearestDonorsResultPage extends StatefulWidget {
  final LatLng userLocation;
  final String bloodGroup;

  const NearestDonorsResultPage({
    super.key,
    required this.userLocation,
    required this.bloodGroup,
  });

  @override
  State<NearestDonorsResultPage> createState() => _NearestDonorsResultPageState();
}

class _NearestDonorsResultPageState extends State<NearestDonorsResultPage> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  bool loading = true;
  List<Map<String, dynamic>> donors = [];
  late AnimationController _animController;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fetchDonors();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchDonors() async {
    try {
      final data = await supabase.from('profiles').select(
        'id, full_name, blood_group, latitude, longitude, alternative_mobile, donation_eligibility, profile_image_url',
      ).eq('blood_group', widget.bloodGroup);

      List<Map<String, dynamic>> temp = [];

      for (var donor in data) {
        final status = (donor['donation_eligibility'] ?? '').toString().toLowerCase();

        if (status == 'eligible' || status == 'ready') {
          if (donor['latitude'] != null && donor['longitude'] != null) {
            final distance = Geolocator.distanceBetween(
              widget.userLocation.latitude,
              widget.userLocation.longitude,
              donor['latitude'],
              donor['longitude'],
            );

            temp.add({
              "id": donor['id'],
              "name": donor['full_name'] ?? "Unknown",
              "phone": donor['alternative_mobile'] ?? "",
              "lat": donor['latitude'],
              "lng": donor['longitude'],
              "dist": distance / 1000,
              "img": donor['profile_image_url'],
            });
          }
        }
      }

      temp.sort((a, b) => a['dist'].compareTo(b['dist']));

      setState(() {
        donors = temp;
        loading = false;
      });
    } catch (e) {
      debugPrint("Fetch error: $e");
      setState(() => loading = false);
    }
  }

  Future<void> _call(String number) async {
    if (number.isEmpty) {
      _showMessage('No phone number available', isError: true);
      return;
    }
    HapticFeedback.mediumImpact();
    final uri = Uri.parse("tel:$number");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _copyNumber(String number) {
    if (number.isEmpty) {
      _showMessage('No phone number available', isError: true);
      return;
    }
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: number));
    _showMessage('Number copied!', isError: false);
  }

  void _showMessage(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? Colors.redAccent.withOpacity(0.9) : Colors.greenAccent.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<Polyline> _buildPolylines() {
    return donors.map((d) {
      return Polyline(
        points: [
          widget.userLocation,
          LatLng(d['lat'], d['lng']),
        ],
        strokeWidth: 2.5,
        color: Colors.cyanAccent.withOpacity(0.5),
        gradientColors: [
          Colors.cyanAccent.withOpacity(0.7),
          Colors.blueAccent.withOpacity(0.3),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F2027), Color(0xFF2C5364)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite, color: Colors.redAccent, size: 18),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'NEAREST ${widget.bloodGroup} DONORS',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Background Orbs
            Positioned(top: -50, right: -50, child: _blurOrb(200, Colors.redAccent.withOpacity(0.1))),
            Positioned(bottom: -80, left: -80, child: _blurOrb(250, Colors.cyanAccent.withOpacity(0.08))),

            SafeArea(
              child: loading ? _buildLoadingState() : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blurOrb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      boxShadow: [
        BoxShadow(color: color, blurRadius: 100, spreadRadius: 50),
      ],
    ),
  );

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.redAccent.withOpacity(0.2),
                  Colors.pinkAccent.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(color: Colors.redAccent, strokeWidth: 3),
          ),
          const SizedBox(height: 20),
          const Text(
            'Finding nearest donors...',
            style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        const SizedBox(height: 10),
        _buildStatsHeader(),
        const SizedBox(height: 16),
        _buildMapSection(),
        const SizedBox(height: 16),
        _buildListSection(),
      ],
    );
  }

  Widget _buildStatsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem(Icons.people_outline, '${donors.length}', 'Found'),
                Container(width: 1, height: 30, color: Colors.white24),
                _statItem(
                  Icons.location_on_outlined,
                  donors.isNotEmpty ? '${donors.first['dist'].toStringAsFixed(1)} km' : '--',
                  'Nearest',
                ),
                Container(width: 1, height: 30, color: Colors.white24),
                _statItem(Icons.bloodtype_outlined, widget.bloodGroup, 'Group'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.cyanAccent, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 260,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.15), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: widget.userLocation,
                  initialZoom: 12,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),
                  PolylineLayer(polylines: _buildPolylines()),
                  MarkerLayer(
                    markers: [
                      // User Marker
                      Marker(
                        point: widget.userLocation,
                        width: 60,
                        height: 60,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.cyanAccent.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const Icon(Icons.person_pin_circle, color: Colors.cyanAccent, size: 50),
                          ],
                        ),
                      ),
                      // Donor Markers
                      ...donors.asMap().entries.map(
                            (entry) => Marker(
                          point: LatLng(entry.value['lat'], entry.value['lng']),
                          width: 50,
                          height: 50,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const Icon(Icons.location_on, color: Colors.redAccent, size: 40),
                              Positioned(
                                top: 8,
                                child: Text(
                                  '${entry.key + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                top: 12,
                right: 12,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.map_outlined, color: Colors.cyanAccent, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${donors.length} Donors',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildListSection() {
    return Expanded(
      child: donors.isEmpty
          ? _buildEmptyState()
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.people, color: Colors.cyanAccent, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Available Donors',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: donors.length,
              itemBuilder: (context, index) {
                return FadeTransition(
                  opacity: _animController,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(0, 0.5 * (index + 1)),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _animController,
                        curve: Interval(
                          (index / donors.length) * 0.5,
                          1.0,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                    ),
                    child: _buildDonorCard(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonorCard(int index) {
    final d = donors[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProfilePage(id: d['id'])),
                  );
                },
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Rank Badge
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: index == 0
                                ? [Colors.amber, Colors.orange]
                                : [Colors.cyanAccent.withOpacity(0.3), Colors.blueAccent.withOpacity(0.2)],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: index == 0 ? Colors.amber : Colors.cyanAccent.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: index == 0 ? Colors.white : Colors.cyanAccent,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Avatar
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.cyanAccent, Colors.blueAccent],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFF0F2027),
                          backgroundImage: d['img'] != null ? NetworkImage(d['img']) : null,
                          child: d['img'] == null
                              ? Text(
                            d['name'][0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    d['name'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (index == 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Colors.amber, Colors.orange],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'NEAREST',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.redAccent, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${d['dist'].toStringAsFixed(2)} km away',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () => _copyNumber(d['phone']),
                              child: Row(
                                children: [
                                  const Icon(Icons.phone, color: Colors.cyanAccent, size: 14),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      d['phone'].isEmpty ? "No number" : d['phone'],
                                      style: const TextStyle(
                                        color: Colors.cyanAccent,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.copy, color: Colors.cyanAccent, size: 12),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Call Button
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.greenAccent, Colors.green],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.call, color: Colors.white, size: 20),
                          onPressed: () => _call(d['phone']),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.redAccent.withOpacity(0.2),
                  Colors.pinkAccent.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off, color: Colors.redAccent, size: 60),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Donors Found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No available ${widget.bloodGroup} donors found\nin your area',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
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
  State<NearestDonorsResultPage> createState() =>
      _NearestDonorsResultPageState();
}

class _NearestDonorsResultPageState extends State<NearestDonorsResultPage> {
  final supabase = Supabase.instance.client;
  bool loading = true;
  List<Map<String, dynamic>> donors = [];

  @override
  void initState() {
    super.initState();
    _fetchDonors();
  }

  Future<void> _fetchDonors() async {
    try {
      final data = await supabase
          .from('profiles')
          .select(
        'id, full_name, blood_group, latitude, longitude, alternative_mobile, donation_eligibility, profile_image_url',
      )
          .eq('blood_group', widget.bloodGroup);

      List<Map<String, dynamic>> temp = [];

      for (var donor in data) {
        final status =
        (donor['donation_eligibility'] ?? '').toString().toLowerCase();

        if (status == 'eligible' || status == 'ready') {
          if (donor['latitude'] != null &&
              donor['longitude'] != null) {
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
    if (number.isEmpty) return;
    final uri = Uri.parse("tel:$number");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _copyNumber(String number) {
    if (number.isEmpty) return;
    Clipboard.setData(ClipboardData(text: number));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Number copied to clipboard"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 🔹 Create polylines from user to all donors
  List<Polyline> _buildPolylines() {
    return donors.map((d) {
      return Polyline(
        points: [
          widget.userLocation,
          LatLng(d['lat'], d['lng']),
        ],
        strokeWidth: 3,
        color: Colors.cyanAccent.withOpacity(0.6),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "NEAREST ${widget.bloodGroup} DONORS",
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: loading
            ? const Center(
          child:
          CircularProgressIndicator(color: Colors.cyanAccent),
        )
            : Column(
          children: [
            /// MAP SECTION
            SizedBox(
              height: 240,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: widget.userLocation,
                  initialZoom: 12,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),

                  /// 🔹 LINE LAYER
                  PolylineLayer(
                    polylines: _buildPolylines(),
                  ),

                  /// MARKERS
                  MarkerLayer(
                    markers: [
                      /// USER
                      Marker(
                        point: widget.userLocation,
                        width: 50,
                        height: 50,
                        child: const Icon(
                          Icons.person_pin_circle,
                          color: Colors.cyanAccent,
                          size: 45,
                        ),
                      ),

                      /// DONORS
                      ...donors.map(
                            (d) => Marker(
                          point: LatLng(d['lat'], d['lng']),
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.redAccent,
                            size: 36,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// LIST SECTION
            Expanded(
              child: donors.isEmpty
                  ? const Center(
                child: Text(
                  "No available donors found",
                  style: TextStyle(color: Colors.white54),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: donors.length,
                itemBuilder: (_, i) {
                  final d = donors[i];
                  return Container(
                    margin:
                    const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color:
                      Colors.white.withOpacity(0.05),
                      borderRadius:
                      BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white
                              .withOpacity(0.08)),
                    ),
                    child: ListTile(
                      contentPadding:
                      const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor:
                        const Color(0xFF1A2A3A),
                        backgroundImage: d['img'] != null
                            ? NetworkImage(d['img'])
                            : null,
                        child: d['img'] == null
                            ? Text(
                          d['name'][0].toUpperCase(),
                          style: const TextStyle(
                              color:
                              Colors.cyanAccent,
                              fontWeight:
                              FontWeight.bold),
                        )
                            : null,
                      ),
                      title: Text(
                        d['name'],
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900),
                      ),
                      subtitle: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            "${d['dist'].toStringAsFixed(2)} km away",
                            style: const TextStyle(
                                color: Colors.white70),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () =>
                                _copyNumber(d['phone']),
                            child: Text(
                              d['phone'].isEmpty
                                  ? "No number"
                                  : d['phone'],
                              style: const TextStyle(
                                color: Colors.cyanAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.call,
                          color: Colors.greenAccent,
                        ),
                        onPressed: () =>
                            _call(d['phone']),
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ProfilePage(id: d['id']),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

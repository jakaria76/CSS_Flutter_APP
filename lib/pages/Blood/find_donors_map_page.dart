import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'nearest_donors_result_page.dart';

/// 🔑 JAWG MAP API KEY
/// এখানে আপনার Jawg dashboard থেকে নেওয়া token বসান
const String jawgApiKey = 'HXItpcrkdp5O9JL78V2YStGqTr3WvNclrB1nF6Hik1WPgbAxBkj1S28DfAv3AeSZ';

class FindDonorsMapPage extends StatefulWidget {
  final String bloodGroup;
  const FindDonorsMapPage({super.key, required this.bloodGroup});

  @override
  State<FindDonorsMapPage> createState() => _FindDonorsMapPageState();
}

class _FindDonorsMapPageState extends State<FindDonorsMapPage> {
  final MapController _mapController = MapController();

  LatLng? _userLoc;
  bool _loading = true;
  bool _mapReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitialLocation();
  }

  /// Load initial GPS location
  Future<void> _loadInitialLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw "Location service disabled";

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw "Location permission denied";
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userLoc = LatLng(pos.latitude, pos.longitude);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// My Location button
  Future<void> _goToMyLocation() async {
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final loc = LatLng(pos.latitude, pos.longitude);

    setState(() => _userLoc = loc);

    if (_mapReady) {
      _mapController.move(loc, 14);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "SELECT LOCATION (${widget.bloodGroup})",
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.white,
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
        child: _loading
            ? const Center(
          child:
          CircularProgressIndicator(color: Colors.cyanAccent),
        )
            : _error != null
            ? Center(
          child: Text(
            _error!,
            style:
            const TextStyle(color: Colors.redAccent),
          ),
        )
            : Stack(
          children: [
            /// MAP
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _userLoc!,
                initialZoom: 14,
                onMapReady: () {
                  _mapReady = true;
                  _mapController.move(_userLoc!, 14);
                },
                interactionOptions:
                const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
                onTap: (_, point) {
                  setState(() => _userLoc = point);
                  if (_mapReady) {
                    _mapController.move(point, 14);
                  }
                },
              ),
              children: [
                /// ✅ JAWG STREETS (COLOURFUL & SAFE)
                TileLayer(
                  urlTemplate:
                  'https://tile.jawg.io/jawg-streets/{z}/{x}/{y}.png?access-token=$jawgApiKey',
                  userAgentPackageName:
                  'com.yourapp.blooddonor',
                ),

                /// USER MARKER
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLoc!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.person_pin_circle,
                        color: Colors.cyanAccent,
                        size: 45,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            /// MY LOCATION BUTTON
            Positioned(
              right: 16,
              bottom: 120,
              child: FloatingActionButton(
                backgroundColor: Colors.cyanAccent,
                onPressed: _goToMyLocation,
                child: const Icon(
                  Icons.my_location,
                  color: Color(0xFF0F2027),
                ),
              ),
            ),

            /// SEARCH BUTTON
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          NearestDonorsResultPage(
                            userLocation: _userLoc!,
                            bloodGroup:
                            widget.bloodGroup,
                          ),
                    ),
                  );
                },
                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  Colors.cyanAccent,
                  foregroundColor:
                  const Color(0xFF0F2027),
                  padding:
                  const EdgeInsets.symmetric(
                      vertical: 14),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "SEARCH DONORS",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

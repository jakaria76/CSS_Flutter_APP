import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../SettingsPage/settings_constants.dart';
import 'nearest_donors_result_page.dart';

class FindDonorsMapPage extends StatefulWidget {
  final String bloodGroup;
  const FindDonorsMapPage({super.key, required this.bloodGroup});

  @override
  State<FindDonorsMapPage> createState() => _FindDonorsMapPageState();
}

class _FindDonorsMapPageState extends State<FindDonorsMapPage>
    with SingleTickerProviderStateMixin {
  MapController? _mapController;
  late AnimationController _animController;
  late Animation<double>   _fadeAnimation;
  late Animation<Offset>   _slideAnimation;

  LatLng? _userLoc;
  bool    _loading = true;
  String? _error;

  bool  get _isDark    => SC.isDark;
  Color get _bgColor   => _isDark ? const Color(0xFF060810) : const Color(0xFFF0F4FF);
  Color get _cardColor => _isDark ? const Color(0xFF0F1E2E) : Colors.white;
  Color get _textColor => _isDark ? Colors.white : const Color(0xFF1A2332);
  Color get _subColor  => _isDark ? Colors.white : const Color(0xFF4A5568);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: _animController, curve: Curves.easeOutCubic));
    _loadInitialLocation();
  }

  @override
  void dispose() { _animController.dispose(); super.dispose(); }

  Future<void> _loadInitialLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw SC.tr('locationOff');
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied)
        perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever)
        throw SC.tr('locationPermissionDenied');
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;
      _mapController = MapController();
      setState(() { _userLoc = LatLng(pos.latitude, pos.longitude); _loading = false; });
      _animController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _goToMyLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final loc = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() => _userLoc = loc);
      _mapController?.move(loc, 14);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(15),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (context, __, ___) => _buildScaffold(),
      ),
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: _bgColor,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: (_isDark ? Colors.black : Colors.white).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: (_isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.2)),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: _isDark ? Colors.white : const Color(0xFF1A2332)),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: (_isDark ? Colors.black : Colors.white).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Colors.cyanAccent.withValues(alpha: 0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                  color: Colors.cyanAccent, shape: BoxShape.circle),
              child: Text(widget.bloodGroup,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F2027), fontSize: 12)),
            ),
            const SizedBox(width: 10),
            Text(SC.tr('selectedLocation'),
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _textColor, fontSize: 14)),
          ]),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: _isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: _isDark
              ? const LinearGradient(
            colors: [Color(0xFF0A1128), Color(0xFF001F54), Color(0xFF034078)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          )
              : const LinearGradient(
            colors: [Color(0xFFF0F4FF), Color(0xFFE8EFFF), Color(0xFFEFF6FF)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: _loading
            ? _buildLoading()
            : _error != null
            ? _buildError()
            : _buildMap(),
      ),
    );
  }

  Widget _buildLoading() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.cyanAccent.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const CircularProgressIndicator(
            color: Colors.cyanAccent, strokeWidth: 3),
      ),
      const SizedBox(height: 24),
      Text(SC.tr('findingLocation'),
          style: TextStyle(color: _subColor.withValues(alpha: 0.7),
              fontSize: 16, fontWeight: FontWeight.w500)),
    ]),
  );

  Widget _buildError() => Center(
    child: Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3),
            width: 2),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.location_off, color: Colors.redAccent, size: 48),
        const SizedBox(height: 16),
        Text(_error!, textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent, fontSize: 16)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {
            setState(() { _loading = true; _error = null; });
            _loadInitialLocation();
          },
          icon: const Icon(Icons.refresh),
          label: Text(SC.tr('retry')),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: const Color(0xFF0F2027)),
        ),
      ]),
    ),
  );

  Widget _buildMap() {
    final userLoc = _userLoc!;
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Stack(children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: userLoc,
                initialZoom: 14,
                minZoom: 3, maxZoom: 19,
                interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all),
                onTap: (_, point) => setState(() => _userLoc = point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.yourapp.blooddonor',
                  maxZoom: 19,
                ),
                MarkerLayer(markers: [
                  Marker(
                      point: _userLoc!, width: 80, height: 80,
                      child: _PulsingMarker()),
                ]),
              ],
            ),
          ),

          // OSM Attribution
          Positioned(
            bottom: 4, left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(SC.tr('osmAttribution'),
                  style: const TextStyle(fontSize: 9, color: Colors.black87)),
            ),
          ),

          // Info card
          Positioned(
            top: 100, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (_isDark ? Colors.black : Colors.white)
                    .withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.cyanAccent.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.touch_app,
                      color: Colors.cyanAccent, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(SC.tr('tapMapToSelect'),
                      style: TextStyle(color: _textColor,
                          fontSize: 14, fontWeight: FontWeight.w500)),
                ),
              ]),
            ),
          ),

          // My location button
          Positioned(
            right: 16, bottom: 140,
            child: GestureDetector(
              onTap: _goToMyLocation,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF00B8D4)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.my_location,
                    color: Color(0xFF0F2027), size: 28),
              ),
            ),
          ),

          // Search donors button
          Positioned(
            bottom: 30, left: 20, right: 20,
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => NearestDonorsResultPage(
                    userLocation: _userLoc!,
                    bloodGroup: widget.bloodGroup),
              )),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF00B8D4)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3), width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.search,
                          color: Color(0xFF0F2027), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(SC.tr('searchDonors'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, letterSpacing: 1.5,
                            color: Color(0xFF0F2027), fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _PulsingMarker extends StatefulWidget {
  @override
  State<_PulsingMarker> createState() => _PulsingMarkerState();
}

class _PulsingMarkerState extends State<_PulsingMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))..repeat();
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 50 + (_animation.value * 30),
            height: 50 + (_animation.value * 30),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.cyanAccent
                  .withValues(alpha: 0.3 - (_animation.value * 0.3)),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.cyanAccent, shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: 0.5),
                  blurRadius: 15, spreadRadius: 3)],
            ),
            child: const Icon(Icons.person_pin,
                color: Color(0xFF0F2027), size: 30),
          ),
        ],
      ),
    );
  }
}
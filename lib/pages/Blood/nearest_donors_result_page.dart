import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../SettingsPage/settings_constants.dart';
import '../About/person_details_page.dart';

class NearestDonorsResultPage extends StatefulWidget {
  final LatLng   userLocation;
  final String   bloodGroup;
  const NearestDonorsResultPage({
    super.key, required this.userLocation, required this.bloodGroup});

  @override
  State<NearestDonorsResultPage> createState() =>
      _NearestDonorsResultPageState();
}

class _NearestDonorsResultPageState extends State<NearestDonorsResultPage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  bool loading = true;
  List<Map<String, dynamic>> donors = [];
  late AnimationController _animController;
  final MapController _mapController = MapController();

  bool  get _isDark    => SC.isDark;
  Color get _bgColor   => _isDark ? const Color(0xFF0F2027) : const Color(0xFFF0F4FF);
  Color get _cardColor => _isDark ? const Color(0xFF0F1E2E) : Colors.white;
  Color get _textColor => _isDark ? Colors.white : const Color(0xFF1A2332);
  Color get _subColor  => _isDark ? Colors.white : const Color(0xFF4A5568);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _fetchDonors();
  }

  @override
  void dispose() { _animController.dispose(); super.dispose(); }

  Future<void> _fetchDonors() async {
    try {
      final data = await supabase.from('profiles').select(
        // FIX: extra fields fetch করা হচ্ছে PersonDetailsPage এর জন্য
        'id, full_name, blood_group, latitude, longitude, alternative_mobile, '
            'donation_eligibility, profile_image_url, committee_position, '
            'short_bio, present_address, location_dms, '
            'school_name, school_group, school_passing_year, '
            'college_name, college_group, college_passing_year, '
            'university_name, department, current_year, current_semester, '
            'designation, member_type',
      ).eq('blood_group', widget.bloodGroup);

      List<Map<String, dynamic>> temp = [];
      for (var donor in data) {
        final status = (donor['donation_eligibility'] ?? '')
            .toString().toLowerCase();
        if ((status == 'eligible' || status == 'ready') &&
            donor['latitude'] != null && donor['longitude'] != null) {
          final distance = Geolocator.distanceBetween(
            widget.userLocation.latitude, widget.userLocation.longitude,
            donor['latitude'], donor['longitude'],
          );
          temp.add({
            // Basic
            'id':           donor['id'],
            'name':         donor['full_name'] ?? 'Unknown',
            'phone':        donor['alternative_mobile'] ?? '',
            'lat':          donor['latitude'],
            'lng':          donor['longitude'],
            'dist':         distance / 1000,
            'img':          donor['profile_image_url'],
            'blood_group':  donor['blood_group'],
            // PersonDetailsPage fields
            'committee_position':   donor['committee_position'],
            'designation':          donor['designation'],
            'member_type':          donor['member_type'],
            'short_bio':            donor['short_bio'],
            'present_address':      donor['present_address'],
            'location_dms':         donor['location_dms'],
            'school_name':          donor['school_name'],
            'school_group':         donor['school_group'],
            'school_passing_year':  donor['school_passing_year'],
            'college_name':         donor['college_name'],
            'college_group':        donor['college_group'],
            'college_passing_year': donor['college_passing_year'],
            'university_name':      donor['university_name'],
            'department':           donor['department'],
            'current_year':         donor['current_year'],
            'current_semester':     donor['current_semester'],
          });
        }
      }
      temp.sort((a, b) => a['dist'].compareTo(b['dist']));
      setState(() { donors = temp; loading = false; });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> _call(String number) async {
    if (number.isEmpty) {
      _showMessage(SC.tr('noNumberAvailable'), isError: true); return;
    }
    HapticFeedback.mediumImpact();
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _copyNumber(String number) {
    if (number.isEmpty) {
      _showMessage(SC.tr('noNumberAvailable'), isError: true); return;
    }
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: number));
    _showMessage(SC.tr('numberCopied'), isError: false);
  }

  void _showMessage(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: isError
          ? Colors.redAccent.withValues(alpha: 0.9)
          : Colors.greenAccent.withValues(alpha: 0.9),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  // FIX: donor card click → PersonDetailsPage এ navigate করে
  void _navigateToDonorDetails(Map<String, dynamic> d, int index) {
    HapticFeedback.selectionClick();

    // Role নির্ধারণ: committee position > designation > blood group donor
    final role = (d['committee_position'] as String?)?.isNotEmpty == true
        ? d['committee_position'] as String
        : (d['designation'] as String?)?.isNotEmpty == true
        ? d['designation'] as String
        : SC.tr('bloodDonor'); // fallback label

    // Category নির্ধারণ
    final memberType = (d['member_type'] as String?) ?? '';
    String category;
    if (memberType == 'present_committee') {
      category = SC.tr('currentCommitteeMember');
    } else if (memberType == 'advisor') {
      category = SC.tr('advisor');
    } else if (memberType == 'previous_committee') {
      category = SC.tr('pastCommitteeMember');
    } else {
      category = SC.tr('bloodDonor');
    }

    final heroTag = 'donor_${d['id']}_$index';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PersonDetailsPage(
          name:               d['name'] as String,
          role:               role,
          category:           category,
          heroTag:            heroTag,
          imageUrl:           d['img'] as String?,
          bio:                d['short_bio'] as String?,
          presentAddress:     d['present_address'] as String?,
          bloodGroup:         d['blood_group'] as String?,
          locationDms:        d['location_dms'] as String?,
          schoolName:         d['school_name'] as String?,
          schoolGroup:        d['school_group'] as String?,
          schoolPassingYear:  d['school_passing_year'] as int?,
          collegeName:        d['college_name'] as String?,
          collegeGroup:       d['college_group'] as String?,
          collegePassingYear: d['college_passing_year'] as int?,
          universityName:     d['university_name'] as String?,
          department:         d['department'] as String?,
          currentYear:        d['current_year'] as int?,
          currentSemester:    d['current_semester'] as int?,
          themeColor:         Colors.redAccent,
          visibility:         'public',
          isOwner:            false,
        ),
      ),
    );
  }

  List<Polyline> _buildPolylines() => donors.map((d) => Polyline(
    points: [widget.userLocation, LatLng(d['lat'], d['lng'])],
    strokeWidth: 2.5,
    color: Colors.cyanAccent.withValues(alpha: 0.5),
    gradientColors: [
      Colors.cyanAccent.withValues(alpha: 0.7),
      Colors.blueAccent.withValues(alpha: 0.3),
    ],
  )).toList();

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
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: _isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (_isDark ? Colors.black : Colors.white)
                .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                color: _textColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite,
                color: Colors.redAccent, size: 18),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              '${SC.tr('nearestDonors')} ${widget.bloodGroup} ${SC.tr('donors')}',
              style: TextStyle(color: _textColor,
                  fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: _isDark
              ? const LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          )
              : const LinearGradient(
            colors: [Color(0xFFF0F4FF), Color(0xFFE8EFFF), Color(0xFFEFF6FF)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: Stack(children: [
          Positioned(top: -50, right: -50,
              child: _blurOrb(200, Colors.redAccent.withValues(alpha: 0.1))),
          Positioned(bottom: -80, left: -80,
              child: _blurOrb(250, Colors.cyanAccent.withValues(alpha: 0.08))),
          SafeArea(child: loading ? _buildLoadingState() : _buildContent()),
        ]),
      ),
    );
  }

  Widget _blurOrb(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 50)]),
  );

  Widget _buildLoadingState() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const CircularProgressIndicator(color: Colors.redAccent, strokeWidth: 3),
      const SizedBox(height: 20),
      Text(SC.tr('findingDonors'),
          style: TextStyle(color: _subColor.withValues(alpha: 0.7),
              fontSize: 16, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _buildContent() => Column(children: [
    const SizedBox(height: 10),
    _buildStatsHeader(),
    const SizedBox(height: 16),
    _buildMapSection(),
    const SizedBox(height: 16),
    _buildListSection(),
  ]);

  Widget _buildStatsHeader() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (_isDark ? Colors.white : Colors.black)
            .withValues(alpha: 0.1)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _statItem(Icons.people_outline, '${donors.length}', SC.tr('found')),
        Container(width: 1, height: 30,
            color: (_isDark ? Colors.white : Colors.black)
                .withValues(alpha: 0.15)),
        _statItem(Icons.location_on_outlined,
          donors.isNotEmpty
              ? '${donors.first['dist'].toStringAsFixed(1)} km'
              : '--',
          SC.tr('nearest'),
        ),
        Container(width: 1, height: 30,
            color: (_isDark ? Colors.white : Colors.black)
                .withValues(alpha: 0.15)),
        _statItem(Icons.bloodtype_outlined, widget.bloodGroup, SC.tr('group')),
      ]),
    ),
  );

  Widget _statItem(IconData icon, String value, String label) => Column(
    children: [
      Icon(icon, color: Colors.cyanAccent, size: 24),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(color: _textColor,
          fontSize: 18, fontWeight: FontWeight.w900)),
      Text(label, style: TextStyle(
          color: _subColor.withValues(alpha: 0.6),
          fontSize: 11, fontWeight: FontWeight.w600)),
    ],
  );

  Widget _buildMapSection() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: (_isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.15), width: 2),
        ),
        child: Stack(children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.userLocation,
              initialZoom: 12,
              interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.css',
                maxNativeZoom: 19,
              ),
              // TileLayer(
              //   urlTemplate: 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}',
              //   userAgentPackageName: 'com.example.css',
              //   maxNativeZoom: 20,
              // ),
              PolylineLayer(polylines: _buildPolylines()),
              MarkerLayer(markers: [
                Marker(
                  point: widget.userLocation, width: 60, height: 60,
                  child: const Icon(Icons.person_pin_circle,
                      color: Colors.cyanAccent, size: 50),
                ),
                ...donors.asMap().entries.map((entry) => Marker(
                  point: LatLng(entry.value['lat'], entry.value['lng']),
                  width: 50, height: 50,
                  child: Stack(alignment: Alignment.center, children: [
                    const Icon(Icons.location_on,
                        color: Colors.redAccent, size: 40),
                    Positioned(
                      top: 8,
                      child: Text('${entry.key + 1}',
                          style: const TextStyle(color: Colors.white,
                              fontSize: 10, fontWeight: FontWeight.w900)),
                    ),
                  ]),
                )),
              ]),
            ],
          ),
          Positioned(
            bottom: 4, right: 4,
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
        ]),
      ),
    ),
  );

  Widget _buildListSection() => Expanded(
    child: donors.isEmpty
        ? _buildEmptyState()
        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.people, color: Colors.cyanAccent, size: 18),
          ),
          const SizedBox(width: 10),
          Text(SC.tr('availableDonors'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                  color: _textColor)),
        ]),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          itemCount: donors.length,
          itemBuilder: (context, index) => FadeTransition(
            opacity: _animController,
            child: _buildDonorCard(index),
          ),
        ),
      ),
    ]),
  );

  Widget _buildDonorCard(int index) {
    final d = donors[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: (_isDark ? Colors.white : Colors.black)
                .withValues(alpha: 0.08)),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: _isDark ? 0.3 : 0.07),
            blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // FIX: ProfilePage এর বদলে PersonDetailsPage এ navigate করছে
          onTap: () => _navigateToDonorDetails(d, index),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              // Rank badge
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: index == 0
                        ? [Colors.amber, Colors.orange]
                        : [Colors.cyanAccent.withValues(alpha: 0.3),
                      Colors.blueAccent.withValues(alpha: 0.2)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: index == 0
                        ? Colors.amber
                        : Colors.cyanAccent.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text('${index + 1}',
                      style: TextStyle(
                          color: index == 0 ? Colors.white : Colors.cyanAccent,
                          fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),

              // Avatar — Hero tag দেওয়া হয়েছে navigation এর সাথে match করতে
              Hero(
                tag: 'donor_${d['id']}_$index',
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Colors.cyanAccent, Colors.blueAccent]),
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: _cardColor,
                    backgroundImage: d['img'] != null
                        ? NetworkImage(d['img']) : null,
                    child: d['img'] == null
                        ? Text(d['name'][0].toUpperCase(),
                        style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.bold, fontSize: 20))
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(d['name'],
                              style: TextStyle(color: _textColor,
                                  fontWeight: FontWeight.w900, fontSize: 15),
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (index == 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [Colors.amber, Colors.orange]),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(SC.tr('nearestBadge'),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 9,
                                    fontWeight: FontWeight.w900)),
                          ),
                      ]),
                      const SizedBox(height: 6),
                      Row(children: [
                        const Icon(Icons.location_on,
                            color: Colors.redAccent, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${d['dist'].toStringAsFixed(2)} ${SC.tr('kmAway')}',
                          style: TextStyle(color: _subColor.withValues(alpha: 0.7),
                              fontSize: 12),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => _copyNumber(d['phone']),
                        child: Row(children: [
                          const Icon(Icons.phone,
                              color: Colors.cyanAccent, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              d['phone'].isEmpty
                                  ? SC.tr('noNumber') : d['phone'],
                              style: const TextStyle(
                                  color: Colors.cyanAccent,
                                  fontWeight: FontWeight.w600, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.copy,
                              color: Colors.cyanAccent, size: 12),
                        ]),
                      ),
                    ]),
              ),

              // Call button
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Colors.greenAccent, Colors.green]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  icon: const Icon(Icons.call, color: Colors.white, size: 20),
                  // FIX: call button এ GestureDetector bubble up বন্ধ
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _call(d['phone']);
                  },
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.search_off, color: Colors.redAccent, size: 60),
      ),
      const SizedBox(height: 20),
      Text(SC.tr('noDonorsFound'),
          style: TextStyle(color: _textColor, fontSize: 22,
              fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      Text(
        '${SC.tr('noDonorsDesc')} ${widget.bloodGroup}',
        textAlign: TextAlign.center,
        style: TextStyle(color: _subColor.withValues(alpha: 0.6), fontSize: 14),
      ),
    ]),
  );
}
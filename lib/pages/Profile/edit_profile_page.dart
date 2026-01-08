import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/profile_model.dart';
import '../../services/profile_service.dart';

class EditProfilePage extends StatefulWidget {
  final ProfileModel profile;
  const EditProfilePage({super.key, required this.profile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _service = ProfileService();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _imageBytes;
  bool _saving = false;

  final MapController _mapController = MapController();
  LatLng _selectedLocation = const LatLng(23.8103, 90.4125);
  List<Marker> _markers = [];
  bool _fetchingAddress = false;

  String? _selectedGender, _selectedMemberType, _selectedBloodGroup, _selectedCommitteePos;

  final List<String> committeePositions = [
    "সভাপতি", "সহ-সভাপতি", "সাধারণ সম্পাদক", "যুগ্ম-সাধারণ সম্পাদক", "সাংগঠনিক সম্পাদক",
    "সহ-সাংগঠনিক সম্পাদক", "দপ্তর সম্পাদক", "সিনিয়র সহ-দপ্তর সম্পাদক", "সহ-দপ্তর সম্পাদক",
    "অর্থ সম্পাদক", "সিনিয়র অর্থ সম্পাদক", "সহ-অর্থ সম্পাদক", "শিক্ষা সম্পাদক", "সহ-শিক্ষা সম্পাদক",
    "পরিকল্পনা সম্পাদক", "সহ-পরিকল্পনা সম্পাদক", "মানব সম্পদ সম্পাদক", "সহ-মানব সম্পদ সম্পাদক",
    "পরিবেশ সম্পাদক", "সহ-পরিবেশ সম্পাদক", "ধর্ম সম্পাদক", "সহ-ধর্ম সম্পাদক", "প্রচার সম্পাদক",
    "সহ-প্রচার সম্পাদক", "ব্র্যান্ড ও গণমাধ্যম সম্পাদক", "সিনিয়র ব্র্যান্ড ও গণমাধ্যম সম্পাদক",
    "গ্রাফিক্স ডিজাইনার", "সহ-গ্রাফিক্স ডিজাইনার", "ক্রিয়া সম্পাদক", "সহ-ক্রিয়া সম্পাদক",
    "পাঠাগার সম্পাদক", "সহ-পাঠাগার সম্পাদক", "সাংস্কৃতিক সম্পাদক", "সহ-সাংস্কৃতিক সম্পাদক",
    "বিজ্ঞান ও প্রযুক্তি সম্পাদক", "সহ-বিজ্ঞান ও প্রযুক্তি সম্পাদক", "সমাজ কল্যাণ সম্পাদক",
    "সহ-সমাজ কল্যাণ সম্পাদক", "স্বাস্থ্য সম্পাদক", "সহ-স্বাস্থ্য সম্পাদক", "নারী সম্পাদক",
    "সহ-নারী সম্পাদক", "আন্তর্জাতিক সম্পাদক", "সহ-আন্তর্জাতিক সম্পাদক", "ছাত্র কল্যাণ সম্পাদক",
    "সহ-ছাত্র কল্যাণ সম্পাদক", "সাহিত্য সম্পাদক", "সহ-সাহিত্য সম্পাদক", "তথ্য ও গবেষণা সম্পাদক",
    "সহ-তথ্য ও গবেষণা সম্পাদক", "ত্রাণ ও দুর্যোগ সম্পাদক", "সিনিয়র ত্রাণ ও দুর্যোগ সম্পাদক",
    "সহ-ত্রাণ ও দুর্যোগ সম্পাদক", "কার্যকরী সদস্য"
  ];

  late TextEditingController
  fullNameCtrl, fullNameBnCtrl, memberSinceCtrl, dobCtrl, altMobileCtrl,
      whatsappCtrl, fbLinkCtrl, presentAddrCtrl, permanentAddrCtrl, districtCtrl,
      upazilaCtrl, lastDonationCtrl, nextDonationCtrl, eligibilityCtrl,
      donationCountCtrl, prefLocationCtrl, schoolNameCtrl, schoolGroupCtrl,
      schoolYearCtrl, collegeNameCtrl, collegeGroupCtrl, collegeYearCtrl,
      uniNameCtrl, deptCtrl, studentIdCtrl, currYearCtrl, currSemCtrl,
      bioCtrl, whyJoinedCtrl, goalsCtrl, hobbiesCtrl, fbUserCtrl, portfolioCtrl,
      latCtrl, lngCtrl, addressCtrl, committeePosCtrl;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;

    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();

    _selectedGender = p.gender;
    _selectedMemberType = p.memberType;
    _selectedBloodGroup = p.bloodGroup;
    _selectedCommitteePos = p.committeePosition;

    fullNameCtrl = TextEditingController(text: p.fullName);
    fullNameBnCtrl = TextEditingController(text: p.fullNameBn);
    memberSinceCtrl = TextEditingController(text: _fmtDate(p.memberSince));
    dobCtrl = TextEditingController(text: _fmtDate(p.dateOfBirth));
    altMobileCtrl = TextEditingController(text: p.alternativeMobile);
    whatsappCtrl = TextEditingController(text: p.whatsappNumber);
    fbLinkCtrl = TextEditingController(text: p.facebookLink);
    presentAddrCtrl = TextEditingController(text: p.presentAddress);
    permanentAddrCtrl = TextEditingController(text: p.permanentAddress);
    districtCtrl = TextEditingController(text: p.district);
    upazilaCtrl = TextEditingController(text: p.upazila);
    lastDonationCtrl = TextEditingController(text: _fmtDate(p.lastDonationDate));
    nextDonationCtrl = TextEditingController(text: _fmtDate(p.nextAvailableDonationDate));
    eligibilityCtrl = TextEditingController(text: p.donationEligibility);
    donationCountCtrl = TextEditingController(text: p.totalDonationCount?.toString());
    prefLocationCtrl = TextEditingController(text: p.preferredDonationLocation);
    schoolNameCtrl = TextEditingController(text: p.schoolName);
    schoolGroupCtrl = TextEditingController(text: p.schoolGroup);
    schoolYearCtrl = TextEditingController(text: p.schoolPassingYear?.toString());
    collegeNameCtrl = TextEditingController(text: p.collegeName);
    collegeGroupCtrl = TextEditingController(text: p.collegeGroup);
    collegeYearCtrl = TextEditingController(text: p.collegePassingYear?.toString());
    uniNameCtrl = TextEditingController(text: p.universityName);
    deptCtrl = TextEditingController(text: p.department);
    studentIdCtrl = TextEditingController(text: p.studentId);
    currYearCtrl = TextEditingController(text: p.currentYear?.toString());
    currSemCtrl = TextEditingController(text: p.currentSemester?.toString());
    bioCtrl = TextEditingController(text: p.shortBio);
    whyJoinedCtrl = TextEditingController(text: p.whyJoined);
    goalsCtrl = TextEditingController(text: p.futureGoals);
    hobbiesCtrl = TextEditingController(text: p.hobbies);
    fbUserCtrl = TextEditingController(text: p.facebook);
    portfolioCtrl = TextEditingController(text: p.portfolioWebsite);
    latCtrl = TextEditingController(text: p.latitude?.toString());
    lngCtrl = TextEditingController(text: p.longitude?.toString());
    addressCtrl = TextEditingController(text: p.locationDms);
    committeePosCtrl = TextEditingController(text: p.committeePosition);

    if (p.latitude != null && p.longitude != null) {
      _selectedLocation = LatLng(p.latitude!, p.longitude!);
    }
    _setInitialMarker(_selectedLocation);
  }

  void _setInitialMarker(LatLng pos) {
    _markers = [
      Marker(
        point: pos,
        width: 80,
        height: 80,
        child: const Icon(Icons.location_on, size: 50, color: Colors.redAccent),
      )
    ];
  }

  @override
  void dispose() {
    _animController.dispose();
    fullNameCtrl.dispose(); fullNameBnCtrl.dispose(); memberSinceCtrl.dispose();
    dobCtrl.dispose(); altMobileCtrl.dispose(); whatsappCtrl.dispose();
    fbLinkCtrl.dispose(); presentAddrCtrl.dispose(); permanentAddrCtrl.dispose();
    districtCtrl.dispose(); upazilaCtrl.dispose(); lastDonationCtrl.dispose();
    nextDonationCtrl.dispose(); eligibilityCtrl.dispose(); donationCountCtrl.dispose();
    prefLocationCtrl.dispose(); schoolNameCtrl.dispose(); schoolGroupCtrl.dispose();
    schoolYearCtrl.dispose(); collegeNameCtrl.dispose(); collegeGroupCtrl.dispose();
    collegeYearCtrl.dispose(); uniNameCtrl.dispose(); deptCtrl.dispose();
    studentIdCtrl.dispose(); currYearCtrl.dispose(); currSemCtrl.dispose();
    bioCtrl.dispose(); whyJoinedCtrl.dispose(); goalsCtrl.dispose();
    hobbiesCtrl.dispose(); fbUserCtrl.dispose(); portfolioCtrl.dispose();
    latCtrl.dispose(); lngCtrl.dispose(); addressCtrl.dispose();
    committeePosCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime? d) => d == null ? '' : d.toIso8601String().split('T')[0];

  // ল্যাটিটিউড এবং লঙ্গিটিউড থেকে DMS ফরম্যাট তৈরির ফাংশন
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

  void _onDonationDateChanged(DateTime lastDate) {
    final nextDate = DateTime(lastDate.year, lastDate.month + 3, lastDate.day);
    setState(() {
      nextDonationCtrl.text = _fmtDate(nextDate);
      eligibilityCtrl.text = DateTime.now().isAfter(nextDate) ? "Eligible" : "Ineligible";
    });
  }

  Future<void> _handleMyLocation() async {
    setState(() => _fetchingAddress = true);
    try {
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      LatLng myLoc = LatLng(pos.latitude, pos.longitude);
      await _updateMarker(myLoc);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _fetchingAddress = false);
    }
  }

  Future<void> _updateMarker(LatLng pos) async {
    setState(() {
      _selectedLocation = pos;
      _markers = [
        Marker(
          point: pos,
          width: 80,
          height: 80,
          child: const Icon(Icons.location_on, size: 50, color: Colors.redAccent),
        )
      ];
      latCtrl.text = pos.latitude.toStringAsFixed(6);
      lngCtrl.text = pos.longitude.toStringAsFixed(6);
      // এখানে অ্যাড্রেস খোঁজার পরিবর্তে সরাসরি DMS জেনারেট করা হচ্ছে
      addressCtrl.text = _convertToDMS(pos.latitude, pos.longitude);
    });
    _mapController.move(pos, 15.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Edit Full Profile", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: _saving
            ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
            : FadeTransition(
          opacity: _fadeAnimation,
          child: Form(
            key: _formKey,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: kToolbarHeight + 40)),
                _buildProfileHeaderSection(),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildLocationSection(),
                      _buildSectionCard("Basic Information", Icons.person_rounded, Colors.blueAccent, [
                        _buildModernTextField("Full Name (EN)", fullNameCtrl, required: true, icon: Icons.badge),
                        _buildModernTextField("নাম (বাংলা)", fullNameBnCtrl, icon: Icons.translate),
                        Row(children: [
                          Expanded(child: _buildModernDropdown("Gender", ["Male", "Female", "Other"], _selectedGender, (v) => setState(() => _selectedGender = v))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildModernDatePicker("Birth Date", dobCtrl)),
                        ]),
                        _buildModernDropdown("Member Type", ["Committee", "Volunteer"], _selectedMemberType, (v) => setState(() => _selectedMemberType = v)),

                        _buildModernDropdown(
                            "Committee Position",
                            committeePositions,
                            _selectedCommitteePos,
                                (v) {
                              setState(() {
                                _selectedCommitteePos = v;
                                committeePosCtrl.text = v!;
                              });
                            }
                        ),

                        _buildModernDatePicker("Member Since", memberSinceCtrl),
                      ]),
                      _buildSectionCard("Contact Details", Icons.contact_phone_rounded, Colors.orangeAccent, [
                        _buildModernTextField("WhatsApp Number", whatsappCtrl, icon: Icons.chat_bubble_rounded),
                        _buildModernTextField("Alternative Mobile", altMobileCtrl, icon: Icons.phone_iphone_rounded),
                        _buildModernTextField("Facebook Profile Link", fbLinkCtrl, icon: Icons.link_rounded),
                        _buildModernTextField("Present Address", presentAddrCtrl, icon: Icons.home_rounded, maxLines: 2),
                        _buildModernTextField("Permanent Address", permanentAddrCtrl, icon: Icons.location_city_rounded, maxLines: 2),
                        Row(children: [
                          Expanded(child: _buildModernTextField("District", districtCtrl, icon: Icons.map_rounded)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildModernTextField("Upazila", upazilaCtrl, icon: Icons.explore_rounded)),
                        ]),
                      ]),
                      _buildSectionCard("Blood Donation Status", Icons.water_drop_rounded, Colors.redAccent, [
                        _buildModernDropdown("Blood Group", ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"], _selectedBloodGroup, (v) => setState(() => _selectedBloodGroup = v)),
                        _buildModernDatePicker("Last Donation Date", lastDonationCtrl, isDonation: true),
                        _buildModernTextField("Total Donation Count", donationCountCtrl, number: true, icon: Icons.add_moderator_rounded),
                        _buildModernTextField("Preferred Location", prefLocationCtrl, icon: Icons.pin_drop_rounded),
                        _buildModernTextField("Eligibility", eligibilityCtrl, readOnly: true, icon: Icons.health_and_safety_rounded),
                      ]),
                      _buildSectionCard("Academic Records", Icons.school_rounded, Colors.greenAccent, [
                        _buildModernTextField("School Name", schoolNameCtrl, icon: Icons.apartment_rounded),
                        Row(children: [
                          Expanded(child: _buildModernTextField("SSC Group", schoolGroupCtrl)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildModernTextField("Passing Year", schoolYearCtrl, number: true)),
                        ]),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: Colors.white10)),
                        _buildModernTextField("College Name", collegeNameCtrl, icon: Icons.account_balance_rounded),
                        Row(children: [
                          Expanded(child: _buildModernTextField("HSC Group", collegeGroupCtrl)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildModernTextField("Passing Year", collegeYearCtrl, number: true)),
                        ]),
                      ]),
                      _buildSectionCard("University Details", Icons.account_balance_rounded, Colors.indigoAccent, [
                        _buildModernTextField("University Name", uniNameCtrl, icon: Icons.location_city_rounded),
                        _buildModernTextField("Department", deptCtrl, icon: Icons.category_rounded),
                        _buildModernTextField("Student ID", studentIdCtrl, icon: Icons.fingerprint_rounded),
                        Row(children: [
                          Expanded(child: _buildModernTextField("Current Year", currYearCtrl, number: true)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildModernTextField("Current Semester", currSemCtrl, number: true)),
                        ]),
                      ]),
                      _buildSectionCard("Bio & Social Presence", Icons.public_rounded, Colors.purpleAccent, [
                        _buildModernTextField("Short Bio", bioCtrl, maxLines: 3, icon: Icons.notes_rounded),
                        _buildModernTextField("Why Joined?", whyJoinedCtrl, maxLines: 2, icon: Icons.flag_rounded),
                        _buildModernTextField("Future Goals", goalsCtrl, maxLines: 2, icon: Icons.ads_click_rounded),
                        _buildModernTextField("Hobbies", hobbiesCtrl, icon: Icons.interests_rounded),
                        _buildModernTextField("Facebook Username", fbUserCtrl, icon: Icons.alternate_email_rounded),
                        _buildModernTextField("Portfolio Website", portfolioCtrl, icon: Icons.language_rounded),
                      ]),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildSaveFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  _buildProfileHeaderSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.only(bottom: 30),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 130, height: 130,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 2),
                      boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)]
                  ),
                ),
                CircleAvatar(
                  radius: 60,
                  backgroundColor: const Color(0xFF1A2A3A),
                  backgroundImage: _imageBytes != null
                      ? MemoryImage(_imageBytes!)
                      : (widget.profile.profileImageUrl != null ? NetworkImage(widget.profile.profileImageUrl!) : null) as ImageProvider?,
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.cyanAccent, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF0F2027), size: 20),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 15),
            Text(fullNameCtrl.text, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
            Text(_selectedMemberType ?? "Member", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return _buildSectionCard("Map Location Settings", Icons.map_rounded, Colors.tealAccent, [
      Container(
          height: 220,
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                      initialCenter: _selectedLocation,
                      initialZoom: 14,
                      onTap: (tapPosition, point) => _updateMarker(point)
                  ),
                  children: [
                    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                    MarkerLayer(markers: _markers)
                  ]
              )
          )
      ),
      _buildModernTextField("Current Location (DMS)", addressCtrl, readOnly: true, icon: Icons.my_location_rounded),

      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _handleMyLocation,
          icon: Icon(Icons.gps_fixed_rounded, size: 18, color: _fetchingAddress ? Colors.white38 : const Color(0xFF0F2027)),
          label: Text(_fetchingAddress ? "Updating DMS..." : "Update Current Location DMS", style: const TextStyle(fontWeight: FontWeight.w900)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.tealAccent,
            foregroundColor: const Color(0xFF0F2027),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    ]);
  }

  Widget _buildSectionCard(String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 12),
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(20), child: Column(children: children)),
        ],
      ),
    );
  }

  Widget _buildModernTextField(String label, TextEditingController c, {bool required = false, bool number = false, bool readOnly = false, int maxLines = 1, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c, maxLines: maxLines, readOnly: readOnly,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
          prefixIcon: icon != null ? Icon(icon, color: Colors.cyanAccent.withOpacity(0.5), size: 20) : null,
          filled: true,
          fillColor: Colors.black.withOpacity(0.2),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.cyanAccent, width: 1.5)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.5))),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.redAccent)),
        ),
        validator: required ? (v) => (v == null || v.isEmpty) ? "Required Field" : null : null,
      ),
    );
  }

  Widget _buildModernDropdown(String label, List<String> items, String? val, Function(String?) fn) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: (val != null && items.contains(val)) ? val : null,
        dropdownColor: const Color(0xFF203A43),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
          filled: true,
          fillColor: Colors.black.withOpacity(0.2),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.cyanAccent)),
        ),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: fn,
      ),
    );
  }

  Widget _buildModernDatePicker(String label, TextEditingController c, {bool isDonation = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c, readOnly: true,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
        onTap: () async {
          DateTime? d = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1950),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark(primary: Colors.cyanAccent, onPrimary: Color(0xFF0F2027), surface: Color(0xFF203A43), onSurface: Colors.white)), child: child!);
              }
          );
          if (d != null) { setState(() { c.text = _fmtDate(d); if (isDonation) _onDonationDateChanged(d); }); }
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
          prefixIcon: Icon(Icons.calendar_today_rounded, color: Colors.cyanAccent.withOpacity(0.5), size: 18),
          filled: true,
          fillColor: Colors.black.withOpacity(0.2),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.cyanAccent)),
        ),
      ),
    );
  }

  Widget _buildSaveFAB() {
    return Container(
      width: 200,
      height: 55,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 15, spreadRadius: -5)]
      ),
      child: FloatingActionButton.extended(
        onPressed: _saveProfile,
        backgroundColor: Colors.cyanAccent,
        elevation: 0,
        icon: const Icon(Icons.cloud_upload_rounded, color: Color(0xFF0F2027)),
        label: const Text("SAVE CHANGES", style: TextStyle(color: Color(0xFF0F2027), fontWeight: FontWeight.w900, letterSpacing: 1.2)),
      ),
    );
  }

  Future<void> _pickImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (x != null) { final b = await x.readAsBytes(); setState(() => _imageBytes = b); }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final p = widget.profile;

    p.fullName = fullNameCtrl.text;
    p.fullNameBn = fullNameBnCtrl.text;
    p.gender = _selectedGender;
    p.dateOfBirth = DateTime.tryParse(dobCtrl.text);
    p.memberType = _selectedMemberType;
    p.committeePosition = committeePosCtrl.text;
    p.memberSince = DateTime.tryParse(memberSinceCtrl.text);
    p.whatsappNumber = whatsappCtrl.text;
    p.alternativeMobile = altMobileCtrl.text;
    p.facebookLink = fbLinkCtrl.text;
    p.presentAddress = presentAddrCtrl.text;
    p.permanentAddress = permanentAddrCtrl.text;
    p.district = districtCtrl.text;
    p.upazila = upazilaCtrl.text;
    p.bloodGroup = _selectedBloodGroup;
    p.lastDonationDate = DateTime.tryParse(lastDonationCtrl.text);
    p.totalDonationCount = int.tryParse(donationCountCtrl.text);
    p.preferredDonationLocation = prefLocationCtrl.text;
    p.donationEligibility = eligibilityCtrl.text;
    p.schoolName = schoolNameCtrl.text;
    p.schoolGroup = schoolGroupCtrl.text;
    p.schoolPassingYear = int.tryParse(schoolYearCtrl.text);
    p.collegeName = collegeNameCtrl.text;
    p.collegeGroup = collegeGroupCtrl.text;
    p.collegePassingYear = int.tryParse(collegeYearCtrl.text);
    p.universityName = uniNameCtrl.text;
    p.department = deptCtrl.text;
    p.studentId = studentIdCtrl.text;
    p.currentYear = int.tryParse(currYearCtrl.text);
    p.currentSemester = int.tryParse(currSemCtrl.text);
    p.shortBio = bioCtrl.text;
    p.whyJoined = whyJoinedCtrl.text;
    p.futureGoals = goalsCtrl.text;
    p.hobbies = hobbiesCtrl.text;
    p.facebook = fbUserCtrl.text;
    p.portfolioWebsite = portfolioCtrl.text;

    p.latitude = double.tryParse(latCtrl.text);
    p.longitude = double.tryParse(lngCtrl.text);
    p.locationDms = addressCtrl.text;

    p.lastUpdatedDate = DateTime.now();

    try {
      if (_imageBytes != null) {
        final path = 'profiles/${p.id}.jpg';
        await Supabase.instance.client.storage.from('profile-images').uploadBinary(path, _imageBytes!, fileOptions: const FileOptions(upsert: true));
        p.profileImageUrl = Supabase.instance.client.storage.from('profile-images').getPublicUrl(path);
      }
      await _service.saveProfile(p);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Save Error: $e")));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}